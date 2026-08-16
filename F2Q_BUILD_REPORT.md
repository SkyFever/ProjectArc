# SM-F916N One UI 8 bootstrap build report

This is a historical bring-up and validation log. Entries describing direct
super-image experiments document verified fixes, but only fixes represented by
files under `objectives/f2q`, `platform/sm8250`, `scripts/helpers`, or the base
`ui-8.0-stock` branch are automated by the ProjectArc build pipeline.

Build date: 2026-07-31

## Inputs

- Target: Galaxy Z Fold2 5G `SM-F916N/KOO`
- Target firmware: `F916NKSS4KXH1` (Android 13 package, Android 11/VNDK 30 vendor)
- Donor: Galaxy Z Fold4 `SM-F936N/KOO`
- Donor firmware: `F936NKSS8IZG2` (One UI 8 / Android 16)
- Output filesystem: ext4
- Build profile: `--bootstrap`

## Output

- Current full-Astro installer:
  `out/AstroROM_f2q_v2.1.Spring_20260731_astrofull_signed.zip`
- Size: `4,972,732,569` bytes
- SHA-256: `dee9e113ffa0aad35255eb5e414f3612fac27d530d8359b30dd1aee3ba9c5c26`
- ZIP format: Zip64, signed by SignApk
- Direct-flash image: `out/f2q_astrofull_direct/super.img`
- Direct image SHA-256:
  `5c38e08a2a28bd1b4ff583f4329b44dfe78c8f478a3f5d4194377a7f9689dedb`

- Current stock-OEM isolation image:
  `out/f2q_astrofull_stock_oem_direct/super.img`
- Stock-OEM isolation image SHA-256:
  `3ccac4b5800eccf4c7947af861b54ecc85c8d0e50792271c2d286e35efad5894`

The installer checks `ro.product.vendor.device=f2q` and writes only
`super.img`. AVB remains managed separately by the existing device setup.

## Verified

- Fold4 compressed F2FS files were read with compression and security-xattr
  support enabled.
- No empty donor SELinux labels remained in the extraction configs.
- Generated ext4 images passed read-only `e2fsck`.
- Dynamic partition payload before super packing:
  - `odm`: 1,503,232 bytes
  - `product`: 771,665,920 bytes
  - `system`: 7,086,940,160 bytes
  - `vendor`: 1,666,568,192 bytes
  - Total: 9,526,677,504 bytes
- Fold2 dynamic group limit: 10,812,915,712 bytes
- Remaining group headroom: 1,286,238,208 bytes
- Final super size: 10,817,110,016 bytes
- Metadata size: 65,536 bytes
- Metadata slots: 2
- Group: `qti_dynamic_partitions`
- ZIP extraction CRC passed.
- Corrected update-binary shebang is LF-terminated (`#!/sbin/sh\n`).
- No vbmeta image is included in the installer.
- The combined Android 16 system and F916N vendor SELinux policy compiles
  successfully with the imported F916N 30.0 mapping files.
- `com.android.vndk.v30.apex` is byte-identical to the F916N stock image:
  `eba5ec7b849952360482836b4c6e68f9138567280a25f9cdca1f2c77b2c13944`.
- The Fold4 donor `com.android.vndk.v32.apex` is retained byte-identically:
  `7ae4061e6642b7d10478990d1acee404f7082ee9514483d293147f161a8567af`.
- This build was made without `--bootstrap`. All 22 executable scripts selected
  by the `astro/` layer were applied. The resulting properties identify it as
  `AstroROM 2.1.Spring`, `ro.astro.codename=f2qksx`, and
  `ro.product.astro.model=SM-F916N`.
- The optional Via Browser download server did not respond. Its incomplete APK
  was removed before image packing; no partial APK is present in the result.
- Direct super metadata matches the F916N geometry:
  - physical size: `10,817,110,016`
  - metadata max size: `65,536`
  - metadata slots: `2`
  - group: `qti_dynamic_partitions`
  - group maximum size: `10,812,915,712`

## Boot-test status

The first recovery install stopped with status 255. Its bundled
`update-binary` used CRLF, making its interpreter path `/sbin/sh\r`; release
packaging now normalizes installer scripts to LF.

The first direct-super test rebooted between the Samsung splash screens with
AVB already disabled. Host-side split-policy compilation reproduced an early
boot failure in the donor `system_ext` SELinux 30.0 mapping. The same compiler
and arguments successfully compiled the complete stock F916N policy.

Replacing the donor system, system_ext, and product 30.0 mapping CIL files with
the corresponding F916N stock mappings successfully compiled the combined
Android 16 system and Android 11 vendor policy. The build now imports these
target mappings before merging system_ext into system.

The direct-super image containing this SELinux mapping fix produced the same
splash, blackout, and reboot sequence. Recovery found no file in pstore after
that reset, so there is still no persisted kernel panic trace. This makes the
exact reset source unproven; a watchdog or hardware reset remains possible.

The previous ProjectArc VNDK logic removed the Fold4 donor VNDK v32 APEX and
installed only a generic VNDK v30 APEX signed with a different key. The current
full-Astro build retains the exact Fold4 VNDK v32 APEX and adds the exact F916N
stock VNDK v30 APEX, with both versions declared in the system manifest.

The earlier `sepolicyfix` and `vndkfix` images were bootstrap-profile builds.
They used the ProjectArc kitchen but intentionally skipped the full `astro/`
layer. The current `astrofull` image corrects that profile mismatch and uses
the Fold4 firmware as donor input with the complete Astro ROM layer applied.

The supplied custom kernel successfully boots the LineageOS 23.2 Android 16
QPR2 GSI. That GSI explicitly includes compatibility patches for Android 11
vendors, while the current Fold4 One UI system is SDK 36, its native donor
vendor baseline is SDK 32, and the F916N vendor is SDK 30. Kernel Android 16
support is therefore established, but One UI userspace/vendor compatibility
and Samsung-specific kernel interfaces remain open candidates.

A diagnostic copy of the exact supplied custom boot image is available at
`../kernel/diagnostic/boot_initfatal_panic.img`. Its only intentional semantic
change is the appended kernel command-line option
`androidboot.init_fatal_panic=true`; unpack verification confirmed identical
kernel, ramdisk, and DTB payloads. If Android init hits a fatal condition, this
option requests a kernel panic so pstore can capture the cause.

The full-Astro super still rebooted at the same point. Testing the
`init_fatal_panic` boot image produced the same reset and no pstore file. This
makes a normal second-stage init fatal less likely, but does not prove pstore is
functional or exclude a reset before init processes that option.

The successful GSI test retained the original F916N OEM partitions, whereas
all earlier ProjectArc supers rebuilt and replaced vendor and odm. The rebuilt
full-Astro images were 1,666,568,192 bytes for vendor and 1,503,232 bytes for
odm; the untouched stock images are 1,696,956,416 and 4,349,952 bytes.

The `stock_oem` isolation super therefore uses the full-Astro system and
product images while embedding the original F916N vendor and odm images
without filesystem reconstruction. Direct extent hashing confirms exact
matches:

- vendor: `4ef962c9e72601cdbd7d2c6e06fb174c3745bc9d9b796a75cc54abc8b756d7eb`
- odm: `e81968500fc4541b7c0a65e312a670f9b3414f96cea57340cf74eea2795687da`

Its total logical payload is 9,559,912,448 bytes, leaving 1,253,003,264 bytes
in the F916N dynamic group. Metadata size, slot count, physical super size, and
group geometry all match the stock target values.

If this VNDK build still reboots with an empty pstore, the next controlled test
is the same custom kernel with the Qualcomm watchdog disabled. That is intended
to expose the actual first-stage init, mount, VINTF, or userspace failure rather
than treating the absence of pstore as evidence that no failure occurred.

The current custom-kernel workflow reuses a Magisk-patched ramdisk whose fstab
has the stock userdata encryption flags removed. A stock-encrypted userdata
volume therefore needs to be formatted before that boot image can mount it;
formatting data erases internal storage.

Treat this ZIP as an experimental bootstrap image, not a daily-use ROM.

## Property-context fatal fix (2026-08-01)

The diagnostic boot image produced a 256 KiB `console-ramoops-0` trace. It
proves that the previous reset was an Android init fatal rather than an
independent kernel, DTBO, AVB, mount, watchdog, or subsystem failure:

- `system`, `product`, `vendor`, `odm`, `prism`, and `optics` mounted.
- AVB reported `VerificationDisabled` and SELinux policy loaded.
- Second-stage init rejected a duplicate prefix for
  `init.svc.vendor.wvkprov_server_hal` while serializing property contexts.
- `PropertyInit()` aborted, then `androidboot.init_fatal_panic=true` converted
  the fatal into an intentional sysrq kernel panic so ramoops could persist it.

The duplicate came from the Fold4 donor
`system_ext_property_contexts` and the F916N target
`vendor_property_contexts`. The old Astro patch incorrectly passed this
property name to `REMOVE_SELINUX_ENTRIES`, which only edits CIL policy files.
The corrected Astro patch now removes the donor property-context line only
when the target vendor already owns that prefix.

Controlled direct-flash test image:

- `out/f2q_propertyfix_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `a9a46b37f2bf7f976e8742bd24292d6fb8dfa61dd1634953dc6cc81e1d0aa6ff`
- System SHA-256:
  `65440a2c0ea947afe47f02957526a974ff4c17fae0e817cd1fe594ecdd1a8089`

This is the previous stock-OEM hybrid super with exactly one regular-file data
byte changed: the donor duplicate line's first byte was changed from `i` to
`#`. This preserves the system ext4 inode, ownership, mode, SELinux xattr,
filesystem geometry, product image, and byte-identical stock F916N vendor/odm.
The patched super was unpacked again; its system image matched the intended
patched system byte-for-byte and passed read-only `e2fsck`.

Continue using `../kernel/diagnostic/boot_initfatal_panic.img` for the next
boot test so any subsequent init fatal is captured in pstore. A separate audit
also found that the target vendor declares VINTF target level 4 while the donor
system currently carries framework compatibility matrices starting at level 5.
That remains a likely next-stage failure, but it is intentionally not changed
in this controlled image until the next pstore trace confirms the next stop.

## FCM4 controlled test (2026-08-01)

The property-fix image reached the same visible splash/reset sequence but did
not create a new pstore record. With the diagnostic boot still installed, that
is consistent with passing `PropertyInit()` and later taking a normal reboot or
watchdog path which `androidboot.init_fatal_panic=true` does not convert.

The next concrete compatibility gap is VINTF. The untouched F916N vendor
manifest declares `target-level="4"`, while the donor system contained only
framework matrices `5`, `6`, `7`, `8`, `202404`, and `202504`. AOSP libvintf
requires an exact level-4 framework matrix for this device manifest.

Controlled direct-flash test image:

- `out/f2q_fcm4fix_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `bdf23b2e61f29da13e2d3accb2bca2bafe964ea1ed0156307f81207b0f115f89`

This image is the property-fix super plus exactly one new file from the F916N
stock system:

- `/system/etc/vintf/compatibility_matrix.4.xml`
- Size: `114,893` bytes
- SHA-256: `ab6a1d2a87d4b51c5842f01c9d9ea586b1f2264ae21514837b348d497a1565dd`
- XML root: framework compatibility matrix level 4
- Metadata: `0:0`, mode `0644`, SELinux `u:object_r:system_file:s0`

The system ext4 image inside the final super was accessed through its linear LP
extent, the stock file was verified before and after insertion, and read-only
`e2fsck` passed. Existing donor matrices remain unchanged; level 3 was not
imported because the current vendor explicitly targets level 4.

For no-pstore resets, use `../collect_boot_reset_logs.sh` once immediately
after entering recovery. It preserves Samsung reset reason/klog/summary,
`last_kmsg`, recovery dmesg, pstore, and the raw boot-partition SHA-256 before
the reset proc entries are consumed.

## Android 25Q2 BPF kernel gate (2026-08-01)

The FCM4 test still showed the same visible reset, but the Samsung reset bundle
captured the complete cause. The diagnostic boot was confirmed on the device by
its raw boot-partition SHA-256, and ramoops registered correctly. Pstore was
empty because this was a controlled userspace reboot, not a panic:

- FCM4 device and framework manifests were processed successfully.
- `/data` mounted successfully.
- API 36 `NetBpfLoad` v0.47 detected kernel 4.19 and printed
  `Android 25Q2 requires kernel 5.4.`
- `bpfloader` exited with status 1.
- Its APEX service definition applied `reboot_on_failure`, producing
  `reboot,bpfloader-failed` and a clean shutdown at 13.19 seconds.

Controlled boot-only test image:

- `out/f2q_bpfskip_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `c16339600775b461b24442f152258b5547778a494a865fd14f851260c6d2f729`

This is the FCM4 image with a three-location, size-preserving change to
`/system/etc/init/netbpfload.rc`:

- fallback command `/system/bin/false` -> `/system/bin/true`
- fallback `reboot_on_failure` disabled
- `updatable` disabled so the Tethering APEX cannot replace the fallback with
  its kernel-5.4-gated service

Android late-init already triggers `bpf-progs-loaded` after
`load-bpf-programs`, so `netd` can start and the boot can proceed to the next
compatibility boundary. The regular-file inode, size, ownership, mode, and
SELinux xattr are unchanged, and read-only `e2fsck` passed.

This is intentionally a boot diagnostic shim, not a final networking solution:
Android 16 BPF programs are not loaded. A production-quality port will require
a compatible Connectivity/Tethering module and BPF loader, backported kernel
BPF support, or a newer kernel baseline.

## netd BPF initialization crash (2026-08-01)

The BPF fallback image progressed past the Samsung splash and displayed the
One UI boot animation. The new Samsung reset bundle confirms that init parsed
`/system/etc/init/99_logcat_new.rc` and executed its `post-fs-data` action.
The custom logcat service itself failed with `Permission denied` while init
tried to execute `/system/bin/logcat`; this did not cause the reboot. Android's
pmsg ramoops still preserved the native crash records.

The actual boot loop was a deterministic `netd` crash loop:

- `/system/bin/netd` received `SIGABRT` about every five seconds.
- Every backtrace ended at `libnetd_updatable_init.cfi+582` in the Android 16
  Tethering APEX `libnetd_updatable.so`.
- The BPF-loader shim intentionally created none of the mandatory networking
  BPF maps or programs, so netd's updatable initializer aborted.
- Samsung's resetreason message called each event a `system_server native
  crash`, but every tombstone identifies the real command line as
  `/system/bin/netd`.
- After ten resets, `/system/bin/bootchecker` requested the controlled reboot
  target `reboot,rescueparty_by_bootchecker` at 57.57 seconds.

Controlled boot-only test image:

- `out/f2q_netdinit_skip_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `9c2c6443e2dcb413b184892412109e2276c5e58f1f6dcd5e50c9fda0f373f62e`

The APEX remains byte-identical and signed. Instead, exactly one ARM64
instruction in `/system/bin/netd` is changed at ELF file offset `0x89a24`:

- before: `bl libnetd_updatable_init@plt` (`8b 89 01 94`)
- after: `mov w0, wzr` (`e0 03 1f 2a`)

The following `cbnz` therefore observes a successful initializer result and
allows netd startup to continue. The source netd SHA-256 and expected original
instruction are both mandatory guards in the build scripts. The final system
filesystem retained netd's inode, size, mode, ownership, and
`u:object_r:netd_exec:s0` label; read-only `e2fsck` and LP metadata validation
passed.

This remains a diagnostic boot shim. BPF-backed traffic accounting, socket
tagging, firewalling, and networking may fail or cause a later userspace error.
Its purpose is to reveal the next boot blocker without modifying the signed
Tethering APEX.

## netd clean-exit instrumentation (2026-08-01)

The initializer-skip image removed the earlier netd `SIGABRT`; no subsequent
backtrace referenced `libnetd_updatable_init`. Netd instead exited normally
with status 1 approximately 0.44 seconds after each restart. Init consequently
restarted both zygotes, and Samsung bootchecker requested
`reboot,rescueparty_by_bootchecker` after the twelfth cycle at 68.04 seconds.

The clean reboot did not preserve a pmsg ramoops record, while netd's detailed
failure message was sent only to logd. Static analysis limits the remaining
fatal exits to startup checks around NFLogListener, NapProxy, FwmarkServer,
NetdNativeService, and MDnsService.

Controlled logging-only test image:

- `out/f2q_netd_exitpanic_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `f79c7a8a3280065851a6f58ff6560401b5cf2cd11d7004a8ac1c796dc7912fbd`

This is the initializer-skip image with one additional ARM64 instruction
change in `/system/bin/netd`. Its imported `exit()` PLT entry at file offset
`0xec038` is redirected to the existing `abort()` PLT entry:

- before: `adrp x16, ...` (`50 00 00 90`)
- after: `b 0xead18` (`38 fb ff 17`)

The original exit callers keep their link register, so the resulting tombstone
identifies the exact `main.cfi` call site that requested termination. The abort
also gives crash_dump/logd a chance to persist the immediately preceding ALOG
message in pmsg. This image is instrumentation only and is not a functional
networking fix.

## netd BandwidthController failure and boot bypass (2026-08-01)

The exit-to-abort image produced persistent native tombstones. All twelve
`/system/bin/netd` crashes from the latest boot have the same backtrace:

- `abort+160`
- `android::net::Controllers::init()+1568` at netd PC `0x0a2a14`
- `main.cfi+420` at netd PC `0x089ae4`

The instrumented PC maps to the `exit(1)` path used only when
`bandwidthCtrl.enableBandwidthControl()` returns nonzero. In the exact netd
binary, file offset `0x0a2438` contains `cbnz w0, 0x0a29f0` (`c0 2d 00 35`),
which branches to the `Failed to initialize BandwidthController` handler and
then the observed `exit(1)` at `0x0a2a14`.

This is consistent with the preceding BPF-loader bypass: Android 16's basic
bandwidth rules reference mandatory pinned BPF programs, but the kernel-5.4
gated loader was replaced with a successful no-op for boot diagnostics.
The exact failed iptables command and errno remain available in Samsung's
`/data/log/dumpstate_sys_native.zip` if production networking work requires
them.

Controlled boot-only test image:

- `out/f2q_bandwidth_skip_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `46fc3a2c54bc17e11e371bacb03bcba3aaa1f8d64d89aa510a6d31242f1a2665`
- Patched netd SHA-256:
  `1f9aa352a379824010f3f52b421dba4990fd1030a399718f2d296e75a12010af`

