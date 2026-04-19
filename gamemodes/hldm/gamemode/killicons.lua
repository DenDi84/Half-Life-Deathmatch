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
	{"weapon_hl1_snark", "snark"},
}

local killiconCol = Color(255, 150, 50, 255)

hook.Add("InitPostEntity","killicons", function()
	for _, v in pairs(weps) do
		killicon.Add(v[1], "hl11/icons/"..v[2], killiconCol)
		--print("weapon:", v[1], "path: ", v[2])
	end
end)

killicon.AddAlias("ent_hl1_crossbow_bolt", "weapon_hl1_crossbow")
killicon.AddAlias("ent_hl1_hornet", "weapon_hl1_hornetgun")
killicon.AddAlias("hornet", "ent_hl1_hornet")
killicon.AddAlias("ent_hl1_rpg_rocket", "weapon_hl1_rpg")
killicon.AddAlias("ent_hl1_grenade", "weapon_hl1_handgrenade")
killicon.AddAlias("ent_hl1_cgrenade", "ent_hl1_grenade")
killicon.AddAlias("hl1_monster_tripmine", "weapon_hl1_tripmine")
killicon.AddAlias("monster_tripmine", "hl1_monster_tripmine")
killicon.AddAlias("hl1_monster_satchel", "weapon_hl1_satchel")
killicon.AddAlias("monster_satchel", "hl1_monster_satchel")
killicon.AddAlias("monster_snark", "weapon_hl1_snark")

--print("killicon LUA LOADED!!")