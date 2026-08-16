# Stock-compatible bootstrap profile

The `ui-8.0-stock` branch includes an opt-in `--bootstrap` profile for
bringing up a new target without applying AstroROM's global feature
modifications. The profile rebuilds the workspace, runs only the platform and
device `bootstrap/` layers, and skips global APK/JAR feature patches.

```bash
sudo -E ./build.sh --yes --debug --bootstrap --build <device>
```

The build framework also supports device-controlled compatibility options for
local pre-extracted firmware, target CSC partitions, stock SELinux mappings,
stock VNDK APEX files, retaining a donor VNDK, and skipping the `twentyfive`
feature layer when the donor already provides the same-generation framework.
These options are disabled unless an objective explicitly enables them.

Additional common fixes in this branch cover:

- incremental workspace regeneration;
- F2FS extraction and SELinux xattr validation;
- duplicate dynamic-partition filtering;
- recovery script LF normalization;
- optional disabled-vbmeta generation;
- deterministic ext4 tool configuration; and
- removal of an unsafe Android 16 Bluetooth signature that could break local
  IRK retrieval and trusted-device or contacts discovery.
