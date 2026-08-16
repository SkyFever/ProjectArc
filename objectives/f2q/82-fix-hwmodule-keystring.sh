# ==============================================================================
#
# MOD_NAME="Route the Fold2 hardware-test keystring"
# MOD_AUTHOR="ProjectArc f2q"
# MOD_DESC="Adds the One UI 8 package target for *#0*# in Korean OMC data."
#
# ==============================================================================

PATCHER="$ASTROROM/scripts/helpers/patch_samsung_keystrings.py"
DRPARSER="$WORKSPACE/system/system/app/DRParser/DRParser.apk"

[[ -f "$PATCHER" ]] || ERROR_EXIT "Missing Samsung keystring patcher"
[[ -f "$DRPARSER" ]] || ERROR_EXIT "Missing donor DRParser"

KEYSTRING_FILES=(
    "$WORKSPACE/prism/etc/carriers/LUC/LUC_keystrings.dat"
    "$WORKSPACE/prism/etc/carriers/single/KOO/KOO_keystrings.dat"
)

for KEYSTRING_FILE in "${KEYSTRING_FILES[@]}"; do
    [[ -f "$KEYSTRING_FILE" ]] \
        || ERROR_EXIT "Missing Korean keystring data: $KEYSTRING_FILE"
    python3 "$PATCHER" \
        --apk "$DRPARSER" \
        --input "$KEYSTRING_FILE" \
        --output "$KEYSTRING_FILE" \
        --set-package-for-sequence '*#0*#' \
        --package com.sec.android.app.hwmoduletest \
        || ERROR_EXIT "Failed to patch $KEYSTRING_FILE"
done
