# ==============================================================================
#
# MOD_NAME="Install Fold2 init compatibility rules"
# MOD_AUTHOR="ProjectArc f2q"
# MOD_DESC="Installs target identity and light-performance GPU node rules."
#
# ==============================================================================

SYSTEM_PATH="$(GET_PARTITION_PATH system)" \
    || ERROR_EXIT "Failed to get system partition path"
SYSTEM_INIT_DIR="$SYSTEM_PATH/etc/init"

install -D -m 0644 \
    "$ASTROROM/objectives/f2q/f2q-activatedid-bridge.rc" \
    "$SYSTEM_INIT_DIR/f2q-activatedid-bridge.rc" \
    || ERROR_EXIT "Failed to install Fold2 activatedid bridge"

install -D -m 0644 \
    "$ASTROROM/init/f2q-light-gpu.rc" \
    "$SYSTEM_INIT_DIR/f2q-light-gpu.rc" \
    || ERROR_EXIT "Failed to install Fold2 light-performance GPU rules"
