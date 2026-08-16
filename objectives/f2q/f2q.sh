#
# Galaxy Z Fold2 5G (Korea) bootstrap port configuration
#

CODENAME="f2q"
PLATFORM="sm8250"
DEVICE_ACTUAL_MODEL="SM-F916N"

# Target firmware: Galaxy Z Fold2 5G (KOO)
STOCK_MODEL="${F2Q_STOCK_MODEL:-SM-F916N}"
STOCK_CSC="${F2Q_STOCK_CSC:-KOO}"
STOCK_IMEI="${F2Q_STOCK_IMEI:-}"

# One UI 8 donor. Fold4 remains the default; q7q builds override these values
# through the environment without replacing known-good Fold4 workspaces.
MODEL="${F2Q_DONOR_MODEL:-SM-F936N}"
CSC="${F2Q_DONOR_CSC:-KOO}"
IMEI="${F2Q_DONOR_IMEI:-}"

# Pre-extracted local firmware images. Override these with the corresponding
# environment variables when the firmware directory is moved.
F2Q_FIRMWARE_ROOT="${F2Q_FIRMWARE_ROOT:-$(cd "$ASTROROM/.." && pwd)}"
SOURCE_LOCAL_FIRMWARE_DIR="${F2Q_DONOR_IMAGE_DIR:-$F2Q_FIRMWARE_ROOT/AP_F936NKSS8IZG2_F936NKSS8IZG2_MQB111920281_REV00_user_low_ship_MULTI_CERT_meta_OS16}"
STOCK_LOCAL_FIRMWARE_DIR="${F2Q_STOCK_IMAGE_DIR:-$F2Q_FIRMWARE_ROOT/AP_F916NKSS4KXH1_F916NKSS4KXH1_MQB84407716_REV00_user_low_ship_MULTI_CERT_meta_OS13}"

# Optional SM8250 comparison firmware. Keep empty for the first boot attempt.
EXTRA_MODEL="${F2Q_REFERENCE_MODEL:-}"
EXTRA_CSC="${F2Q_REFERENCE_CSC:-}"
EXTRA_IMEI="${F2Q_REFERENCE_IMEI:-}"

# Fold2 stock uses ext4 dynamic partitions.
FILESYSTEM="ext4"

# SM-F916N stock super metadata. The generated super image must fit the
# target bootloader's physical super partition, not the Fold4 donor's.
DEVICE_SUPER_PARTITION_SIZE="10817110016"
DEVICE_SUPER_GROUP_BASIC_SIZE="10812915712"
DEVICE_SUPER_METADATA_SIZE="65536"
DEVICE_SUPER_METADATA_SLOTS="2"
DEVICE_SUPER_GROUP_NAME="qti_dynamic_partitions"

# Keep target-specific CSC partitions instead of the donor's copies.
DEVICE_USE_STOCK_CSC=true

# Android 16 init must compile the split policy because the donor system policy
# hashes cannot match the Android 11 vendor precompiled policy. The donor's
# unused Samsung 30.0 mapping does not compile against F916N vendor policy, so
# use the target firmware's known-good 30.0 mapping CIL files.
DEVICE_USE_STOCK_SEPOLICY_MAPPING=true

# AVB is managed separately by the existing device setup.
DEVICE_INCLUDE_DISABLED_VBMETA=false

# Current Fold2 stock vendor is Android 11 / VNDK 30.
DEVICE_VNDK_VERSION="30"
DEVICE_USE_STOCK_VNDK_APEX=true
DEVICE_KEEP_DONOR_VNDK_APEX=true

# A native q7q One UI 8 system already contains the same-generation features
# that Astro otherwise imports from pa3q. Keep the donor package/resource set
# coherent instead of overwriting it with the twentyfive layer.
if [[ "$MODEL" == SM-F966* ]]; then
    DEVICE_SKIP_TWENTYFIVE_LAYER=true
else
    DEVICE_SKIP_TWENTYFIVE_LAYER="${F2Q_SKIP_TWENTYFIVE_LAYER:-false}"
fi

# Basic target display capabilities. Foldable-specific behavior is restored
# incrementally after the first successful boot.
DEVICE_DISPLAY_HFR_MODE="3"
DEVICE_DISPLAY_REFRESH_RATE_VALUES_HZ="60,48,96,120"
