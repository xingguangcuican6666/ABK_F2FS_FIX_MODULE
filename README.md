# ABK External Module Template

Template repository for AnyBase Kernel (ABK) custom external modules.

ABK clones external module repositories during the kernel build and runs
`setup.sh` from the repository root at the configured injection stage. This
template is intentionally safe by default: it logs the build context and does
not modify the kernel tree until you add your own logic.

## Usage

Enable "custom external modules" in the ABK app or GitHub Actions.

In the ABK app, add the repository URL. The app reads `module.conf`, verifies
the supported stages, then asks the user which stage or stages to add:

```text
https://github.com/your-name/your-module.git
```

For raw GitHub Actions input, ABK accepts both the legacy format and the SC5
tagged format.

Legacy:

```text
https://github.com/your-name/your-module.git;after_patch
```

Tagged single module:

```text
module:https://github.com/your-name/your-module.git;after_patch
```

Tagged module-set child:

```text
set:https://github.com/your-name/your-module.git#feat_selinux_guard;before_build
```

Multiple modules are separated with `|`:

```text
module:https://github.com/your-name/module-a.git;after_patch|set:https://github.com/your-name/module-set.git#fix_policy_cleanup;before_build
```

Supported stages:

| Stage | Timing | Typical use |
| --- | --- | --- |
| `after_patch` | After ABK finishes built-in source integrations such as SUSFS, ZRAM, BBG, DDK, Re-Kernel, NTsync, IPSet, and BBR | Apply source patches, copy driver files, edit Kconfig or Makefile files |
| `before_build` | After ABK sets the kernel name and build timestamp, immediately before compilation | Final defconfig edits, generated files, validation checks |

`befor_build` is accepted by ABK as a compatibility alias, but new modules
should use `before_build`.

## module.conf Metadata

`module.conf` is now part of the ABK module contract. The app uses it for
validation, stage selection, and module repository display. Keep it
shell-compatible because `setup.sh` also sources it.

| Field | Required | Meaning |
| --- | --- | --- |
| `ABK_MODULE_NAME` | Yes | Display name |
| `ABK_MODULE_ID` | Recommended | Stable id used by metadata/control integrations |
| `ABK_MODULE_VERSION` | Recommended | Display version |
| `ABK_MODULE_DESCRIPTION` | Recommended | Short display description |
| `ABK_MODULE_REPO_URL` | Recommended | Canonical repository URL |
| `ABK_MODULE_SUPPORTED_STAGES` | Recommended | Comma-separated list, usually `after_patch,before_build` |
| `ABK_MODULE_DEFAULT_STAGE` | Recommended | Stage preselected when no recommendation is available |
| `ABK_MODULE_RECOMMENDED_STAGES` | Recommended | Comma-separated stages marked as recommended in the app |
| `ABK_MODULE_KIND` | Optional | `module_set` enables grouped child selection in the app |
| `ABK_MODULE_SET_ID` | Module-set only | Stable module-set id |
| `ABK_MODULE_SET_NAME` | Module-set only | Module-set display name |
| `ABK_MODULE_SET_VERSION` | Module-set only | Module-set display version |
| `ABK_MODULE_SET_DESCRIPTION` | Module-set only | Module-set description |
| `ABK_MODULE_SET_ITEMS` | Module-set only | Multi-line child declarations parsed by the app |

Example:

```bash
ABK_MODULE_ID="example_feature"
ABK_MODULE_NAME="Example Feature"
ABK_MODULE_VERSION="1.0.0"
ABK_MODULE_DESCRIPTION="Patch and configure an example kernel feature."
ABK_MODULE_REPO_URL="https://github.com/your-name/example-feature"
ABK_MODULE_SUPPORTED_STAGES="after_patch,before_build"
ABK_MODULE_DEFAULT_STAGE="after_patch"
ABK_MODULE_RECOMMENDED_STAGES="after_patch,before_build"
```

When publishing through a central module repository, point the catalog item
`repoUrl` to this module repository and mirror the same `supportedStages`,
`defaultStage`, and `recommendedStages` values in the catalog JSON.

For module-set repositories, the central catalog should only declare the entry
as `"kind": "module_set"`. Child feat/fix definitions stay in `module.conf`.

## Repository Layout

```text
.
|-- setup.sh
|-- module.conf
|-- scripts/
|   `-- libabk.sh
|-- patches/
|   `-- README.md
|-- files/
|   `-- README.md
`-- docs/
    `-- development.md
