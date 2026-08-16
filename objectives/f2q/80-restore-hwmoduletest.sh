# ==============================================================================
#
# MOD_NAME="Restore the Fold2 hardware test menu"
# MOD_AUTHOR="ProjectArc f2q"
# MOD_DESC="Restores the SM-F916N receiver and implementation for *#0*#."
#
# ==============================================================================

HWMODULE_SOURCE="$STOCK_FW/system/system/priv-app/HwModuleTest"
HWMODULE_PERMISSIONS="$STOCK_FW/system/system/etc/permissions/privapp-permissions-com.sec.android.app.hwmoduletest.xml"

[[ -f "$HWMODULE_SOURCE/HwModuleTest.apk" ]] \
    || ERROR_EXIT "Missing Fold2 HwModuleTest: $HWMODULE_SOURCE/HwModuleTest.apk"
[[ -f "$HWMODULE_PERMISSIONS" ]] \
    || ERROR_EXIT "Missing Fold2 HwModuleTest permission allowlist"

# Fold4 no longer ships HwModuleTest. The Fold2 package declares the Samsung
# secret-code receiver for android_secret_code://0* and contains the target's
# dual-display/sensor factory tests.
ADD "system" "$HWMODULE_SOURCE" "priv-app/HwModuleTest" "Fold2 hardware test menu"
ADD "system" "$HWMODULE_PERMISSIONS" \
    "etc/permissions/privapp-permissions-com.sec.android.app.hwmoduletest.xml" \
    "Fold2 hardware test permissions"
