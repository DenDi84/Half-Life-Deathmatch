
local weps = {
	{"weapon_hl1_crowbar", "crowbar"},
	{"weapon_hl1_glock", "glock"},
	{"weapon_hl1_357", "357"},
	{"weapon_hl1_mp5", "mp5"},
	{"weapon_hl1_shotgun", "shotgun"},
	{"weapon_hl1_crossbow", "crossbow"},
	{"weapon_hl1_rpg", "rpg"},
	{"weapon_hl1_gauss", "gauss"},
	{"weapon_hl1_egon", "egon"},
	{"weapon_hl1_hornetgun", "hgun"},
	{"weapon_hl1_handgrenade", "grenade"},
	{"weapon_hl1_satchel", "satchel"},
	{"weapon_hl1_tripmine", "tripmine"},
	{"ent_hl1_crossbow_bolt", "crossbow"},
    {"ent_hl1_hornet", "hgun"},
    {"hornet", "hgun"},
    {"ent_hl1_rpg_rocket", "rpg"},
    {"ent_hl1_grenade", "grenade"},
    {"hl1_monster_tripmine", "tripmine"},
    {"monster_tripmine", "tripmine"},
    {"hl1_monster_satchel", "satchel"},
    {"monster_satchel", "satchel"},
    {"monster_snark", "snark"},
}

WEAPON_ICONS = {}
for _, data in ipairs(weps) do
    local weaponClass = data[1]
    local iconName = data[2]
    WEAPON_ICONS[weaponClass] = iconName
end


WEAPON_ICONS["worldspawn"] = "skull" 