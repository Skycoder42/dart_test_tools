#!/usr/bin/env bash
#
# Branch resolver and update runner for the dart-test-tools-auto-update skill.
#
# Works out whether this is a *new* dependency update (default branch) or a *fix* for an
# existing one (the auto-update PR branch), puts the worktree on the matching branch, and
# — for a new update — reproduces locally what the shared auto-update workflow does in CI.
#
# It never commits, pushes, merges or rebases. The only mutation it performs on the
# repository itself is switching branches, and only on a clean worktree.
#
set -euo pipefail

readonly SELF="${0##*/}"
readonly UPDATE_BRANCH='automatic-dependency-updates'
readonly WORKFLOW_REF='Skycoder42/dart_test_tools/.github/workflows/auto-update.yml'
readonly OUT_DIR="${TMPDIR:-/tmp}/dart-test-tools-auto-update"

# Accumulated `warning:` lines. They are collected rather than printed as they happen so
# that the record stays one contiguous block on stdout.
declare -a WARNINGS=()
# One TAB separated workflow match per entry, filled by scan_update_workflows.
declare -a MATCHES=()

note() {
	printf '%s: %s\n' "$SELF" "$*" >&2
}

warn() {
	WARNINGS+=("$*")
	printf '%s: warning: %s\n' "$SELF" "$*" >&2
}

# Emits an `error` record and exits non-zero. Reserved for failures of the script itself:
# a bad invocation, an unusable git state, a missing tool. A failing auto_update run is a
# result, not a script failure, and is reported through `update_exit_code` instead.
die() {
	printf '%s: error: %s\n' "$SELF" "$*" >&2
	printf '>>> auto-update-prepare\n'
	printf 'status: error\n'
	local w
	for w in ${WARNINGS[@]+"${WARNINGS[@]}"}; do
		printf 'warning: %s\n' "$w"
	done
	printf 'error: %s\n' "$*"
	printf '<<< auto-update-prepare\n'
	exit 1
}

usage() {
	cat >&2 <<-EOF
		usage: $SELF [<mode>] [ignore-branch]

		  <mode>          'new' (start a fresh dependency update, on the default branch)
		                  or 'existing' (fix the update that is already open on
		                  '$UPDATE_BRANCH'). Optional — when omitted the
		                  mode is derived from the branch that is currently checked out.
		  ignore-branch   Trust that the correct branch is already checked out and skip
		                  every git inspection and branch switch. Requires <mode>.

		Output is a single machine readable record on stdout:

		  >>> auto-update-prepare
		  <key>: <value>
		  ...
		  <<< auto-update-prepare

		Keys are lowercase, values are single-line, and everything after the first
		': ' belongs to the value. 'warning' may appear any number of times, every
		other key at most once. Progress and diagnostics go to stderr and are not
		part of the record.
	EOF
	exit 64
}

# --- git helpers -----------------------------------------------------------------------

repo_root() {
	git rev-parse --show-toplevel 2>/dev/null || die "not inside a git repository"
}

current_branch() {
	local branch
	branch="$(git rev-parse --abbrev-ref HEAD)"
	[[ $branch != HEAD ]] || die "HEAD is detached — check out a branch first"
	printf '%s\n' "$branch"
}

worktree_is_clean() {
	[[ -z "$(git status --porcelain --untracked-files=no)" ]]
}

branch_exists() {
	git show-ref --verify --quiet "refs/heads/$1"
}

remote_branch_exists() {
	git show-ref --verify --quiet "refs/remotes/origin/$1"
}

# The default branch, normally 'main'. Falls back to whatever origin/HEAD points at so the
# skill still works in a repository that named its default branch differently.
main_branch() {
	if branch_exists main || remote_branch_exists main; then
		printf 'main\n'
		return
	fi
	local head
	if head="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)"; then
		printf '%s\n' "${head#origin/}"
		return
	fi
	printf 'main\n'
}

branch_for_mode() {
	case "$1" in
		new) main_branch ;;
		existing) printf '%s\n' "$UPDATE_BRANCH" ;;
	esac
}

