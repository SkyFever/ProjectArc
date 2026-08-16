# ==============================================================================
#
# MOD_NAME="Import the target vendor FCM"
# MOD_AUTHOR="ProjectArc f2q bootstrap"
# MOD_DESC="Adds the F916N framework compatibility matrix required by its vendor."
#
# ==============================================================================

SYSTEM_PATH="$(GET_PARTITION_PATH system)" \
    || ERROR_EXIT "Failed to get system partition path"
STOCK_FCM_DIR="$STOCK_FW/system/system/etc/vintf"
TARGET_FCM_DIR="$SYSTEM_PATH/etc/vintf"
VENDOR_MANIFEST="$WORKSPACE/vendor/etc/vintf/manifest.xml"

TARGET_LEVEL="$(
    sed -n -E 's/.*target-level="([^"]+)".*/\1/p' "$VENDOR_MANIFEST" \
        | head -n 1
)"
[[ "$TARGET_LEVEL" =~ ^[0-9]+$ ]] \
    || ERROR_EXIT "Could not determine target-level from vendor manifest"

STOCK_FCM="$STOCK_FCM_DIR/compatibility_matrix.$TARGET_LEVEL.xml"
TARGET_FCM="$TARGET_FCM_DIR/compatibility_matrix.$TARGET_LEVEL.xml"
[[ -f "$STOCK_FCM" ]] \
    || ERROR_EXIT "Missing stock framework compatibility matrix: $STOCK_FCM"

mkdir -p "$TARGET_FCM_DIR"
install -m 0644 "$STOCK_FCM" "$TARGET_FCM"

grep -q -E "<compatibility-matrix[^>]+type=\"framework\"[^>]+level=\"$TARGET_LEVEL\"" \
    "$TARGET_FCM" \
    || ERROR_EXIT "Imported matrix does not declare framework FCM level $TARGET_LEVEL"
