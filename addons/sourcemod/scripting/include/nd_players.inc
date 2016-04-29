#if defined _nd_players_included_
  #endinput
#endif
#define _nd_players_included_

#define BK_CLIENT_TYPE_REGULAR 		0
#define BK_CLIENT_TYPE_GRADUATED 	1
#define BK_CLIENT_TYPE_MIDDLE 		2
#define BK_CLIENT_TYPE_VETERAN 		3

/**
 * Checks what type of client we're looking at
 * Backup method for if server statistics goes down
 *
 * @parm 1: The index of the client 
 */
native ND_BackupClientType(client);

#define NDBCT_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_BackupClientType") == FeatureStatus_Available)

/**
 * Checks the position of the client in the veteran array
 * Backup method for if server statistics goes down
 *
 * @parm 1: The index of the client 
 */
native ND_BackupPosition(client);

#define NDBP_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_BackupPosition") == FeatureStatus_Available)

/**
 * Checks what type of client we're looking at
 *
 * @parm 1: The index of the client 
 * @return The Client's type by array presance
 */
native ND_IsDonar(client);

#define NDID_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "ND_IsDonar") == FeatureStatus_Available)