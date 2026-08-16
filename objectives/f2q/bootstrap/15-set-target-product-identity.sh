# ==============================================================================
#
# MOD_NAME="Set the Fold2 product identity"
# MOD_AUTHOR="ProjectArc f2q bootstrap"
# MOD_DESC="Keeps Android and Samsung services on one SM-F916N model identity."
#
# ==============================================================================

# Keep Android 16 build/version fields from the Fold4 source, but normalize the
# hardware-facing product identity to the Fold2 stock values.  The stock
# system/product/system_ext/system_dlkm device is qssi, while vendor/odm use
# f2q; those device fields are already supplied by their respective sources.
# Explicit generic name/device/model values avoid init deriving them from a
# mixture of donor and stock partition properties.
TARGET_PRODUCT_NAME="$(GET_PROP "system" "ro.product.system.name" "stock" || true)"
: "${TARGET_PRODUCT_NAME:=f2qksx}"

BPROP "system" "ro.product.name" "$TARGET_PRODUCT_NAME"
BPROP "system" "ro.product.device" "$CODENAME"
BPROP "system" "ro.product.model" "$DEVICE_MODEL"
BPROP "system" "ro.product.system.name" "$TARGET_PRODUCT_NAME"
BPROP "system" "ro.product.system.model" "$DEVICE_MODEL"
BPROP "system_ext" "ro.product.system_ext.name" "$TARGET_PRODUCT_NAME"
BPROP "system_ext" "ro.product.system_ext.model" "$DEVICE_MODEL"
BPROP "product" "ro.product.product.name" "$TARGET_PRODUCT_NAME"
BPROP "product" "ro.product.product.model" "$DEVICE_MODEL"
BPROP "system_dlkm" "ro.product.system_dlkm.name" "$TARGET_PRODUCT_NAME"
BPROP "system_dlkm" "ro.product.system_dlkm.model" "$DEVICE_MODEL"

# Astro-patched camera libraries query this alias instead of ro.product.name.
BPROP "system" "ro.astro.codename" "$TARGET_PRODUCT_NAME"
BPROP "system" "ro.product.astro.model" "$DEVICE_MODEL"
BPROP "system" "ro.factory.model" "$DEVICE_MODEL"
