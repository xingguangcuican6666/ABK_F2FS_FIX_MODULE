#!/usr/bin/env bash

abk_log() {
  printf '[ABK storage rollback] %s\n' "$*"
}

abk_warn() {
  printf '[ABK storage rollback][warn] %s\n' "$*" >&2
}

abk_die() {
  printf '[ABK storage rollback][error] %s\n' "$*" >&2
  exit 1
}

abk_require_env() {
  local name
  for name in "$@"; do
    if [ -z "${!name:-}" ]; then
      abk_die "required environment variable is empty: $name"
    fi
  done
}

abk_common_dir() {
  abk_require_env KERNEL_ROOT
  printf '%s/common\n' "$KERNEL_ROOT"
}

abk_kernel_makefile_path() {
  local common_makefile root_makefile

  common_makefile="$(abk_common_dir)/Makefile"
  root_makefile="$KERNEL_ROOT/Makefile"

  if [ -f "$common_makefile" ]; then
    printf '%s\n' "$common_makefile"
    return 0
  fi

  abk_require_file "$root_makefile"
  printf '%s\n' "$root_makefile"
}

abk_require_file() {
  local path="$1"
  [ -f "$path" ] || abk_die "required file not found: $path"
}

abk_require_dir() {
  local path="$1"
  [ -d "$path" ] || abk_die "required directory not found: $path"
}

abk_kernel_make_value() {
  local key="$1"
  local makefile
  makefile="$(abk_kernel_makefile_path)"
  awk -v key="$key" '$1 == key && $2 == "=" { print $3; exit }' "$makefile"
}

abk_kernel_sublevel() {
  abk_kernel_make_value SUBLEVEL
}

abk_apply_reverse_patch() {
  local patch_file="$1"
  local target_dir="${2:-$(abk_common_dir)}"

  abk_require_file "$patch_file"
  abk_require_dir "$target_dir"

  (
    cd "$target_dir" || exit
    if git apply --reverse --check --allow-empty "$patch_file" >/dev/null 2>&1; then
      git apply --reverse --allow-empty "$patch_file"
      abk_log "applied rollback patch: $patch_file"
      exit 0
    fi

    if git apply --check --allow-empty "$patch_file" >/dev/null 2>&1; then
      abk_log "rollback patch already applied: $patch_file"
      exit 0
    fi

    abk_die "rollback patch does not match current kernel tree: $patch_file"
  )
}
