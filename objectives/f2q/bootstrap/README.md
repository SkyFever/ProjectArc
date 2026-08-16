# f2q bootstrap patches

Only patches proven necessary for reaching Android boot should be added here.

The first bootstrap build intentionally contains no device scripts. It combines:

- One UI 8 `system`, `product`, and `system_ext` from the Fold4 donor.
- `vendor`, `odm`, and related hardware partitions from the Fold2 target.
- `optics` and `prism` from the Fold2 target.
- The target VNDK compatibility layer.

Feature, debloat, Knox, encryption, camera enhancement, and cosmetic patches are
excluded from the bootstrap profile.
