#!/usr/bin/env bash
#
# Pull request resolver, post-upgrade runner and package scanner for the
# dart-test-tools-renovate-fix skill.
#
# Finds the open Renovate pull request, puts the worktree on its branch, re-runs the
# `renovate-post-upgrade` step that Renovate runs inside its commit, and describes the
# updated packages (or workspaces) so the caller knows which checks to run where.
#
# It never commits, pushes, merges or rebases. The only mutations it performs on the
# repository itself are switching branches (only on a clean worktree) and the working
# tree changes of the post-upgrade run.
#
set -euo pipefail

readonly SELF="${0##*/}"
readonly BRANCH_PREFIX='renovate/'
# The identity Renovate commits with (RENOVATE_GIT_AUTHOR of the shared renovate.yml).
readonly RENOVATE_EMAIL='41898282+github-actions[bot]@users.noreply.github.com'
readonly PRESET_PATTERN='Skycoder42/dart_test_tools//renovate/(library|application)'
readonly CI_PATTERN='^Skycoder42/dart_test_tools/\.github/workflows/(dart|flutter)\.yml@'
readonly DATA_FILE_VAR='RENOVATE_POST_UPGRADE_COMMAND_DATA_FILE'
readonly PR_FIELDS='number,title,url,state,headRefName,headRefOid,baseRefName,isCrossRepository,author'
readonly OUT_DIR="${TMPDIR:-/tmp}/dart-test-tools-renovate-fix"
# The repository config files Renovate looks for, in its own order. The first one found
# is the one it uses.
readonly -a CONFIG_FILES=(
	renovate.json renovate.json5 .github/renovate.json .github/renovate.json5
	.renovaterc .renovaterc.json .renovaterc.json5
)

# ASCII unit separator. Used instead of TAB because `read` folds runs of TAB together —
# which would silently shift the fields of a job that sets `unitTestPaths: ""`.
readonly US=$'\x1f'

# Accumulated `warning:` lines. They are collected rather than printed as they happen so
# that the record stays one contiguous block on stdout.
declare -a WARNINGS=()
# Jobs calling the shared dart/flutter CI workflow, filled by scan_ci_workflows:
#   <absolute workingDirectory>US<unitTestPaths>US<integrationTestPaths>US<buildRunner>
declare -a CI_ENTRIES=()
# The pubspec.yaml files the pull request modified, relative to the repository root.
declare -a CHANGED_PUBSPECS=()
# Absolute pub roots (package or workspace root) of CHANGED_PUBSPECS, deduplicated.
declare -a ROOTS=()
# One entry per package, filled by scan_packages:
#   <name>US<path>US<root index>US<tool>US<publishable>US<unitTests>US<integrationTests>US<testSource>US<buildRunner>
declare -a PACKAGE_INFO=()
# The command that runs the post-upgrade CLI, without its --mode.
declare -a POST_UPGRADE_CMD=()

note() {
	printf '%s: %s\n' "$SELF" "$*" >&2
}

warn() {
	WARNINGS+=("$*")
	printf '%s: warning: %s\n' "$SELF" "$*" >&2
}

# Emits an `error` record and exits non-zero. Reserved for failures of the script itself:
# a bad invocation, an unusable git state, a missing tool. A failing post-upgrade run is a
# result, not a script failure, and is reported through `post_upgrade_exit_code` instead.
die() {
	printf '%s: error: %s\n' "$SELF" "$*" >&2
	printf '>>> renovate-fix\n'
	printf 'status: error\n'
	local w
	for w in ${WARNINGS[@]+"${WARNINGS[@]}"}; do
		printf 'warning: %s\n' "$w"
	done
	printf 'error: %s\n' "$*"
	printf '<<< renovate-fix\n'
	exit 1
}

usage() {
	cat >&2 <<-EOF
		usage: $SELF [<pull request>] [skip-post-upgrade | allow-dirty]

		  <pull request>     Number, URL or branch of the Renovate pull request. Optional —
		                     when omitted, the pull request of the checked out
		                     '${BRANCH_PREFIX}…' branch is used, or else the only open
		                     Renovate pull request.
		  skip-post-upgrade  Do not re-run renovate-post-upgrade, only describe the packages.
		  allow-dirty        Re-run renovate-post-upgrade although the worktree has
		                     uncommitted changes (a re-run after fixing the cause of a failed
		                     run). Never switches branches.

		Output is a single machine readable record on stdout:

		  >>> renovate-fix
		  <key>: <value>
		  ...
		  <<< renovate-fix

		Keys are lowercase and may be dotted and indexed ('package.1.name'), values are
		single-line, and everything after the first ': ' belongs to the value. 'warning'
		may appear any number of times, every other key at most once. Progress and
		diagnostics go to stderr and are not part of the record.
	EOF
	exit 64
}

