#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$MODULE_DIR/module.conf" ]; then
  # shellcheck disable=SC1091
  source "$MODULE_DIR/module.conf"
fi

# shellcheck disable=SC1091
source "$MODULE_DIR/scripts/libabk.sh"
# shellcheck disable=SC1091
source "$MODULE_DIR/scripts/abk_storage_fix_suite.sh"

abk_require_env KERNEL_ROOT DEFCONFIG CUSTOM_EXTERNAL_MODULE_STAGE

module_name="${ABK_MODULE_SET_NAME:-${ABK_MODULE_NAME:-ABK external module}}"
module_version="${ABK_MODULE_SET_VERSION:-${ABK_MODULE_VERSION:-unknown}}"

abk_log "module: $module_name"
abk_log "version: $module_version"
abk_log "stage: $CUSTOM_EXTERNAL_MODULE_STAGE"
abk_log "config: ${CONFIG:-unknown}"
abk_log "kernel root: $KERNEL_ROOT"
if [ -n "${ABK_MODULE_CHILD_ID:-}" ]; then
  abk_log "module-set child: ${ABK_MODULE_CHILD_ID}"
fi

case "$CUSTOM_EXTERNAL_MODULE_STAGE" in
  after_patch|before_build)
    abk_storage_fix_suite_apply_selected
    ;;
  *)
    abk_die "unsupported CUSTOM_EXTERNAL_MODULE_STAGE: $CUSTOM_EXTERNAL_MODULE_STAGE"
    ;;
esac

abk_log "done"
