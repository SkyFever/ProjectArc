#!/usr/bin/env bash
#
# First-boot size reduction for the SM-F916N super partition.
# Keep framework, SystemUI, Settings, launcher, telephony, WebView, GMS core,
# Play Store, Samsung Account, camera, gallery, keyboard and setup components.
#

PRODUCT_FIRST_BOOT_REMOVALS=(
    "priv-app/Velvet"
    "priv-app/AiWallpaper"
    "priv-app/AndroidAutoStub"
    "app/YouTube"
    "app/Gmail2"
    "app/Maps"
    "app/SpeechServicesByGoogle"
    "app/BardShell"
    "app/DuoStub"
)

SYSTEM_FIRST_BOOT_REMOVALS=(
    "app/Notes40"
    "app/OCRDataProvider"
    "app/KTCustomerService"
    "app/SamsungTTSVoice_en_US_l03"
    "app/SKTMemberShip_new"
    "app/LGUMiniCustomerCenter"
    "app/TWorld"
    "app/SmartReminder"
    "app/SmartManager_v6_DeviceSecurity"
    "app/BlockchainBasicKit"
    "app/LiveTranscribe"
    "app/VideoEditorLite_Dream_N"
    "app/VisionIntelligence3.7"
    "app/Cameralyzer"
    "priv-app/AREmojiEditor"
    "priv-app/AREmoji"
    "priv-app/AvatarEmojiSticker"
    "priv-app/StickerFaceARAvatar"
    "priv-app/DressRoom"
    "priv-app/LiveEffectService"
    "priv-app/SamsungSmartSuggestions"
    "priv-app/YourPhone_P1_5"
    "priv-app/PhotoEditor_AIFull"
    "priv-app/PhotoRemasterService"
    "priv-app/TalkbackSE"
    "priv-app/Bixby"
    "priv-app/BixbyInterpreter"
    "app/BixbyWakeup"
    "priv-app/TPhoneOnePackage"
    "priv-app/KTOneStore"
    "priv-app/SKTOneStore"
    "priv-app/LGUOZStore"
    "priv-app/OneStoreService"
    "priv-app/GameHome"
    "priv-app/DigitalKey"
    "priv-app/HashTagService"
    "priv-app/SingleTakeService"
)

LOG_INFO "Removing non-critical packages to fit the Fold2 super partition..."

for PATH_TO_REMOVE in "${PRODUCT_FIRST_BOOT_REMOVALS[@]}"; do
    REMOVE "product" "$PATH_TO_REMOVE"
done

for PATH_TO_REMOVE in "${SYSTEM_FIRST_BOOT_REMOVALS[@]}"; do
    REMOVE "system" "$PATH_TO_REMOVE"
done

LOG_END "First-boot size reduction applied."