# --- git helpers -----------------------------------------------------------------------

# These are called from command substitutions, so they must never call `die` themselves:
# the error record would be captured by the substitution instead of reaching stdout. They
# report failure through their exit status and let the caller do the dying.

repo_root() {
	git rev-parse --show-toplevel 2>/dev/null
}

current_branch() {
	git rev-parse --verify --quiet HEAD >/dev/null || return 1
	git rev-parse --abbrev-ref HEAD 2>/dev/null
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

# --- yaml helpers ----------------------------------------------------------------------

# Converts the YAML on stdin to JSON. Works with both the Go (mikefarah) and the Python
# yq; everything beyond plain field access is done in jq.
yaml_to_json() {
	if [[ $YQ_FLAVOR == go ]]; then
		yq -o=json '.' -
	else
		yq '.'
	fi
}

# --- pull request resolution -----------------------------------------------------------

# Sets PR_NUMBER, PR_TITLE, PR_URL, PR_BRANCH, PR_HEAD and BASE_BRANCH.
resolve_pr() {
	local requested="$1" branch json='' count

	if [[ -n $requested ]]; then
		json="$(gh pr view "$requested" --json "$PR_FIELDS" 2>/dev/null)" ||
			die "gh found no pull request '$requested' — is gh authenticated for this repository?"
		[[ "$(jq -r .state <<<"$json")" == OPEN ]] ||
			die "pull request '$requested' is not open"
	else
		# The checked out Renovate branch wins: it is what the user is looking at.
		branch="$(current_branch)" || die "the repository has no commits yet"
		if [[ $branch == "$BRANCH_PREFIX"* ]] &&
			json="$(gh pr view "$branch" --json "$PR_FIELDS" 2>/dev/null)" &&
			[[ "$(jq -r .state <<<"$json")" == OPEN ]]; then
			:
		else
			json="$(gh pr list --state open --author app/github-actions --json "$PR_FIELDS" 2>/dev/null)" ||
				die "could not list the pull requests with gh — is it installed and authenticated for this repository?"
			json="$(jq --arg prefix "$BRANCH_PREFIX" \
				'[.[] | select((.headRefName | startswith($prefix)) and (.isCrossRepository | not))]' <<<"$json")"
			count="$(jq length <<<"$json")"
			case "$count" in
				0) die "no open Renovate pull request (by github-actions[bot] from a '${BRANCH_PREFIX}…' branch) found" ;;
				1) json="$(jq '.[0]' <<<"$json")" ;;
				*)
					die "$count open Renovate pull requests: $(jq -r 'map("#\(.number) (\(.headRefName))") | join(", ")' <<<"$json") — pass the one to work on"
					;;
			esac
		fi
	fi

	PR_NUMBER="$(jq -r .number <<<"$json")"
	PR_TITLE="$(jq -r '.title | gsub("[\r\n]+"; " ")' <<<"$json")"
	PR_URL="$(jq -r .url <<<"$json")"
	PR_BRANCH="$(jq -r .headRefName <<<"$json")"
	PR_HEAD="$(jq -r .headRefOid <<<"$json")"
	BASE_BRANCH="$(jq -r .baseRefName <<<"$json")"

	[[ "$(jq -r .isCrossRepository <<<"$json")" == false ]] ||
		die "pull request #$PR_NUMBER comes from a fork — Renovate pushes its branches to the repository itself"
	[[ $PR_BRANCH == "$BRANCH_PREFIX"* ]] ||
		die "pull request #$PR_NUMBER is on '$PR_BRANCH', not on a '${BRANCH_PREFIX}…' branch — it is not a Renovate pull request"
	case "$(jq -r .author.login <<<"$json")" in
		app/github-actions | github-actions | 'github-actions[bot]') ;;
		*) warn "pull request #$PR_NUMBER was not opened by github-actions[bot] — the finish job of the CI will not merge it" ;;
	esac
}

