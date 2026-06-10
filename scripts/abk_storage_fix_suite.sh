#!/usr/bin/env bash

abk_storage_fix_suite_common_dir() {
  abk_common_dir
}

abk_storage_fix_suite_apply_patch_dir() {
  local patch_subdir="$1"
  local common_dir

  common_dir="$(abk_storage_fix_suite_common_dir)"
  abk_require_dir "$common_dir"
  abk_require_dir "$MODULE_DIR/patches/$patch_subdir"
  abk_apply_patch_dir "$MODULE_DIR/patches/$patch_subdir" "$common_dir"
}

abk_storage_fix_suite_default_options_range() {
  local source_file="$1"

  abk_require_file "$source_file"

  awk '
    BEGIN {
      in_func = 0
      seen_open = 0
      depth = 0
      start = 0
    }
    /^static void default_options\(struct f2fs_sb_info \*sbi\)/ {
      if (start != 0)
        exit 2
      start = NR
      in_func = 1
    }
    in_func {
      line = $0
      opens = gsub(/\{/, "{", line)
      closes = gsub(/\}/, "}", line)
      if (opens > 0)
        seen_open = 1
      if (seen_open)
        depth += opens - closes
      if (seen_open && depth == 0) {
        printf "%s:%s\n", start, NR
        exit 0
      }
    }
    END {
      if (start == 0 || !seen_open || depth != 0)
        exit 1
    }
  ' "$source_file"
}

abk_storage_fix_suite_print_default_options_context() {
  local source_file="$1"
  local range
  local start
  local end
  local context_start
  local context_end

  if ! range="$(abk_storage_fix_suite_default_options_range "$source_file" 2>/dev/null)"; then
    abk_warn "unable to locate default_options() in $source_file"
    return 0
  fi

  start="${range%%:*}"
  end="${range##*:}"
  context_start="$start"
  context_end="$end"

  if [ "$context_start" -gt 3 ]; then
    context_start="$((context_start - 3))"
  else
    context_start=1
  fi
  context_end="$((context_end + 3))"

  abk_warn "default_options() context from $source_file:"
  nl -ba "$source_file" | sed -n "${context_start},${context_end}p" >&2
}

abk_storage_fix_suite_die_lowdepth_context() {
  local source_file="$1"
  local message="$2"

  abk_storage_fix_suite_print_default_options_context "$source_file"
  abk_die "$message"
}

abk_storage_fix_suite_apply_lowdepth_fix() {
  local source_file="${1:-$(abk_storage_fix_suite_common_dir)/fs/f2fs/super.c}"
  local source_dir
  local range
  local start
  local end
  local posix_count
  local nobarrier_count
  local inline_data_count
  local tmp

  abk_require_file "$source_file"
  source_dir="$(dirname "$source_file")"

  if ! range="$(abk_storage_fix_suite_default_options_range "$source_file")"; then
    abk_storage_fix_suite_die_lowdepth_context \
      "$source_file" \
      "unsupported f2fs layout: default_options() not found or malformed in $source_file"
  fi

  start="${range%%:*}"
  end="${range##*:}"

  posix_count="$(
    sed -n "${start},${end}p" "$source_file" |
      grep -Ec '[[:space:]]*F2FS_OPTION\(sbi\)\.fsync_mode = FSYNC_MODE_POSIX;' || true
  )"
  nobarrier_count="$(
    sed -n "${start},${end}p" "$source_file" |
      grep -Ec '[[:space:]]*F2FS_OPTION\(sbi\)\.fsync_mode = FSYNC_MODE_NOBARRIER;' || true
  )"
  inline_data_count="$(
    sed -n "${start},${end}p" "$source_file" |
      grep -Ec '[[:space:]]*set_opt\(sbi, INLINE_DATA\);' || true
  )"

  if [ "$posix_count" -eq 0 ] && [ "$nobarrier_count" -eq 0 ]; then
    abk_storage_fix_suite_die_lowdepth_context \
      "$source_file" \
      "unsupported f2fs layout: no fsync_mode assignment found in default_options() for $source_file"
  fi

  if [ $((posix_count + nobarrier_count)) -ne 1 ]; then
    abk_storage_fix_suite_die_lowdepth_context \
      "$source_file" \
      "ambiguous f2fs layout: expected exactly one fsync_mode assignment in default_options() for $source_file"
  fi

  if [ "$inline_data_count" -gt 1 ]; then
    abk_storage_fix_suite_die_lowdepth_context \
      "$source_file" \
      "ambiguous f2fs layout: expected at most one INLINE_DATA default in default_options() for $source_file"
  fi

  if [ "$nobarrier_count" -eq 1 ] && [ "$inline_data_count" -eq 0 ]; then
    abk_log "lowdepth fix already applied: $source_file"
    return 0
  fi

  tmp="$(mktemp "$source_dir/.abk-lowdepth.XXXXXX")"
  awk -v start="$start" -v end="$end" '
    NR < start || NR > end {
      print
      next
    }
    {
      line = $0
      if (line ~ /^[[:space:]]*set_opt\(sbi, INLINE_DATA\);[[:space:]]*$/)
        next
      if (line ~ /^[[:space:]]*F2FS_OPTION\(sbi\)\.fsync_mode = FSYNC_MODE_POSIX;[[:space:]]*$/)
        sub(/FSYNC_MODE_POSIX;/, "FSYNC_MODE_NOBARRIER;", line)
      print line
    }
  ' "$source_file" > "$tmp"
  mv "$tmp" "$source_file"

  abk_log "applied lowdepth semantic fix: $source_file"
}

abk_storage_fix_suite_apply_child() {
  local child_id="$1"

  case "$child_id" in
    abk_f2fs_perf_fix)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_fix_suite_common_dir)/fs/f2fs"
      abk_storage_fix_suite_apply_patch_dir "abk_f2fs_perf_fix"
      ;;
    abk_f2fs_lowdepth_fix)
      abk_log "apply child: $child_id"
      abk_storage_fix_suite_apply_lowdepth_fix
      ;;
    abk_ufs_pm_fix)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_fix_suite_common_dir)/drivers/ufs/core"
      abk_storage_fix_suite_apply_patch_dir "abk_ufs_pm_fix"
      ;;
    abk_dm_default_key_fix)
      abk_log "apply child: $child_id"
      abk_require_dir "$(abk_storage_fix_suite_common_dir)/drivers/md"
      abk_storage_fix_suite_apply_patch_dir "abk_dm_default_key_fix"
      ;;
    *)
      abk_die "unsupported ABK module-set child id: $child_id"
      ;;
  esac
}

abk_storage_fix_suite_apply_selected() {
  local child_id="${ABK_MODULE_CHILD_ID:-}"

  if [ -n "$child_id" ]; then
    abk_storage_fix_suite_apply_child "$child_id"
    return 0
  fi

  abk_log "no ABK_MODULE_CHILD_ID provided; apply all storage fix children"
  abk_storage_fix_suite_apply_child "abk_f2fs_perf_fix"
  abk_storage_fix_suite_apply_child "abk_f2fs_lowdepth_fix"
  abk_storage_fix_suite_apply_child "abk_ufs_pm_fix"
  abk_storage_fix_suite_apply_child "abk_dm_default_key_fix"
}
