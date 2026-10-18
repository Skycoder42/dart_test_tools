#!/usr/bin/env bash
#
# Template regenerator and change tracker for the dart-test-tools-native-update skill.
#
# Re-runs `flutter create` over every flutter app project in the repository, so that the
# native platform projects (android/, ios/, linux/, macos/, web/, windows/) and the top
# level project files pick up the templates of the installed Flutter SDK. Everything else
# the template touches is reset straight away. What remains is listed for the caller to
# evaluate, and can be thrown away again path by path.
#
# It never commits, pushes or stages. A regeneration only ever starts from a clean working
# tree, so that every change left behind came from the template and git can revert it.
#
set -euo pipefail

readonly SELF="${0##*/}"
readonly OUT_DIR="${TMPDIR:-/tmp}/dart-test-tools-native-update"
readonly -a PLATFORMS=(android ios linux macos web windows)
# Top level files the template rewrites but that are never part of the native update.
readonly -a PROJECT_FILES=(pubspec.yaml pubspec.lock)

# ASCII unit separator, used to pack fields into one array entry. See prepare-update.sh of
# the dart-test-tools-auto-update skill for why it is not TAB.
readonly US=$'\x1f'

# Accumulated `warning:` lines, printed with the record.
declare -a WARNINGS=()
# One entry per flutter app project, filled by discover_projects:
#   <dir>US<name>US<platforms>US<previous revision>
# <dir> is relative to the repository root ('.' for the root itself), <platforms> is a
# comma separated list.
declare -a PROJECTS=()
# Per project create results, parallel to PROJECTS: <exit code>US<log>
declare -a CREATE_RESULTS=()
# One entry per changed path, filled by collect_changes: <path>US<kind>
declare -a CHANGES=()
# Paths reset or discarded by this run.
declare -a RESET=()
declare -a DISCARDED=()

note() {
	printf '%s: %s\n' "$SELF" "$*" >&2
}

warn() {
	WARNINGS+=("$*")
	printf '%s: warning: %s\n' "$SELF" "$*" >&2
}

die() {
	printf '%s: error: %s\n' "$SELF" "$*" >&2
	printf '>>> native-update\n'
	printf 'status: error\n'
	local w
	for w in ${WARNINGS[@]+"${WARNINGS[@]}"}; do
		printf 'warning: %s\n' "$w"
	done
	printf 'error: %s\n' "$*"
	printf '<<< native-update\n'
	exit 1
}

usage() {
	cat >&2 <<-EOF
		usage: $SELF regenerate [--org <org>]
		       $SELF status
		       $SELF discard <path>...

		  regenerate   Requires a clean working tree. Runs 'flutter create --overwrite' over
		               every flutter app project for the platforms it already has, resets
		               everything outside the platform folders and the top level project
		               files, and lists the remaining changes.
		               --org is only needed when flutter cannot work out the organisation
		               of a project by itself.
		  status       Lists the changes that are currently left.
		  discard      Reverts the given changed files — or every changed file below the
		               given folders — and lists what is left. Paths are relative to the
		               repository root, or absolute. Only works inside the native scope.

		Output is a single machine readable record on stdout:

		  >>> native-update
		  <key>: <value>
		  ...
		  <<< native-update

		Keys are lowercase and may be dotted and indexed ('change.1.path'), values are
		single-line, and everything after the first ': ' belongs to the value. 'warning'
		may appear any number of times, every other key at most once. Progress and
		diagnostics go to stderr and are not part of the record.
	EOF
	exit 64
}

# --- helpers ---------------------------------------------------------------------------

# Joins a project directory and a path inside of it, without a leading './'.
project_path() {
	if [[ $1 == . ]]; then
		printf '%s\n' "$2"
	else
		printf '%s/%s\n' "$1" "$2"
	fi
}

# Prints a tracked file as it is in HEAD, falling back to the working tree.
head_file() {
	git show "HEAD:$1" 2>/dev/null || cat -- "$1" 2>/dev/null
}

contains() {
	local needle="$1" item
	shift
	for item in "$@"; do
		[[ $item == "$needle" ]] && return 0
	done
	return 1
}

# Deletes an untracked file, then every folder above it that became empty by that.
remove_untracked() {
	local path="$1" dir
	rm -f -- "$path"
	dir="$(dirname -- "$path")"
	while [[ $dir != . ]] && rmdir -- "$dir" 2>/dev/null; do
		dir="$(dirname -- "$dir")"
	done
}

revert_path() {
	local path="$1" kind="$2"
	if [[ $kind == added ]]; then
		remove_untracked "$path"
	else
		git restore --worktree -- "$path"
	fi
}

