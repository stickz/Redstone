#if defined _nd_tick_included_
  #endinput
#endif
#define _nd_tick_included_

// Fires when movement buttons are processed for bots
forward void ND_OnFakeClientRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]);

// Fires when movement buttons are processed for players
forward void ND_OnRealClientRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]);
