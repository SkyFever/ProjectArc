#!/usr/bin/env bash

# build.sh sources every helper while initializing its function library. This
# file is an executable transformer, so do nothing (including shell-option
# changes) when it is merely sourced.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 0
fi

set -euo pipefail

[[ $# -eq 3 ]] || {
    echo "Usage: $0 DONOR_XML FOLD2_XML OUTPUT_XML" >&2
    exit 2
}

donor_xml="$1"
fold2_xml="$2"
output_xml="$3"

for xml in "$donor_xml" "$fold2_xml"; do
    [[ -f "$xml" ]] || { echo "Missing floating feature: $xml" >&2; exit 1; }
    xmlstarlet val -e "$xml" >/dev/null
done

cp "$donor_xml" "$output_xml"

replace_family() {
    local family="$1"
    xmlstarlet ed -L \
        -d "//*[starts-with(name(), '$family')]" "$output_xml"

    while IFS=$'\t' read -r tag value; do
        [[ -n "$tag" ]] || continue
        xmlstarlet ed -L -s '/SecFloatingFeatureSet' -t elem \
            -n "$tag" -v "$value" "$output_xml"
    done < <(
        xmlstarlet sel -t \
            -m "//*[starts-with(name(), '$family')]" \
            -v 'name()' -o $'\t' -v '.' -n "$fold2_xml"
    )
}

copy_exact() {
    local tag="$1"
    local count value
    count="$(xmlstarlet sel -t -v "count(//$tag)" "$fold2_xml")"
    xmlstarlet ed -L -d "//$tag" "$output_xml"
    [[ "$count" != 0 ]] || return 0
    value="$(xmlstarlet sel -t -v "//$tag" "$fold2_xml")"
    xmlstarlet ed -L -s '/SecFloatingFeatureSet' -t elem \
        -n "$tag" -v "$value" "$output_xml"
}

# Keep the donor One UI 8 namespaces as the compatibility baseline. Replacing
# whole Android 13 CAMERA/AUDIO/LCD families makes the newer apps and services
# select obsolete layouts and policies.

# Keep the rest of the donor One UI 8 feature surface, but override the
# target-specific fold/display/touch/accessory identity entries.
for tag in \
    SEC_FLOATING_FEATURE_SETTINGS_CONFIG_BRAND_NAME \
    SEC_FLOATING_FEATURE_SYSTEM_CONFIG_SIOP_POLICY_FILENAME \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_CAMID_BOKEH \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_CAMID_MACRO \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_CAMID_TELE2 \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_CAMID_TELE_BINNING \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_CAMID_TELE_STANDARD_CROP \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_CAMID_UW \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_CAMID_WIDE \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_FRONT_FLASH_BRIGHTNESS \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_GALAXYRAW_PLATFORM_VERSION \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_HIGH_RESOLUTION_MAX_CAPTURE \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_MEMORY_USAGE_LEVEL \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_UW_DISTORTION_CORRECTION \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_VENDOR_LIB_INFO \
    SEC_FLOATING_FEATURE_CAMERA_CONFIG_WIDE_DISTORTION_CORRECTION \
    SEC_FLOATING_FEATURE_CAMERA_SUPPORT_LOGICAL_CAMERA \
    SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_MODE \
    SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE \
    SEC_FLOATING_FEATURE_LCD_CONFIG_SUB_HFR_MODE \
    SEC_FLOATING_FEATURE_LCD_CONFIG_SUB_HFR_SUPPORTED_REFRESH_RATE \
    SEC_FLOATING_FEATURE_SYSTEMUI_CONFIG_STATUSBAR_CONTAINER_POSITION \
    SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_AOD_ITEM \
    SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_NFC_LED_COVER_LEVEL \
    SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_SPEN_GARAGE_SPEC \
    SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_SPEN_VERSION \
    SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_PROVIDE_TSP_RAWDATA \
    SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_TSP_STATE_MANAGER \
    SEC_FLOATING_FEATURE_COMMON_SUPPORT_BLE_SPEN; do
    copy_exact "$tag"
done

# Fold4 has an under-display inner camera, while Fold2 has a punch-hole camera.
# Retain the modern SDK feature list but remove only the UDC-specific contract.
camera_sdk_tag=SEC_FLOATING_FEATURE_CAMERA_CONFIG_SDK_FEATURE_INFO
camera_sdk_value="$(xmlstarlet sel -t -v "//$camera_sdk_tag" "$output_xml")"
camera_sdk_value="${camera_sdk_value//,limit_level_udc_camera_id.v71/}"
camera_sdk_value="${camera_sdk_value//limit_level_udc_camera_id.v71,/}"
camera_sdk_value="${camera_sdk_value//limit_level_udc_camera_id.v71/}"
xmlstarlet ed -L -u "//$camera_sdk_tag" -v "$camera_sdk_value" "$output_xml"

# Fold2 does not use the newer donor's lid-state GNSS calibration contract.
# Leaving the donor value at 3 produced many visible satellites but no usable
# fix; value 0 restored a stable 3D fix without replacing the target GNSS HAL.
gps_fold_tag=SEC_FLOATING_FEATURE_GPS_CONFIG_FOLD_CALIBRATED
gps_fold_count="$(xmlstarlet sel -t -v "count(//$gps_fold_tag)" "$output_xml")"
if [[ "$gps_fold_count" == 0 ]]; then
    xmlstarlet ed -L -s '/SecFloatingFeatureSet' -t elem \
        -n "$gps_fold_tag" -v 0 "$output_xml"
else
    xmlstarlet ed -L -u "//$gps_fold_tag" -v 0 "$output_xml"
fi

xmlstarlet val -e "$output_xml" >/dev/null
