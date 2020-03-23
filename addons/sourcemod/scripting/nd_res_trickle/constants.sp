#define FRACKING_MIN_PLYS 8 // Specifies the minimum player count to enable fracking

#define PRIMARY_TEAM_TRICKLE 3000 // Reserved pool of resources for each team
#define PRIMARY_TEAM_TRICKLE_LRG 6000 // Reserved pool of resources on large maps
#define PRIMARY_TEAM_TRICKLE_CORNER 40000 // Reserved pool of resources on corner
#define PRIMARY_TRICKLE_SET 76500 // Initial pool of resources, first come, first serve
#define PRIMARY_TRICKLE_SET_LRG 35250 // Initial pool of resources on large maps
#define PRIMARY_TRICKLE_SET_CORNER 40000 // Initial pool of resources on corner

#define PRIMARY_TRICKLE_REGEN_AMOUNT 3000 // Amount to get every fifteen seconds
#define PRIMARY_TRICKLE_REGEN_INTERVAL 75 // Maximum amount to regen on opposite team's pool
#define PRIMARY_TRICKLE_DEGEN_INTERVAL 375 // Amount to degenerate every fifteen seconds
#define PRIMARY_TRICKLE_DEGEN_MINUTES 12 // Minutes to degenerate if team hasn't owned tertiary

#define PRIMARY_FRACKING_AMOUNT 750 // Amount of resources to grant per frack
#define PRIMARY_FRACKING_SECONDS 30 // Number of seconds inbetween fracks
#define PRIMARY_FRACKING_LEFT 1500 // Amount of resources left before fracking is enabled
#define PRIMARY_FRACKING_DELAY 20.0  // Number of minutes a team most own a prime to start fracking

#define PRIMARY_FRACKING_AMOUNT_FASTER 3000 // Amount of resources to grant per frack at faster rates
#define PRIMARY_FRACKING_SECONDS_FASTER 60 // Number of seconds inbetween fracks at faster rates
#define PRIMARY_FRACKING_DELAY_FASTER 15.0  // Number of minutes a team most own a prime to start fracking at faster rates

#define SECONDARY_TEAM_TRICKLE 3300 // Reserved pool of resources for each team
#define SECONDARY_TEAM_TRICKLE_LRG 6600 // Reserved pool of resources on large maps
#define SECONDARY_TRICKLE_SET 40700 // Initial pool of resources, first come, first serve
#define SECONDARY_TRICKLE_SET_LRG 17050 // Initial pool of resources on large maps

#define SECONDARY_TRICKLE_REGEN_AMOUNT 3300 // Maximum amount to regen on opposite team's pool
#define SECONDARY_TRICKLE_REGEN_INTERVAL 55 // Amount to regen every ten seconds

#define SECONDARY_FRACKING_AMOUNT 275 // Amount of resources to grant per frack
#define SECONDARY_FRACKING_SECONDS 20 // Number of seconds inbetween fracks
#define SECONDARY_FRACKING_LEFT 825 // Amount of resources left before fracking is enabled
#define SECONDARY_FRACKING_DELAY 15.0  // Number of minutes a team most own a secondary to start fracking

#define TERTIARY_TEAM_TRICKLE 8000 // Reserved pool of resources for each team
#define TERTIARY_TEAM_TRICKLE_LRG 4000 // Reserved pool of resources for large maps
#define TERTIARY_TRICKLE_SET 8000 // Initial pool of resources, first come, first serve
#define TERTIARY_TRICKLE_SET_LRG 2000 // Initial pool of resources, for large maps

#define TERTIARY_TRICKLE_REGEN_INTERVAL 15 // Amount to regenerate every five seconds
#define TERTIARY_TRICKLE_REGEN_AMOUNT 2160 // Maximum amount to regen on opposite team's pool
#define TERTIARY_TRICKLE_DEGEN_INTERVAL 25 // Amount to degenerate every five seconds
#define TERTIARY_TRICKLE_DEGEN_MINUTES 8 // Minutes to degenerate if team hasn't owned tertiary

#define TERTIARY_FRACKING_AMOUNT 50 // Amount of resources to grant per frack
#define TERTIARY_FRACKING_SECONDS 15 // Number of seconds inbetween fracks
#define TERTIARY_FRACKING_LEFT 300 // Amount of resources left before fracking is enabled
#define TERTIARY_FRACKING_DELAY 13.0 // Number of minutes a team most own a teritary to start fracking

#define TRICKLE_REDUCE_COUNT_MED 12 // Number of players to reduce trickle resources for medium maps
#define TRICKLE_REDUCE_COUNT_LRG 16 // Number of players to reduce trickle resources for large maps