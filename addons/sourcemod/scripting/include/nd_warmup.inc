/* Fires when the warmup plugin completes the warmup */
forward void ND_OnWarmupComplete();

/* Ask the warmup plugin if the warmup is completed */
native bool ND_WarmupCompleted();
#define ND_WC_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_WarmupCompleted") == FeatureStatus_Available)
