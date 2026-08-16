#!/usr/bin/env bash

F2Q_RECEIVER_DIAGNOSTIC="$ASTROROM/../work/q7q_analysis/receiver-build.smali" \
    python3 "$ASTROROM/scripts/helpers/patch_hwmoduletest_receiver.py" \
    || ERROR_EXIT "Failed to patch the HwModuleTest receiver compatibility check"