This image changes the BandwidthController result branch at netd file offset
`0x0a2438` to `nop` (`1f 20 03 d5`), allowing execution to continue at the
normal success path. The earlier `libnetd_updatable_init` bypass and global
`exit()`-to-`abort()` instrumentation remain present, so a subsequent netd
startup exit should still produce a precise tombstone.

The final system filesystem passed read-only `e2fsck`; `/system/bin/netd`
retains mode `0755`, owner `0:2000`, and SELinux label
`u:object_r:netd_exec:s0`. LP geometry remains the F916N stock layout.

This is not a networking fix. BPF-backed accounting, quotas, firewall rules,
and related traffic controls remain unavailable until a compatible networking
module is used or the required kernel BPF support is backported.

## DnsProxyListener abort after BandwidthController bypass (2026-08-01)

The BandwidthController branch bypass worked: the next ten current-boot netd
tombstones (`tombstone_07` through `tombstone_16`) no longer end in
`Controllers::init()`. They all abort in the same later path:

- `abort+160`
- `android::net::DnsProxyListener::DnsProxyListener()+1844` in
  `/apex/com.android.resolv/lib64/libnetd_resolv.so`
- `android::net::DnsResolver::DnsResolver()+24`
- `resolv_init.cfi+600`

The Android 16 resolver constructor calls the Tethering APEX export
`ADnsHelper_init()` and aborts when it returns nonzero. Register `x21` is
`0xffffffff` in the captured crash, strongly identifying `-EPERM`. This is the
expected consequence of the successful no-op bpfloader: none of the pinned
networking BPF resources used by the DNS helper exist. Netd is restarted ten
times, init kills and restarts both zygotes after each death, and Samsung
bootchecker finally requests `reboot,rescueparty_by_bootchecker`; this is not a
kernel panic or watchdog reset.

## Real Android 16 NetBpfLoad with only the kernel gate bypassed (2026-08-01)

The next controlled image replaces the no-op service with the original
Android 16 Tethering APEX `netbpfload` copied to `/system/bin/f2q`. The source
binary is verified before patching:

- original SHA-256:
  `cad99f3ef16dfb940e2a29b0a5061d0c8d21063604ace33877023bc78a27ad13`
- patched SHA-256:
  `b4458f3107e66cff08e01de87586d2659578a4f16f09b13f846f047920eb0e61`
- original Build ID: `499f7b9b32a3ef2003b0b4b3dcac70a2`

Exactly one instruction at ELF file offset `0x0dc64` is changed:

- before: `tbz w0, #0, 0xdf3c` (`c0 16 00 36`), the false result from
  `isAtLeastKernelVersion(5, 4, 0)`
- after: `nop` (`1f 20 03 d5`)

All real map and program loading remains enabled. The system service runs the
patched loader with the original `CHOWN`, `SYS_ADMIN`, and `NET_ADMIN`
capabilities; groups; 1 GiB memlock limit; `/dev/kmsg` file; and
`u:object_r:bpfloader_exec:s0` executable label. The APEX service is still
prevented from overriding it, and reboot-on-loader-failure remains disabled so
the next verifier or feature error can be collected instead of causing an
immediate opaque reboot.

Controlled test image:

- `out/f2q_netbpfload_k419_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `3ebdc8d11f9ac2e564a4d2b4d5375074a8a04790284abb5843806d4fd34c5642`

The inserted loader is byte-verified after writing, its mode, ownership, and
SELinux xattr are checked, read-only `e2fsck` passes, and LP geometry remains
unchanged. This test determines which Android 16 networking BPF feature, if
any, is the first one the custom 4.19 kernel cannot load.

## LUC carrier location-notice setup blocker (2026-08-01)

The real Android 16 NetBpfLoad image boots normally, reaches Samsung
SetupWizard, scans and connects to Wi-Fi, and enters the carrier location
notice step. The test handset uses LUC rather than KOO CSC.

Samsung SetupWizard's `LocationInfoNoticeWrapper` explicitly selects the
following component for LUC:

- package: `com.lguplus.lgugpsnwps`
- activity: `com.lguplus.lgugpsnwps.ui.GWAlterNativeActivity`

The corresponding `/system/priv-app/LGUGPSnWPS/LGUGPSnWPS.apk` is an Android
13 carrier component protected by INKA AppSealing. Its decoded protection
code declares `BLOCK_ENV_ROOTING_ALERT`, matching the on-device refusal on the
unlocked test environment. The APK SHA-256 is
`4db55168a4411469822a4fd6e5e551b7fdc4355f86c3be37993147803d1e3f28`.

SetupWizard builds the `location_notice` step only when
`PackageManager.getApplicationInfo("com.lguplus.lgugpsnwps",
GET_META_DATA)` succeeds. A controlled image therefore removes only the base
APK. It does not modify or resign either Samsung SetupWizard or the sealed U+
application. Without the base APK, the native library and oat files left in
the directory are inert and PackageManager does not install the package.

Controlled LUC setup-skip image:

- `out/f2q_luc_setupskip_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `39e3083b7b89d3a80134e44be2d5090e272153b32d6f79815617051f65899676`

The system filesystem passes read-only `e2fsck` and LP geometry is unchanged.
This bypass disables the LG U+ GPS/NWPS carrier component, including its
carrier-specific emergency/network positioning integration. It does not
remove the phone dialer, Android location framework, or Samsung Emergency SOS.

## SystemUI restart loop after SetupWizard (2026-08-02)

The apparent SystemUI refresh on screen-off, application close, and recents
was one repeated Java crash rather than three graphics problems. SystemUI
throws a `SecurityException` while opening `LauncherProvider` from
`KshDataUtils.isDexDisplay()` because the provider requires
`com.samsung.android.launcher.permission.READ_SETTINGS`.

The donor `Routines.apk` shares `android.uid.systemui` and requests this normal
permission. Removing Routines in the first-boot size-reduction list therefore
removed the permission from the shared UID. `priv-app/Routines` is no longer a
debloat target. A controlled image based on the LUC setup-skip super restores
the donor base APK with owner `0:0`, mode `0644`, and
`u:object_r:system_file:s0` while retaining the LGUGPSnWPS removal:

- `out/f2q_routinesfix_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `f692a086141aacb98f18f880c5f1725e73225d20fa340010cbf8dfe294417f3a`
- Restored Routines APK SHA-256:
  `2072ae27ef5ea8be6383a620cd943d04231dca8e77c47d6fe714d9a221eabf75`

The restored APK was read back byte-for-byte, the system filesystem passed
read-only `e2fsck`, and LP geometry is unchanged.

## Audio and vibrator kernel blockers (2026-08-02)

Audio framework and vendor services are alive, but `/proc/asound/cards` reports
no soundcards and `/dev/snd` contains only `timer`. Reprobing the Kona ASoC
card first fails because `cs35l41-pcm` is not registered. All three Fold2
CS35L41 I2C devices exist but fail probe with `Failed to get reset GPIO: -517`.
Their reset lines use PCAL6524 offsets 9, 8, and 10. The expander itself is
bound as `3-0022` and exposes `gpiochip300`, so the remaining fault is in the
kernel GPIO-provider/consumer binding path rather than AudioPolicy or the
Android 16 vendor policy.

The vibrator HAL independently reports that neither the timed-output nor LED
vibrator node exists. Fold2 uses a Cirrus CS40L25A device, but the merged
runtime kernel configuration does not enable its motor driver. The kernel
source contains the enabled DT node and driver, while `f2q.config` omits
`CONFIG_MOTOR_DRV_CS40L2X`, `CONFIG_MOTOR_DRV_CS40L2X_PMIC_RESET`, and
`CONFIG_CS40L2X_SAMSUNG_FEATURE` that are enabled by the sibling SM8250 device
fragments. This is a kernel configuration defect and cannot be fixed in the
ROM filesystem.

### Live GPIO provider state

The live consumer phandles and provider node are consistent: all CS35L41 reset
properties point at phandle `0x6c6`, and the bound PCAL6524 device and its GPIO
class device both resolve to `/soc/i2c@23/pcal6524@22`. The registered legacy
`gpiochip300` object is nevertheless corrupt: its exported `base`, `label`, and
`ngpio` values are `0`, empty, and `0`, while every other gpiochip exports sane
values. Reprobing the three amplifiers after the provider is bound still gives
`Failed to get reset GPIO: -517`. This explains why OF lookup cannot match the
provider even though the DT is correct.

The running kernel identifies itself as `g8f1323f0ae22-dirty`, while the
current fork HEAD is `0fc9a413a`; the running commit is no longer reachable
from any current fork branch. A clean comparison kernel was therefore built
from current `test2` HEAD instead of applying an unverified lifetime fix to the
old binary revision. Its verified final configuration enables the Fold2
CS40L25A stack and retains PCAL6524 and CS35L41:

- kernel version:
  `4.19.325-cip128-st12-perf-f2q-hwtest-0fc9a413a`
- raw Image SHA-256:
  `d2cf8d9f32f9951f45bec1af61c42f1d6890c04e4850cd1b5ef72c8d64a1b45b`
- repacked boot path: `kernel/boot-f2q-hwtest.img`
- repacked boot SHA-256:
  `5b2dcd1d3b69887b87f95b886ff252c1387c74fa88c400965e850a910daf1b9e`
- boot size: `71,303,168` bytes

The test boot uses the currently booted custom `kernel/boot.img` as its
container. Header v2 fields, cmdline, DTB, compressed ramdisk, Samsung SEAndroid
footer, and existing ramdisk modifications are retained. The repacked image
was unpacked again and its embedded kernel compared byte-for-byte with the
built Image.

### Live hwtest result and vibrator framework bridge

The hwtest boot starts successfully. The CS40L25A binds at I2C address
`11-0040`, creates `/sys/class/timed_output/vibrator/enable`, and a direct
250 ms timed-output pulse is physically felt on the device. This confirms the
Fold2 vibrator hardware, DT, and CS40L2X kernel path are working.

Android still enumerates zero vibrators because the current vendor starts only
Samsung's HIDL extension service. A controlled vendor update adds the donor
dm3q Android AIDL vibrator service, its V3 NDK platform library, init rc, and
VINTF fragment without replacing the legacy Samsung service:

- `out/f2q_vibrator_aidl_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `9bb932a5eaad89b4dc37a96e403248d37302897dffd7cdc5d72b602d992fb2fd`

The service binary retains owner `0:2000`, mode `0755`, and the existing
`hal_vibrator_default_exec` SELinux label. The image passed filesystem checks,
file readback hashes, and unchanged LP geometry verification.

### PCAL6524 provider lifetime fix

The audio reset-GPIO failure was traced to a deterministic driver bug rather
than DT data or the amplifier drivers. With `CONFIG_DEBUG_FS=n`,
`debugfs_create_dir()` returns an error stub after `gpiochip_add()` succeeds.
The old PCAL6524 probe error path then freed the driver object without calling
`gpiochip_remove()` and returned the still-zero `ret`. I2C consequently showed
the provider as bound while `gpiochip300` referenced freed memory and exported
base `0`, an empty label, and `ngpio=0`. Every CS35L41 consumer therefore
deferred with `-EPROBE_DEFER`.

The driver now treats debugfs as optional and, on real later probe failures,
removes the registered gpiochip before freeing its backing object. An
incremental test kernel and boot image were built from the same verified HEAD:

- kernel version:
  `4.19.325-cip128-st12-perf-f2q-hwfix-0fc9a413a`
- raw Image SHA-256:
  `bb9dbdb2ddc2d3785b275de76c02810a1d76063ae7cb815218b9a996271bb7e7`
- repacked boot path: `kernel/boot-f2q-hwfix.img`
- repacked boot SHA-256:
  `fff678fbe844fb5219031f010b7ecce39b76b7b48cc81c42625fd75b20488e3e`
- boot size: `71,303,168` bytes

The boot image was unpacked after repacking and its embedded kernel was
verified byte-for-byte. This image is expected to retain the confirmed direct
vibration path while allowing PCAL6524, all three CS35L41 amplifiers, and the
Kona sound card to complete probe.

### Device verification

Both fixes were verified independently on the physical SM-F916N:

- `f2q_routinesfix_direct/super.img` plus `boot-f2q-hwfix.img` boots and audio
  playback works. This confirms the PCAL6524 lifetime fix restores the
  CS35L41/Kona audio path without requiring a vendor filesystem change.
- Replacing the super image with `f2q_vibrator_aidl_direct/super.img` makes
  Android vibration work as well. This confirms the remaining haptic failure
  was only the missing Android AIDL vibrator bridge.

The verified AIDL bridge import is now part of
`objectives/f2q/bootstrap/20-import-vibrator-aidl.sh`, so both bootstrap and
normal Astro builds include it. The verified PCAL6524 correction remains in
the separately flashed `kernel/boot-f2q-hwfix.img` boot partition image.

## Product identity and Samsung dialer keystrings (2026-08-02)

The running image exposes correct stock-scoped models in vendor and odm but
leaves `ro.product.model` and `ro.product.system.model` empty, while product
and system_ext still report donor model `SM-F936N`. Galaxy Store 4.5.97.2
therefore logs `device::unknown::csc::LUC`; its `countrySearchEx` request is
rejected by the Samsung server with error 1004 (`invalid device`). APK code
inspection confirms its device loader ultimately returns `Build.MODEL`.

`objectives/f2q/bootstrap/15-set-target-product-identity.sh` now sets the
generic and system, system_ext, and product-scoped model properties to
`SM-F916N`. The donor product names, Android version, and build fingerprints
are deliberately left unchanged until the model-only server test is complete.

The hidden-menu receiver packages are installed and enabled. An explicit
`0011` broadcast starts `com.sec.android.RilServiceModeApp/.ServiceModeApp`
and communicates with the modem successfully, proving the backend is intact.
The One UI 8 SamsungDialer first binds
`com.sec.android.app.parser/.ParseService`, but that package is absent because
the common Astro debloat list removes donor `DRParser`. The f2q-only
`objectives/f2q/70-restore-drparser.sh` now restores the original donor
directory after the common Astro layer has run.

Controlled model/DRParser test image:

- `out/f2q_identity_drparser_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `80d340b8d995954c24c33d23e17e9586120a9f818ef0e64b8c5ae395fcb43bc2`
- DRParser APK SHA-256:
  `db2c6229f2904bddd86dee24c1bd50dc8e4fe00303d03b4e37f78df006ab61eb`

The source system filesystem had no allocatable blocks. The direct test copy
therefore removes `priv-app/BixbyInterpreter`, which is already in the f2q
first-boot removal policy, before adding the 98 KiB parser. It retains the
verified AIDL vibrator vendor changes. The image independently passed ext4
filesystem checks, property readback, donor APK byte comparison, owner/mode
checks, SELinux xattr checks, and unchanged LP metadata verification.

## Feature stabilization after first boot (2026-08-02)

Physical testing of the identity/DRParser image confirmed that Galaxy Store
now works and the Samsung dialer reaches its hidden-menu parser. Four further
issues were then isolated to specific donor/target mismatches.

### UWB hot reboot

SM-F916N does contain UWB hardware. Its stock vendor HAL and both Android UWB
services are registered successfully. Disabling UWB killed `system_server`
in `SamsungExtension.updateDeviceState()` because Fold2's vendor wrapper can
deliver the current device state synchronously from `setDeviceListener()`.
Fold4's `semuwb-service.jar` registered that listener before constructing
`BigdataManager` and `SamsungUwbSessionManager`, producing the observed null
`BigdataManager` call.

An initial patch delayed listener registration until every callback dependency
had been initialized. Although the rebuilt JAR decompiled correctly, physical
SM-F916N testing showed that this ordering change made the hot reboot repeat
continuously. That patch is disabled and must not be used in normal builds.

- Fold4 stock JAR SHA-256:
  `e45194dd4e1bf632581d53178ae29eddcb9a05793ad3107c6e84c80457eb9bbd`
- rejected delayed-listener JAR SHA-256:
  `e36fcf73dcd595f24f2770e2ba2d02a3992cf38d41b4d8f81564b0d5792a3b52`
- experimental stock-order/null-guard JAR SHA-256:
  `5bdf247dcddad862211c12270cd82d28f7dbbb2b698eae2f007c99e56dcd5fba`

### EnvironmentAdaptiveDisplay and regional packages

The Fold4 stock system image has no `EnvironmentAdaptiveDisplay.apk`. Astro's
twentyfive layer imports the S25 `pa3q` APK by itself. Its compiled framework
resource IDs are shifted relative to the Fold4 `framework-res.apk`, so the
service requests an integer CCT array as a string RGB array and repeatedly
crashes its persistent system-UID process in `getWhiteRGBOffsetArray()`.
`objectives/f2q/75-remove-incompatible-addons.sh` returns f2q to the coherent
Fold4 baseline by removing that unsupported package. It also removes the
China-only SmartManager, DeviceSecurity, AppLock, and Firewall packages from
the Korean KOO/LUC build.

### Quick Share and `*#0*#`

