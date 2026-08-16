# ==============================================================================
#
# MOD_NAME="Bypass netd BPF initialization for boot diagnostics"
# MOD_AUTHOR="ProjectArc f2q bootstrap"
# MOD_DESC="Lets netd continue past missing Android 16 networking BPF objects."
#
# ==============================================================================

SYSTEM_PATH="$(GET_PARTITION_PATH system)" \
    || ERROR_EXIT "Failed to get system partition path"
NETD="$SYSTEM_PATH/bin/netd"

[[ -f "$NETD" ]] || ERROR_EXIT "Missing system netd binary"

NETD_SHA=$(sha256sum "$NETD" | awk '{print $1}')
case "$NETD_SHA" in
    # Fold4 One UI 8, 2026-07
    83169ee84f6f1170f9c7b38edb818e6f2320a3f3ba84e472284c45318e0b5e96)
        FILE_OFFSET=$((0x89a24))
        EXPECTED_HEX=8b890194
        ;;
    # Fold7 One UI 8, F966NKSS7AYLT
    bad0a0d85d9cc6994e0e09b79e870ef3fd3addbab40dde2f39446e498da2d32f)
        FILE_OFFSET=$((0x8ca24))
        EXPECTED_HEX=63890194
        ;;
    *)
        ERROR_EXIT "Unexpected netd build; refusing offset-based patch: $NETD_SHA"
        ;;
esac

# Replace `bl libnetd_updatable_init@plt` with `mov w0, wzr`. The immediately
# following cbnz treats the skipped initializer as successful.
REPLACEMENT_HEX=e0031f2a
ACTUAL_HEX="$(
    dd if="$NETD" bs=1 skip="$FILE_OFFSET" count=4 status=none \
        | od -An -tx1 -v | tr -d ' \n'
)"
[[ "$ACTUAL_HEX" == "$EXPECTED_HEX" ]] \
    || ERROR_EXIT "Unexpected netd instruction at $FILE_OFFSET"

# LINK_PARTITIONS builds the workspace with hard links.  Detach netd before an
# in-place write so a failed/incremental build cannot corrupt the extracted
# donor cache and make the next clean workspace start from an already-patched
# binary.
NETD_PRIVATE="${NETD}.f2q-cow.$$"
cp -a "$NETD" "$NETD_PRIVATE" \
    || ERROR_EXIT "Failed to create a private netd copy"
mv -f "$NETD_PRIVATE" "$NETD" \
    || ERROR_EXIT "Failed to detach netd from the donor cache"

printf '\xe0\x03\x1f\x2a' \
    | dd of="$NETD" bs=1 seek="$FILE_OFFSET" conv=notrunc status=none

PATCHED_HEX="$(
    dd if="$NETD" bs=1 skip="$FILE_OFFSET" count=4 status=none \
        | od -An -tx1 -v | tr -d ' \n'
)"
[[ "$PATCHED_HEX" == "$REPLACEMENT_HEX" ]] \
    || ERROR_EXIT "Failed to patch netd BPF initializer call"