```

Required entry point:

- `setup.sh` must exist at the repository root.
- ABK executes it with `bash setup.sh`.
- The current working directory is the module repository root.

Recommended workflow:

1. Create a new repository from this template.
2. Update `module.conf` with your module name, version, and description.
3. Put patch files under `patches/`.
4. Put source files or templates under `files/`.
5. Implement stage-specific logic in `setup.sh`.
6. Keep every operation idempotent.

## Minimal Example

```bash
#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$MODULE_DIR/module.conf" ]; then
  source "$MODULE_DIR/module.conf"
fi
source "$MODULE_DIR/scripts/libabk.sh"

abk_require_env KERNEL_ROOT DEFCONFIG CUSTOM_EXTERNAL_MODULE_STAGE

case "$CUSTOM_EXTERNAL_MODULE_STAGE" in
  after_patch)
    abk_apply_patch_dir "$MODULE_DIR/patches/common"
    ;;
  before_build)
    abk_enable_config CONFIG_EXAMPLE_FEATURE
    ;;
esac
```

## Common Environment Variables

| Variable | Meaning |
| --- | --- |
| `GITHUB_WORKSPACE` | GitHub Actions workspace and ABK repository root |
| `CONFIG` | Build tuple, for example `android15-6.6-118` |
| `KERNEL_ROOT` | Kernel source directory |
| `DEFCONFIG` | GKI defconfig path |
| `CUSTOM_EXTERNAL_MODULE_STAGE` | Current stage, `after_patch` or `before_build` |
| `CUSTOM_EXTERNAL_MODULES_MANIFEST` | Parsed ABK module manifest |
| `ZZH_PATCHES` | ABK repository root |
| `SUSFS4KSU` | SUSFS repository path when SUSFS is enabled |
| `KERNEL_PATCHES` | `WildKernels/kernel_patches` repository path |
| `SUKISU_PATCHES` | `ShirkNeko/SukiSU_patch` repository path |
| `ANYKERNEL3` | AnyKernel3 repository path |
| `ACTION_BUILD` | Action-Build repository path |
| `KBUILD_BUILD_TIMESTAMP` | Available in `before_build` |
| `KBUILD_BUILD_VERSION` | Available in `before_build` |

Build-parameter variables exported to modules:

| Variable | Meaning |
| --- | --- |
| `ABK_BUILD_ANDROID_VERSION` | Selected Android branch, for example `android14` |
| `ABK_BUILD_KERNEL_VERSION` | Selected kernel line, for example `6.1` |
| `ABK_BUILD_SUB_LEVEL` | Selected sublevel |
| `ABK_BUILD_OS_PATCH_LEVEL` | Selected Android security patch level |
| `ABK_BUILD_REVISION` | Selected kernel revision |
| `ABK_BUILD_KSU_VARIANT` | KernelSU variant |
| `ABK_BUILD_KSU_BRANCH` | KernelSU branch label |
| `ABK_BUILD_VERSION` | Custom kernel local version input |
| `ABK_BUILD_TIME` | Build timestamp input |
| `ABK_BUILD_VIRTUALIZATION_SUPPORT` | Virtualization support setting |
| `ABK_BUILD_ZRAM_EXTRA_ALGOS` | Extra ZRAM algorithm list |

Feature flags are exported as `true` or `false`: `ABK_FEATURE_USE_ZRAM`,
`ABK_FEATURE_USE_BBG`, `ABK_FEATURE_USE_DDK`, `ABK_FEATURE_USE_NTSYNC`,
`ABK_FEATURE_USE_NETWORKING`, `ABK_FEATURE_USE_KPM`,
`ABK_FEATURE_USE_REKERNEL`, `ABK_FEATURE_ENABLE_SUSFS`,
`ABK_FEATURE_SUPP_OP`, and `ABK_FEATURE_ZRAM_FULL_ALGO`.

See [docs/development.md](docs/development.md) for the full development guide.

## Safety Rules

- Do not commit tokens, private keys, device private data, or opaque binaries.
- Do not download and execute unaudited remote scripts.
- Validate kernel versions and target files before modifying the source tree.
- Fail clearly with `exit 1` when a required condition is not met.
- Prefer changing only `$KERNEL_ROOT`, `$DEFCONFIG`, or files inside this
  module repository.

## License

GPL-3.0. Make sure any third-party code or patches you add are compatible with
the target kernel and this repository license.