# Reports how far the local branch trails its upstream, if at all. Purely informational —
# the script deliberately does not merge or rebase on the user's behalf.
check_up_to_date() {
	local branch="$1"
	remote_branch_exists "$branch" || return 0
	local behind
	behind="$(git rev-list --count "$branch..origin/$branch" 2>/dev/null || echo 0)"
	((behind > 0)) &&
		warn "local '$branch' is $behind commit(s) behind 'origin/$branch' — it may not reflect the state of the open pull request"
	return 0
}

switch_branch() {
	local branch="$1"

	worktree_is_clean ||
		die "the worktree has uncommitted changes — refusing to switch to '$branch'. Commit or stash them first."

	# Best effort: an offline run must still work as long as the branch exists locally.
	git fetch --quiet origin "$branch" 2>/dev/null ||
		warn "could not fetch 'origin/$branch' — working with the local state only"

	note "switching to '$branch'"
	if branch_exists "$branch"; then
		git switch --quiet "$branch" || die "failed to check out '$branch'"
	elif remote_branch_exists "$branch"; then
		git switch --quiet --create "$branch" --track "origin/$branch" ||
			die "failed to create a local '$branch' tracking 'origin/$branch'"
	else
		die "branch '$branch' exists neither locally nor on origin"
	fi
}

# --- mode resolution -------------------------------------------------------------------

# Sets MODE, BRANCH and BRANCH_CHECK.
resolve_mode() {
	local requested="$1" ignore_branch="$2"

	if [[ $ignore_branch == true ]]; then
		MODE="$requested"
		BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
		BRANCH_CHECK=ignored
		warn "branch checks skipped on request — assuming '$MODE' is correct for the current worktree"
		return
	fi

	local branch main
	branch="$(current_branch)"
	main="$(main_branch)"

	if [[ -n $requested ]]; then
		local want
		want="$(branch_for_mode "$requested")"
		MODE="$requested"
		if [[ $branch == "$want" ]]; then
			BRANCH_CHECK=matched
		else
			switch_branch "$want"
			BRANCH_CHECK=switched
		fi
		BRANCH="$want"
	else
		case "$branch" in
			"$main") MODE=new ;;
			"$UPDATE_BRANCH") MODE=existing ;;
			*)
				die "branch '$branch' is neither '$main' nor '$UPDATE_BRANCH' — check out one of them, or pass an explicit mode"
				;;
		esac
		BRANCH="$branch"
		BRANCH_CHECK=derived
	fi

	check_up_to_date "$BRANCH"
}

# --- workflow discovery ----------------------------------------------------------------