Quick Share was absent because the f2q size-reduction list explicitly removed
Fold4's `priv-app/ShareLive`. It is no longer removed. The Fold4 APK hash is
`8098e26db55a5245cd331cd9ce7d102d12c3dc9575602117458032690af3fe76`.

Samsung encodes `*#0*#` as the secret-code authority `0*`. Fold4 ships no
receiver for that authority, while Fold2 stock `HwModuleTest.apk` declares it
and contains the target-specific dual-display and sensor tests. The Fold2 APK
and its priv-app allowlist are restored by
`objectives/f2q/80-restore-hwmoduletest.sh`. Its APK SHA-256 is
`36dafd0eb46d2cab315ed5379edd0ee204f48b196c5b8b5230883d31da450fb3`.

### Integrated direct test image

- `out/f2q_featurefix_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `a4ebec1c24a733fcea1fe47ca8f1b08b2091090c5f954977070497c8b45a40f2`
- Status: **rejected; do not flash**

The system logical partition was expanded by 128 MiB into previously
unallocated space in the existing dynamic-partition group; product, vendor,
and odm sizes are unchanged. The image passed independent SHA readback,
package-presence/absence checks, owner and SELinux xattr checks, clean ext4
verification, and LP geometry verification. The enlarged system filesystem
has 52,230 free 4 KiB blocks after the additions.

### UWB recovery and revised experiment

The safe recovery image keeps all non-UWB feature fixes but restores the exact
Fold4 stock UWB JAR:

- `out/f2q_featurefix_uwbrollback_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `bc240db2694e811714902c08a172624ff4767cebb3d2d5758df5fd741ae223dd`

This image independently passed stock UWB JAR readback, Quick Share and
HwModuleTest readback, owner/SELinux checks, ext4 verification, and LP layout
verification. It is the required recovery image after the continuous hot
reboot regression.

The revised experimental image preserves the exact Fold4 listener-registration
position and returns early only if `BigdataManager` or
`SamsungUwbSessionManager` has not been constructed. It must not be tried
until the rollback image has restored stable boot and logs can be collected:

- `out/f2q_featurefix_uwbguard_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `0dc36201f342f3bb646ab8717a8a008fccda70b0759e4e0c7384b507dc5d02fe`
- Status: experimental, not enabled in the normal objective

## Korean regional features and Device Care recovery (2026-08-02)

Testing of the safe UWB rollback image confirmed Quick Share was restored, but
Settings still exposed a crashing App Lock preference while global Device Care,
Dual Messenger, and Super HDR appeared to be absent. The App Lock failure was
caused by an incomplete China Smart Manager rollback: Astro's Smart-CN layer had
changed `SEC_FLOATING_FEATURE_SMARTMANAGER_CONFIG_PACKAGE_NAME` to
`com.samsung.android.sm_cn` and removed Fold4's global Device Care packages.
The f2q removal layer then deleted the China APKs without restoring the global
package name or APKs. Settings therefore retained its China SmartManager rune
and exposed App Lock with no backend.

`objectives/f2q/76-restore-global-devicecare-features.sh` now restores Fold4's
`SmartManager_v5`, `SmartManager_v6_DeviceSecurity`, and both `lool` permission
files. It also restores the global package feature values:

- SmartManager: `com.samsung.android.lool`
- device monitor: `com.samsung.android.sm.devicesecurity`

Astro already imports pa3q's 64-bit `libphotohdr.so`. The same objective now
sets `SEC_FLOATING_FEATURE_MMFW_SUPPORT_PHOTOHDR=TRUE`, which is the exact
availability gate used by One UI 8 Settings for Super HDR.

Dual Messenger did not require another framework or APK patch. DAAgent is
installed and its `DualAppActivity` starts successfully. The One UI 8 Settings
controller also returns available for owner user 0 when there is no device
owner, K05 disabled-menu flag, or China minor-mode restriction. It should be
rechecked after the regional image rebuilds the Settings feature list.

The UWB unavailable state observed during this test was not a missing HAL or a
country-code failure. `UwbSettingsStore` retained `settings_toggle=true` and the
country resolved to KR, but airplane mode was enabled and
`airplane_mode_radios` explicitly included `uwb`. AOSP therefore correctly
kept `mSetEnabled=false` without attempting device initialization. The regional
image intentionally keeps the exact stock Fold4 UWB JAR; the null-guard remains
a separate experiment for testing only after airplane mode is disabled.

Controlled regional-feature image:

- `out/f2q_regional_features_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `3f330e32b6ae7618cf7a52485bb03d9f64868c87f911188a713752223ecf89eb`
- UWB JAR: exact Fold4 stock SHA-256 `e45194dd4e1bf632581d53178ae29eddcb9a05793ad3107c6e84c80457eb9bbd`
- Available system blocks: 34,856 × 4 KiB (about 136 MiB)

Independent verification passed the whole-image hash, clean ext4 check,
floating-feature XML validation, donor APK hash readback, Quick Share and
HwModuleTest preservation, China/EAD package absence, SELinux xattrs, and LP
geometry checks.

## Fold2 hardware-test keystring routing (2026-08-02)

`*#0*#` reached One UI 8 DRParser but did not launch Fold2 HwModuleTest. The
active LUC OMC keystring and the fallback KOO keystring both mapped the input
to secret-code authority `0*` while leaving `<packagename>` empty. The donor
DRParser unconditionally applies that value with `Intent.setPackage()`, so it
produced an intent restricted to the empty package and delivered it nowhere.
Direct system-UID broadcast testing had already proved that Fold2's receiver
and activity work.

Samsung's `*_keystrings.dat` format was reproduced byte-for-byte: raw 512-bit
RSA blocks contain 53-byte plaintext chunks, use public exponent 65537 for
encoding, and use the private modulus/exponent stored in DRParser assets for
decoding. `scripts/helpers/patch_samsung_keystrings.py` now decodes, encodes,
or patches this format. The f2q objective
`objectives/f2q/82-fix-hwmodule-keystring.sh` sets the `*#0*#` package in both
LUC and KOO data to `com.sec.android.app.hwmoduletest` during normal builds.

Because `/prism` is a separate physical ext4 partition rather than a logical
partition inside `super`, a standalone image was built from a read-only dump
of the running device's current prism partition:

- `out/f2q_prism_hwmodule_direct/prism.img`
- Size: `419,430,400` bytes
- SHA-256: `89f2af524f4c234ae82c70be37e78193b81ec91fdfbda48ec1c1fb1e2e8eac01`
- LUC patched data SHA-256:
  `10353d88fe5a4fff7bf52efc2248e2c8506460967146e2879609ba7bf759fa27`
- KOO patched data SHA-256:
  `ff374f7c90f4f2faf2066026ecf4c61e2e43deca7138eda3263680efd66c65aa`

Independent verification passed the full image hash, clean ext4 check, exact
encrypted-file hashes, XML decode/validation, package-target readback,
root:root 0644 metadata, and `vendor_configs_file` SELinux labels. A recursive
comparison against the source image confirmed that the LUC and KOO keystring
files are the only changed file contents. This image must be flashed to
`prism` separately from the regional-feature `super.img`.

## Fold4 feature baseline and HwModuleTest Android 16 compatibility (2026-08-02)

Physical testing of the regional image confirmed that App Lock disappeared and
that Super HDR and Dual Messenger became visible. Super HDR, however, was
permanently shown as enabled and did not affect rendered photos. Comparison
against the exact Fold4 KOO donor proved that Fold4 does not define
`SEC_FLOATING_FEATURE_MMFW_SUPPORT_PHOTOHDR`; the exposed preference came from
the manually added S25 PhotoHDR gate and library rather than a Fold4 feature.

`scripts/helpers/compose_f2q_floating_feature.sh` now starts with the exact
Fold4 KOO XML, replaces the AUDIO, CAMERA, LCD, and SYSTEMUI namespaces with
Fold2 KOO values, and applies the target AOD, touch, SPen, brand, accessory,
and SIOP entries. This preserves the Android 16 Fold4 software feature surface
without advertising Fold4/S25 hardware. In particular, it removes PhotoHDR,
UDC status-bar layout, Fold4 cover-display VRR, and unsupported S25 AI gates;
it restores Fold2 camera IDs, panel modes, dual-display AOD configuration, and
audio capability values. The normal build applies this as
`objectives/f2q/77-normalize-fold4-hardware-features.sh`.

The encrypted prism keystring patch successfully launched Fold2 HwModuleTest,
but the Android 13 APK crashed from `HwModuleTest.onResume()` because its
dynamic custom-action receiver used the legacy two-argument `registerReceiver`
call. Android 16 requires an explicit exported state. The f2q smali patch now
uses the three-argument overload with `RECEIVER_EXPORTED`; rebuilding and then
re-decompiling the APK confirmed the new call in DEX. A complete APK-content
comparison showed that only `classes.dex` changed. The stale ART profile is
removed with the patched APK.

Controlled combined image:

- `out/f2q_fold4baseline_hwmodule_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `71eab782788df0852e715936f0abdd8d7a4b8852a43d0d5f107f799e4d4106ea`
- composed floating-feature SHA-256:
  `c21eb2ca9a2c8cf3bbf326fd8ad4f4377207fc79ac267c572dce93e24ddfd25f`
- patched HwModuleTest APK SHA-256:
  `41934b84b47dfaaea202c1dc55e2cefc20761fc8de0acd7e7fe54dc495f759ec`

Independent verification passed the whole-image hash, clean ext4 check,
floating-feature value/absence assertions, patched APK readback, SELinux and
owner/mode checks, and preservation of stock Fold4 UWB and Quick Share. A full
system tree comparison against the regional source found exactly three
changes: the floating-feature XML, HwModuleTest APK, and removal of the old APK
profile.

The same live log capture exposed a separate pre-existing crash loop in
`com.qualcomm.location`: `DebugReportingMonitor` restarts roughly once per
second because `DebugReportService.registerForDebugReporting()` dereferences a
null `DataPerPackageAndUser` after reporting that the ILoc AIDL interface is not
supported. This is independent of the HwModuleTest and floating-feature fixes
and requires a separate target-vendor location compatibility pass.

## Fold4 baseline v3 regression repair (2026-08-02)

Physical testing of `f2q_fold4baseline_hwmodule_direct` found four regressions:
HwModuleTest was missing from PackageManager, audio output ignored the volume
slider and became excessively loud, Dolby processing did not take effect, and
HDR playback could drop panel brightness to zero. The camera UI also remained
laid out for the wrong display/camera class.

The patched Android 13 HwModuleTest APK had lost its Samsung platform-signature
identity during rebuild and was rejected during the system package scan. It is
now restored byte-for-byte with its original ART profile. Instead, a narrowly
scoped `services.jar` patch exempts only
`com.sec.android.app.hwmoduletest` from the Android 14+ dynamic-receiver flag
enforcement. The rebuilt JAR was decompiled again and the package-specific
branch was confirmed in the final DEX. The prism keystring routing remains
unchanged.

The audio/HDR regressions came from replacing the complete One UI 8 AUDIO and
LCD namespaces with Android 13 Fold2 values. The composer now keeps the exact
Fold4 namespaces, overriding only Fold2 panel refresh capabilities. For the
camera it likewise keeps the Fold4 One UI 8 feature surface while importing
Fold2 physical camera IDs, sensor/vendor pipeline declarations, memory level,
and distortion data. The Fold4-only under-display-camera contract is removed
because Fold2 uses a punch-hole inner camera. A live test that temporarily
disabled WindowManager's `ignoreOrientationRequest` setting did not change the
broken camera layout, and the setting was restored; global orientation policy
was therefore ruled out.

Final controlled image:

- `out/f2q_fold4baseline_v3_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `54296323d34d1d4995c0a5e5b33542ab67c11a2e68fa5fb0efdf1becc39c4318`
- floating-feature SHA-256:
  `3a3f33ba3e7bc2771ef2463a0fa555b9fabfa5653ca28f1b82459f9a105019b5`
- patched services.jar SHA-256:
  `63de8d8cc6b297f56dca2df98e1e1a6eeb4b0f9dacedc3db1af9090965af8f01`
- original HwModuleTest APK SHA-256:
  `36dafd0eb46d2cab315ed5379edd0ee204f48b196c5b8b5230883d31da450fb3`

Independent verification passed the full-image hash, clean ext4 check, XML
validation and feature assertions, original APK/profile readback, patched DEX
inspection, file metadata and SELinux labels, and preservation of stock UWB
and Quick Share. Recursive comparison against the known-booting regional base
confirmed that only `floating_feature.xml` and `services.jar` differ.

## Fold2 factory provider and extended-brightness guard (2026-08-02)

Physical testing of v3 showed that HwModuleTest now launched and remained
alive, but rendered an empty white activity. PID-filtered logs repeatedly
reported that PackageManager could not find
`com.samsung.android.providers.factory.FactoryTestProvider`. The exact Fold2
stock `FactoryTestProvider` APK, ART profile, and platform permission allowlist
are now restored by `objectives/f2q/81-restore-factorytestprovider.sh`. The
provider uses the system shared UID and exposes the authority queried while
HwModuleTest constructs its main menu.

