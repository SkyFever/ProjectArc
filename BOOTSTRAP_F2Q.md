# Galaxy Z Fold2 (SM-F916N/KOO) bootstrap

The first milestone is a clean boot test, not a feature-complete ROM.

## Partition strategy

| Role | Firmware |
| --- | --- |
| One UI 8 system donor | Galaxy Z Fold4 `SM-F936N/KOO` |
| Hardware target | Galaxy Z Fold2 `SM-F916N/KOO` |
| SM8250 reference | Note20 Ultra `c2q`, then S20+ `y2q` |

The bootstrap profile skips all AstroROM feature modifications. It keeps the
Fold2 hardware and CSC partitions, adds the target VNDK layer, and repacks the
minimum donor/target combination.

## Local firmware input

The `f2q` objective reads the pre-extracted Fold4 and Fold2 partition images
from firmware directories next to the ProjectArc checkout by default. No IMEI
or firmware download is needed. If either directory is elsewhere, set
`F2Q_DONOR_IMAGE_DIR` or `F2Q_STOCK_IMAGE_DIR` to its new WSL path.

The Fold4 images use compressed F2FS. The WSL kernel must support F2FS
compression and security xattrs during the first extraction. Once a complete
extraction cache exists, later builds reuse it.

Preserve those variables through `sudo`. First create unpacked debug images so
their sizes and filesystem metadata can be inspected without producing a
flashable package:

```bash
sudo -E bash build.sh --yes --debug --bootstrap --build f2q
```

After the debug images pass those checks, create the experimental flashable
package with:

```bash
sudo -E bash build.sh --yes --bootstrap --build f2q
```

Do not flash it until its super partition geometry and installer asserts have
been checked against the target.

See `F2Q_BUILD_REPORT.md` for the generated artifact, checksum, geometry, and
first-boot safety checks.