# Fills MATCHES with one TAB separated record per job that calls the shared auto-update
# workflow: <file>\t<job>\t<uses>\t<workingDirectory>\t<flutterCompat>. Inputs that the
# caller did not set become the literal string `null`. Runs in the current shell so that
# warnings raised here survive into the record.
scan_update_workflows() {
	local root="$1" dir="$1/.github/workflows" file rel out line
	MATCHES=()
	[[ -d $dir ]] || return 0

	for file in "$dir"/*.yml "$dir"/*.yaml; do
		[[ -f $file ]] || continue
		rel="${file#"$root"/}"

		if ! out="$(
			yq -r '(.jobs // {}) | to_entries[]
			       | select((.value.uses // "") | test("^'"$WORKFLOW_REF"'@"))
			       | [.key, .value.uses, (.value.with.workingDirectory | tostring), (.value.with.flutterCompat | tostring)]
			       | join("\t")' "$file" 2>/dev/null
		)"; then
			warn "could not parse '$rel' as YAML — skipped"
			continue
		fi

		while IFS= read -r line; do
			[[ -n ${line//[[:space:]]/} ]] || continue
			MATCHES+=("$rel"$'\t'"$line")
		done <<<"$out"
	done
}

# --- update run ------------------------------------------------------------------------

# Builds and runs the auto_update invocation, mirroring the `Update dependencies` step of
# the shared workflow. Sets the UPDATE_* and WORKFLOW_* values for the record.
run_update() {
	local root="$1"

	WORKFLOW_FILE=none
	WORKFLOW_JOB=none
	local working_directory=. flutter_compat=null

	scan_update_workflows "$root"

	if ((${#MATCHES[@]} == 0)); then
		warn "no workflow in .github/workflows calls '$WORKFLOW_REF' — falling back to the repository root and the auto_update defaults"
	else
		((${#MATCHES[@]} == 1)) ||
			warn "${#MATCHES[@]} jobs call '$WORKFLOW_REF' — using the first one"
		IFS=$'\t' read -r WORKFLOW_FILE WORKFLOW_JOB _ working_directory flutter_compat <<<"${MATCHES[0]}"
		[[ $working_directory != null && -n $working_directory ]] || working_directory=.
	fi

	# In CI the workflow checks out the repository root and points auto_update at
	# `workingDirectory` inside it, so the same relative path applies here.
	TARGET="$(cd "$root/$working_directory" 2>/dev/null && pwd)" ||
		die "workingDirectory '$working_directory' from '$WORKFLOW_FILE' does not exist under '$root'"
	[[ -f $TARGET/pubspec.yaml ]] ||
		die "no pubspec.yaml in '$TARGET' — auto_update needs a dart package"

	# The workflow hardcodes --mode, --bump-version and --report around the two inputs it
	# forwards, so a faithful local run has to pass those too.
	local -a args=(-t "$TARGET" --mode update)
	case "$flutter_compat" in
		false) args+=(--no-flutter-compat) ;;
		*) args+=(--flutter-compat) ;;
	esac
	args+=(--bump-version --report "$UPDATE_REPORT")

	UPDATE_COMMAND="dart run dart_test_tools:auto_update ${args[*]}"
	note "running: $UPDATE_COMMAND"
	note "output goes to $UPDATE_LOG"

	rm -f "$UPDATE_REPORT"
	set +e
	(cd "$TARGET" && dart run dart_test_tools:auto_update "${args[@]}") >"$UPDATE_LOG" 2>&1
	UPDATE_EXIT=$?
	set -e

	[[ -f $UPDATE_REPORT ]] || UPDATE_REPORT=none
	note "auto_update exited with $UPDATE_EXIT"
}

# --- record ----------------------------------------------------------------------------

emit_record() {
	printf '>>> auto-update-prepare\n'
	printf 'status: ok\n'
	printf 'mode: %s\n' "$MODE"
	printf 'branch: %s\n' "$BRANCH"
	printf 'branch_check: %s\n' "$BRANCH_CHECK"
	printf 'repo_root: %s\n' "$ROOT"

	if [[ $MODE == new ]]; then
		printf 'workflow_file: %s\n' "$WORKFLOW_FILE"
		printf 'workflow_job: %s\n' "$WORKFLOW_JOB"
		printf 'target: %s\n' "$TARGET"
		printf 'update_command: %s\n' "$UPDATE_COMMAND"
		printf 'update_exit_code: %s\n' "$UPDATE_EXIT"
		printf 'update_log: %s\n' "$UPDATE_LOG"
		printf 'update_report: %s\n' "$UPDATE_REPORT"
	fi

	local w
	for w in ${WARNINGS[@]+"${WARNINGS[@]}"}; do
		printf 'warning: %s\n' "$w"
	done
	printf '<<< auto-update-prepare\n'
}

# --- main ------------------------------------------------------------------------------

main() {
	local requested='' ignore_branch=false

	case "${1-}" in
		-h | --help | help) usage ;;
		'' | new | existing) requested="${1-}" ;;
		*) die "invalid mode '$1' — expected 'new' or 'existing'" ;;
	esac

	case "${2-}" in
		'') ;;
		ignore-branch) ignore_branch=true ;;
		*) die "invalid second argument '$2' — the only accepted value is 'ignore-branch'" ;;
	esac

	[[ $# -le 2 ]] || die "too many arguments (expected at most 2)"
	[[ $ignore_branch == false || -n $requested ]] ||
		die "'ignore-branch' has no branch to assume — combine it with an explicit mode"

	command -v git >/dev/null || die "git is not on PATH"
	command -v dart >/dev/null || die "the dart SDK is not on PATH"
	command -v yq >/dev/null || die "yq is not on PATH (it reads the workflow files)"

	ROOT="$(repo_root)"
	resolve_mode "$requested" "$ignore_branch"

	if [[ $MODE == new ]]; then
		mkdir -p "$OUT_DIR"
		UPDATE_LOG="$OUT_DIR/auto_update.log"
		UPDATE_REPORT="$OUT_DIR/update_report.md"
		run_update "$ROOT"
	fi

	emit_record
}

main "$@"
