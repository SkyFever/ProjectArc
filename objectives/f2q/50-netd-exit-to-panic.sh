# ==============================================================================
#
# MOD_NAME="Persist the next netd failure"
# MOD_AUTHOR="ProjectArc f2q bootstrap"
# MOD_DESC="Turns netd exit() into abort() so pmsg and a tombstone survive."
#
# ==============================================================================

# This was a Fold4-era failure-capture aid, not a runtime compatibility fix.
# Keep q7q netd's normal exit path so a later service failure does not turn
# into an avoidable native abort/hot reboot.
if [[ "$MODEL" == SM-F966* ]]; then
    LOG_INFO "Skipping Fold4 netd exit-to-abort diagnostic on q7q"
    return 0
fi

SYSTEM_PATH="$(GET_PARTITION_PATH system)" \
    || ERROR_EXIT "Failed to get system partition path"
NETD="$SYSTEM_PATH/bin/netd"

[[ -f "$NETD" ]] || ERROR_EXIT "Missing system netd binary"

INIT_PATCH_HEX="$(
    dd if="$NETD" bs=1 skip=$((0x89a24)) count=4 status=none \
        | od -An -tx1 -v | tr -d ' \n'
)"
[[ "$INIT_PATCH_HEX" == e0031f2a ]] \
    || ERROR_EXIT "netd BPF initializer bypass is not present"

FILE_OFFSET=$((0xec038))
EXPECTED_HEX=50000090
REPLACEMENT_HEX=38fbff17
ACTUAL_HEX="$(
    dd if="$NETD" bs=1 skip="$FILE_OFFSET" count=4 status=none \
        | od -An -tx1 -v | tr -d ' \n'
)"
[[ "$ACTUAL_HEX" == "$EXPECTED_HEX" ]] \
    || ERROR_EXIT "Unexpected netd exit PLT instruction"

printf '\x38\xfb\xff\x17' \
    | dd of="$NETD" bs=1 seek="$FILE_OFFSET" conv=notrunc status=none

PATCHED_HEX="$(
    dd if="$NETD" bs=1 skip="$FILE_OFFSET" count=4 status=none \
        | od -An -tx1 -v | tr -d ' \n'
)"
[[ "$PATCHED_HEX" == "$REPLACEMENT_HEX" ]] \
    || ERROR_EXIT "Failed to redirect netd exit to abort"
