# One UI 8.5 stock profile

The `ui-8.5-stock` branch is based on `ui-8.5` and keeps Samsung stock
features and port-compatibility patches while avoiding unrelated global feature
injections.

The target firmware's CSC/OMC, prism resources, and Samsung Device Care
configuration are preserved. This branch does not import another device's
carrier configuration or write a common feature set into every CSC.

The following optional additions are excluded:

- Smart Manager China, AppLock, and Firewall payloads;
- Google Photos Pixel device spoofing;
- PUI theme overlays;
- AstroROM/ArcadeROM CSC, e-label, and build-display branding; and
- the global 0.85x WindowManager animation modification.

Samsung compatibility modifications such as the Knox app fixes, the secure
screen/screenshot-detection bypass, and the BSOH battery information patch are
retained. Sysscope uses Samsung's localized `sysscope_normal` resource so the
Official status follows the current system language.
