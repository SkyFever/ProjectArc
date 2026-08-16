# ==============================================================================
#
# MOD_NAME="Bypass the Android 16 BPF kernel gate"
# MOD_AUTHOR="ProjectArc f2q bootstrap"
# MOD_DESC="Allows boot diagnostics to continue on the F916N 4.19 kernel."
#
# ==============================================================================

SYSTEM_PATH="$(GET_PARTITION_PATH system)" \
    || ERROR_EXIT "Failed to get system partition path"
NETBPFLOAD_RC="$SYSTEM_PATH/etc/init/netbpfload.rc"

[[ -f "$NETBPFLOAD_RC" ]] \
    || ERROR_EXIT "Missing system netbpfload service definition"

# Android 25Q2 NetBpfLoad exits before loading programs on kernels older than
# 5.4. Keep this as a boot-only compatibility shim: retain the base service,
# make it succeed without loading BPF, and prevent the Tethering APEX from
# overriding it with the kernel-gated service. late-init still triggers
# bpf-progs-loaded immediately after load-bpf-programs, so netd can start.
sed -i \
    -e 's|^service bpfloader /system/bin/false$|service bpfloader /system/bin/true|' \
    -e 's|^    reboot_on_failure reboot,netbpfload-missing$|    # reboot_on_failure reboot,netbpfload-missing|' \
    -e 's|^    updatable$|    # updatable|' \
    "$NETBPFLOAD_RC"

grep -q '^service bpfloader /system/bin/true$' "$NETBPFLOAD_RC" \
    || ERROR_EXIT "Failed to replace the fallback bpfloader command"
! grep -q '^    reboot_on_failure reboot,netbpfload-missing$' "$NETBPFLOAD_RC" \
    || ERROR_EXIT "Fallback bpfloader still reboots on failure"
! grep -q '^    updatable$' "$NETBPFLOAD_RC" \
    || ERROR_EXIT "Tethering APEX can still override the compatibility service"
