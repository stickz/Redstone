# supplystation stuff
nd_supplystation_max_ammo - how much ammo the supplystation can carry

nd_supplystation_max_health - how much health the supplystation can carry

nd_supplystation_refill_interval - how often the supplystation refills both ammo and health

nd_supplystation_refill_amount - how much that the supplystation refills of both ammo and health per refill

nd_supplystation_refill_radius - how much radius that the supplystation has

nd_supplystation_costs_resources - does the supplystation cost resource to refill


# hypospray jazz
nd_hypospray_damage_reduction - Percent, in decimal, of damage reduction under hypospray effect

nd_hypospray_heal_reduction - Percent, in decimal, of healing reduction under hypospray effect

nd_hypospray_duration

nd_hypospray_supportedly_bonus - Enables invulnerability effect for hypospray. (overrides damage reduction)

nd_hypospray_score_rate

# stealth stuff
nd_stealth_invis_time - 

nd_stealth_invis_unstealth_time - Transition time in and out of spy invisibility

nd_stealth_cloak_consume_rate - cloak to use per second while cloaked, from 100 max 

nd_stealth_cloak_regen_rate - defaults to 3.3, cloak to regen per second, up to 100 max

# EMP nade duration stuff (I think)

emp_min_hinder_time

emp_max_hinder_time

tactical regen gizmo stuff(not sure if command)

tac_regen_amount_per_interval

tac_regen_interval

tac_regen_time_since_damaged

kinetic field gizmo stuff(not sure if command)

kinetic_field_cooldown

# commander ability stuff
-> damage <-
nd_commander_ability_damage_value - 700.0

nd_commander_ability_damage_value2 - 770.0

nd_commander_ability_damage_value3 - 840.0

nd_commander_ability_damage_radius

nd_commander_ability_damage_radius2

nd_commander_ability_damage_radius3

-> poison <-
nd_commander_ability_hinder_time

nd_commander_ability_hinder_time2 - 21?

nd_commander_ability_hinder_time3 - 22?

nd_commander_ability_hinder_interval

nd_commander_ability_hinder_interval2

nd_commander_ability_hinder_interval3

nd_commander_ability_hinder_value

nd_commander_ability_hinder_value2

nd_commander_ability_hinder_value3

nd_commander_ability_hinder_radius

nd_commander_ability_hinder_radius2

nd_commander_ability_hinder_radius3

-> heal <-
nd_commander_ability_heal_time

nd_commander_ability_heal_time2 - 11.0?

nd_commander_ability_heal_time3

nd_commander_ability_heal_interval

nd_commander_ability_heal_interval2

nd_commander_ability_heal_interval3 - 0.45?

nd_commander_ability_heal_value - 40.0

nd_commander_ability_heal_value2 - 44.0

nd_commander_ability_heal_value3 - 48.0

nd_commander_ability_heal_radius

nd_commander_ability_heal_radius2

nd_commander_ability_heal_radius3

# potentially useful, maybe not even commands
nd_buildtimemultipler

nd_one_use_build_queue

nd_sv_armory_purchase_radius - The maximum distance from the closest armory a player can stand at and still be able buy items

nd_structure_deathdmg - 200.0

nd_structure_deathrad - 500.0

nd_spawn_cluster_radius

# resource commands, probably useless
nd_resource_drill_amt

nd_resource_drill_delay

nd_resource_drill_maxdist

nd_reactor_power

# turret stuff
nd_turret_reaction_time

nd_turret_scanrate_idle

nd_turret_scanrate_combat

nd_turret_damage

nd_turret_yawspeed - 120.0

nd_turret_pitchspeed - 60.0

# custom gamemode
nd_custom_gamemode_name - Manually setting this will exclude your server from Play Now

nd_custom_gamemode_desc

nd_custom_kitrestriction - it's complicated

# structure related
nd_repairspeed_override

nd_buildspeed_override

nd_instabuild - I think this isn't a functional command

nd_struct_statuslight

nd_struct_spawnhealth_percent - Health percent at which the structures at after they are placed by the commander

nd_struct_armor_protection - Percentage of damage absorbed by the structure's armor

nd_hide_structures - Toggle hide of structures

nd_sv_onlycrates - wat?

# boosts
nd_playerboost_health_bonus

nd_playerboost_health_bonus2

nd_playerboost_health_bonus3

nd_playerboost_damage_bonus

nd_playerboost_damage_bonus2

nd_playerboost_damage_bonus3

nd_structureboost_health_bonus

nd_structureboost_health_bonus2

nd_structureboost_health_bonus3

# ammopack stuff
nd_ammopack_max_ammo

nd_ammopack_refill_interval - Ammopack will refill this often (seconds), defaults to 1.75

nd_ammopack_refill_amount - Ammopack will refill this much each refill

nd_ammopack_max_lifetime - Max lifetime for ammopacks (in seconds). Default 45. -1 to always last until depletion or death (if set)

ammo_radius - maybe not a command

ammo_per_sec - also maybe not a command

# radarkit stuff
nd_radarkit_health

nd_radarkit_upright_angle

nd_radarkit_blip_frequency

nd_radarkit_blip_height

nd_radarkit_fow_range

# healthkit stuff
heal_radius - maybe not a command

health_per_sec - also maybe not a command