# Sets BRANCH and BRANCH_CHECK.
checkout_pr_branch() {
	local current behind ahead

	# Best effort: an offline run must still work as long as the branches exist locally.
	git fetch --quiet origin "$BASE_BRANCH" "$PR_BRANCH" 2>/dev/null ||
		warn "could not fetch '$BASE_BRANCH' and '$PR_BRANCH' from origin — working with the local state only"

	current="$(current_branch)" || die "the repository has no commits yet"
	if [[ $current == "$PR_BRANCH" ]]; then
		BRANCH_CHECK=matched
	else
		worktree_is_clean ||
			die "the worktree has uncommitted changes — refusing to switch to '$PR_BRANCH'. Commit or stash them first."
		note "switching to '$PR_BRANCH'"
		if branch_exists "$PR_BRANCH"; then
			git switch --quiet "$PR_BRANCH" || die "failed to check out '$PR_BRANCH'"
		elif remote_branch_exists "$PR_BRANCH"; then
			git switch --quiet --create "$PR_BRANCH" --track "origin/$PR_BRANCH" ||
				die "failed to create a local '$PR_BRANCH' tracking 'origin/$PR_BRANCH'"
		else
			die "branch '$PR_BRANCH' exists neither locally nor on origin"
		fi
		BRANCH_CHECK=switched
	fi
	BRANCH="$PR_BRANCH"

	# Purely informational — the script deliberately does not reset the user's branch.
	# Renovate rebuilds its branch from scratch and force-pushes, so a stale local branch
	# is common.
	if remote_branch_exists "$PR_BRANCH"; then
		behind="$(git rev-list --count "HEAD..origin/$PR_BRANCH" 2>/dev/null || echo 0)"
		ahead="$(git rev-list --count "origin/$PR_BRANCH..HEAD" 2>/dev/null || echo 0)"
		((behind == 0)) ||
			warn "local '$PR_BRANCH' is missing $behind commit(s) of 'origin/$PR_BRANCH' — Renovate may have rebuilt the branch; you may be looking at an outdated update"
		((ahead == 0)) ||
			warn "local '$PR_BRANCH' has $ahead commit(s) that are not on 'origin/$PR_BRANCH'"
	fi
	[[ "$(git rev-parse HEAD)" == "$PR_HEAD" ]] ||
		warn "HEAD is not the head commit of pull request #$PR_NUMBER ($PR_HEAD)"
}

# Sets BASE_COMMIT, RENOVATE_COMMITS and OTHER_COMMITS.
inspect_commits() {
	local ref total
	BASE_COMMIT=''
	for ref in "origin/$BASE_BRANCH" "$BASE_BRANCH"; do
		BASE_COMMIT="$(git merge-base "$ref" HEAD 2>/dev/null)" && break
	done
	[[ -n $BASE_COMMIT ]] ||
		die "could not find where '$PR_BRANCH' forked off '$BASE_BRANCH'"

	total="$(git rev-list --count "$BASE_COMMIT..HEAD")"
	RENOVATE_COMMITS="$(git rev-list --count --fixed-strings --author="$RENOVATE_EMAIL" "$BASE_COMMIT..HEAD")"
	OTHER_COMMITS=$((total - RENOVATE_COMMITS))
}

