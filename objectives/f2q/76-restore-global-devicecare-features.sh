# ==============================================================================
#
# MOD_NAME="Restore Korean Device Care"
# MOD_AUTHOR="ProjectArc f2q"
# MOD_DESC="Reverts Astro's China Smart Manager defaults for KOO/LUC devices."
#
# ==============================================================================

DEVICE_CARE_SOURCE="$SOURCE_FW/system/system/priv-app/SmartManager_v5"
DEVICE_SECURITY_SOURCE="$SOURCE_FW/system/system/app/SmartManager_v6_DeviceSecurity"
LOOL_PRIVAPP_SOURCE="$SOURCE_FW/system/system/etc/permissions/privapp-permissions-com.samsung.android.lool.xml"
LOOL_SIGNATURE_SOURCE="$SOURCE_FW/system/system/etc/permissions/signature-permissions-com.samsung.android.lool.xml"

[[ -f "$DEVICE_CARE_SOURCE/SmartManager_v5.apk" ]] \
    || ERROR_EXIT "Missing Fold4 global Device Care"
[[ -f "$DEVICE_SECURITY_SOURCE/SmartManager_v6_DeviceSecurity.apk" ]] \
    || ERROR_EXIT "Missing Fold4 global Device Security"
[[ -f "$LOOL_PRIVAPP_SOURCE" ]] \
    || ERROR_EXIT "Missing Fold4 Device Care privapp allowlist"
[[ -f "$LOOL_SIGNATURE_SOURCE" ]] \
    || ERROR_EXIT "Missing Fold4 Device Care signature permissions"

# The common Astro layer switches Device Care to the China-only packages. The
# f2q layer removes those APKs for KOO/LUC, so leaving the China package names
# behind exposes a dead App Lock preference and leaves Device Care absent.
FF "SMARTMANAGER_CONFIG_PACKAGE_NAME" "com.samsung.android.lool"
FF "SECURITY_CONFIG_DEVICEMONITOR_PACKAGE_NAME" "com.samsung.android.sm.devicesecurity"

ADD "system" "$DEVICE_CARE_SOURCE" "priv-app/SmartManager_v5" "Fold4 global Device Care"
ADD "system" "$DEVICE_SECURITY_SOURCE" "app/SmartManager_v6_DeviceSecurity" "Fold4 global Device Security"
ADD "system" "$LOOL_PRIVAPP_SOURCE" \
    "etc/permissions/privapp-permissions-com.samsung.android.lool.xml" \
    "Device Care privapp allowlist"
ADD "system" "$LOOL_SIGNATURE_SOURCE" \
    "etc/permissions/signature-permissions-com.samsung.android.lool.xml" \
    "Device Care signature permissions"
