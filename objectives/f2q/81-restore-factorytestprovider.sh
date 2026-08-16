# ==============================================================================
#
# MOD_NAME="Restore the Fold2 factory-test provider"
# MOD_AUTHOR="ProjectArc f2q"
# MOD_DESC="Restores the data provider required by the Fold2 *#0*# test menu."
#
# ==============================================================================

FACTORY_PROVIDER_SOURCE="$STOCK_FW/system/system/priv-app/FactoryTestProvider"
FACTORY_PROVIDER_PERMISSIONS="$STOCK_FW/system/system/etc/permissions/privapp-permissions-com.samsung.android.providers.factory.xml"

[[ -f "$FACTORY_PROVIDER_SOURCE/FactoryTestProvider.apk" ]] \
    || ERROR_EXIT "Missing Fold2 FactoryTestProvider APK"
[[ -f "$FACTORY_PROVIDER_PERMISSIONS" ]] \
    || ERROR_EXIT "Missing Fold2 FactoryTestProvider permission allowlist"

# HwModuleTest queries this system-UID provider while constructing its main
# menu. Without it the activity stays alive but renders an empty white screen.
ADD "system" "$FACTORY_PROVIDER_SOURCE" \
    "priv-app/FactoryTestProvider" "Fold2 factory-test provider"
ADD "system" "$FACTORY_PROVIDER_PERMISSIONS" \
    "etc/permissions/privapp-permissions-com.samsung.android.providers.factory.xml" \
    "Fold2 factory-test provider permissions"