The v3 outdoor-mode reproduction also isolated the brightness failure. One UI
8 requested its extended maximum `2.0` (`510` in Samsung's integer logging),
but the Fold2 Android 11 display stack converted that request into a very low
panel backlight value. `DisplayPowerController` is now clamped to the normal
`1.0` range for f2q. This is a deliberate compatibility guard: it prevents the
black-screen path while true extended HBM remains unavailable until the old
HWC/kernel interface is adapted.

Additional live diagnostics kept separate from this image:

- Camera remained mislaid out at both logical density 420 and physical density
  480, so a resource-density mismatch is ruled out.
- HDR playback requested brightness `60 -> 120` and changed Qualcomm HWC
  `hs_mode` from 1 to 3 at the failure point. This is a lower display-stack
  compatibility issue and is not claimed fixed by the 1.0 guard.
- Dolby parameters and profiles reached AudioFlinger, but the active YouTube
  deep-buffer track did not activate the integrated Dolby effect stage. This
  is an effect-route compatibility issue rather than a missing settings gate.

Controlled v4 image:

- `out/f2q_fold4baseline_v4_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `ae202b617950655708f2eb97477b7aab62d132dcc7512d8c8244126e894daaa5`
- patched services.jar SHA-256:
  `ff6e6840fa2338fdc67a874f925e18bc0361bb78a347883ab36646edc4e058a1`
- Fold2 FactoryTestProvider APK SHA-256:
  `ae0be36060d414af755c2db1bb56d10cecfdb73aca3569da96182f0d1521bd79`

Independent verification passed the full-image hash, clean ext4 check,
floating-feature preservation, exact provider/profile/permission hashes,
ownership and SELinux labels, and re-decompiled DEX inspection for both the
HwModuleTest receiver exception and the extended-brightness clamp. Recursive
comparison against v3 found exactly the intended three tree changes:
`services.jar`, the new FactoryTestProvider directory, and its permission XML.

Physical validation confirmed that v4 makes the `*#0*#` menu and its tests
available. Returning from individual tests can pause before responding, but no
system ANR was recorded; the only retained event was LMKD later reclaiming the
idle HwModuleTest process at oom_adj 935. Outdoor mode and HDR playback no
longer darken the panel above 50 percent. The compatibility clamp also means
HDR currently changes the HWC color mode without providing a visible
brightness lift, so true HDR luminance remains a separate display-stack task.

Camera startup logging showed the precise layout fault. The Fold4 Camera
selects its `g3/k` fold layout manager, whose default layout state is `TABLET`.
On the Fold2 inner display it calculated `shutter_area` bounds such as
`1662..1875` and `1567..1969` for a 1768-pixel-wide window, placing the control
outside the visible area. Logical-density tests at 420, 480, and 600 dpi and a
temporary primary-orientation property test did not change this selection.
The disabled experiment
`objectives/f2q/SamsungCamera.apk/Force-Fold2-Phone-Layout.patch.disabled`
routes only Camera's layout-manager construction to the `g3/h` PHONE manager;
it must not enter the normal build until APK signature handling and a physical
test image are verified.

Dolby logging now also identifies the exact break: after receiving
`g_effect_dolby_enable=1`, audioserver classifies playback as non-spatialized
stage `-2113` and logs `disable content proc`. The Fold4 spatialized Dolby
contract therefore does not engage on the Fold2 audio HAL even though the UI,
profile, and global Dolby state are enabled.

## Fold UI scaling investigation (2026-08-02)

The Camera-only phone-layout experiment was assembled and independently
verified as `out/f2q_camera_phone_v5_direct/super.img`, but it is held as a
diagnostic artifact and is not recommended as the next normal image. Edge
Panel was subsequently reported as unusually large as well, so the shared
display configuration was audited before physical testing v5.

The active inner-display configuration is internally consistent: physical
size `1768x2208`, logical density `420`, `sw674dp`, large-screen class, main
display device type, and device state `OPENED`. A controlled `410dpi` test
produced the Fold4-equivalent `sw690dp` and changed Edge item calculations,
but Camera still selected the same Fold `TABLET` layout and the same preview
algorithm. Density was restored to `420` immediately after the test.

Decompiling the active One UI 8 Launcher showed that Edge Panel is not being
globally magnified by framework density. Launcher directly defines
`edge_panel_height=667dp` and `edge_panel_width=138dp`, then reads those
resources in `AppsEdgeViewModel`. Its new parser only tests whether
`SEC_FLOATING_FEATURE_COMMON_CONFIG_EDGE` is non-empty and looks for feature
keywords; it does not consume the Fold2 Android 13 `devicescale:1.064`
parameter. Thus the large Edge Panel is a Fold4 Launcher design/resource issue
and does not by itself establish a shared Camera scaling fault.

A second controlled test temporarily emulated the Fold4 inner resolution
`1812x2176` at `420dpi`. Camera reported the expected Fold4 `sw690dp` window
and recalculated its preview to `x=90, w=1632, h=2176`, but continued to select
the same `TABLET` state. Physical Fold2 size and `420dpi` were restored. The
next Camera image should therefore remain isolated from Edge Panel work; v5
must not be treated as a global display fix.

## Fold2 build-property normalization (2026-08-02)

The v4 property audit found a mixed product identity rather than a global
display-density error. Fold2 stock vendor and odm were already intact as
`f2q/f2qksx/SM-F916N`, and the active vendor display properties matched stock.
However, donor `product`, `system_ext`, and `system_dlkm` still advertised
`q4qksx/SM-F936N`; `system` also retained the donor product name. Live Android
therefore exposed different identities depending on which property an app
queried.

Astro's target patch contained a concrete partition-selection bug: it wrote
`ro.product.product.model` through `BPROP "system"` instead of
`BPROP "product"`. This is corrected. The f2q late identity objective now
normalizes generic and partition-scoped name/model properties, including
Astro's camera-library alias `ro.astro.codename`, while retaining the donor
Android 16 build/version fields.

Controlled v6 image:

- `out/f2q_stockprops_v6_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `a084cea9310750eed64ee2b1448f74c13c675dd23d92ad7d0c2936f7d7636665`
- Base: `f2q_fold4baseline_v4_direct`

Only four files differ from v4:

- `system/system/build.prop`
- `system/system/system_ext/etc/build.prop`
- `system/system/system_dlkm/etc/build.prop`
- `product/etc/build.prop`

Their product identity is normalized to `f2q/f2qksx/SM-F916N`. Android 16
version, SDK, build ID, security patch and fingerprints remain unchanged, as
do Fold2 vendor/odm, density and SurfaceFlinger properties. Both edited ext4
filesystems passed repair-mode e2fsck followed by read-only property and tree
verification. This image is intentionally a narrow identity diagnostic: it
may affect Camera or Samsung app feature selection, but it does not modify the
Fold4 Launcher resources responsible for the oversized Edge Panel.

Physical testing found no visible or functional change from the v6 identity
normalization; the existing Camera, Edge Panel, HDR and Dolby faults remained.

## Fold2 product resource overlay restoration (2026-08-02)

The Fold2 punch-hole status-bar geometry exposed the next shared donor
artifact. Although the composed floating feature correctly removed
`ShowIconsInUDC`, the active `product/overlay/product_overlay.apk` was still
byte-identical to Fold4's
`framework-res__q4qksx__auto_generated_rro_product.apk`. It overrides the
framework with an empty `config_mainBuiltInDisplayCutout`, a populated
`config_mainBuiltInDisplayCutoutForUDC`, Fold4 status-bar margins, and Fold4
inner/sub-display cutout paths.

The same Fold4 RRO also supplies panel-specific brightness curves, extended
maximum 510, AFPC values and rounded-corner dimensions. Fold2 stock instead
uses a physical main punch-hole path, its own sub-display path and status-bar
dimensions, extended maximum 453, and SM8250 panel brightness/AFPC tables.
This misplaced RRO is therefore a stronger common cause for the status-bar
fault and HDR/panel incompatibility than build properties were.

Fold2 and Fold4 RROs have the same package name, static priority, and Samsung
signing certificate SHA-256
`b9a42dd5fc4e054889ae4127a6274cec64e75c41733d42f5991e7019f9ea5caf`.
Android idmap2 maps legacy RRO entries by type/name and skips names absent from
the Android 16 target, so the original signed Fold2 APK can be used without
rebuilding or signature substitution. The normal f2q objective now restores
this stock RRO after the donor workspace is assembled.

Controlled v7 image:

- `out/f2q_stockrro_v7_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `f72dcab65de826ac00f06820095c308b327507db40fd70e1cc2975a8bcf8acae`
- Base: `f2q_stockprops_v6_direct`
- Fold2 product RRO SHA-256:
  `fe016173802eff1aacf0e153d9363dcec2928d264968a7e9a69aac722e578b34`

Tree verification found exactly one changed file:
`product/overlay/product_overlay.apk`. Its readback hash and Samsung
certificate match the untouched Fold2 stock APK, and product ext4 passed
e2fsck. The v4 extended-brightness clamp is deliberately retained so this
test isolates RRO activation. If status-bar/cutout behavior is corrected and
the image remains stable, the next controlled step is to remove the clamp and
retest HDR against the restored Fold2 brightness tables.

## Fold2 corner, HBM ceiling and Quick Share classification diagnostic (2026-08-03)

Physical v7 testing confirmed that the Fold2 product RRO corrected the inner
status-bar thickness, but Camera, HDR luminance and Quick Share classification
remained faulty. Live overlay lookup proved the Fold2 cutout and status-bar
resources were active. Android 16 nevertheless fell back to generic framework
corner values absent from the Android 13 RRO: inner top/bottom `36dp` instead
of Fold2 stock `20dp`, and secondary top/bottom `24dp` instead of Fold2 stock
`0px`. At 420dpi the inner fallback becomes a 95-pixel mask, matching the
oversized rotated corner shown in the physical screenshot.

The live display also advertised Fold2's restored extended maximum
`1.7764705` (`453/255`), while the v4 services patch still forced the framework
ceiling to `1.0`. The next diagnostic therefore uses Fold2's exact ceiling
rather than either the no-HBM `1.0` guard or Fold4's unsupported `2.0` request.
This is intended to test the restored Fold2 brightness tables without claiming
that the old composer/HWC path can yet provide correct HDR luminance.

Quick Share logging showed that Google Play Services discovers the remote
devices and marks them `isSelfShare=true` and `isKnown=true`, including valid
shared credentials. Samsung ShareLive/MCF receives the same peer only as
`ANONYMOUS`, with null buddy/contact identifiers, so BLE discovery and basic
contact permission are not the missing layer. Recursive donor comparison found
ShareLive, MCFDeviceSync, MdxKit, HWResourceShare, Samsung Account, Samsung
Cloud and contacts byte-identical to Fold4. The only matching component that
differed was `VisualCloudCore`: Astro's twentyfive feature script overwrote
Fold4's APK with the pa3q/S25 version. The diagnostic restores the exact Fold4
APK; this is a controlled compatibility test, not yet a confirmed fix.

Controlled v8 image:

- `out/f2q_hwcompat_v8_direct/super.img`
- Size: `10,817,110,016` bytes
- SHA-256: `67bcc80ff2db8549cdced5a3e0ec55728310440e064e495a3babf22f73bbefda`
- Base: `f2q_stockrro_v7_direct`
- Fold2-cap services.jar SHA-256:
  `d6706e60c14c59b790a835e4ff8ccb6445ed3a0f17dc59ad63810fa7fe69983a`
- Fold4 VisualCloudCore SHA-256:
  `1bb157fafd12a82ddef53cd126290b0eb5505058aed57e1cb025c8a736837b06`
- F2qFrameworkOverlay SHA-256:
  `b1265143cec86bbd51108730cdd1a4263c6905a462887ef66a8d8e2d50e44937`

Independent whole-tree verification found exactly two changed files and one
added file in system: `services.jar`, `VisualCloudCore.apk`, and the unique
static `F2qFrameworkOverlay.apk`. Product is byte-identical to v7. The overlay
package, priority, exact Fold2 corner values, owner/mode/SELinux context,
brightness constant, retained HwModuleTest exception and donor APK hash all
passed readback verification. Camera is deliberately unchanged because its
fault remains the SamsungCamera-internal `g3/k` TABLET layout choice rather
than framework cutout geometry.

Physical v8 validation confirmed that the custom RRO makes the rotated inner
corners substantially more natural. They remain only slightly rounder than the
physical panel and are acceptable, so the 20dp Fold2 stock value is retained.

The Fold2 `453/255` framework ceiling produced a real luminance increase during
HDR playback, proving that the restored extended range reaches the display
stack. It also reproduced the above-50-percent darkening fault, while the
manual Extra Brightness toggle still produced no visible increase. Therefore
the failure is below the framework ceiling/resource layer: extended Android 16
brightness requests require translation for the Android 11 Fold2
composer/display HAL. Future boot baselines return to the safe `1.0` guard
until that lower path is adapted; resource or maximum-value changes alone are
not considered a fix.

Quick Share still failed to populate both My devices and Contacts after the
exact Fold4 VisualCloudCore restoration. That APK is ruled out as the cause.
The next donor experiment keeps a coherent Fold7 One UI 8 sharing stack rather
than mixing individual Fold4/S25 services.

## Fold7 q7q donor first-boot image (2026-08-03)

The SM-F966N KOO `F966NKSS7AYLT` One UI 8 donor was built as a separate
ProjectArc branch without replacing any Fold4/v8 output. Because q7q is a
native One UI 8 donor, the mixed S25 `twentyfive` layer is skipped. Fold2
vendor/odm, VNDK 30, SELinux mappings, product RRO, camera hardware data,
vibrator bridge, Korean CSC data, and the existing f2q boot compatibility
patches remain the target side of the port.

ProjectArc local-firmware extraction was fixed to include `prism`/`optics` CSC
images. The generated q7q test set therefore contains a separate Fold2-stock
`prism.img` with both LUC and KOO keystrings. The first boot test should still
flash only `super.img`; keep the currently working prism in place until q7q
boot behavior is known.

Direct-flash output:

- `out/f2q_q7q_boot_direct/super.img`
- SHA-256: `6a6728dcf32c6ac539d2dfaa6f54ae97a88078dea19516b9c0c0493094a10116`
- Size: `10817110016` bytes (exact Fold2 physical super size)
- Separate CSC image: `out/f2q_q7q_boot_direct/prism.img`
- prism SHA-256: `55e9e1cf530bf504a57829003bf801d8a8427c9fc1bbf136dee93369dede6138`

The super metadata contains `system`, `vendor`, `product`, and `odm`, with two
65536-byte metadata slots and the `qti_dynamic_partitions` group limit of
`10812915712` bytes. The four images total `9807962112` bytes, leaving
`1004953600` bytes of group headroom. Read-only `e2fsck` completed cleanly on
all four dynamic images and the separate prism image. The extracted q7q netd
cache retained its pristine hash after the build, confirming that the new
copy-on-write binary patch no longer modifies the donor cache.

For the first boot, use the already proven `boot-f2q-hwfix.img` kernel and stock
dtbo with this super image. Do not flash the newly generated prism image in the
same trial; this keeps a q7q framework boot failure separate from CSC changes.

## q7q first physical boot failure and dual-ABI correction (2026-08-03)

Physical testing of `f2q_q7q_boot_direct` with only its super image changed
rebooted at the Samsung splash. Three consecutive boots in
`log/q7q-test/last_kmsg.txt` reached early-init and then failed identically:

- `/vendor/bin/boringssl_self_test32` existed in the Fold2 vendor image.
- `execve()` returned `ENOENT` because the q7q 64-bit-only system had no
  `/system/bin/linker` interpreter.
- `boringssl_self_test.rc` deliberately requested
  `reboot,boringssl-self-check-failed` at approximately 5.5 seconds.

This is a fundamental ABI contract mismatch, not a kernel panic, AVB failure,
or missing vendor file. Fold2 also has 32-bit-only audio, CAS, Widevine and OMX
HAL services, so merely disabling the BoringSSL reboot or hiding the 32-bit ABI
would not be a valid compatibility fix.

Controlled dual-ABI image:

- `out/f2q_q7q_dualabi_direct/super.img`
- SHA-256: `b9e3a02d066930a2f5965eedf56a336ab56aec4d7bac37c8c6d7a79f11508c56`
- Size: `10817110016` bytes
- Base: `f2q_q7q_boot_direct`

The q7q Samsung framework, apps, product and display resources remain intact.
The known-booting Fold4 One UI 8 donor supplies the complete dual-ABI APEX set,
`/system/lib`, `app_process32`, 32-bit BoringSSL/media/exFAT binaries, and the
32-bit linker symlinks. Fold4 and q7q Runtime APEX signing keys were verified
identical before replacement. The system ABI properties now advertise both
`arm64-v8a` and `armeabi-v7a`.

The rebuilt system image is `7746711552` bytes. All four dynamic images total
`10344833024` bytes, leaving `468082688` bytes under the Fold2 group limit.
Read-only ext4 verification passed, super metadata contains the expected four
partitions, `app_process32` is an Android 36 ARM ELF using `/system/bin/linker`,
and the restored Runtime APEX contains both its 32-bit linker and libc.

## q7q boot-animation stall and resolv correction (2026-08-03)

Physical testing of `f2q_q7q_dualabi_direct` reached Samsung boot animation,
confirming that the dual-ABI correction passed the former splash-stage
`boringssl_self_test32` reboot. The device remained in boot animation until
Samsung `bootchecker` deliberately triggered a sysrq panic at 604 seconds.
That final kernel panic is a timeout consequence rather than the original
failure.

All 32 collected tombstones are repeated `/system/bin/netd` SIGABRT crashes.
The first tombstone aborts in
`/apex/com.android.resolv/lib64/libnetd_resolv.so` while constructing
`DnsProxyListener`, with the diagnostic string:

`resolveIsUidNetworkingBlockedFn: ADnsHelper_init failed No such file or directory`

The broad Fold4 APEX graft had paired the patched q7q `netd` with Fold4's
`com.google.android.resolv_compressed.apex`. Their different builds are not a
coherent pair. The next image therefore restores only q7q's resolv APEX while
retaining the Fold4 dual-ABI Runtime, ART, `/system/lib`, linker, and
`app_process32` required by the Fold2 vendor.

Controlled resolv correction:

- `out/f2q_q7q_resolvfix_direct/super.img`
- SHA-256: `9a2bee029ba68e569e4a18b00023c4023482d5de1f07e073fd617d75b6c6a750`
- Size: `10817110016` bytes
- Base: `f2q_q7q_dualabi_direct`
- Fold4 resolv APEX SHA-256 before replacement:
  `f1699315c03415a8b8948ef35bf7ac39c37644f3de4ac4487fd05a3324a7c96f`
- Restored q7q resolv APEX SHA-256:
  `06caccb3bcdc8301059c5727783ffa2a6803a43489d6f0f62b84f25b19cc7085`

The four dynamic partitions remain `10344833024` bytes, leaving `468082688`
bytes under the Fold2 group limit. Read-only ext4 verification and super
metadata validation passed. The physical trial should again flash only this
new super image and retain the proven `boot-f2q-hwfix.img`, stock dtbo, and
current prism.

## q7q-test3 DNS helper correction (2026-08-03)

`f2q_q7q_resolvfix_direct` again remained at boot animation until Samsung
`bootchecker` forced a sysrq panic at 590 seconds. The replacement itself was
confirmed active: `libnetd_resolv.so` changed from the Fold4 Build ID
`b9f77c95cbeab69f6156b5055126ab11` to the q7q Build ID
`0a4b54cd322596f989dd8ab38cb50130`. Despite that change, all 32 native
tombstones remained repeated `/system/bin/netd` SIGABRT crashes with the same
`ADnsHelper_init failed No such file or directory` diagnostic.

Inspection of q7q `libnetd_resolv.so` identified the missing runtime module as
`libcom.android.tethering.dns_helper.so`. The resolver dynamically loads that
library and resolves `ADnsHelper_init` and
`ADnsHelper_isUidNetworkingBlocked`. Both are present in q7q's
`com.google.android.tethering_compressed.apex`, while the Fold4 tethering APEX
left by the broad dual-ABI graft does not contain this Samsung extension. No
matching SELinux denial was recorded, so this is an absent module rather than
an access rejection.

Controlled DNS helper image:

- `out/f2q_q7q_dnshelper_direct/super.img`
- SHA-256: `d0b86b96709fec63f8330937b27c8bf3a8a28e34d6239122c412e0884889b136`
- Size: `10817110016` bytes
- Base: `f2q_q7q_dualabi_direct`
- Restored q7q APEX pair: `com.google.android.resolv_compressed.apex` and
  `com.google.android.tethering_compressed.apex`
- Retained Fold4 dual-ABI Runtime, ART, `/system/lib`, linker, and
  `app_process32`

The four dynamic images remain `10344833024` bytes, leaving `468082688` bytes
under the Fold2 group limit. The q7q tethering source was verified to contain
the DNS helper library and both required entry points before copying. The
copied APEX hashes, ext4 filesystem, and final super metadata all passed
verification.

## q7q-test4 legacy NetBpfLoad service correction (2026-08-03)

`f2q_q7q_dnshelper_direct` again remained at boot animation until
`bootchecker` triggered its timeout panic at 605 seconds. The Fold7 helper
restoration was successful: all netd tombstones map
`/apex/com.android.tethering/lib64/libcom.android.tethering.dns_helper.so`
with Build ID `9fc73605233dc163267c9ba345934624`. The helper itself now returns
`ENOENT` because its required pinned networking maps are absent.

Static inspection shows that the helper waits for these resources:

- `/sys/fs/bpf/netd_shared/map_netd_uid_owner_map`
- `/sys/fs/bpf/netd_shared/map_netd_configuration_map`
- `/sys/fs/bpf/netd_shared/mainline_done`
- `/sys/fs/bpf/netd_shared/map_netd_data_saver_enabled_map`

Fold2's Android 10 first API and 4.19 kernel select the helper's Android-S
compatibility path, which requests the `mdnsd_netbpfload` init service. API
35+ APEX rc selection instead exposes the modern `bpfloader` service name, so
the legacy request cannot launch the loader. The already inserted q7q loader
was also found with normalized metadata (`0755`, `0:2000`,
`u:object_r:system_file:s0`) rather than the executable metadata required by
the bpfloader SELinux domain.

The q7q loader binary itself is valid. Its SHA-256 is
`1522c644164a6e24dc45d7a30ff282b801a2e41a4b3e0536f1d242f1e998faa5`,
and its single Fold2 compatibility patch at offset `0xdb34` is the expected
`nop`, bypassing only the kernel-5.4 version gate.

Controlled legacy-service image:

- `out/f2q_q7q_netbpf_alias_direct/super.img`
- SHA-256: `34de9ed42b648c6481ae7a7b30ebf939384f06604cfebecb4a7ce33e23a00a40`
- Size: `10817110016` bytes
- Base: `f2q_q7q_dnshelper_direct`
- Restored loader metadata: `0750`, `0:0`,
  `u:object_r:bpfloader_exec:s0`
- Added `mdnsd_netbpfload` alias with the real loader capabilities, groups,
  `/dev/kmsg`, and 1 GiB memlock limit

The q7q resolv/tethering pair and Fold4 dual-ABI Runtime/ART core remain
unchanged. Read-only ext4 validation, the inserted rc contents and xattrs,
and final super metadata all passed verification. If this loader reaches an
unsupported 4.19 BPF verifier feature, the next reset log should move away
from the repeated DNS-helper `ENOENT` and expose that exact loader failure.

## q7q-test5 NetBpfLoad success and missing dual-ABI zygote rc (2026-08-03)

The q7q-test5 trial was intentionally stopped with the hardware reset keys at
approximately 138 seconds to avoid OLED burn-in. This short capture is fully
sufficient and preserved more useful early-boot data than the ten-minute
bootchecker timeout runs. Future stuck-animation tests should be stopped after
roughly 90 to 120 seconds; waiting for bootchecker is no longer required.

The BPF correction succeeded completely:

- init parsed `f2q_mdnsd_netbpfload.rc`.
- the patched q7q `NetBpfLoad v0.47` started at 14.61 seconds;
- it selected and loaded the kernel-4.19 variants of the networking programs;
- the required `netd_shared` maps and programs were pinned;
- the platform Samsung BPF loader continued afterward;
- `NetBpfLoad: success` was recorded at 14.835 seconds;
- netd started once at 14.837 seconds and remained running until the manual
  reset.

The netd tombstones visible in `/data/tombstones` were retained files from the
previous tests, not current crashes. The only new native tombstones were the
two non-blocking Qualcomm HDCP provisioning checks.

The next boot blocker was explicit in init's early log:

- `init.zygote64_32.rc` was selected and added to the import list;
- opening it failed with `ENOENT` because q7q is a 64-bit-only donor;
- the `zygote-start` action could not find either `zygote` or
  `zygote_secondary`;
- consequently no `system_server` process was ever started.

Controlled dual-ABI zygote image:

- `out/f2q_q7q_zygote_direct/super.img`
- SHA-256: `73ae3b9edae0ff11c46068cea3e63a136cda5cfd0b17f81322a7460a150156e6`
- Size: `10817110016` bytes
- Base: `f2q_q7q_netbpf_alias_direct`
- Added only Fold4 Android 16 `init.zygote64_32.rc`
- Source rc SHA-256:
  `649a621c1c646ca05d669b9bf6686fd46c0ea50ef729761324d213206fbf96cd`

The restored rc imports q7q's existing primary `init.zygote64.rc` and defines
the secondary service using the already restored ARM `app_process32`. The
q7q networking stack and Fold4 dual-ABI Runtime/ART remain unchanged. File
ownership, mode, SELinux label, read-only ext4 validation, and final super
metadata all passed verification.

## q7q-test6 ARM HWUI registration bridge (2026-08-03)

The zygote rc correction worked. Init parsed `init.zygote64_32.rc`, started
both `zygote` and `zygote_secondary`, and launched the ARM64 and ARM
`app_process` binaries. The ARM secondary zygote then aborted within roughly
one second on every restart. Its current tombstones identify the exact JNI
registration failure in the restored Fold4 ARM `libhwui.so`:

`NoSuchMethodError: HardwareRenderer.nSemGetResourceCacheLimit()I`

The Fold4 ARM HWUI library registers three Samsung resource-cache query
natives that q7q's `HardwareRenderer` class does not declare:

- `nSemGetCurrentResourceCacheMax()J`
- `nSemGetCurrentResourceCacheUsage()J`
- `nSemGetResourceCacheLimit()I`

The q7q ARM64 HWUI library does not register those getters and retains only
the shared `nSemSetResourceCacheLimit(I)Z` entry. Consequently, replacing the
whole q7q class or ARM64 HWUI would unnecessarily disturb the native q7q
graphics path.

The unusually fast reboot was deliberate framework recovery, not a kernel
panic or spontaneous power loss. At 61.09 seconds init recorded that the
updatable `zygote_secondary` had exited four times before boot completion. At
62.42 seconds Samsung `bootchecker` reached rescue level 4 and requested
`sys.powerctl=reboot,rescueparty_by_bootchecker`; the orderly reboot completed
afterward. The absent boot sound is consistent with the primary zygote being
killed on every secondary restart before system_server and the audio stack can
finish starting.

Controlled ARM HWUI registration bridge:

- `out/f2q_q7q_hwui32_direct/super.img`
- SHA-256: `165fba858f0e3717f65e89fad3b4c06c53b150a5ee8ca96fbffb1af7ff505c64`
- Size: `10817110016` bytes
- Base: `f2q_q7q_zygote_direct`
- Original q7q framework SHA-256:
  `d2612f2f5ad93c2a0d0c9a30725fa32053c6f87a7f6cfc91230d51a6692765b8`
- Patched q7q framework SHA-256:
  `fac2136a35e9f723b713fa95b1cb062192f5b8c5463ab75889cf1bfdf11454f0`

Only the three missing private static native declarations were added to q7q
`framework.jar` `classes.dex`. No Java call sites were imported, and both
HWUI binaries, ART/Runtime APEX files, services, properties, and hardware
configuration remain byte-identical to the preceding image. The final jar
passes ZIP validation, retains the original `dex 039` container, and a fresh
disassembly confirms all three getters plus the existing setter exactly once.
Read-only ext4 validation and final super metadata validation passed. The four
dynamic partitions remain `10344833024` bytes, leaving `468082688` bytes under
the Fold2 group limit.

## q7q-test8 clean secondary-zygote exit and logd capture (2026-08-03)

The q7q-test8 capture confirms that the HWUI registration bridge changed the
failure mode. There is no current native tombstone: the `05:11` ARM zygote
tombstones retained in `/data/tombstones` predate this boot. Both zygotes and
system_server now start, the primary completes preload, and the audio stack is
alive long enough to play the Samsung boot sound.

The remaining deterministic loop is a clean secondary-zygote return:

- `zygote_secondary` exits with status 0 rather than SIGABRT;
- the first exit occurs after system_server reaches its early service setup;
- subsequent secondary zygotes live for approximately five seconds;
- the secondary service's standard `onrestart restart zygote` action then
  kills the healthy primary zygote and system_server;
- Samsung bootchecker eventually requests the orderly rescue-party reboot.

`/data/log/prev_dump.log` was added to the recovery collection. It is a copy
of Samsung's previous kernel buffer and confirms the timing, but it does not
contain the ART/logd message immediately preceding the clean Java return.
`sec-vibrator-aidl` and `vendor.face_hal` also restart independently during
this window; neither produces the primary zygote restart that drives this
specific loop.

Controlled all-buffer logd diagnostic image:

- `out/f2q_q7q_bootlog_direct/super.img`
- SHA-256: `8ceeeff86a315fc48b4cc2ca537cabc0304979666b164a3d5eebcab4b43dfe64`
- Size: `10817110016` bytes
- Base: `f2q_q7q_hwui32_direct`
- Added only `system/etc/init/99_logcat_new.rc`
- Source rc SHA-256:
  `58f1e749a24a91016c0630d8655cecbec7f869f2722b61bacf7c4a8274afb774`

The service starts at `post-fs-data` as the logd user, captures every log
buffer into `/data/misc/logd/f2q_boot_log.txt`, rotates at 4 MiB, and stops if
boot completes. No zygote behavior, restart policy, framework code, vendor
file, property, or hardware configuration changed. The recovery collector
already copies this path and its rotated files. File metadata, SELinux label,
preceding HWUI/zygote/BPF corrections, read-only ext4 validation, and final
super metadata all passed verification. Dynamic partition usage remains
`10344833024` bytes with `468082688` bytes of Fold2 group headroom.

## q7q-test9 boot-through secondary zygote policy (2026-08-03)

The first logd diagnostic image reproduced the same clean ARM secondary
zygote exit and rescue reboot. Its standalone post-fs-data logging service did
not leave a file in `/data/misc/logd`, so no new ART line was captured. The
kernel sequence remains deterministic: `zygote_secondary` returns status 0,
its Fold4 rc executes `onrestart restart zygote`, the healthy primary zygote
and system_server are killed, and bootchecker eventually reboots the device.

The next controlled test changes only that restart policy. It does not attempt
to disguise a crash or suppress bootchecker globally. The ARM zygote keeps its
existing command and is marked `oneshot`; after its current clean exit it is
left stopped, and the two secondary `onrestart` commands that restart the
primary zygote and perfmond are removed. This lets the q7q ARM64 zygote and
system_server continue far enough to reach boot or ADB. The same rc, which is
already proven to be selected by init, also starts continuous and exit-snapshot
logcat collection under `/cache`.

Controlled boot-through image:

- `out/f2q_q7q_zygote32_oneshot_direct/super.img`
- SHA-256: `0d5b6cae917ceb410118f02dc755f7895c6218e244d8717d4f453e05b593b2b2`
- Size: `10817110016` bytes
- Base: `f2q_q7q_hwui32_direct`
- Original Fold4 zygote rc SHA-256:
  `649a621c1c646ca05d669b9bf6686fd46c0ea50ef729761324d213206fbf96cd`
- Diagnostic zygote rc SHA-256:
  `5994427fffa1701a6904c83d53787688112acc9ff0b6a9871c7a81613dbd9f31`

This diagnostic temporarily stops 32-bit Android app spawning after the ARM
zygote's first status-0 return. It does not remove the 32-bit linker, native
libraries, ART/Runtime, or standalone ARM vendor binaries. q7q framework,
ABI properties, hardware files, and all preceding networking/HWUI corrections
remain unchanged. The recovery collector now includes
`/cache/f2q_boot_log.txt*` and `/cache/f2q_zygote_exit.txt*`. Final rc contents,
ownership, mode, SELinux label, ext4 filesystem, and super metadata all passed
verification; dynamic partition headroom remains `468082688` bytes.

## q7q-test10 VibratorManagerService watchdog blocker (2026-08-03)

The secondary-zygote oneshot policy removed the former primary-zygote restart
cascade. The q7q-test10 capture therefore kept the primary zygote and
system_server alive long enough to identify the next deterministic blocker.
At 119.79 seconds Android Watchdog killed system_server because its main thread
had been blocked for 66 seconds in:

`VibratorManagerService.nativeGetVibratorIds()`

The stack continues through `VibratorManagerService.<init>`, its Lifecycle
`onStart`, `SystemServiceManager.startService`, and
`SystemServer.startOtherServices`. This is the direct cause of the stuck boot
animation in this trial; the later system_server restart is a consequence.

The hardware-side evidence separates this from a missing vibrator driver:

- the stock HIDL vibrator service remains alive;
- it reads the Fold2 CS40L2X motor type as `LINEAR_INDEX_RC`;
- the exact `boot-f2q-hwfix.img` hash is still installed;
- the imported AIDL service, library, rc and VINTF XML are byte-identical to
  the previously vibration-working Fold4-port image;
- `sec-vibrator-aidl` nevertheless exits with status 1 before
  `android.hardware.vibrator.IVibrator/default` remains registered;
- q7q servicemanager then repeatedly attempts the absent service while the
  framework's synchronous native enumeration blocks the SystemServer main
  thread.

Controlled boot-through image:

- `out/f2q_q7q_vibrator_skip_direct/super.img`
- SHA-256: `b8e54f4db073500374de60176133a4757c433fe07a178afd11f19ffec7fc6506`
- Size: `10817110016` bytes
- Base: `f2q_q7q_zygote32_oneshot_direct`
- Original services.jar SHA-256:
  `863fac7272da976fdc14e47ba61914a94c6bb06c9df3db3fcbc05df3c26a2b0b`
- Patched services.jar SHA-256:
  `9733ccabc7c7b4fa79881d174f9bf9c0c9c8a7cbf4bbad430fbb15332ebc9579`

Only the synchronous `VibratorManagerService$Lifecycle` start call in q7q
`SystemServer.startOtherServices()` is replaced with a no-op. No vibrator
HAL, VINTF declaration, kernel driver, framework API, native library, or
service binary is removed or replaced. Android vibration is unavailable in
this diagnostic image; its purpose is to pass the proven watchdog blocker and
expose the next boot stage before repairing q7q servicemanager/AIDL
registration compatibility.

The rebuilt services container retains `dex 035`; fresh disassembly confirms
the lifecycle start call is absent while its class reference is still unique.
The prior HWUI framework hash, oneshot zygote policy, and NetBpfLoad alias were
verified before packaging. ZIP, ext4 and super metadata checks passed. The
four partitions total `10344833024` bytes and retain `468082688` bytes of
Fold2 dynamic-partition headroom.

## q7q-test11 boot-complete secondary-zygote crash (2026-08-03)

The vibrator boot-through image passed the previous watchdog blocker, enabled
the screen, and reached `wm_boot_animation_done`. The recovery capture then
recorded three consecutive system_server crashes at approximately 65.689,
77.659, and 89.917 seconds. Every crash has the same fatal chain:

`ActivityManagerService.finishBooting()` ->
`ZygoteProcess.bootCompleted()` ->
`attemptConnectionToSecondaryZygote()` -> `LocalSocket ENOENT`

The secondary socket is intentionally absent because the earlier diagnostic
left the cleanly exiting ARM zygote stopped. The no-argument boot-complete API
still attempts both zygotes, throws `Failed to inform zygote of boot_completed`,
and kills system_server. This is the direct cause of the post-boot hot-reboot
loop in q7q-test11.

The q7q source system is natively 64-bit-only (`arm64-v8a`, empty ABI32 list),
whereas the diagnostic port had advertised a dual-ABI Android runtime and
selected `zygote64_32`. The controlled correction restores the coherent q7q
application-runtime contract:

- vendor `ro.zygote` is changed from `zygote64_32` to `zygote64`;
- the system ABI list is restored to q7q stock `arm64-v8a` only;
- ActivityManagerService calls the existing
  `ZygoteProcess.bootCompleted("arm64-v8a")` overload instead of the
  no-argument method that requires an absent secondary socket.

Controlled image:

- `out/f2q_q7q_zygote64_bootcomplete_direct/super.img`
- SHA-256: `0394da96e414216c57091765addc17335f1af725da2a166066d0110901d606fa`
- Size: `10817110016` bytes
- Base: `f2q_q7q_vibrator_skip_direct`
- Original services.jar SHA-256:
  `9733ccabc7c7b4fa79881d174f9bf9c0c9c8a7cbf4bbad430fbb15332ebc9579`
- Patched services.jar SHA-256:
  `03a883d615af2152672ca3861d98334fee9e6848ae8ed227a1d0e7f98619d73d`

The restored 32-bit linker, VNDK, libraries, and `app_process32` file remain
available for standalone Fold2 vendor executables and later diagnosis; only
the Android application zygote contract is returned to q7q's native 64-bit
configuration. The preceding network, HWUI and vibrator boot-through changes
remain intact. Android vibration therefore remains intentionally unavailable
in this diagnostic image. Fresh DEX disassembly confirms the ABI-specific
boot-complete call and the retained vibrator-service skip. Checksums, ext4
filesystems and generated super metadata passed; dynamic-partition headroom
remains `468082688` bytes.

## q7q-test12 private boot-complete API correction (2026-08-04)

The preceding image removed the secondary-zygote socket failure, but every
captured post-boot system_server failure now terminates at the replacement
call itself:

`java.lang.IllegalAccessError: Method 'void android.os.ZygoteProcess.bootCompleted(java.lang.String)' is inaccessible to ActivityManagerService`

The q7q framework declares `bootCompleted(String)` as a private helper. Only
the public no-argument `bootCompleted()` method inside `ZygoteProcess` may call
it. Calling the private helper directly from services.jar was therefore an
invalid cross-class access and is the direct cause of the q7q-test12 hot-reboot
loop at `wm_boot_animation_done`.

The corrected image starts again from the vibrator boot-through base, so
ActivityManagerService and services.jar retain their original public
`bootCompleted()` call. The public method implementation in framework.jar
classes3.dex is changed to call its own private helper with `arm64-v8a`; no
private API crosses the framework/services class boundary. The q7q `zygote64`
and arm64-only application ABI settings are retained.

Controlled image:

- `out/f2q_q7q_zygote64_publicboot_direct/super.img`
- SHA-256: `d2bd3b77830d60a9572f8f0fd9ff090ec91e7c41526b6b5fd9714bd8f55dce47`
- Size: `10817110016` bytes
- Base: `f2q_q7q_vibrator_skip_direct`
- Original framework.jar SHA-256:
  `fac2136a35e9f723b713fa95b1cb062192f5b8c5463ab75889cf1bfdf11454f0`
- Patched framework.jar SHA-256:
  `03476537ff91c84387e04b777ca8a1d915e7b8bf25d4897ed68bcddbcb45007e`
- Unmodified public-call services.jar SHA-256:
  `9733ccabc7c7b4fa79881d174f9bf9c0c9c8a7cbf4bbad430fbb15332ebc9579`

Fresh disassembly from the completed image confirms that ActivityManagerService
calls the public no-argument method, while only ZygoteProcess itself invokes
the private ABI-specific helper. The system properties expose arm64 only,
vendor selects `zygote64`, all four super partitions are present, and the final
super checksum passes. The Fold2 ARM runtime files remain for standalone
vendor executables. The vibrator-service boot-through skip is unchanged, so
Android vibration remains unavailable in this diagnostic build. Dynamic
partition headroom remains `468082688` bytes.

## Vibrator, Bluetooth and Chinese Smart Manager correction (2026-08-10)

The first stable q7q boot exposed one shared framework failure behind two
apparently separate symptoms. Android's vibrator services were absent because
the earlier boot-through diagnostic had skipped `VibratorManagerService`.
Every Bluetooth connection-state change then called
`BtHelper -> VibratorManagerInternal.updateWatchConnectionState()` with a null
internal service and killed system_server. Three Dropbox records captured the
same `NullPointerException` at the Bluetooth connection event.

The imported AIDL vibrator binary and V3 library are byte-identical to the
previously vibration-working Fold4-port build. Its executable xattr, however,
was generated as `hal_allocator_default_exec`; the dynamic linker consequently
reported the physically present V3 library as unavailable. The q7q face HAL
had the same wrong allocator label and independently restarted every five
seconds.

Controlled repair image:

- `out/f2q_q7q_vibrator_bt_smartmanager_direct/super.img`
- SHA-256: `38cef0b58dee750c13410d11d6f07b1b974a6633ceb6b18c2e100bf681f60e28`
- Size: `10817110016` bytes
- Base: `f2q_q7q_ipm_atlas_false_direct`
- Restored q7q services.jar SHA-256:
  `863fac7272da976fdc14e47ba61914a94c6bb06c9df3db3fcbc05df3c26a2b0b`
- Preserved compatibility framework.jar SHA-256:
  `55ba1bc17a6756c606352b72fc33b3af4db0d48159dd9221c906ea254864562c`
- Vibrator executable label:
  `u:object_r:hal_vibrator_default_exec:s0`
- Face executable label: `u:object_r:hal_face_default_exec:s0`

The original q7q `VibratorManagerService` lifecycle is restored. This should
both expose Android vibration and provide the non-null internal service used
by Samsung AudioService during Bluetooth connection changes. The unrelated
face HAL label correction removes its independent linker restart loop.

Only the two Chinese Smart Manager applications and their two dedicated
`com.samsung.android.sm_cn` permission files were removed:

- `/system/priv-app/SmartManagerCN`
- `/system/app/SmartManager_v6_DeviceSecurity_CN`

`SmartManager_v5`, the normal Samsung Device Care base, remains present. The
completed super was unpacked again; all four embedded images matched their
build inputs, system and vendor passed read-only e2fsck, the two service labels
and framework hashes matched, and the Chinese packages were absent.

Live media diagnosis was kept separate from this repair. An MP3 session opened
the compressed-offload speaker path on PCM device 7, while an Ogg session
opened the deep-buffer speaker path on PCM device 0. Both sessions were active,
unmuted and error-free in AudioFlinger, but neither used the primary PCM device
24 used by working system/boot sounds. This isolates the remaining media issue
to the media-only offload/deep-buffer path or its DSP/mixer calibration rather
than AudioService mute state. No speculative audio-policy change is included
in this image.

The media comparison was extended against the previously working
`f2q_vibrator_aidl_direct` Fold4 port. All 174 vendor-side audio files are
byte-identical, including `audio_policy_configuration.xml`, the Fold2 mixer and
calibration files, and `audio.primary.default.so`. System/product audio
properties are also identical except for the donor Dolby extractor revision
(`3.10` versus q7q `3.13`); the apparent effect-config differences are only
line endings. The substantive generation change is in q7q's native Samsung
audio stack, notably SoundBooster `2070` in place of Fold4 `1100`.

Temporarily disabling compressed offload moved MP3 playback from PCM device 7
to the same PCM device 0 deep-buffer path used by decoded Ogg media. The track
remained active, unmuted, error-free, and AudioFlinger recorded non-zero signal
power. This confirms that offload alone is not the common failure. Forcing
`audio.deep_buffer.media=false` requires audioserver reinitialization; the live
test did not restart audioserver because the service kill was denied, and all
temporary properties and media volume were restored. A future controlled
audio image can disable both offload and deep-buffer selection at boot to test
the known-working primary PCM path without replacing the byte-identical Fold2
vendor audio stack.

## q7q-test13 Samsung IPM Atlas rune compatibility (2026-08-04)

The public boot-complete correction works: q7q-test13 reaches
`wm_boot_animation_done`, sets `sys.boot_completed=1`, completes the system
user unlock sequence, and begins home-screen initialization. The observed
system_server restarts occur approximately five to six seconds later. Both
captured failures are identical:

`java.lang.NoSuchFieldError: No field SYSPERF_ATLAS_ENABLE of type Z in com.samsung.android.rune.CoreRune`

The exception originates in
`SecIpmManagerServiceImpl.handleInitIpm()` on `IpmMainHandler` and immediately
terminates system_server. Fold7 CoreRune does not declare this Fold4-era Atlas
performance rune, while the earlier Fold4 framework reference declares it as
a public static final boolean and calculates it from device conditions.

The controlled bridge adds only the missing public boolean rune to q7q
CoreRune with value `false`. Fold2 should not select an unsupported Atlas
performance path. No IPM service, boot-complete callback, package, or hardware
service is disabled or skipped.

Controlled image:

- `out/f2q_q7q_ipm_atlas_false_direct/super.img`
- SHA-256: `8b0635ab0f21579734ed946d5a426f7615d72a1af5a801db6c06133dfe0b3b02`
- Size: `10817110016` bytes
- Base: `f2q_q7q_zygote64_publicboot_direct`
- Original framework.jar SHA-256:
  `03476537ff91c84387e04b777ca8a1d915e7b8bf25d4897ed68bcddbcb45007e`
- Patched framework.jar SHA-256:
  `55ba1bc17a6756c606352b72fc33b3af4db0d48159dd9221c906ea254864562c`
- Preserved services.jar SHA-256:
  `9733ccabc7c7b4fa79881d174f9bf9c0c9c8a7cbf4bbad430fbb15332ebc9579`

Fresh disassembly from the completed image confirms the disabled Atlas field,
the ARM64-only public boot-complete path, and the original public AMS call.
The q7q `zygote64` properties, all four super partitions, ext4 filesystem and
final checksum pass verification. Android vibration remains unavailable due
to the retained VibratorManagerService boot-through diagnostic. Dynamic
partition headroom remains `468082688` bytes.

## q7q media audio cold-boot reproduction and SoundBooster v1100 image (2026-08-10)

A clean reboot reproduced the media failure without Bluetooth involvement.
YouTube opened the speaker deep-buffer path on PCM device 0, enabled the dual
speaker amp and DSM protection, loaded the Fold2 ACDB speaker calibration, and
delivered non-zero PCM data without underruns, but the device remained silent.
Ringtone and notification output remained available.

The same MP3 opened through Samsung SoundPlayer used compressed offload on PCM
device 7 and was audible immediately. After that offload session closed, the
same YouTube deep-buffer path became audible and subsequent application media
continued to work. This confirms a cold-boot initialization defect in the q7q
PCM effects state rather than Bluetooth routing, codec support, AudioService
mute state, speaker routing, DSM, or the Fold2 vendor audio HAL.

The q7q system initializes SoundBooster v2070 and SoundBoosterEQ on every
speaker PCM stage. Its boot log reports `SoundBooster_v20 Param mismatch` when
loading Fold2's `/vendor/etc/SoundBoosterParam.txt`, and it cannot load the
optional Fold tuning file. The previously working Fold4 system instead uses a
coherent SoundBooster v1100 chain without SoundBoosterEQ.

Controlled diagnostic image:

- `out/f2q_q7q_soundbooster1100_direct/super.img`
- SHA-256: `9b6d34befcee22c72fd7f66cc35c5246dc0b1c7e85e3e9aef21baa922b94083c`
- Size: `10817110016` bytes
- Base: `f2q_q7q_vibrator_bt_smartmanager_direct`
- Fold4 stage policy SHA-256:
  `07d3a2ab47dade4f97de3a16d62fccd1f4542b85eaa6dadd54af886e918c1035`
- Fold4 SoundBooster v1100 SHA-256:
  `0f0b8d7e155717a614c3be7c87c1f0174a3abbf40764f38f8dedee3ebb5dd16b`
- Fold4 v1100 wrapper SHA-256:
  `8387defa77d1f6669b5dd5c6a64c13eba0bfd6d3166f2a9972dda768227291e6`

Only `stage_policy.conf`, the SoundBooster wrapper, and its matching v1100
core were changed. The q7q v2070 and EQ binaries remain byte-identical but are
unreferenced by the Fold4 policy. The final super was unpacked again: every
embedded partition matched its build input, the system filesystem passed
read-only e2fsck, all three audio files and SELinux labels matched, the fixed
services/framework jars were preserved, and the Chinese Smart Manager
packages remained absent.

Runtime result from `q7q-test14`: **failed; do not flash this image again.**
The boot animation did not finish because audioserver crashed and restarted
roughly every five seconds. Twenty-eight captured audioserver tombstones have
the same SIGSEGV first frame:

`lib_SoundBooster_ver1100.so: SAG_BASS::Third_Harm_SetPar()`

The stack continues through `LoadParameter_File()` and
`SoundBoosterInit()`. This proves the Fold4 v1100 core cannot safely parse the
Fold2 vendor SoundBooster parameters in the q7q system, despite the wrapper
and stage-policy set being internally coherent. The v1100 transplant is
retired.

## q7q native SoundBoosterEQ bypass image (2026-08-10)

The follow-up image returns completely to the normal-booting q7q audio ABI.
It preserves q7q SoundBooster v2070, its q7q wrapper, and the installed q7q EQ
library byte-for-byte. Only the eleven `STAGE_EFFECT_SOUNDBOOSTER_EQ`
references in q7q `stage_policy.conf` are bypassed; the surrounding policy and
all ordinary SoundBooster stages remain active. No Fold4 audio binary is
present.

This isolates the separate PCM EQ stage because the cold-boot silent path uses
it, while the successful compressed-offload wake-up bypasses it. It avoids the
proven-incompatible v1100 parameter parser.

Controlled image:

- `out/f2q_q7q_sbeq_bypass_direct/super.img`
- SHA-256: `3204b5aa56d425161ec922e75757abc2a0294476a080bde83038c86ca9005f86`
- Size: `10817110016` bytes
- Base: `f2q_q7q_vibrator_bt_smartmanager_direct`
- Patched q7q stage policy SHA-256:
  `a84ccba71a17674a01fa4f17de782099c3c6521dcf467f903bf06408633901a9`
- Preserved q7q SoundBooster v2070 SHA-256:
  `a06d704e7b0066732bbae7c9ee6572af329b5a260fb34468fdc3ba4c4e507ac5`

The final super was unpacked again. Every embedded partition matches its
build input, ext4 passes read-only e2fsck, all EQ references are absent from
the active policy, v1100 is absent, the fixed services/framework jars are
preserved, and the Chinese Smart Manager packages remain absent.

### q7q-test15 flash-content audit

`q7q-test15` is not a runtime result for the EQ-bypass image. Recovery was
connected and the files were pulled directly from the mounted live system
partition. The installed content exactly matches the retired v1100 image:

- installed `lib_SoundBooster_ver1100.so`:
  `0f0b8d7e155717a614c3be7c87c1f0174a3abbf40764f38f8dedee3ebb5dd16b`
- installed SoundBooster wrapper:
  `8387defa77d1f6669b5dd5c6a64c13eba0bfd6d3166f2a9972dda768227291e6`
- installed stage policy:
  `07d3a2ab47dade4f97de3a16d62fccd1f4542b85eaa6dadd54af886e918c1035`

All 32 new tombstones consequently show the same v1100
`SAG_BASS::Third_Harm_SetPar()` crash. The intended EQ-bypass image has stage
policy hash `a84ccba71a17674a01fa4f17de782099c3c6521dcf467f903bf06408633901a9`,
q7q wrapper hash `20ee8b35fdaa61923b4d986776a416e6e2693723ab2325a3b9be758b863fb96c`,
and contains no v1100 file. It still requires its first device test.

The correctly transferred EQ-bypass image subsequently completed boot. This
confirms the q7q v2070 stack remains boot-safe with only the separate
SoundBoosterEQ policy references bypassed. Cold-boot media output still needs
to be evaluated independently.

## LUC CIDManager activation loop and boot header bridge (2026-08-10)

The persistent Korean "Service provider update" overlay belongs to
`com.samsung.android.cidmanager` 5.0.08, not an LG carrier application. A
controlled button reproduction selected mapped activation ID `LUC`, then
failed after two synchronous five-second VaultKeeper operations:

- `SetActivatedId : Failed to write AID in VK, Result: -1`
- `vk read failed null`
- final activation result `501`

The device has the VK block partition and running VaultKeeper services. The
relevant state is instead incomplete: `ro.boot.activatedid` is empty while
`persist.sys.prev_activatedid=LUC`. q7q CIDManager's decoded implementation
only writes VaultKeeper when `ro.boot.activatedid` is empty. When that boot
property is present it takes its explicit `bypass if already set` path and
continues normal activation completion.

Controlled boot image:

- `kernel/boot-f2q-hwfix-lucaid.img`
- SHA-256: `9138519454a3f24e812885c8419021106b93bad4f4051a916fadbecf88c17182`
- Size: `71303168` bytes
- Base SHA-256:
  `fff678fbe844fb5219031f010b7ecce39b76b7b48cc81c42625fd75b20488e3e`
- Sole header addition: `androidboot.activatedid=LUC`

The output was unpacked again. Kernel, ramdisk, and DTB hashes match the base;
header version, OS version, patch level, page size, product name, image size,
Samsung SEAndroid trailer, and VBMETA footer remain present. No carrier-id,
sales-code, or other cmdline property was changed.

Runtime result: the LUC diagnostic boot supplied `ro.boot.activatedid=LUC`.
After one real restart, CIDManager completed activation and its overlay did
not return. This confirms the missing boot property as the cause. Because the
header value is hardcoded, this image is diagnostic-only and not suitable for
a multi-CSC release.

## Generic activated-id bridge and China Firewall removal (2026-08-10)

The release-oriented bridge is in system init rather than the boot header. At
early init it derives `ro.boot.activatedid` from the device's existing
`ro.boot.sales_code`. LUC therefore resolves to LUC, KOO to KOO, and the same
kernel/boot image remains usable across Fold2 CSC variants.

The recurring "Identify unsaved numbers" consent overlay was traced to
`com.sec.android.app.firewall/.spamfilter.settings.SpamFilterLegalInfoActivity`.
Its text explicitly discloses Tencent, Beijing Teddy Bear, and OAID data use.
The containing `Firewall.apk` is the China-specific number-identification
suite. It is absent from both Fold2 LUC stock and the earlier Fold4 KOO port.
The package was removed as a whole; the separate Korean
`BlockedNumberProvider` and `SmartCallProvider` packages are retained.

Controlled image:

- `out/f2q_q7q_sbeq_korcsc_direct/super.img`
- SHA-256: `e53018f2e488e2678dab867c62971a38ab1d13415e5737d12519b7e84112a3d2`
- Size: `10817110016` bytes
- Base: `f2q_q7q_sbeq_bypass_direct`
- Added: `system/etc/init/f2q-activatedid-bridge.rc`
- Removed: `system/priv-app/Firewall`

The completed super was unpacked again. All embedded partitions match their
inputs, ext4 passes read-only e2fsck, the China package is absent, both Korean
call-management packages are present, the dynamic bridge and SELinux label
match, and all audio/framework/Device Care fixes remain byte-identical.

## q7q cold-boot media offload transition probe (2026-08-10)

The boot-tested SoundBoosterEQ-bypass system remains silent for ordinary
media after a clean boot. This rejects the standalone q7q SoundBoosterEQ
stage as the cause.

A controlled Samsung SoundPlayer MP3 launch opens compressed offload PCM 7
successfully. During that transition AudioFlinger/HAL performs several
operations that are absent from the already-running silent deep-buffer path:

- `l_stream_music_active=true`
- `AudioFlinger::DualSpkControl ... enableAmp 1`
- `l_dual_speaker_amp_left_power_enable=true`
- removal of `upper-spk-amp-mute`
- SoundBooster rotation/flat-motion and `UPSCALER 2` programming
- SoundAlive offload effect refresh (`VSP`, `DLB`, `SA`, and `VM`)

The direct output is routed to the speaker with ACDB 13, DSM and
VI-feedback are enabled, and compressed data is accepted without underrun.
After pausing, the offload thread closes normally. This points to a missing
one-time Samsung audio/effect/amp initialization rather than missing PCM data,
an AudioPolicy route failure, or the bypassed EQ stage.

SoundAlive exposes an explicit effect-refresh receiver. Its required form was
confirmed from the installed APK and live-tested without a receiver crash:

```text
am broadcast -a com.sec.android.app.soundalive.SET_EFFECTS_SETTING \
  -n com.sec.android.app.soundalive/.receiver.SoundAliveReceiver \
  --es EQUALIZER 0
```

It starts SoundAlive and reapplies the balanced EQ to all three native
SoundAlive instances. The next clean-boot experiment must run only this
broadcast before opening any offload media, then test an ordinary deep-buffer
source. That separates SoundAlive initialization from the compressed-offload
and dual-speaker amplifier initialization paths.

The clean-boot separation was completed. Reapplying only SoundAlive EQ did not
restore media. Directly removing `upper-spk-amp-mute`, setting
`l_stream_music_active=true`, applying all three UHQ routing/format values, and
programming `SB flatmotion=1` also left YouTube silent. None of those tests
opened compressed offload. The offload stream itself remains the only observed
operation that repairs later deep-buffer playback.

## q7q Fold2-order media stage diagnostic (2026-08-10)

Ringtone/notification/boot audio and application media do not use the same
software output path. Working system sounds primarily use the primary/fast
mixers, while ordinary application media uses the speaker deep-buffer output.
Both terminate at the same physical Fold2 speaker, but the deep-buffer path
has its own Dolby, SoundAlive, AdaptSound, and SoundBooster integrated chain.

The q7q deep-buffer policy runs Voice Booster before Dolby and places
SoundBooster before SoundAlive. Fold2 stock omits Voice Booster on the normal
media path, runs SoundAlive in `integ-pre`, and places SoundBooster after
AdaptSound in `integ-post`. A controlled diagnostic changes only these three
lines in q7q's speaker deep-buffer `normal` block. It deliberately retains q7
SoundBooster v2070, does not install the crashing Fold4 v1100 binary, retains
the boot-tested EQ bypass, and does not add Fold2's obsolete TDM global stage.

Controlled image:

- `out/f2q_q7q_media_stageorder_direct/super.img`
- SHA-256: `6351ebbf1402ad30a9caa92300763f7d087a67cba655fb01b535176f118d3c88`
- Size: `10817110016` bytes
- Base: `f2q_q7q_sbeq_bypass_direct`
- Patched stage-policy SHA-256:
  `57320a0af1a0140ae862fad072534068f61f7cc60b41cc94320297506bc3d0a6`

The completed super was independently unpacked. All four embedded partitions
match their build inputs, system ext4 passes read-only e2fsck, the media-only
stage assertions pass, q7 SoundBooster v2070 and its wrapper are preserved,
SoundBoosterEQ remains bypassed, and Fold4 v1100 is absent.

Runtime result: the media stage-order image boots but cold-boot YouTube remains
silent. Voice Booster placement and the SoundAlive/AdaptSound/SoundBooster
integrated ordering are therefore excluded.

Root mixer access then allowed an exact active-state comparison. YouTube was
kept actively writing non-zero PCM to I/O 21/PCM 0 both before and after the
known offload wake-up. The cold-silent and warm-audible deep-buffer states
differed in only these stable controls after dynamic telemetry was excluded:

- `UPSCALER`: `0` -> `2`
- `Audio Stream 7 App Type Cfg`: `0 0 0 0 0` ->
  `69941 13 48000 55 0`
- right/left Cirrus `CSPL_STATE`: `2` -> `0`

The warm state also reported non-zero left/right speaker output power while
the same YouTube AudioTrack remained active. AudioFlinger showed identical
deep-buffer format, speaker device, volume, nonzero ready frames, and no
underruns in both states. The offload route did not need to re-enable the
already-active shared speaker device; instead it programmed PCM 7's DSP app
type and `UPSCALER=2`, after which both Cirrus speaker-protection DSPs left
state 2 and entered state 0. These controls are now the minimal cold-boot
initialization candidates.

Directly writing `UPSCALER=2` is rejected while compress PCM 7 is closed.
An ID3-free 35-second silent 48 kHz stereo MP3 was therefore generated at
`work/f2q_silent_raw.mp3` and copied to
`/data/local/tmp/f2q_silent_raw.mp3`; vendor `/vendor/bin/cplay` can open it
directly on card 0, device 7 without involving AudioPolicy or Dolby.

A manual warm-up opened that file on PCM 7, temporarily programmed the PCM 7
app type and offload mixer route, and set `UPSCALER=2`. The temporary route was
then disabled and the app type reset before YouTube was started. YouTube's
ordinary deep-buffer stream became audible; both Cirrus `CSPL_STATE` values
changed from `2` to `0`. At capture time the temporary MultiMedia4 route was
off and the app-type value was effectively reset, while `UPSCALER=2` remained.
This proves that an inaudible direct PCM 7 warm-up can repair cold-boot media
without playing a user-visible offload track or changing Dolby settings.

The next clean-boot test will run only silent `cplay` plus `UPSCALER=2` before
the first media playback. If that reproduces the result, this is the minimal
boot-time initializer and the broader route/app-type writes are unnecessary.

That clean-boot test succeeded. Before any media playback the device reported
`UPSCALER=0`, an empty PCM 7 app type, and `CSPL_STATE=2` on both Cirrus DSPs.
Opening only the raw silent MP3 on PCM 7 and setting only `UPSCALER=2` made the
first subsequent YouTube deep-buffer stream audible. During audible playback
both Cirrus DSPs entered `CSPL_STATE=0`, while the PCM 7 app type remained
empty and both MultiMedia1/MultiMedia4 controls remained off. The broader
route and app-type writes are conclusively unnecessary.

Automated diagnostic image:

- `out/f2q_q7q_media_warmup_direct/super.img`
- SHA-256: `6826cd33425e5088f83a2bdc96f5d3d2e1ee8044089c66bf700fed197e1b551b`
- Base: `f2q_q7q_sbeq_bypass_direct`
- Starts after `sys.boot_completed=1`
- Uses the currently installed Magisk `/product/bin/su`
- Opens the silent raw MP3 directly on compress PCM 7
- Sets and verifies only `UPSCALER=2`
- Holds the silent stream for eight seconds, then closes it
- Does not alter app type, MultiMedia routes, Dolby, volume, or stage order

The generated super was independently unpacked. System, product, and ODM are
byte-identical to the stable EQ-bypass base; vendor ext4 passes read-only
e2fsck; the silent asset, init rc, script contents, file labels, retained q7
`cplay`, and absence of route/app-type writes all pass verification. This is a
boot-automation diagnostic and currently depends on Magisk; a final rootless
implementation should move the same operation into an audio-HAL-authorized
native helper after runtime behavior is confirmed.

Runtime result for the first automated image: media remained silent because
the warm-up script never ran. Init registered the service and trigger, but
rejected its executable before launch:

`/product/bin/su` was labeled `system_file` and had no SELinux domain
transition from `init`. The service command also used MagiskSU without `-c`,
so its remaining arguments would not have invoked the script correctly. ADB
execution with the corrected `su 0 -c` form ran the exact installed script,
produced `UPSCALER=2` and `CSPL_STATE=0` on both DSPs, confirming there is no
fault in the warm-up payload.

Corrected automated image:

- `out/f2q_q7q_media_warmup_v2_direct/super.img`
- SHA-256: `0191e52e5b66c58837233650fbc7d55c21e3ee0b26700a05be0f1df3097a55a0`
- Runs `/vendor/bin/sh /vendor/bin/f2q-media-warmup.sh` directly with
  `seclabel u:r:magisk:s0`
- Removes the invalid init-to-`system_file` executable transition
- Retains the byte-identical proven warm-up script and silent MP3

The v2 super was independently unpacked and verified. System, product, and ODM
remain byte-identical to the stable EQ-bypass base; vendor ext4 passes
read-only e2fsck; the corrected service executable, explicit Magisk domain,
property trigger, file labels, silent asset, and absence of route/app-type
writes all pass assertions.

The Magisk implementation is diagnostic only. MagiskSU is supplied by the
patched boot environment rather than the kernel itself, but v2 still cannot
operate with an unrooted boot because its init service explicitly enters the
Magisk SELinux domain.

A rootless replacement was implemented and tested interactively. A static
ARM64 orchestration helper directly forks the byte-identical q7 `cplay` and
the byte-identical system `tinymix`; it does not use a shell, `su`, Magisk, or
reimplemented Qualcomm compress/mixer ioctls. The helper retries `tinymix 276
2` while q7 `cplay` opens PCM 7, holds the proven state for eight seconds, then
terminates the silent child. The exact helper completed successfully on the
device and reported `PCM7 initialized, UPSCALER=2`.

Rootless image:

- `out/f2q_q7q_media_warmup_rootless_direct/super.img`
- SHA-256: `e15210813d7193892cb175161562e3ed664743a02fdc0ea0676c595d560b5ae1`
- Base: `f2q_q7q_sbeq_bypass_direct`
- Service user/group: `audioserver:audio`
- Service domain: automatic `hal_audio_default` transition through
  `hal_audio_default_exec`
- No `su`, Magisk domain, vendor shell, PCM app-type write, or route write

The rootless super was independently unpacked. System, product, and ODM are
byte-identical to the stable base; vendor ext4 passes read-only e2fsck; helper,
q7 cplay, system tinymix, silent asset, static linkage, init service, file
ownership, and all three audio-HAL executable labels pass verification.

An additional active-state effect dump found a separate processing issue.
SoundAlive receives real EQ band values and is audible, while Dolby reports
`EN=1` but `Bypass=-1` and `ProcEN=-1`; VoiceBooster retains an all-zero preset.
The framework does deliver `g_effect_dolby_enable=1` and
`g_effect_dolby_volume_leveler=7`, so Dolby, volume normalization, and voice
clarity are not failing at the UI/settings layer. Their q7 processing
initialization or binary/config pairing must be diagnosed separately from the
PCM7 cold-boot fix.

Runtime result for `f2q_q7q_media_warmup_rootless_direct`: media remained
silent. Init successfully started the static helper in `hal_audio_default`,
but it exited with status 1 after only 12 ms and `UPSCALER` remained 0. The
same helper had succeeded in the Magisk domain. This isolates the rootless
failure to the helper's attempt to fork/exec its cplay/tinymix children from
inside `hal_audio_default`; no init executable transition or payload file
integrity failure occurred.

The rootless mechanism was therefore simplified again. Init now owns the
entire sequence and directly starts every `hal_audio_default_exec` binary:

1. start q7 cplay on compress PCM 7;
2. start a static one-second delay service;
3. when the delay stops, start `tinymix 276 2`;
4. when tinymix stops, stop cplay.

No HAL process forks or execs another binary, and no shell, `su`, Magisk
domain, app-type setting, or MultiMedia route is used.

Init-sequenced rootless image:

- `out/f2q_q7q_media_warmup_initseq_direct/super.img`
- SHA-256: `9cbbb8b538a5db490abb0e2e54e1cf7c6f6b463d3bc81c41c5cc45402ca05a67`
- Base lineage: stable EQ-bypass -> rootless payload copies -> init sequence

The completed super was independently unpacked. System, product, and ODM are
byte-identical to the stable base; vendor ext4 passes read-only e2fsck; the
failed orchestration helper is absent; q7 cplay, system tinymix, static delay,
all audio-HAL labels, and all three init property transitions pass assertions.

Runtime result: the init-sequenced rootless image boots and ordinary media is
audible on the first cold-boot playback without any ADB or `su` action. All
three init services finish and report `stopped`. The confirmed audible state
is:

- `UPSCALER=2`
- right and left Cirrus `CSPL_STATE=0`
- `Audio Stream 7 App Type Cfg=0 0 0 0 0`
- MultiMedia1 route off
- MultiMedia4 route off

This closes the cold-boot media-silence issue with the intended minimal,
rootless mechanism. Neither a forced audio route nor an app-type write is part
of the solution. The remaining Dolby/normalization/voice-clarity behavior is a
separate effect-processing compatibility issue.

The effect-processing issue was then traced at runtime with media active and
all three UI controls toggled. The controls and framework are not bypassing
the engines:

- Voice clarity changes `g_voice_booster_preset_all` from all zeroes to
  `2,0,0,0,0,0,0,0`.
- `sag_ai_sound_sep_a64` reports `Exe non-bypass` at 48 kHz.
- Dolby transitions through `PREROLL_ACTIVE` into `DAP_ACTIVE` and continuously
  calls `DlbDap2Process::process()` in processing mode 10.
- Volume normalization changes DAP `dvla` between 0 and 7.

The Fold7 VoiceBooster, its embedded SAG model library and Samsung TFLite
runtime are present, load successfully and execute. The lack of a perceived
effect is therefore downstream of UI state and engine activation. A file-level
audit also showed that current Fold7 effect libraries are byte-identical to
the donor; the only deliberate policy difference is removal of the crashing
SoundBoosterEQ stage.

Because the same inaudible Dolby behavior occurred with the earlier Fold4
base, the first hardware-tuning candidate replaces only the 64-bit Dolby DAP
engine with the Fold2 stock implementation. The current One UI 8 policy,
SoundAlive app, Fold7 VoiceBooster AI stack, working v2070 SoundBooster and
rootless PCM7 initialization remain unchanged. The Fold2 vendor-side Dolby
stack was already in use.

Hardware-profile effect candidate:

- Windows output: `build/out/f2q_q7q_effects_f2dolby_direct/super.img`
- SHA-256: `58e996f11dd42e06a3951573963160794843a7da7d2878a9942e46d94b99d8f4`
- New `/system/lib64/libswdap_legacy.so` SHA-256:
  `cb74590b6f4871fb916ea6697fa080d39a393457c9dad81b05e1bfdbdf2c36cc`
- Preserved VoiceBooster SHA-256:
  `ed5902ed77029b12ebbcb9b292d92a32ff3fdea7dfb31e193a3a1b284e49c174`

The candidate passed ext4 read-only checking, dynamic-partition metadata
inspection, complete super checksum verification, target library/policy
assertions, and byte comparison of unchanged vendor, product and ODM images.

Runtime result for `f2q_q7q_effects_f2dolby_direct`: cold-boot speaker media
playback remains reliable. Dolby processing is audible in Movie mode, Voice
Clarity is audible, and the existing equalizer remains functional. Volume
normalization is source-dependent and was not independently quantified.

## Display, performance profile and Quick Share follow-up

The One UI 8 display controls are not uniformly broken:

- Environment Adaptive Display is operational. Toggling `ead_enabled` starts
  the Fold2 TMD4907 CCT sensor, reads ambient CCT/lux, calculates a 5700 K
  target and drives DisplayAiqe/mDNIe through the expected level transition.
- `Extra brightness` is exposed by the Fold7 floating feature, but Fold2 stock
  does not declare `SEC_FLOATING_FEATURE_LCD_SUPPORT_EXTRA_BRIGHTNESS` at all.
  Both current and Fold2 framework resource arrays contain a neutral 1.00
  DisplaySolution factor. This control should therefore be removed for a
  stock-faithful Fold2 profile unless an explicitly experimental brightness
  emulation is desired.
- The One UI 8 and Fold2 SDHMS implementations both observe
  `sem_low_heat_mode` and acquire the same SemDvfsManager hint 0x384. Their
  SSRM `PerformanceRestrictionObserver` and `DeviceStatus` restriction logic
  are functionally equivalent. Static cpufreq maximum values are not a valid
  assertion for this mode because the implementation suppresses boost/thermal
  behavior rather than permanently rewriting scaling_max_freq.

Quick Share radio discovery, Samsung Account access and GMS identity
classification all work. GMS identifies nearby account devices with
`isSelfShare=true`, but Samsung MCF cannot construct its cloud-MDE identity:

- `BluetoothApi.getLocalIrk(): invalid irk=`
- `CloudMdeSdkInterface.getScaMde(): not ready`
- `CloudMdeRepository: Invalid AccountId`

The Bluetooth APEX reports the read-only aconfig flag
`com.android.bluetooth.flags.non_zero_local_irk=false`, and
`BluetoothAdapter.semGetLocalBleIrk()` consequently receives no usable
16-byte IRK from `IBluetooth.getLocalBleIrk()`. MCF then classifies a discovered
Samsung laptop as `ANONYMOUS`; `myDevices` and contact lists stay empty. This
is below ShareLive, Mobile Service and account permissions. A correct ROM fix
must repair the Bluetooth APEX IRK behavior (or use a compatible coherent
Bluetooth APEX), not fake a random IRK in ShareLive/MDX because that would not
match the controller identity used for BLE resolution.

## Fold2 Light-mode and conservative Extra Brightness candidate

Runtime inspection with the Light profile enabled showed that the inherited
SDHMS hint 0x384 did not change the Fold2 CPU/GPU ceilings. A focused bridge
was therefore added inside SSRM's existing
`PerformanceRestrictionObserver`. It uses Samsung's own `SemDvfsManager`
resource path rather than `su`, an init shell or direct sysfs writes:

- CPU_MAX type 0x0d is acquired at 2,841,600 kHz.
- GPU_MAX type 0x11 is acquired at 587,000 kHz.
- These are Snapdragon 865-level prime/GPU clocks for the Fold2's 865+.
- Silver and gold CPU maxima remain unchanged because they are already below
  the common CPU_MAX ceiling.
- Disabling Light mode releases both DVFS locks; boot-time persisted state is
  applied by the existing content observer initialization.

The exposed Extra Brightness control is retained as an experiment. Its inert
DisplaySolution array value is changed from 1.00 to a conservative 1.15 using
the static Fold2 framework overlay. The existing Fold2 HBM controller,
3000-lux gate, framework brightness ceiling and thermal protection remain
unchanged. This does not force the panel's advertised 1500-nit HDR peak.

Candidate:

- Windows output: `build/out/f2q_q7q_light865_hbm115_direct/super.img`
- SHA-256: `1f520f4992cab6c0cea440cb307890e3e56b61c6b1082486ca7ebdb63af7f017`
- Patched SSRM SHA-256:
  `9fd23c2d2835b6c10e43a8afc4baf8ba9087ec57c9191413b700b6bbecd318d8`
- Patched framework overlay SHA-256:
  `2bd89ab539f272242d5198a493492c8ebddf1fc8ec822aa404b9f4776828856e`

The candidate passed smali assemble/re-disassemble validation, JAR archive
testing, overlay resource decode assertions, ext4 read-only checking,
dynamic-partition metadata inspection and complete super checksum generation.
Quick Share is deliberately unchanged in this focused image.

Runtime correction: v1 acquired CPU_MAX successfully but watched
`restricted_device_performance`, which remained `1,1` independently of the
One UI Light-profile toggle. The CPU lock therefore stayed active in both UI
states. The GPU request was also ignored because the Fold2 HyPer GPU resource
expects Hz rather than the legacy kHz-style value used by the first candidate.

Corrected v2:

- Watches and reads `global sem_low_heat_mode` directly.
- Acquires/releases both locks on that setting's content-observer callback.
- Keeps CPU_MAX at 2,841,600 kHz.
- Sends GPU_MAX as 587,000,000 Hz.
- Preserves the v1 1.15 brightness overlay and all other partitions.
- Windows output:
  `build/out/f2q_q7q_light865_hbm115_v2_direct/super.img`
- SHA-256: `4dae5f3e6ca36c7c200f990acd3979142ff8f6046955284d476b724743c3e850`

The v2 DEX and JAR passed assemble/re-disassemble and archive verification;
the system image passed ext4 checking and the final super metadata and full
checksum were regenerated. CPU-Z may continue showing the immutable hardware
capability table (3.09 GHz/670 MHz); acceptance is based on the policy/devfreq
ceilings and observed runtime clocks. If those still exceed 2.8416 GHz and
587 MHz while Light mode is active, the next fix must add a Fold2-specific
Power HAL Light profile rather than spoofing CPU-Z's capability display.

v2 runtime result: CPU_MAX correctly toggles between 3,091,200 and 2,841,600
kHz, but the Fold2 HyPer service accepts the GPU_MAX request without applying
it. Both 587,000 and 587,000,000 request values left KGSL `max_freq` at
670,000,000 Hz. A controlled root test proved the kernel node itself works:
`max_freq` changed 670 -> 587 -> 670 MHz and restored successfully.

The live vendor policy already grants `system_server` write access to
`vendor_sysfs_kgsl`; only the nodes' root:root 0644 DAC mode prevented direct
SSRM control. v3 therefore:

- Grants system:system 0664 access at init only to KGSL `max_pwrlevel` and
  `devfreq/max_freq`.
- Writes power level 1 and 587,000,000 Hz in Light mode.
- Writes power level 0 and 670,000,000 Hz in Normal mode.
- Leaves `thermal_pwrlevel` and the vendor thermal engine untouched.
- Uses no su, daemon, polling loop or runtime shell.

v3 candidate:

- Windows output:
  `build/out/f2q_q7q_light865_hbm115_v3_direct/super.img`
- SHA-256: `d5a4eb4ced48c5786d46096455cb7f7c4745d3d83f59f15f8f3c58169c697fd1`
- SSRM SHA-256:
  `cdc4d1a1986ad3d44c0241020944adb4cbf53c6035f00f7c81eeeb3750eff7c3`
- GPU init rc SHA-256:
  `ff23b7d02b48afa1c0e6c77a4abe4e7280886ecb0adad95e2dcfd97f10b0915d`

v3 runtime showed that the Light profile itself was correct but the persisted
boot state was only partially retained. CPU policy 7 was limited to 2,841,600
kHz and KGSL `max_pwrlevel` remained at 1, while a later GPU/power
initialization path restored only `devfreq/max_freq` to 670,000,000 Hz.
Toggling Light mode off and on after boot reapplied the intended 587,000,000
Hz ceiling.

v4 corrects that boot-order race inside SSRM:

- The existing content observer remains the authoritative toggle path.
- SSRM reapplies the persisted state at `BOOT_COMPLETED` and once more 10
  seconds later, after late GPU/power initialization.
- This is a bounded one-shot callback, not a polling service, root daemon,
  `su` script or persistent shell process.
- The intended Light state remains CPU 2,841,600 kHz, KGSL power level 1 and
  GPU 587,000,000 Hz; Normal restores 3,091,200 kHz, level 0 and 670,000,000
  Hz.
- CPU-Z's 3.09 GHz / 670 MHz labels can still represent the immutable SoC
  capability table. Runtime acceptance is based on policy/devfreq ceilings
  and observed frequencies, not those static labels.

v4 candidate:

- Windows output:
  `build/out/f2q_q7q_light865_hbm115_v4_direct/super.img`
- SHA-256:
  `31c758161b665edf924082fbd478b8ccb625ddb36ad6d04d03dbddf31985c16a`
- SSRM SHA-256:
  `976fd5f445ed326536c99e0596995f94ab5c1b035bd5aa1f4b6b73e338667618`
- SSRM DEX SHA-256:
  `7d6be19e966e03d279dfadd3b205173264cbb6220d48caddfbe35fbfa3d18372`

The v4 DEX passed API-34 assembly and full disassemble/reassemble validation;
the JAR passed archive testing, the system image passed ext4 checking, and
the final super image passed dynamic-partition metadata validation and full
checksum generation. All non-SSRM contents are inherited unchanged from v3.

## Fold7 Qualcomm location runaway correction

Runtime idle-temperature analysis found a persistent userspace restart loop,
not a CPU/GPU Light-profile fault. `com.qualcomm.location/.LocationService`
had crashed 39,721 times over roughly 28 hours. Each restart accumulated stale
`IzatService` records in ActivityManager and generated approximately 87,838
ActivityManager error lines in a two-second sample. This drove `system_server`
to about 200% CPU, `logd` as high as 96% and `statsd` to about 31%, with AP,
battery and skin temperatures reaching approximately 55, 42 and 47 degrees C.

The Fold7 package attempts to use the new Qualcomm LOCAIDL interface. Fold2
vendor does not publish it, producing:

```text
LOCAIDL service not available
ILoc AIDL is not supported!
```

`DebugReportService` then leaves `mDataPerPackageAndUser` uninitialized, while
`DebugReportingMonitor` calls it and terminates the persistent process with a
NullPointerException. Fold2 stock firmware contains neither this APK nor its
private QTI location SDK.

v5 therefore removes the complete unsupported Fold7 client set:

- `system_ext/priv-app/com.qualcomm.location`
- `system_ext/framework/com.qti.location.sdk.jar` and its oat/fs-verity files
- `com.qti.location.sdk.xml`, `com.qualcomm.location.xml`, and the package's
  privapp-permission XML

Manifest scanning confirmed that no other system APK consumes
`com.qti.location.sdk`, `services.core`, or `com.qualcomm.permission.IZAT`.
The Fold2 vendor GNSS HAL/libraries and `izat.conf`, Android FusedLocation,
Samsung NSFusedLocation/SLocation, and Google location components remain
unchanged. All v4 performance, display and hardware fixes are preserved.

v5 candidate:

- Windows output:
  `build/out/f2q_q7q_light865_hbm115_v5_locationfix_direct/super.img`
- SHA-256:
  `6777d9d718f79e5027ce3233942766b94bc86943becaed204e5808e8f4bc01a6`
- System image SHA-256:
  `9a1cfe7f6e14739291c14c1f9f64e987941a0134864f7458bb032b89ba5e8e3d`

The build asserts both absence of the unsupported package/SDK and presence of
FusedLocation, NSFusedLocation and SLocation in the final ext4 image. The
system image passed read-only ext4 checking, and the final super image passed
dynamic-partition metadata validation and full checksum generation.

v5 runtime rejected the broader removal scope. `q7q-test16` shows repeated
system-server fatal exits during `startOtherServices`:

```text
NoClassDefFoundError: com.android.server.ssrm.CustomFrequencyManagerService
```

The removed `com.qualcomm.location.xml` is misleadingly named: in addition to
the Qualcomm permission groups it publishes `services.core` from
`/system/framework/services.jar`. Removing it broke Samsung system-server's
SSRM class-loader path. The earlier manifest-consumer scan only covered APK
manifests and therefore did not detect this framework-side dependency.

v6 uses the conservative and correct scope:

- Starts again from the known-booting v4 image.
- Removes only `system_ext/priv-app/com.qualcomm.location`, including its own
  app oat artifacts.
- Retains `com.qualcomm.location.xml`, `com.qti.location.sdk.xml`, the privapp
  permission XML, the QTI location SDK JAR and all framework oat metadata.
- Retains the working v4 SSRM byte-for-byte.
- Retains Fold2 GNSS HAL, FusedLocation, NSFusedLocation and SLocation.

v6 candidate:

- Windows output:
  `build/out/f2q_q7q_light865_hbm115_v6_locationapk_direct/super.img`
- SHA-256:
  `63660113192582b356d64a659eed88d8acb090fff325845a3bd9882d2f48a811`

`q7q-test17` proved that v6 still failed with the same missing SSRM outer
class. A direct DEX class-list audit then identified the actual build defect:
while staging the new v4 boot Runnable, shell expansion of the `$` class-name
separator caused the Runnable smali file to overwrite
`CustomFrequencyManagerService.smali`. Consequently v4-v6 `ssrm.jar` files
contained `CustomFrequencyManagerService$Lifecycle` but not the outer
`CustomFrequencyManagerService` class. Existing ART state may have obscured
this defect during the first test, but a fresh compile cannot load SSRM.

v7 was rebuilt cleanly from the known-good v3 SSRM rather than any v4-v6
artifact. The intended boot-complete Light-mode callback files were applied
without relying on a `$` filename, and the build now hard-fails unless the
outer SSRM class is present:

- in the newly assembled DEX;
- after insertion into the patched JAR;
- after full JAR disassembly/reassembly;
- after extraction back from the final ext4 system image.

Only the incompatible `com.qualcomm.location` application directory is
removed. All QTI/Samsung shared-library XML, framework JARs, permission files,
and the working Fold2 location providers remain.

v7 candidate:

- Windows output:
  `build/out/f2q_q7q_light865_hbm115_v7_locationfix_direct/super.img`
- SHA-256:
  `832b6a069b1daa2a026f8e3240de8af921aa5e36e4c31c9adb7b5e9a19924204`
- Corrected SSRM SHA-256:
  `8e70581f09b97adfb35f82d6cb9ad8caae64f2e07904e48d946389d890c3eab8`
- Corrected SSRM DEX SHA-256:
  `6f3ca8d9bf4ff555550354645493f627d2333a92a8c77a1aa060203d0111d791`

## Fold2 GNSS fold-calibration compatibility probe

The booted v7 image exposed the Fold2 GNSS HAL successfully, but an outdoor
GPS Test session saw 22 satellites and used none. `dumpsys location` recorded
4,957 satellite-status messages, zero fixes, zero TTFF reports and zero
satellites used in a fix. Live logs confirmed that Android was requesting
high-accuracy GPS normally and that the Fold2 Qualcomm 2.1 GNSS service was
running.

The remaining system location applications were not Fold2 binaries. Their
runtime hashes matched Fold7 exactly:

- NSFusedLocation: `a740901667c3166dd48cff7afc5f0e48c181ab777515824c215ff1dd258feff1`
- SLocation: `4895093cd519144854fc563fb8360452d80bd1fdea502d084d0c7e5f9562aa02`
- FusedLocation: `5b13f0c78a1bc69dc64bf9b086af505ea1e46fa7f97f01c50b5a98414848af5d`

More importantly, the active system floating feature advertised
`SEC_FLOATING_FEATURE_GPS_CONFIG_FOLD_CALIBRATED=3`, identical to Fold7.
Fold2 stock advertises `0`. Samsung `GnssLocationProviderSec` interprets a
positive value as a supported RF calibration count and converts the unfolded
raw lid state `1` to that value before sending it to the GNSS HAL. Thus the
Fold7 framework selects `LID_STATE=3` on Fold2 hardware, whereas the Fold2
stock value `0` suppresses this injection entirely.

This is a narrower and more hardware-specific mismatch than the missing
`secgps.conf`. The latter also exists and causes the Qualcomm stack to log
`no secgps conf file, using defaults`; however, v8 deliberately does not
hardcode a carrier SUPL endpoint or alter Fold2 vendor configuration until
the RF calibration mismatch is tested independently.

v8 changes only this floating-feature value from `3` to Fold2 stock `0` on
top of the boot-proven v7 image. It does not replace framework or any location
APK, and retains the corrected SSRM and removal of only the incompatible
Fold7 Qualcomm location daemon.

v8 GNSS calibration candidate:

- Output:
  `build/out/f2q_q7q_light865_hbm115_v8_gnssfold0_final_direct/super.img`
- SHA-256:
  `26e9e1cfb5128be94e9326d60765244df38d78a64a0391c71632ebeba01153eb`
- System image SHA-256:
  `a099a28c2bec7efa238993b62e9e1a27863f709be454ccde0f349156abe069c7`
- Patched floating-feature SHA-256:
  `58778cf46ee658cff33ee7f547c9dd4bac39c7f09665ee69b8310eb3e61a949a`

The system image passed read-only ext4 checking. The final super image has
valid metadata for system, vendor, product and odm, and its full 10.8 GB
SHA-256 was independently recalculated after all build processes exited.

### v8 rejection and v9 metadata-safe rebuild

`q7q-test18` rejected v8. The device reached ADB during boot animation, but
SystemUI repeatedly terminated on its background thread:

```text
java.lang.NumberFormatException: empty String
  at java.lang.Float.parseFloat
  at com.android.systemui.statusbar.phone.IndicatorGardenAlgorithm.<init>
```

After the repeated SystemUI failures, Android requested
`reboot,RescueParty by com.android.systemui`. This was not a GNSS HAL or
kernel reset and therefore did not disprove the GNSS calibration hypothesis.

The build defect was `sed -i` replacing the ext4 inode for
`system/etc/floating_feature.xml`. The new v8 inode had no
`security.selinux` extended attribute, while v7 had
`u:object_r:system_file:s0`. SystemUI consequently received empty floating
feature strings and failed while parsing an indicator/cutout dimension.

v9 starts again from boot-proven v7 and writes the one-character content
change into the existing inode. The build asserts that inode, mode, owner and
SELinux context survive the edit, and verifies the final ext4 image with
`debugfs`. An independent file comparison confirmed that the only XML content
change from v7 is:

```text
SEC_FLOATING_FEATURE_GPS_CONFIG_FOLD_CALIBRATED: 3 -> 0
```

v9 GNSS calibration candidate:

- Output:
  `build/out/f2q_q7q_light865_hbm115_v9_gnssfold0_direct/super.img`
- SHA-256:
  `344d5e17159a2c4ab075243e73e70810d8f46a6bc67dc7e89fe2f60e1463ea8b`
- System image SHA-256:
  `3a2d4462f23ece6f52631e7853d7dea260b4b0a9d0860aa8d118f04730296b3c`
- Patched floating-feature SHA-256:
  `58778cf46ee658cff33ee7f547c9dd4bac39c7f09665ee69b8310eb3e61a949a`
- Final inode/mode/owner:
  `1274 / 0644 / 0:0`
- Final SELinux context:
  `u:object_r:system_file:s0`

The v8 image is rejected and must not be flashed. v9 supersedes it.

### v9 GNSS runtime result and v10 Quick Share identity fix

The metadata-safe v9 image boots normally. GNSS reception changed from a
single usable signal with no fix to 53 satellites in view, seven in use, a
3D fix and 9 m reported accuracy in the same test application. Framework and
HAL location delivery are therefore operational. A lower in-use count than
the Fold7 reference is not accompanied by a GNSS service crash or missing
provider; remaining variation is RF conditions, assistance freshness and
Fold2 antenna/receiver capability rather than the rejected Fold7 lid-state
calibration.

Quick Share tracing then exposed a deterministic Bluetooth identity failure:

```text
BluetoothApi.getLocalIrk(): invalid irk=
ScpmKeyStoreInterface: parameter is not set ... irk=
CloudKeyStoreImpl: Invalid AccountId
```

The Fold2 Bluetooth database already contained a correctly formatted local
IRK, and regenerating that key did not change the failure. The active library
mapping showed that Bluetooth loads `/system/lib64/libbluetooth_jni.so`, the
copy extracted by Astro, rather than the signed APEX path.

Astro's first Android 16 hex signature had collided with
`btif_storage_get_ble_local_key()`. It replaced the function's key-type
conditional branch with an unconditional jump to the return epilogue before
the status register was initialized. `getLocalBleIrkNative()` consequently
received a failure for every valid database key and returned null to Samsung
MCF.

The v10 patch restores only the original conditional branch. It does not
hardcode, log, regenerate or expose the device IRK. A live bind-mount test of
the resulting library produced the following successful sequence:

- `ScpmKeyStoreInterface` received an IRK of length 16.
- Samsung cloud account certificate retrieval completed.
- `syncMyDevices()` returned device details and classified peers as
  `MY_DEVICE`.
- Contacts visibility propagated as `CONTACT_ONLY` to MCF and `ALL_CONTACTS`
  to Google Nearby Sharing.
- Local contact-book/certificate upload completed successfully.
- Nearby peers were discovered as `isKnown=true` and `isSelfShare=true`.
- No further `invalid irk` or `Invalid AccountId` messages appeared.

v10 Quick Share identity candidate:

- Output:
  `build/out/f2q_q7q_gnss_qshare_v10_direct/super.img`
- SHA-256:
  `1c9bcfa9907557bede8a40c518456fcbbe6cb2a82008161aafb909b067bcd4e4`
- System image SHA-256:
  `2bcfb9c4910bbd037e626dc8a8bea179dc2b3e908e954b7cbd539085e12c0ef2`
- Patched Bluetooth JNI SHA-256:
  `6cb0bb8c5c192322500263a148abc2b52ea00d532cd47171fe54eb8eeeb5ee4b`
- Bluetooth JNI SELinux context:
  `u:object_r:system_lib_file:s0`

The patch changes three binary bytes in the system JNI, preserves its inode,
owner, mode and SELinux xattr, and leaves vendor, product and ODM byte-identical
to v9. The final ext4 image and complete super checksum were independently
verified.
