# ==============================================================================
#
# MOD_NAME="Remove unsupported selinux entries."
# MOD_AUTHOR="Fede2782"
# MOD_DESC="Removes unsupported sepolicy entries."
#
# ==============================================================================

if ! GET_FEATURE DEVICE_USE_STOCK_BASE; then

# One UI 8.0 entries
REMOVE_SELINUX_ENTRIES \
    heatmap_default \
    heatmap_default_exec

# One UI 7.0 entries
REMOVE_SELINUX_ENTRIES \
    attiqi_app \
    attiqi_app_data_file \
    ker_app \
    kpp_app \
    kpp_data_file

# One UI 6.1.1 entries
REMOVE_SELINUX_ENTRIES \
    hal_dsms_default \
    hal_dsms_default_exec \
    proc_compaction_proactiveness \
    sbauth \
    sbauth_exec

# Additional entries
REMOVE_SELINUX_ENTRIES \
    audiomirroring \
    fabriccrypto \
    hal_dsms_service \
    kpoc_charger \
    kpp_data \
    proc_fmw \
    qb_id_prop

# The Android 16 donor declares this service property in system_ext, while
# older Samsung vendors may already declare the same prefix in
# vendor_property_contexts with their own label. Android init rejects duplicate
# property prefixes before services start, so keep the target vendor entry and
# remove only the donor copy.
SYSTEM_EXT_PATH="$(GET_PARTITION_PATH system_ext)" \
    || ERROR_EXIT "Failed to get system_ext partition path"
SYSTEM_EXT_PROPERTY_CONTEXTS="$SYSTEM_EXT_PATH/etc/selinux/system_ext_property_contexts"
VENDOR_PROPERTY_CONTEXTS="$WORKSPACE/vendor/etc/selinux/vendor_property_contexts"

if grep -q -E '^init\.svc\.vendor\.wvkprov_server_hal([[:space:]]|$)' \
        "$VENDOR_PROPERTY_CONTEXTS" 2>/dev/null; then
    sed -i -E '/^init\.svc\.vendor\.wvkprov_server_hal([[:space:]]|$)/d' \
        "$SYSTEM_EXT_PROPERTY_CONTEXTS"
fi

fi
