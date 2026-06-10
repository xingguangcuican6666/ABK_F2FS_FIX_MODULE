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

abk_storage_fix_suite_c_function_range() {
  local source_file="$1"
  local signature="$2"

  abk_require_file "$source_file"

  awk -v signature="$signature" '
    BEGIN {
      in_func = 0
      seen_open = 0
      depth = 0
      start = 0
    }
    $0 == signature {
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

abk_storage_fix_suite_default_options_range() {
  local source_file="$1"

  abk_storage_fix_suite_c_function_range \
    "$source_file" \
    "static void default_options(struct f2fs_sb_info *sbi)"
}

abk_storage_fix_suite_ufshcd_init_clk_gating_range() {
  local source_file="$1"

  abk_storage_fix_suite_c_function_range \
    "$source_file" \
    "static void ufshcd_init_clk_gating(struct ufs_hba *hba)"
}

abk_storage_fix_suite_ufshcd_init_range() {
  local source_file="$1"

  abk_storage_fix_suite_c_function_range \
    "$source_file" \
    "int ufshcd_init(struct ufs_hba *hba, void __iomem *mmio_base, unsigned int irq)"
}

abk_storage_fix_suite_print_function_context() {
  local source_file="$1"
  local range_func="$2"
  local context_label="$3"
  local range
  local start
  local end
  local context_start
  local context_end

  if ! range="$("$range_func" "$source_file" 2>/dev/null)"; then
    abk_warn "unable to locate $context_label in $source_file"
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

  abk_warn "$context_label context from $source_file:"
  nl -ba "$source_file" | sed -n "${context_start},${context_end}p" >&2
}

abk_storage_fix_suite_print_default_options_context() {
  local source_file="$1"

  abk_storage_fix_suite_print_function_context \
    "$source_file" \
    "abk_storage_fix_suite_default_options_range" \
    "default_options()"
}

abk_storage_fix_suite_die_lowdepth_context() {
  local source_file="$1"
  local message="$2"

  abk_storage_fix_suite_print_default_options_context "$source_file"
  abk_die "$message"
}

abk_storage_fix_suite_print_ufs_pm_context() {
  local source_file="$1"

  abk_storage_fix_suite_print_function_context \
    "$source_file" \
    "abk_storage_fix_suite_ufshcd_init_clk_gating_range" \
    "ufshcd_init_clk_gating()"
  abk_storage_fix_suite_print_function_context \
    "$source_file" \
    "abk_storage_fix_suite_ufshcd_init_range" \
    "ufshcd_init()"
}

abk_storage_fix_suite_die_ufs_pm_context() {
  local source_file="$1"
  local message="$2"

  abk_storage_fix_suite_print_ufs_pm_context "$source_file"
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

abk_storage_fix_suite_apply_ufs_pm_fix() {
  local source_file="${1:-$(abk_storage_fix_suite_common_dir)/drivers/ufs/core/ufshcd.c}"
  local source_dir
  local clk_range
  local init_range
  local clk_start
  local clk_end
  local init_start
  local init_end
  local clk_true_count
  local clk_false_count
  local rpm_guard_count
  local rpm_old_count
  local rpm_new_count
  local spm_guard_count
  local spm_old_count
  local spm_new_count
  local tmp

  abk_require_file "$source_file"
  source_dir="$(dirname "$source_file")"

  if ! clk_range="$(abk_storage_fix_suite_ufshcd_init_clk_gating_range "$source_file")"; then
    abk_storage_fix_suite_die_ufs_pm_context \
      "$source_file" \
      "unsupported UFS layout: ufshcd_init_clk_gating() not found or malformed in $source_file"
  fi
  if ! init_range="$(abk_storage_fix_suite_ufshcd_init_range "$source_file")"; then
    abk_storage_fix_suite_die_ufs_pm_context \
      "$source_file" \
      "unsupported UFS layout: ufshcd_init() not found or malformed in $source_file"
  fi

  clk_start="${clk_range%%:*}"
  clk_end="${clk_range##*:}"
  init_start="${init_range%%:*}"
  init_end="${init_range##*:}"

  clk_true_count="$(
    sed -n "${clk_start},${clk_end}p" "$source_file" |
      grep -Ec '[[:space:]]*hba->clk_gating\.is_enabled = true;' || true
  )"
  clk_false_count="$(
    sed -n "${clk_start},${clk_end}p" "$source_file" |
      grep -Ec '[[:space:]]*hba->clk_gating\.is_enabled = false;' || true
  )"
  rpm_guard_count="$(
    sed -n "${init_start},${init_end}p" "$source_file" |
      grep -Ec '[[:space:]]*if \(!hba->rpm_lvl\)' || true
  )"
  rpm_old_count="$(
    sed -n "${init_start},${init_end}p" "$source_file" |
      grep -Ec '[[:space:]]*hba->rpm_lvl = ufs_get_desired_pm_lvl_for_dev_link_state\([[:space:]]*$' || true
  )"
  rpm_new_count="$(
    sed -n "${init_start},${init_end}p" "$source_file" |
      grep -Ec '[[:space:]]*hba->rpm_lvl = UFS_PM_LVL_0;' || true
  )"
  spm_guard_count="$(
    sed -n "${init_start},${init_end}p" "$source_file" |
      grep -Ec '[[:space:]]*if \(!hba->spm_lvl\)' || true
  )"
  spm_old_count="$(
    sed -n "${init_start},${init_end}p" "$source_file" |
      grep -Ec '[[:space:]]*hba->spm_lvl = ufs_get_desired_pm_lvl_for_dev_link_state\([[:space:]]*$' || true
  )"
  spm_new_count="$(
    sed -n "${init_start},${init_end}p" "$source_file" |
      grep -Ec '[[:space:]]*hba->spm_lvl = UFS_PM_LVL_0;' || true
  )"

  if [ $((clk_true_count + clk_false_count)) -ne 1 ]; then
    abk_storage_fix_suite_die_ufs_pm_context \
      "$source_file" \
      "ambiguous UFS layout: expected exactly one clk_gating enable default in ufshcd_init_clk_gating() for $source_file"
  fi
  if [ $((rpm_old_count + rpm_new_count)) -ne 1 ]; then
    abk_storage_fix_suite_die_ufs_pm_context \
      "$source_file" \
      "ambiguous UFS layout: expected exactly one rpm_lvl default assignment in ufshcd_init() for $source_file"
  fi
  if [ "$rpm_new_count" -eq 1 ] && [ "$rpm_guard_count" -ne 0 ]; then
    abk_storage_fix_suite_die_ufs_pm_context \
      "$source_file" \
      "ambiguous UFS layout: rpm_lvl guard remains around UFS_PM_LVL_0 in ufshcd_init() for $source_file"
  fi
  if [ $((spm_old_count + spm_new_count)) -ne 1 ]; then
    abk_storage_fix_suite_die_ufs_pm_context \
      "$source_file" \
      "ambiguous UFS layout: expected exactly one spm_lvl default assignment in ufshcd_init() for $source_file"
  fi
  if [ "$spm_new_count" -eq 1 ] && [ "$spm_guard_count" -ne 0 ]; then
    abk_storage_fix_suite_die_ufs_pm_context \
      "$source_file" \
      "ambiguous UFS layout: spm_lvl guard remains around UFS_PM_LVL_0 in ufshcd_init() for $source_file"
  fi

  if [ "$clk_false_count" -eq 1 ] && [ "$rpm_new_count" -eq 1 ] && [ "$spm_new_count" -eq 1 ]; then
    abk_log "UFS PM fix already applied: $source_file"
    return 0
  fi

  tmp="$(mktemp "$source_dir/.abk-ufs-pm.XXXXXX")"
  awk -v clk_start="$clk_start" -v clk_end="$clk_end" -v init_start="$init_start" -v init_end="$init_end" '
    BEGIN {
      saw_rpm_guard = 0
      saw_spm_guard = 0
      skip_rpm = 0
      skip_spm = 0
    }
    {
      line = $0

      if (skip_rpm) {
        if (line ~ /\);[[:space:]]*$/)
          skip_rpm = 0
        next
      }
      if (skip_spm) {
        if (line ~ /\);[[:space:]]*$/)
          skip_spm = 0
        next
      }

      if (NR >= init_start && NR <= init_end &&
          line ~ /^[[:space:]]*if \(!hba->rpm_lvl\)[[:space:]]*$/) {
        saw_rpm_guard = 1
        next
      }

      if (NR >= init_start && NR <= init_end &&
          line ~ /^[[:space:]]*if \(!hba->spm_lvl\)[[:space:]]*$/) {
        saw_spm_guard = 1
        next
      }

      if (NR >= clk_start && NR <= clk_end &&
          line ~ /^[[:space:]]*hba->clk_gating\.is_enabled = true;[[:space:]]*$/) {
        sub(/true;/, "false;", line)
        print line
        next
      }

      if (NR >= init_start && NR <= init_end &&
          line ~ /^[[:space:]]*hba->rpm_lvl = ufs_get_desired_pm_lvl_for_dev_link_state\([[:space:]]*$/) {
        match(line, /^[[:space:]]*/)
        indent = substr(line, RSTART, RLENGTH)
        print indent "hba->rpm_lvl = UFS_PM_LVL_0;"
        skip_rpm = 1
        saw_rpm_guard = 0
        next
      }

      if (NR >= init_start && NR <= init_end &&
          line ~ /^[[:space:]]*hba->spm_lvl = ufs_get_desired_pm_lvl_for_dev_link_state\([[:space:]]*$/) {
        match(line, /^[[:space:]]*/)
        indent = substr(line, RSTART, RLENGTH)
        print indent "hba->spm_lvl = UFS_PM_LVL_0;"
        skip_spm = 1
        saw_spm_guard = 0
        next
      }

      print line
    }
  ' "$source_file" > "$tmp"
  mv "$tmp" "$source_file"

  abk_log "applied UFS PM semantic fix: $source_file"
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
      abk_storage_fix_suite_apply_ufs_pm_fix
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
