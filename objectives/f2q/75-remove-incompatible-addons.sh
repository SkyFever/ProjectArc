# ==============================================================================
#
# MOD_NAME="Remove incompatible S25 and non-Korean add-ons"
# MOD_AUTHOR="ProjectArc f2q"
# MOD_DESC="Keeps the Fold4 framework coherent and removes packages not shipped for KOR devices."
#
# ==============================================================================

# Astro's twentyfive layer imports the pa3q EAD application, but the Fold4
# framework does not contain the pa3q resource table it was compiled against.
# A q7q donor ships its own coherent EAD package and skips that pa3q layer, so
# retain it for the Fold7 branch.
if [[ "$MODEL" != SM-F966* ]]; then
    REMOVE "system" "priv-app/EnvironmentAdaptiveDisplay"
fi

# These packages are China-market components and should not be exposed on a
# Korean KOO/LUC device. Their generic defaults can become visible when older
# Fold2 OMC data is combined with the Android 16 donor system.
REMOVE "system" "app/SmartManager_v6_DeviceSecurity_CN"
REMOVE "system" "priv-app/AppLock"
REMOVE "system" "priv-app/Firewall"
REMOVE "system" "priv-app/SmartManagerCN"
