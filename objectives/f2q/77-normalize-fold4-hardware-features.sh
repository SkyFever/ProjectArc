# ==============================================================================
#
# MOD_NAME="Use donor One UI 8 features with Fold2 hardware capabilities"
# MOD_AUTHOR="ProjectArc f2q"
# MOD_DESC="Removes unsupported S25 feature gates and restores target hardware values."
#
# ==============================================================================

COMPOSER="$ASTROROM/scripts/helpers/compose_f2q_floating_feature.sh"
DONOR_FEATURES="$SOURCE_FW/system/system/etc/floating_feature.xml"
FOLD2_FEATURES="$STOCK_FW/system/system/etc/floating_feature.xml"
OUTPUT_FEATURES="$WORKSPACE/system/system/etc/floating_feature.xml"

[[ -f "$COMPOSER" ]] || ERROR_EXIT "Missing f2q floating-feature composer"
[[ -f "$DONOR_FEATURES" ]] || ERROR_EXIT "Missing donor floating features"
[[ -f "$FOLD2_FEATURES" ]] || ERROR_EXIT "Missing Fold2 floating features"

bash "$COMPOSER" "$DONOR_FEATURES" "$FOLD2_FEATURES" "$OUTPUT_FEATURES" \
    || ERROR_EXIT "Failed to compose f2q floating features"

chown 0:0 "$OUTPUT_FEATURES"
chmod 0644 "$OUTPUT_FEATURES"
setfattr -n security.selinux -v u:object_r:system_file:s0 "$OUTPUT_FEATURES"
