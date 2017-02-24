#if defined _nd_slots_included
  #endinput
#endif
#define _nd_slots_included

/**
 * Sets wetheir to enable or disable adjusting player slots
 *
 * @param True or False 	Enable/Disable Dyanmic Slots.
 */
native void ToggleDynamicSlots(bool state);

#define TDS_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ToggleDynamicSlots") == FeatureStatus_Available)

/**
 * retreive wetheir dynamic slots are enabled or disabled
 *
 * @return True or False 	Enabled/Disabled Dyanmic Slots.
 */
native bool GetDynamicSlotStatus();

#define GDSS_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "GetDynamicSlotStatus") == FeatureStatus_Available)

/**
 * retreive the server cap for dynamic slots
 *
 * @return the soft server limit
 */
native int GetDynamicSlotCount();

#define GDSC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "GetDynamicSlotCount") == FeatureStatus_Available)