# Sets CHECKS_FAILED, CHECKS_PENDING and ARTIFACT_ERROR from what GitHub knows about the
# pull request. They describe the pushed head commit, not the local worktree.
inspect_pr_state() {
	local json
	CHECKS_FAILED=unknown
	CHECKS_PENDING=unknown
	ARTIFACT_ERROR=unknown
	if ! json="$(gh pr view "$PR_NUMBER" --json statusCheckRollup,comments 2>/dev/null)"; then
		warn "could not read the checks and comments of pull request #$PR_NUMBER"
		return 0
	fi

	CHECKS_FAILED="$(jq -r '
		[.statusCheckRollup[]
		 | select((.conclusion // .state // "") | IN("FAILURE", "ERROR", "TIMED_OUT", "CANCELLED", "STARTUP_FAILURE"))
		 | .name // .context]
		| unique | if length == 0 then "none" else join(", ") end' <<<"$json")"
	CHECKS_PENDING="$(jq -r '
		[.statusCheckRollup[]
		 | select(if .__typename == "CheckRun" then .status != "COMPLETED" else (.state | IN("PENDING", "EXPECTED")) end)]
		| length' <<<"$json")"
	# Renovate comments on its pull request when a postUpgradeTask failed, and removes the
	# comment again once a later run succeeds.
	if jq -e '[.comments[] | select(.body | contains("Artifact update problem"))] | length > 0' <<<"$json" >/dev/null; then
		ARTIFACT_ERROR=yes
	else
		ARTIFACT_ERROR=no
	fi
}

# --- preset ----------------------------------------------------------------------------

# Sets PRESET (library, application or unknown) and PRESET_FILE.
resolve_preset() {
	local file match
	local -a found=()
	PRESET=unknown
	PRESET_FILE=none

	for file in "${CONFIG_FILES[@]}"; do
		[[ -f $file ]] || continue
		PRESET_FILE="$file"
		while IFS= read -r match; do
			found+=("$match")
		done < <(grep -oE "$PRESET_PATTERN" "$file" | sort -u)
		break
	done

	if [[ $PRESET_FILE == none ]]; then
		warn "no Renovate config file found — the post-upgrade mode is unknown"
	elif ((${#found[@]} == 0)); then
		warn "'$PRESET_FILE' extends neither the library nor the application preset of dart_test_tools — the post-upgrade mode is unknown"
	elif ((${#found[@]} > 1)); then
		warn "'$PRESET_FILE' extends both the library and the application preset — the post-upgrade mode is unknown"
	else
		PRESET="${found[0]##*/}"
	fi
}

# --- post-upgrade ----------------------------------------------------------------------

# Fills CHANGED_PUBSPECS. Only modified files count: Renovate never adds or removes one.
find_changed_pubspecs() {
	local file
	CHANGED_PUBSPECS=()
	while IFS= read -r file; do
		[[ -z $file ]] || CHANGED_PUBSPECS+=("$file")
	done < <(git diff --name-only --diff-filter=M "$BASE_COMMIT" HEAD -- ':(glob)**/pubspec.yaml')
}

# Writes the data file Renovate would hand to renovate-post-upgrade, rebuilt from the
# constraint changes of the pull request's pubspecs. One entry per changed dependency and
# package file, like Renovate's own: hosted dependencies, dev dependencies and the SDK
# constraints, which Renovate reports as `dart` and `flutter` with an empty depType.
write_data_file() {
	local file="$1" rel
	local -a parts=()

	for rel in ${CHANGED_PUBSPECS[@]+"${CHANGED_PUBSPECS[@]}"}; do
		parts+=("$(
			jq -n --arg file "$rel" \
				--argjson base "$(git show "$BASE_COMMIT:$rel" | yaml_to_json)" \
				--argjson head "$(git show "HEAD:$rel" | yaml_to_json)" '
				def constraint:
				  if type == "string" then .
				  elif type == "object" and .path == null and .git == null and .sdk == null
				    and (.version | type) == "string" then .version
				  else null end;
				def constraints:
				  [ ((.environment // {}) | to_entries[]
				     | select(.key == "sdk" or .key == "flutter")
				     | {depType: "", depName: (if .key == "sdk" then "dart" else "flutter" end), value}),
				    (("dependencies", "dev_dependencies") as $type
				     | (.[$type] // {}) | to_entries[]
				     | {depType: $type, depName: .key, value: (.value | constraint)})
				  ]
				  | map(select((.value | type) == "string"))
				  | map({key: "\(.depType)/\(.depName)", value: .})
				  | from_entries;
				($base | constraints) as $before
				| [($head | constraints) | to_entries[]
				   | select($before[.key] != null and $before[.key].value != .value.value)
				   | {manager: "pub", depName: .value.depName, packageFile: $file,
				      depType: .value.depType, currentValue: $before[.key].value,
				      newValue: .value.value, updateType: ""}]'
		)")
	done

	printf '%s\n' ${parts[@]+"${parts[@]}"} | jq -s 'add // []' >"$file"
}

# Renovate builds its commit on the base branch, so the post-upgrade step never sees its
# own changelog entries and version bump. Undo exactly those two, so that a re-run adds no
# second entry and no second bump. Everything else it does (resolution, plugin pins,
# build_runner, format, fix, version-sync) converges when run again.
reset_release() {
	local file before now tmp
	RESET_COUNT=0

	while IFS= read -r file; do
		[[ -n $file ]] || continue
		git restore --source="$BASE_COMMIT" --worktree -- "$file"
		RESET_COUNT=$((RESET_COUNT + 1))
	done < <(git diff --name-only --diff-filter=M "$BASE_COMMIT" HEAD -- ':(glob)**/CHANGELOG.md')

	for file in ${CHANGED_PUBSPECS[@]+"${CHANGED_PUBSPECS[@]}"}; do
		before="$(git show "$BASE_COMMIT:$file" | yaml_to_json | jq -r '.version // ""')"
		now="$(yaml_to_json <"$file" | jq -r '.version // ""')"
		[[ -n $before && $before != "$now" ]] || continue
		# Not `sed -i`: its syntax differs between GNU and BSD sed.
		tmp="$(mktemp)"
		sed -E "s/^version:.*/version: $before/" "$file" >"$tmp"
		cat "$tmp" >"$file"
		rm -f "$tmp"
		RESET_COUNT=$((RESET_COUNT + 1))
	done
}

# Prints the absolute directory of the dart_test_tools package a package_config.json
# resolves to, or fails when it does not contain it.
dart_test_tools_dir() {
	local config="$1" uri
	uri="$(jq -r '.packages[] | select(.name == "dart_test_tools") | .rootUri' "$config" 2>/dev/null)" || return 1
	[[ -n $uri ]] || return 1
	case "$uri" in
		file://*) printf '%s\n' "${uri#file://}" ;;
		*) (cd "$(dirname "$config")/$uri" 2>/dev/null && pwd) ;;
	esac
}

# Fills POST_UPGRADE_CMD. CI runs the globally activated executable (install-tools), so
# that is preferred. Otherwise the dart_test_tools dependency of a package in the
# repository is used — the CLI must still run from the repository root, hence the
# explicit package config.
resolve_post_upgrade_command() {
	if command -v renovate-post-upgrade >/dev/null; then
		POST_UPGRADE_CMD=(renovate-post-upgrade)
		return
	fi

	local file dir config package
	local -a dirs=(${ROOTS[@]+"${ROOTS[@]}"})
	while IFS= read -r file; do
		dirs+=("$ROOT/$(dirname "$file")")
	done < <(git ls-files -- ':(glob)**/pubspec.yaml')

	for dir in "${dirs[@]}"; do
		config="$dir/.dart_tool/package_config.json"
		[[ -f $config ]] || continue
		package="$(dart_test_tools_dir "$config")" || continue
		package="${package%/}"
		if [[ ! -f $package/bin/renovate_post_upgrade.dart ]]; then
			warn "the dart_test_tools resolved in '${dir#"$ROOT"/}' has no renovate_post_upgrade — it predates the Renovate support"
			continue
		fi
		POST_UPGRADE_CMD=(dart run "--packages=$config" "$package/bin/renovate_post_upgrade.dart")
		return
	done
	return 1
}

# Sets POST_UPGRADE and, when it ran, the POST_UPGRADE_* details and CHANGED_FILES.
run_post_upgrade() {
	local skip="$1" allow_dirty="$2"

	mkdir -p "$OUT_DIR"
	POST_UPGRADE_DATA="$OUT_DIR/upgrades.json"
	POST_UPGRADE_LOG="$OUT_DIR/post-upgrade.log"
	write_data_file "$POST_UPGRADE_DATA"
	POST_UPGRADE_ENTRIES="$(jq length "$POST_UPGRADE_DATA")"

	if [[ $skip == true ]]; then
		POST_UPGRADE=skipped-request
		return
	fi
	if ((POST_UPGRADE_ENTRIES == 0)); then
		# Exactly what the CLI itself does with a data file without pub entries.
		POST_UPGRADE=skipped-no-pub
		return
	fi
	if [[ $PRESET == unknown ]]; then
		POST_UPGRADE=skipped-no-preset
		return
	fi
	if [[ $allow_dirty == false ]] && ! worktree_is_clean; then
		warn "the worktree has uncommitted changes — renovate-post-upgrade was not run. Pass 'allow-dirty' to run it anyway"
		POST_UPGRADE=skipped-dirty
		return
	fi
	if ! resolve_post_upgrade_command; then
		warn "renovate-post-upgrade is not on PATH and no package in the repository resolves a dart_test_tools that has it — run 'dart pub get' in the package depending on dart_test_tools, or activate it globally as CI does"
		POST_UPGRADE=unavailable
		return
	fi

	reset_release

	POST_UPGRADE_COMMAND="${POST_UPGRADE_CMD[*]} --mode $PRESET"
	note "running: $POST_UPGRADE_COMMAND"
	note "output goes to $POST_UPGRADE_LOG"
	set +e
	env "$DATA_FILE_VAR=$POST_UPGRADE_DATA" "${POST_UPGRADE_CMD[@]}" --mode "$PRESET" >"$POST_UPGRADE_LOG" 2>&1
	POST_UPGRADE_EXIT=$?
	set -e
	note "renovate-post-upgrade exited with $POST_UPGRADE_EXIT"

	POST_UPGRADE=ran
	CHANGED_FILES="$(git status --porcelain | wc -l | tr -d '[:space:]')"
}

# --- workflow discovery ----------------------------------------------------------------

# Fills CI_ENTRIES with the test paths each CI caller job declares, keyed by the absolute
# directory it operates on. `| tostring` turns an absent input into the literal string
# `null`, which distinguishes "not set" from "explicitly set to the empty string" — the two
# mean different things for unitTestPaths.
scan_ci_workflows() {
	local dir="$ROOT/.github/workflows" file rel out line
	local wd unit integration build_runner abs
	CI_ENTRIES=()
	[[ -d $dir ]] || return 0

	for file in "$dir"/*.yml "$dir"/*.yaml; do
		[[ -f $file ]] || continue
		rel="${file#"$ROOT"/}"

		if ! out="$(
			yq -r '(.jobs // {}) | to_entries[]
			       | select((.value.uses // "") | test("'"$CI_PATTERN"'"))
			       | [.key, .value.uses, (.value.with.workingDirectory | tostring), (.value.with.unitTestPaths | tostring), (.value.with.integrationTestPaths | tostring), (.value.with.buildRunner | tostring)]
			       | join("\t")' "$file" 2>/dev/null | tr '\t' '\037'
		)"; then
			warn "could not parse '$rel' as YAML — skipped"
			continue
		fi

		while IFS= read -r line; do
			[[ -n ${line//[[:space:]]/} ]] || continue
			IFS=$US read -r _ _ wd unit integration build_runner <<<"$line"
			[[ $wd != null && -n $wd ]] || wd=.
			abs="$(cd "$ROOT/$wd" 2>/dev/null && pwd)" || continue
			CI_ENTRIES+=("$abs$US$unit$US$integration$US$build_runner")
		done <<<"$out"
	done
}

# --- package scanning ------------------------------------------------------------------

# Prints the pub root of the package in $1, the way renovate-post-upgrade finds it: the
# package itself, or for a workspace member the workspace root above it.
pub_root_of() {
	local dir="$1" resolution
	resolution="$(yq -r '.resolution // ""' "$dir/pubspec.yaml" 2>/dev/null || true)"
	if [[ $resolution != workspace ]]; then
		printf '%s\n' "$dir"
		return
	fi
	while [[ $dir != "$ROOT" && $dir != / ]]; do
		dir="$(dirname "$dir")"
		if [[ -f $dir/pubspec.yaml ]] &&
			yq -e '(.workspace // []) | length > 0' "$dir/pubspec.yaml" >/dev/null 2>&1; then
			printf '%s\n' "$dir"
			return
		fi
	done
	return 1
}

# Fills ROOTS from CHANGED_PUBSPECS.
resolve_roots() {
	local file dir root known
	ROOTS=()
	for file in ${CHANGED_PUBSPECS[@]+"${CHANGED_PUBSPECS[@]}"}; do
		dir="$(cd "$ROOT/$(dirname "$file")" && pwd)"
		if ! root="$(pub_root_of "$dir")"; then
			warn "'$file' is a workspace member, but no workspace root was found above it — skipped"
			continue
		fi
		for known in ${ROOTS[@]+"${ROOTS[@]}"}; do
			[[ $known != "$root" ]] || continue 2
		done
		ROOTS+=("$root")
	done
}

package_tool() {
	local sdk
	sdk="$(yq -r '.dependencies.flutter.sdk // .environment.flutter // ""' "$1/pubspec.yaml" 2>/dev/null || true)"
	if [[ -n $sdk && $sdk != null ]]; then
		printf 'flutter\n'
	else
		printf 'dart\n'
	fi
}

# Mirrors the CI's own check: only `publish_to: none` makes a package unpublishable.
package_publishable() {
	local publish_to
	publish_to="$(yq -r '.publish_to // ""' "$1/pubspec.yaml" 2>/dev/null || true)"
	if [[ $publish_to == none ]]; then
		printf 'no\n'
	else
		printf 'yes\n'
	fi
}

# Sets PKG_UNIT, PKG_INTEGRATION, PKG_TEST_SOURCE and PKG_BUILD_RUNNER for the package
# directory $1.
#
# The CI caller workflow is the authority: it splits unit from integration tests through
# the `unitTestPaths` / `integrationTestPaths` inputs, and a package may legitimately have
# a full `test/` directory that CI runs entirely as integration tests. Only when no CI
# caller covers this directory does the layout get guessed, which is flagged as such.
package_tests() {
	local dir="$1" entry path unit integration build_runner

	for entry in ${CI_ENTRIES[@]+"${CI_ENTRIES[@]}"}; do
		IFS=$US read -r path unit integration build_runner <<<"$entry"
		[[ $path == "$dir" ]] || continue
		[[ $unit != null ]] || unit='test' # the input's own default
		[[ $integration != null ]] || integration=''
		PKG_UNIT="${unit:-none}"
		PKG_INTEGRATION="${integration:-none}"
		PKG_TEST_SOURCE=workflow
		if [[ $build_runner == true ]]; then
			PKG_BUILD_RUNNER=yes
		else
			PKG_BUILD_RUNNER=no
		fi
		return
	done

	if [[ -d $dir/test ]] && [[ -n "$(find "$dir/test" -name '*_test.dart' -print -quit 2>/dev/null)" ]]; then
		PKG_UNIT='test'
	else
		PKG_UNIT=none
	fi
	PKG_INTEGRATION=none
	PKG_TEST_SOURCE=heuristic
	# Without a CI caller, fall back to whether build_runner is a dev dependency at all.
	if yq -e '.dev_dependencies.build_runner' "$dir/pubspec.yaml" >/dev/null 2>&1; then
		PKG_BUILD_RUNNER=yes
	else
		PKG_BUILD_RUNNER=no
	fi
}

# Fills PACKAGE_INFO with the packages of every root. `dart pub workspace list` needs no
# resolved .dart_tool, so this works before a `pub get` too.
scan_packages() {
	local index=0 root json name path entry
	local -a found

	PACKAGE_INFO=()
	for root in ${ROOTS[@]+"${ROOTS[@]}"}; do
		index=$((index + 1))
		found=()
		if json="$( (cd "$root" && dart pub workspace list --json) 2>/dev/null)"; then
			while IFS=$US read -r name path; do
				[[ -n $name && -n $path ]] || continue
				found+=("$name$US$path")
			done < <(jq -r '.packages[] | [.name, .path] | @tsv' <<<"$json" 2>/dev/null | tr '\t' '\037')
		else
			warn "'dart pub workspace list' failed in '$root' — treating it as a single package"
		fi

		if ((${#found[@]} == 0)); then
			name="$(yq -r '.name // "unknown"' "$root/pubspec.yaml" 2>/dev/null || echo unknown)"
			found=("$name$US$root")
		fi

		for entry in "${found[@]}"; do
			IFS=$US read -r name path <<<"$entry"
			package_tests "$path"
			PACKAGE_INFO+=("$name$US$path$US$index$US$(package_tool "$path")$US$(package_publishable "$path")$US$PKG_UNIT$US$PKG_INTEGRATION$US$PKG_TEST_SOURCE$US$PKG_BUILD_RUNNER")
		done
	done
}

# --- flutter versions ------------------------------------------------------------------

# Prints the lower bound of a version constraint ('>=3.47.0', '^3.47.0', '3.47.0'), or
# nothing when it has none.
lower_bound() {
	if [[ $1 =~ ^(\^|>=|>)?[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+) ]]; then
		printf '%s\n' "${BASH_REMATCH[2]}"
	fi
}

# Prints the highest of the given versions, or nothing when none is given.
highest_version() {
	printf '%s\n' "$@" | sed '/^$/d' | sort -V | tail -n 1
}

# Sets FLUTTER_MIN_BASE and FLUTTER_MIN_NOW to the highest minimum flutter version any
# package declares at the base commit and in the working tree, and FLUTTER_UPDATE to how
# far it moved. Also counts the flutter app projects into FLUTTER_APPS: their native
# platform projects come from templates that change with flutter releases, and nothing in
# the dependency update touches them.
scan_flutter_versions() {
	local entry path rel metadata
	local -a now=() before=()

	for entry in ${PACKAGE_INFO[@]+"${PACKAGE_INFO[@]}"}; do
		IFS=$US read -r _ path _ <<<"$entry"
		rel="${path#"$ROOT"}"
		rel="${rel#/}"
		rel="${rel:+$rel/}pubspec.yaml"
		now+=("$(lower_bound "$(yq -r '.environment.flutter // ""' "$path/pubspec.yaml" 2>/dev/null || true)")")
		before+=("$(lower_bound "$(git show "$BASE_COMMIT:$rel" 2>/dev/null | yq -r '.environment.flutter // ""' 2>/dev/null || true)")")
	done

	FLUTTER_MIN_NOW="$(highest_version ${now[@]+"${now[@]}"})"
	FLUTTER_MIN_BASE="$(highest_version ${before[@]+"${before[@]}"})"

	local now_major now_minor now_patch base_major base_minor base_patch
	if [[ -z $FLUTTER_MIN_NOW || -z $FLUTTER_MIN_BASE ]]; then
		FLUTTER_UPDATE=n/a
	else
		IFS=. read -r now_major now_minor now_patch <<<"$FLUTTER_MIN_NOW"
		IFS=. read -r base_major base_minor base_patch <<<"$FLUTTER_MIN_BASE"
		if ((now_major > base_major)); then
			FLUTTER_UPDATE=major
		elif ((now_major == base_major && now_minor > base_minor)); then
			FLUTTER_UPDATE=minor
		elif ((now_major == base_major && now_minor == base_minor && now_patch > base_patch)); then
			FLUTTER_UPDATE='patch'
		else
			FLUTTER_UPDATE=none
		fi
	fi

	FLUTTER_APPS=0
	while IFS= read -r -d '' metadata; do
		if [[ "$(yq -r '.project_type // ""' "$ROOT/$metadata" 2>/dev/null || true)" == app ]]; then
			FLUTTER_APPS=$((FLUTTER_APPS + 1))
		fi
	done < <(git ls-files -z -- ':(glob)**/.metadata')
}

# --- record ----------------------------------------------------------------------------

emit_record() {
	printf '>>> renovate-fix\n'
	printf 'status: ok\n'
	printf 'pr_number: %s\n' "$PR_NUMBER"
	printf 'pr_title: %s\n' "$PR_TITLE"
	printf 'pr_url: %s\n' "$PR_URL"
	printf 'checks_failed: %s\n' "$CHECKS_FAILED"
	printf 'checks_pending: %s\n' "$CHECKS_PENDING"
	printf 'artifact_error: %s\n' "$ARTIFACT_ERROR"
	printf 'branch: %s\n' "$BRANCH"
	printf 'branch_check: %s\n' "$BRANCH_CHECK"
	printf 'base_branch: %s\n' "$BASE_BRANCH"
	printf 'base_commit: %s\n' "$BASE_COMMIT"
	printf 'renovate_commits: %s\n' "$RENOVATE_COMMITS"
	printf 'other_commits: %s\n' "$OTHER_COMMITS"
	printf 'repo_root: %s\n' "$ROOT"
	printf 'preset: %s\n' "$PRESET"
	printf 'preset_file: %s\n' "$PRESET_FILE"

	printf 'post_upgrade: %s\n' "$POST_UPGRADE"
	printf 'post_upgrade_data: %s\n' "$POST_UPGRADE_DATA"
	printf 'post_upgrade_entries: %s\n' "$POST_UPGRADE_ENTRIES"
	if [[ $POST_UPGRADE == ran ]]; then
		printf 'post_upgrade_command: %s\n' "$POST_UPGRADE_COMMAND"
		printf 'post_upgrade_exit_code: %s\n' "$POST_UPGRADE_EXIT"
		printf 'post_upgrade_log: %s\n' "$POST_UPGRADE_LOG"
		printf 'post_upgrade_reset: %s\n' "$RESET_COUNT"
		printf 'changed_files: %s\n' "$CHANGED_FILES"
	fi

	printf 'flutter_min_base: %s\n' "${FLUTTER_MIN_BASE:-none}"
	printf 'flutter_min_now: %s\n' "${FLUTTER_MIN_NOW:-none}"
	printf 'flutter_update: %s\n' "$FLUTTER_UPDATE"
	printf 'flutter_apps: %s\n' "$FLUTTER_APPS"

	printf 'root_count: %s\n' "${#ROOTS[@]}"
	local i=0 root
	for root in ${ROOTS[@]+"${ROOTS[@]}"}; do
		i=$((i + 1))
		printf 'root.%d.path: %s\n' "$i" "$root"
	done

	printf 'package_count: %s\n' "${#PACKAGE_INFO[@]}"
	local entry name path index tool publishable unit integration source build_runner
	i=0
	for entry in ${PACKAGE_INFO[@]+"${PACKAGE_INFO[@]}"}; do
		i=$((i + 1))
		IFS=$US read -r name path index tool publishable unit integration source build_runner <<<"$entry"
		printf 'package.%d.name: %s\n' "$i" "$name"
		printf 'package.%d.path: %s\n' "$i" "$path"
		printf 'package.%d.root: %s\n' "$i" "$index"
		printf 'package.%d.tool: %s\n' "$i" "$tool"
		printf 'package.%d.publishable: %s\n' "$i" "$publishable"
		printf 'package.%d.build_runner: %s\n' "$i" "$build_runner"
		printf 'package.%d.unit_tests: %s\n' "$i" "$unit"
		printf 'package.%d.integration_tests: %s\n' "$i" "$integration"
		printf 'package.%d.test_source: %s\n' "$i" "$source"
	done

	local w
	for w in ${WARNINGS[@]+"${WARNINGS[@]}"}; do
		printf 'warning: %s\n' "$w"
	done
	printf '<<< renovate-fix\n'
}

# --- main ------------------------------------------------------------------------------

main() {
	local requested='' skip=false allow_dirty=false arg

	for arg in "$@"; do
		case "$arg" in
			-h | --help | help) usage ;;
			skip-post-upgrade) skip=true ;;
			allow-dirty) allow_dirty=true ;;
			*)
				[[ -z $requested ]] || die "more than one pull request given: '$requested' and '$arg'"
				requested="$arg"
				;;
		esac
	done
	[[ $skip == false || $allow_dirty == false ]] ||
		die "'skip-post-upgrade' and 'allow-dirty' contradict each other — pass at most one"

	command -v git >/dev/null || die "git is not on PATH"
	command -v gh >/dev/null || die "gh is not on PATH (it finds the pull request)"
	command -v dart >/dev/null || die "the dart SDK is not on PATH"
	command -v yq >/dev/null || die "yq is not on PATH (it reads pubspecs and workflow files)"
	command -v jq >/dev/null || die "jq is not on PATH (it builds the data file)"
	if yq --version 2>&1 | grep -q mikefarah; then
		YQ_FLAVOR=go
	else
		YQ_FLAVOR=python
	fi

	ROOT="$(repo_root)" || die "not inside a git repository"
	cd "$ROOT"

	resolve_pr "$requested"
	checkout_pr_branch
	inspect_commits
	inspect_pr_state
	resolve_preset
	find_changed_pubspecs
	resolve_roots
	run_post_upgrade "$skip" "$allow_dirty"

	# After the post-upgrade run, so that the record describes the state it left behind.
	scan_ci_workflows
	scan_packages
	scan_flutter_versions
	emit_record
}

main "$@"
