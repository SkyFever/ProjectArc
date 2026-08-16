# ==============================================================================
#
# MOD_NAME="Run Android 16 NetBpfLoad on the F916N 4.19 kernel"
# MOD_AUTHOR="ProjectArc f2q bootstrap"
# MOD_DESC="Loads real networking BPF objects while bypassing only the 5.4 gate."
#
# ==============================================================================

SYSTEM_PATH="$(GET_PARTITION_PATH system)" \
    || ERROR_EXIT "Failed to get system partition path"
NETBPFLOAD_RC="$SYSTEM_PATH/etc/init/netbpfload.rc"
TETHERING_CAPEX="$SYSTEM_PATH/apex/com.google.android.tethering_compressed.apex"
PLATFORM_BPFLOADER="$SYSTEM_PATH/bin/bpfloader"
TARGET_LOADER="$SYSTEM_PATH/bin/f2q"

[[ -f "$NETBPFLOAD_RC" && -f "$TETHERING_CAPEX" && -f "$PLATFORM_BPFLOADER" ]] \
    || ERROR_EXIT "Missing netbpfload inputs"

TMP_DIR="$(mktemp -d /tmp/f2q-netbpfload-objective.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' RETURN
unzip -q -o -j "$TETHERING_CAPEX" original_apex -d "$TMP_DIR" \
    || ERROR_EXIT "Failed to extract original tethering APEX"
unzip -q -o -j "$TMP_DIR/original_apex" apex_payload.img -d "$TMP_DIR" \
    || ERROR_EXIT "Failed to extract tethering APEX payload"
debugfs -R "dump /bin/netbpfload $TMP_DIR/netbpfload" \
    "$TMP_DIR/apex_payload.img" >/dev/null 2>&1 \
    || ERROR_EXIT "Failed to extract netbpfload"

LOADER_HASH=$(sha256sum "$TMP_DIR/netbpfload" | cut -d' ' -f1)
case "$LOADER_HASH" in
    # Fold4 One UI 8, 2026-07
    cad99f3ef16dfb940e2a29b0a5061d0c8d21063604ace33877023bc78a27ad13)
        PATCH_OFFSET=$((0xdc64))
        ;;
    # Fold7 One UI 8, F966NKSS7AYLT
    bb2cc638e15774c57bf44537248444ec9ad2cdf8927b0567b54e91c11acac803)
        PATCH_OFFSET=$((0xdb34))
        ;;
    *)
        ERROR_EXIT "Unexpected netbpfload source hash: $LOADER_HASH"
        ;;
esac

cp -a "$PLATFORM_BPFLOADER" "$TARGET_LOADER"
cp "$TMP_DIR/netbpfload" "$TARGET_LOADER"
[[ "$(dd if="$TARGET_LOADER" bs=1 skip="$PATCH_OFFSET" count=4 status=none | xxd -p)" == c0160036 ]] \
    || ERROR_EXIT "Unexpected netbpfload kernel-gate instruction"
printf '\x1f\x20\x03\xd5' \
    | dd of="$TARGET_LOADER" bs=1 seek="$PATCH_OFFSET" conv=notrunc status=none
chmod 0750 "$TARGET_LOADER"
chown 0:0 "$TARGET_LOADER"

sed -i \
    -e 's|^service bpfloader /system/bin/true[[:space:]]*$|service bpfloader /system/bin/f2q|' \
    -e 's|^    # netbpfload will do network bpf loading, then execute /system/bin/bpfloader$|    file /dev/kmsg w|' \
    -e 's|^    #! capabilities |    capabilities |' \
    -e 's|^    #! group |    group |' \
    -e 's|^    #! rlimit |    rlimit |' \
    "$NETBPFLOAD_RC"

grep -q '^service bpfloader /system/bin/f2q$' "$NETBPFLOAD_RC" \
    || ERROR_EXIT "Failed to select patched netbpfload"
grep -q '^    capabilities CHOWN SYS_ADMIN NET_ADMIN$' "$NETBPFLOAD_RC" \
    || ERROR_EXIT "Missing bpfloader capabilities"
grep -q '^    group root graphics network_stack net_admin net_bw_acct net_bw_stats net_raw system$' "$NETBPFLOAD_RC" \
    || ERROR_EXIT "Missing bpfloader groups"
grep -q '^    rlimit memlock 1073741824 1073741824$' "$NETBPFLOAD_RC" \
    || ERROR_EXIT "Missing bpfloader memlock limit"
[[ "$(dd if="$TARGET_LOADER" bs=1 skip="$PATCH_OFFSET" count=4 status=none | xxd -p)" == 1f2003d5 ]] \
    || ERROR_EXIT "Failed to bypass only the kernel 5.4 gate"

rm -rf "$TMP_DIR"
trap - RETURN
