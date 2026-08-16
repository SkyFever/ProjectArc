# ==============================================================================
#
# MOD_NAME="Bypass netd bandwidth initialization for boot diagnostics"
# MOD_AUTHOR="ProjectArc f2q bootstrap"
# MOD_DESC="Lets netd continue when the Android 16 BPF-backed iptables rules fail."
#
# ==============================================================================

SYSTEM_PATH="$(GET_PARTITION_PATH system)" \
    || ERROR_EXIT "Failed to get system partition path"
NETD="$SYSTEM_PATH/bin/netd"

[[ -f "$NETD" ]] || ERROR_EXIT "Missing system netd binary"

# The q7q binary keeps the same Controllers::init() sequence at +0x3000.
# Its exit instrumentation is deliberately disabled because that diagnostic
# turned a normal netd failure into a hot reboot on the newer donor.
if [[ "$MODEL" == SM-F966* ]]; then
    INIT_OFFSET=$((0x8ca24))
    FILE_OFFSET=$((0xa5438))
    REQUIRE_EXIT_INSTRUMENTATION=false
else
    INIT_OFFSET=$((0x89a24))
    FILE_OFFSET=$((0xa2438))
    REQUIRE_EXIT_INSTRUMENTATION=true
fi

# The preceding BPF initializer bypass must already be present.
INIT_PATCH_HEX="$(
    dd if="$NETD" bs=1 skip="$INIT_OFFSET" count=4 status=none \
        | od -An -tx1 -v | tr -d ' \n'
)"
[[ "$INIT_PATCH_HEX" == e0031f2a ]] \
    || ERROR_EXIT "netd BPF initializer bypass is not present"

if [[ "$REQUIRE_EXIT_INSTRUMENTATION" == true ]]; then
    EXIT_PATCH_HEX="$(
        dd if="$NETD" bs=1 skip=$((0xec038)) count=4 status=none \
            | od -An -tx1 -v | tr -d ' \n'
    )"
    [[ "$EXIT_PATCH_HEX" == 38fbff17 ]] \
        || ERROR_EXIT "netd exit instrumentation is not present"
fi

# Controllers::init()+0x44:
#   cbnz w0, 0xa29f0  -> BandwidthController failure handler and exit(1)
# Replace the conditional branch with a NOP so both success and failure take
# the normal continuation at 0xa243c. This is a boot diagnostic only: bandwidth
# accounting, quotas, and BPF-backed iptables rules remain unavailable.
EXPECTED_HEX=c02d0035
REPLACEMENT_HEX=1f2003d5
ACTUAL_HEX="$(
    dd if="$NETD" bs=1 skip="$FILE_OFFSET" count=4 status=none \
        | od -An -tx1 -v | tr -d ' \n'
)"
[[ "$ACTUAL_HEX" == "$EXPECTED_HEX" ]] \
    || ERROR_EXIT "Unexpected netd bandwidth branch at offset $(printf '0x%x' "$FILE_OFFSET")"

printf '\x1f\x20\x03\xd5' \
    | dd of="$NETD" bs=1 seek="$FILE_OFFSET" conv=notrunc status=none

PATCHED_HEX="$(
    dd if="$NETD" bs=1 skip="$FILE_OFFSET" count=4 status=none \
        | od -An -tx1 -v | tr -d ' \n'
)"
[[ "$PATCHED_HEX" == "$REPLACEMENT_HEX" ]] \
    || ERROR_EXIT "Failed to bypass netd BandwidthController failure"
