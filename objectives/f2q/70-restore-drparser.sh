# ==============================================================================
#
# MOD_NAME="Restore the Samsung dialer keystring parser"
# MOD_AUTHOR="ProjectArc f2q"
# MOD_DESC="Restores hidden-menu dialing through SamsungDialer on the Fold2."
#
# ==============================================================================

DRPARSER_SOURCE="$SOURCE_FW/system/system/app/DRParser"

[[ -f "$DRPARSER_SOURCE/DRParser.apk" ]] \
    || ERROR_EXIT "Missing donor DRParser: $DRPARSER_SOURCE/DRParser.apk"

# One UI 8 SamsungDialer binds this service for every keystring. The common
# Astro debloat list removes DRParser as bloat, which leaves all registered
# DeviceKeystring/ServiceMode receivers unreachable from the dial pad.
ADD "system" "$DRPARSER_SOURCE" "app/DRParser" "Samsung dialer keystring parser"
