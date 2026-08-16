# ==============================================================================
#
# MOD_NAME="Import the Android AIDL vibrator bridge"
# MOD_AUTHOR="ProjectArc f2q bootstrap"
# MOD_DESC="Exposes the Fold2 CS40L2X vibrator to the Android 16 framework."
#
# ==============================================================================

VENDOR_PATH="$(GET_PARTITION_PATH vendor)" \
    || ERROR_EXIT "Failed to get vendor partition path"
VIBRATOR_BLOB_ROOT="$BLOBS_DIR/dm3q/vendor"

declare -a VIBRATOR_SOURCES=(
    "$VIBRATOR_BLOB_ROOT/bin/hw/vendor.samsung.hardware.vibrator-service"
    "$VIBRATOR_BLOB_ROOT/lib64/vendor.samsung.hardware.vibrator-V3-ndk_platform.so"
    "$VIBRATOR_BLOB_ROOT/etc/init/vendor.samsung.hardware.vibrator-default.rc"
    "$VIBRATOR_BLOB_ROOT/etc/vintf/manifest/vendor.samsung.hardware.vibrator-default.xml"
)
declare -a VIBRATOR_TARGETS=(
    "$VENDOR_PATH/bin/hw/vendor.samsung.hardware.vibrator-service"
    "$VENDOR_PATH/lib64/vendor.samsung.hardware.vibrator-V3-ndk_platform.so"
    "$VENDOR_PATH/etc/init/vendor.samsung.hardware.vibrator-default.rc"
    "$VENDOR_PATH/etc/vintf/manifest/vendor.samsung.hardware.vibrator-default.xml"
)
declare -a VIBRATOR_HASHES=(
    f1e4ea1584158e37fb851ad9293ff1f9e654492e4f09c1011b201961655f3c8f
    9633b7c351c88a16060c673688ba5e91fe98cc4a403e48850c442e7ed9131540
    f0ed81dea4f2fc4c294275fa0b75bc727454232dc234483a92015e7d1be5d1f7
    af33d7b1dc1b81c06244c156c5c0b81d9a08fa38af252963dd655a05971e6491
)
declare -a VIBRATOR_MODES=(0755 0644 0644 0644)

for INDEX in "${!VIBRATOR_SOURCES[@]}"; do
    SOURCE="${VIBRATOR_SOURCES[$INDEX]}"
    TARGET="${VIBRATOR_TARGETS[$INDEX]}"
    EXPECTED_HASH="${VIBRATOR_HASHES[$INDEX]}"

    [[ -f "$SOURCE" ]] \
        || ERROR_EXIT "Missing vibrator bridge blob: $SOURCE"
    [[ "$(sha256sum "$SOURCE" | cut -d' ' -f1)" == "$EXPECTED_HASH" ]] \
        || ERROR_EXIT "Unexpected vibrator bridge blob: $SOURCE"

    install -D -m "${VIBRATOR_MODES[$INDEX]}" "$SOURCE" "$TARGET"
    [[ "$(sha256sum "$TARGET" | cut -d' ' -f1)" == "$EXPECTED_HASH" ]] \
        || ERROR_EXIT "Failed to install vibrator bridge blob: $TARGET"
done

# The F916N vendor policy already labels this exact service name as
# hal_vibrator_default_exec. Keep that stock rule and add only the userspace
# bridge needed by Android 16; Samsung's legacy HIDL extension stays present.
VENDOR_FILE_CONTEXTS="$VENDOR_PATH/etc/selinux/vendor_file_contexts"
[[ -f "$VENDOR_FILE_CONTEXTS" ]] \
    || ERROR_EXIT "Missing target vendor file contexts"
grep -F 'vendor\.samsung\.hardware\.vibrator-service' \
    "$VENDOR_FILE_CONTEXTS" | grep -q 'hal_vibrator_default_exec' \
    || ERROR_EXIT "Target policy does not label the AIDL vibrator service"

# The image builder preserves entries from workspace/config and only guesses
# labels for paths that are still missing. Newly imported Samsung HAL service
# names were otherwise guessed as hal_allocator_default_exec, which prevents
# the dynamic linker from resolving their vendor-only shared libraries.
GENERATED_VENDOR_CONTEXTS="$(dirname "$VENDOR_PATH")/config/vendor_file_contexts"
[[ -f "$GENERATED_VENDOR_CONTEXTS" ]] \
    || ERROR_EXIT "Missing generated vendor file contexts"

SET_GENERATED_VENDOR_CONTEXT() {
    local PATH_REGEX="$1"
    local SELINUX_CONTEXT="$2"
    local TEMP_CONTEXTS="${GENERATED_VENDOR_CONTEXTS}.f2q-hal.tmp"

    awk -v path="$PATH_REGEX" '$1 != path' \
        "$GENERATED_VENDOR_CONTEXTS" > "$TEMP_CONTEXTS" \
        || ERROR_EXIT "Failed to update generated vendor file contexts"
    printf '%s %s\n' "$PATH_REGEX" "$SELINUX_CONTEXT" >> "$TEMP_CONTEXTS"
    mv "$TEMP_CONTEXTS" "$GENERATED_VENDOR_CONTEXTS"
}

SET_GENERATED_VENDOR_CONTEXT \
    '/vendor/bin/hw/vendor\.samsung\.hardware\.vibrator-service' \
    'u:object_r:hal_vibrator_default_exec:s0'

# Fold7 supplies face@3.0 while the Fold2 policy already owns the compatible
# hal_face_default domain. Apply the same explicit rule only when that donor
# service is present; Fold4-based builds without it remain unchanged.
FACE_SERVICE="$VENDOR_PATH/bin/hw/vendor.samsung.hardware.biometrics.face@3.0-service"
if [[ -f "$FACE_SERVICE" ]]; then
    SET_GENERATED_VENDOR_CONTEXT \
        '/vendor/bin/hw/vendor\.samsung\.hardware\.biometrics\.face@3\.0-service' \
        'u:object_r:hal_face_default_exec:s0'
fi
