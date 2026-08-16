# ==============================================================================
#
# MOD_NAME="Install the Fold2 framework resource overlay"
# MOD_AUTHOR="ProjectArc f2q"
# MOD_DESC="Restores Fold2 display cutout, corner and status-bar resources."
#
# ==============================================================================

PRODUCT_PATH="$(GET_PARTITION_PATH product)" \
    || ERROR_EXIT "Failed to get product partition path"
OVERLAY_SOURCE="$ASTROROM/overlays/F2qFrameworkOverlay.apk"
OVERLAY_TARGET="$PRODUCT_PATH/overlay/F2qFrameworkOverlay.apk"

[[ -f "$OVERLAY_SOURCE" ]] \
    || ERROR_EXIT "Missing Fold2 framework overlay"

install -D -m 0644 "$OVERLAY_SOURCE" "$OVERLAY_TARGET" \
    || ERROR_EXIT "Failed to install Fold2 framework overlay"