# --- discovery -------------------------------------------------------------------------

# Fills PROJECTS. A flutter app project is a tracked `.metadata` with `project_type: app`
# next to a pubspec.yaml. Plugins, packages and modules have no native app to update.
discover_projects() {
	local metadata dir type name revision platform
	local -a found=() listed=()
	PROJECTS=()

	while IFS= read -r -d '' metadata; do
		dir="$(dirname -- "$metadata")"
		type="$(head_file "$metadata" | yq -r '.project_type // ""' 2>/dev/null || true)"
		[[ $type == app ]] || continue

		if [[ ! -f $(project_path "$dir" pubspec.yaml) ]]; then
			warn "'$metadata' describes an app, but there is no pubspec.yaml next to it — skipped"
			continue
		fi
		name="$(yq -r '.name // ""' "$(project_path "$dir" pubspec.yaml)" 2>/dev/null || true)"
		[[ -n $name ]] || {
			warn "could not read the package name of '$dir' — skipped"
			continue
		}

		# The folders are the truth: the template is regenerated for exactly the platforms
		# the project has, so that none get added. `.metadata` is only cross-checked.
		found=()
		for platform in "${PLATFORMS[@]}"; do
			if [[ -n "$(git ls-tree -d --name-only HEAD -- "$(project_path "$dir" "$platform")")" ]]; then
				found+=("$platform")
			fi
		done
		mapfile -t listed < <(head_file "$metadata" | yq -r '.migration.platforms[].platform | select(. != "root")' 2>/dev/null | sort)
		if [[ "${found[*]-}" != "${listed[*]-}" ]]; then
			warn "'$dir': the platform folders (${found[*]-none}) and .metadata (${listed[*]-none}) disagree — regenerating the folders only"
		fi
		if ((${#found[@]} == 0)); then
			warn "'$dir' has no platform folders — nothing to regenerate"
			continue
		fi

		revision="$(head_file "$metadata" | yq -r '.version.revision // "unknown"' 2>/dev/null || echo unknown)"
		PROJECTS+=("$dir$US$name$US$(IFS=,; printf '%s' "${found[*]}")$US$revision")
	done < <(git ls-files -z -- ':(glob)**/.metadata')

	((${#PROJECTS[@]} > 0)) || warn "no flutter app project with platform folders found in this repository"
}

# Prints '<project index>US<area>' for a repository relative path. The area is 'root' for
# a top level file of the project, the platform for anything in one of its platform
# folders, and 'outside' for everything else — then the index is 0. Nested projects belong
# to the innermost one.
classify() {
	local path="$1" i=0 best=0 best_len=-1 entry dir rel
	local name platforms
	for entry in ${PROJECTS[@]+"${PROJECTS[@]}"}; do
		i=$((i + 1))
		IFS=$US read -r dir _ _ _ <<<"$entry"
		if [[ $dir == . ]] || [[ $path == "$dir"/* ]]; then
			if ((${#dir} > best_len)); then
				best=$i
				best_len=${#dir}
			fi
		fi
	done
	if ((best == 0)); then
		printf '0%soutside\n' "$US"
		return
	fi

	IFS=$US read -r dir name platforms _ <<<"${PROJECTS[best - 1]}"
	if [[ $dir == . ]]; then
		rel="$path"
	else
		rel="${path#"$dir"/}"
	fi

	if [[ $rel != */* ]]; then
		if contains "$rel" "${PROJECT_FILES[@]}"; then
			printf '%s%soutside\n' "$best" "$US"
		else
			printf '%s%sroot\n' "$best" "$US"
		fi
	elif [[ ",$platforms," == *",${rel%%/*},"* ]]; then
		printf '%s%s%s\n' "$best" "$US" "${rel%%/*}"
	else
		printf '%s%soutside\n' "$best" "$US"
	fi
}

# --- changes ---------------------------------------------------------------------------

# Fills CHANGES from the working tree. Nothing is ever staged by this script, so the
# working tree side of `git status` is what matters.
collect_changes() {
	local entry code path kind
	CHANGES=()
	while IFS= read -r -d '' entry; do
		code="${entry:0:2}"
		path="${entry:3}"
		case "$code" in
			R* | C*) IFS= read -r -d '' _ ;; # the source of a rename is a field of its own
		esac
		case "$code" in
			'??') kind=added ;;
			*D*) kind=deleted ;;
			*) kind=modified ;;
		esac
		CHANGES+=("$path$US$kind")
	done < <(git status --porcelain=v1 -z --untracked-files=all)
}

# Prints '<content>US<stat>' for a change: content is 'binary', 'whitespace' (the diff
# vanishes when whitespace and blank lines are ignored) or 'text'.
describe_change() {
	local path="$1" kind="$2" numstat added removed
	if [[ $kind == added ]]; then
		numstat="$(git diff --no-index --numstat -- /dev/null "$path" 2>/dev/null || true)"
	else
		numstat="$(git diff --numstat -- "$path")"
	fi
	read -r added removed _ <<<"$numstat" || true
	if [[ ${added-} == - ]]; then
		printf 'binary%sbinary\n' "$US"
		return
	fi
	if [[ $kind == modified ]] && git diff --quiet --ignore-all-space --ignore-blank-lines -- "$path"; then
		printf 'whitespace'
	else
		printf 'text'
	fi
	printf '%s+%s -%s\n' "$US" "${added:-0}" "${removed:-0}"
}

# Reverts every change outside the native scope and records it in RESET.
reset_outside() {
	local entry path kind area
	collect_changes
	for entry in ${CHANGES[@]+"${CHANGES[@]}"}; do
		IFS=$US read -r path kind <<<"$entry"
		IFS=$US read -r _ area <<<"$(classify "$path")"
		[[ $area == outside ]] || continue
		revert_path "$path" "$kind"
		RESET+=("$path")
	done
}

# Reverts every change in the working tree. Only used after a failed regeneration, which
# started from a clean tree — so everything there came from `flutter create`.
reset_all() {
	local entry path kind
	collect_changes
	for entry in ${CHANGES[@]+"${CHANGES[@]}"}; do
		IFS=$US read -r path kind <<<"$entry"
		revert_path "$path" "$kind"
	done
}

# --- actions ---------------------------------------------------------------------------

flutter_info() {
	local json
	json="$(flutter --version --machine 2>/dev/null | sed -n '/^{/,/^}/p' || true)"
	FLUTTER_VERSION="$(yq -p json -r '.frameworkVersion // "unknown"' <<<"$json" 2>/dev/null || echo unknown)"
	FLUTTER_REVISION="$(yq -p json -r '.frameworkRevision // "unknown"' <<<"$json" 2>/dev/null || echo unknown)"
}

regenerate() {
	local org="$1" i=0 entry dir name platforms log code failed=''
	local -a args

	[[ -z "$(git status --porcelain --untracked-files=normal)" ]] ||
		die "the working tree is not clean — commit or stash all changes (untracked files included) first"

	command -v flutter >/dev/null || die "flutter is not on PATH"
	flutter_info
	discover_projects
	mkdir -p "$OUT_DIR"

	for entry in ${PROJECTS[@]+"${PROJECTS[@]}"}; do
		i=$((i + 1))
		IFS=$US read -r dir name platforms _ <<<"$entry"
		log="$OUT_DIR/create-$i.log"
		# --no-pub: `pub get` is not part of a template update, and in a pub workspace it
		# would resolve far more than this one project.
		args=(create --overwrite --empty --no-pub "--platforms=$platforms" "--project-name=$name")
		[[ -z $org ]] || args+=("--org=$org")
		note "regenerating '$dir' for $platforms — output goes to $log"
		set +e
		(cd "$dir" && flutter "${args[@]}" .) >"$log" 2>&1
		code=$?
		set -e
		CREATE_RESULTS+=("$code$US$log")
		((code == 0)) || failed+="${failed:+, }'$dir' (exit code $code, see $log)"
	done

	if [[ -n $failed ]]; then
		reset_all
		die "flutter create failed for $failed — the working tree was reset to its clean state"
	fi

	reset_outside
	DIFF="$OUT_DIR/regenerated.diff"
	git diff >"$DIFF"
}

discard() {
	local target entry path kind area matched
	local -a targets=()
	(($# > 0)) || die "discard needs at least one path"

	discover_projects
	collect_changes

	for target in "$@"; do
		target="${target%/}"
		[[ $target != /* ]] || target="${target#"$ROOT"/}"
		[[ $target != /* ]] || die "'$target' is not inside the repository"
		targets+=("$target")
	done

	# Everything is validated before anything is reverted, so a bad path cannot leave a
	# half applied discard behind.
	local -a selected=()
	for target in "${targets[@]}"; do
		matched=false
		for entry in ${CHANGES[@]+"${CHANGES[@]}"}; do
			IFS=$US read -r path kind <<<"$entry"
			[[ $path == "$target" || $path == "$target"/* ]] || continue
			IFS=$US read -r _ area <<<"$(classify "$path")"
			[[ $area != outside ]] ||
				die "'$path' is outside the native scope — this script only reverts template changes"
			matched=true
			contains "$entry" ${selected[@]+"${selected[@]}"} || selected+=("$entry")
		done
		[[ $matched == true ]] || warn "'$target' has no changes — nothing to discard"
	done

	for entry in ${selected[@]+"${selected[@]}"}; do
		IFS=$US read -r path kind <<<"$entry"
		revert_path "$path" "$kind"
		DISCARDED+=("$path")
	done
}

# --- record ----------------------------------------------------------------------------

emit_record() {
	local action="$1" i=0 entry dir name platforms revision code log path kind index area
	local content stat

	printf '>>> native-update\n'
	printf 'status: ok\n'
	printf 'action: %s\n' "$action"
	printf 'repo_root: %s\n' "$ROOT"

	if [[ $action == regenerate ]]; then
		printf 'flutter_version: %s\n' "$FLUTTER_VERSION"
		printf 'flutter_revision: %s\n' "$FLUTTER_REVISION"
	fi

	printf 'project_count: %s\n' "${#PROJECTS[@]}"
	for entry in ${PROJECTS[@]+"${PROJECTS[@]}"}; do
		i=$((i + 1))
		IFS=$US read -r dir name platforms revision <<<"$entry"
		printf 'project.%d.path: %s\n' "$i" "$dir"
		printf 'project.%d.name: %s\n' "$i" "$name"
		printf 'project.%d.platforms: %s\n' "$i" "$platforms"
		printf 'project.%d.previous_revision: %s\n' "$i" "$revision"
		if [[ $action == regenerate ]]; then
			IFS=$US read -r code log <<<"${CREATE_RESULTS[i - 1]}"
			printf 'project.%d.create_exit_code: %s\n' "$i" "$code"
			printf 'project.%d.create_log: %s\n' "$i" "$log"
		fi
	done

	if [[ $action == regenerate ]]; then
		printf 'diff: %s\n' "$DIFF"
		printf 'reset_count: %s\n' "${#RESET[@]}"
		i=0
		for path in ${RESET[@]+"${RESET[@]}"}; do
			i=$((i + 1))
			printf 'reset.%d.path: %s\n' "$i" "$path"
		done
	fi

	if [[ $action == discard ]]; then
		printf 'discarded_count: %s\n' "${#DISCARDED[@]}"
		i=0
		for path in ${DISCARDED[@]+"${DISCARDED[@]}"}; do
			i=$((i + 1))
			printf 'discarded.%d.path: %s\n' "$i" "$path"
		done
	fi

	collect_changes
	printf 'change_count: %s\n' "${#CHANGES[@]}"
	i=0
	for entry in ${CHANGES[@]+"${CHANGES[@]}"}; do
		i=$((i + 1))
		IFS=$US read -r path kind <<<"$entry"
		IFS=$US read -r index area <<<"$(classify "$path")"
		IFS=$US read -r content stat <<<"$(describe_change "$path" "$kind")"
		printf 'change.%d.path: %s\n' "$i" "$path"
		printf 'change.%d.project: %s\n' "$i" "$index"
		printf 'change.%d.area: %s\n' "$i" "$area"
		printf 'change.%d.kind: %s\n' "$i" "$kind"
		printf 'change.%d.content: %s\n' "$i" "$content"
		printf 'change.%d.stat: %s\n' "$i" "$stat"
	done

	local w
	for w in ${WARNINGS[@]+"${WARNINGS[@]}"}; do
		printf 'warning: %s\n' "$w"
	done
	printf '<<< native-update\n'
}

# --- main ------------------------------------------------------------------------------

main() {
	local action="${1-}"
	(($# == 0)) || shift

	command -v git >/dev/null || die "git is not on PATH"
	command -v yq >/dev/null || die "yq is not on PATH (it reads .metadata and pubspec.yaml)"

	ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repository"
	cd "$ROOT"
	git rev-parse --verify --quiet HEAD >/dev/null || die "the repository has no commits yet"

	case "$action" in
		-h | --help | help | '') usage ;;
		regenerate)
			local org=''
			case "${1-}" in
				'') ;;
				--org)
					[[ -n ${2-} ]] || die "--org needs a value"
					org="$2"
					shift 2
					;;
				*) die "invalid argument '$1' — regenerate only accepts --org <org>" ;;
			esac
			(($# == 0)) || die "too many arguments"
			regenerate "$org"
			;;
		status)
			(($# == 0)) || die "status takes no arguments"
			discover_projects
			;;
		discard) discard "$@" ;;
		*) die "invalid action '$action' — expected 'regenerate', 'status' or 'discard'" ;;
	esac

	emit_record "$action"
}

main "$@"
