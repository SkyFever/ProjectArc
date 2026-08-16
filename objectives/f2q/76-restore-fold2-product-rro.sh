#!/usr/bin/env bash
# ==============================================================================
#
# MOD_NAME="Restore the Fold2 product resource overlay"
# MOD_AUTHOR="ProjectArc f2q"
# MOD_DESC="Uses Fold2 panel, cutout, status-bar and brightness resources."
#
# ==============================================================================

STOCK_PRODUCT_RRO=$(find "$STOCK_FW/product/overlay" -maxdepth 1 -type f \
    -name 'framework-res*auto_generated_rro_product.apk' -print -quit)
TARGET_PRODUCT_RRO="$WORKSPACE/product/overlay/product_overlay.apk"

if [[ -z "$STOCK_PRODUCT_RRO" || ! -f "$STOCK_PRODUCT_RRO" ]]; then
    ERROR_EXIT "Fold2 stock product RRO not found"
fi

mkdir -p "$(dirname "$TARGET_PRODUCT_RRO")"
cp -f "$STOCK_PRODUCT_RRO" "$TARGET_PRODUCT_RRO" || \
    ERROR_EXIT "Failed to restore the Fold2 product RRO"

LOG_INFO "Restored Fold2 product RRO: ${STOCK_PRODUCT_RRO#$STOCK_FW/}"
