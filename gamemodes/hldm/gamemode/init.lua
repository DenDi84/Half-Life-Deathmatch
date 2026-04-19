AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile("scoreboard.lua")
AddCSLuaFile("player.lua")
AddCSLuaFile("killicons.lua")
AddCSLuaFile("concommands.lua")
AddCSLuaFile("sh_spec.lua")
AddCSLuaFile("cl_menuinterface.lua")
AddCSLuaFile("cl_killfeed.lua")
AddCSLuaFile("cl_voice.lua")
AddCSLuaFile("swepPatches.lua")
AddCSLuaFile("cl_chatbox.lua")
AddCSLuaFile("air.lua")

include("shared.lua" )
include("player.lua")
include("sv_footstep.lua")
include("sv_config.lua")
include("sv_killfeed.lua")
include("sh_killfeed.lua")
include("sv_bots/botmainv2.lua")
include("swepPatches.lua")

util.AddNetworkString( "roundstate" )
util.AddNetworkString( "UpdateTime" )
util.AddNetworkString("RoundEndCamera_SetState")
util.AddNetworkString( "killfied" )
util.AddNetworkString("PlayerModel")

CurRoundState = 0

if not recentDeathPositions then
    recentDeathPositions = {}
end

local entTable = {
	["weapon_crowbar"] = "weapon_hl1_crowbar",
	["weapon_crowbar_hl1"] = "weapon_hl1_crowbar",
	["weapon_9mmhandgun"] = "weapon_hl1_glock",
	["weapon_glock"] = "weapon_hl1_glock",
	["weapon_glock_hl1"] = "weapon_hl1_glock",
	["weapon_357"] = "weapon_hl1_357",
	["weapon_357_hl1"] = "weapon_hl1_357",
	["weapon_9mmAR"] = "weapon_hl1_mp5",
	["weapon_9mmar"] = "weapon_hl1_mp5",
	["weapon_mp5"] = "weapon_hl1_mp5",
	["weapon_mp5_hl1"] = "weapon_hl1_mp5",
	["weapon_shotgun"] = "weapon_hl1_shotgun",
	["weapon_shotgun_hl1"] = "weapon_hl1_shotgun",
	["weapon_crossbow"] = "weapon_hl1_crossbow",
	["weapon_crossbow_hl1"] = "weapon_hl1_crossbow",
	["weapon_rpg"] = "weapon_hl1_rpg",
	["weapon_rpg_hl1"] = "weapon_hl1_rpg",
	["weapon_gauss"] = "weapon_hl1_gauss",
	["weapon_egon"] = "weapon_hl1_egon",
	["weapon_hornetgun"] = "weapon_hl1_hornetgun",
	["weapon_handgrenade"] = "weapon_hl1_handgrenade",
	["weapon_satchel"] = "weapon_hl1_satchel",
	["weapon_tripmine"] = "weapon_hl1_tripmine",
	["weapon_snark"] = "weapon_hl1_snark",
	["item_healthkit"] = "hl1_item_healthkit",
	["item_longjump"] = "hl1_item_longjump",
	["item_battery"] = "hl1_item_battery",
	["ammo_9mmar"] = "hl1_ammo_9mmar",
	["ammo_9mmAR"] = "hl1_ammo_9mmar",
	["ammo_9mmbox"] = "hl1_ammo_9mmbox",
	["ammo_9mmclip"] = "hl1_ammo_9mmclip",
	["ammo_357"] = "hl1_ammo_357",
	["ammo_argrenades"] = "hl1_ammo_argrenades",
	["ammo_buckshot"] = "hl1_ammo_buckshot",
	["ammo_crossbow"] = "hl1_ammo_crossbow",
	["ammo_gaussclip"] = "hl1_ammo_gaussclip",
	["ammo_rpgclip"] = "hl1_ammo_rpgclip",
	["ammo_mp5clip"] = "hl1_ammo_9mmar",
	["ammo_mp5grenades"] = "hl1_ammo_argrenades",
	["monster_tripmine"] = "hl1_monster_tripmine",
}

local EndPosOnMaps = {
    ["hldm_crossfire_source"] = {pos = Vector(-445.958130, 288.255310, -1528.649780), ang = Angle(3.123828, 47.895248, 0) },
    ["hldm_boot_camp_source"] = {pos = Vector(-1200.256104, 773.740417, 265.234680), ang = Angle(2.661415, -46.292107, 0.000000) },
    ["hldm_bounce_source"] = {pos = Vector(143.822037, 1463.542969, -1644.762939), ang = Angle(10.527029, -125.290382, 0.000000) },
    ["hldm_datacore_source"] = {pos = Vector(-2059.926758, 2194.292725, 1139.100586), ang = Angle(8.860397, -90.006752, 0.000000) },
    ["hldm_frenzy_source"] = {pos = Vector(-1413.363525, 4.679312, 704.840149), ang = Angle(23.182486, 0.290274, 0.000000) },
    ["hldm_lambda_bunker_source"] = {pos = Vector(-1496.681763, 691.861023, 540.593201), ang = Angle(12.341973, -133.182770, 0.000000) },
    ["hldm_rapidcore_source"] = {pos = Vector(1132.779419, 61.368275, -125.520340), ang = Angle(8.431469, -132.632767, 0.000000) },
    ["hldm_snarkpit_source"] = {pos = Vector(148.672775, -166.682602, -1028.070679), ang = Angle(6.500937, -157.636032, 0.000000) },
    ["hldm_stalkyard_source"] = {pos = Vector(1061.219849, -392.866516, 265.47900), ang = Angle(13.959090, 134.459488, 0.000000) },
    ["hldm_subtransit_source"] = {pos = Vector(-1200.256104, 773.740417, 265.234680), ang = Angle(2.661415, -46.292107, 0.000000) },

}

hook.Add("OnEntityCreated", "HL1SWEPs_Replacements", function(ent)
		local replacement = entTable[ent:GetClass()]
		if replacement then
			timer.Simple(0, function()
				if IsValid(ent) and (ent:CreatedByMap()) then
					local pos, ang, vel, owner = ent:GetPos(), ent:GetAngles(), ent:GetVelocity(), ent:GetOwner()
					if !owner:IsPlayer() or !IsValid(owner) then
						ent:Remove()
						ent = ents.Create(replacement)
						if IsValid(ent) then
							ent:SetPos(pos)
							ent:SetAngles(ang)
							ent:SetOwner(owner)
                            ent:SetKeyValue("respawnable", "1")
							ent:Spawn()
							local phys = ent:GetPhysicsObject()
							if IsValid(phys) then
								phys:SetVelocity(vel)
							else
								ent:SetVelocity(vel)
							end
						end
					end
				end 
			end)
		end
end)

function GM:WaitingForPlayers()
	CurRoundState = 0
	self:UpdateRoundClient()
	--print("WAITINIGIGIGIGIGGI")
	timer.Remove( "MyGamemodeTimer" )
	self:StopEndOfRoundCamera()

end

local ifroundstarted = false
local weaponUnlockTime = 0

function GM:StartRound()
    
    self:StartGameTimer()
    game.CleanUpMap()

    CurRoundState = 1
    self:UpdateRoundClient()
    weaponUnlockTime = CurTime() + .5

    for _,v in pairs(player.GetAll()) do
        v:StripWeapons()
        v:RemoveAllAmmo()
        v:SetFrags(0)
        v:SetDeaths(0)
        if v:GetNWBool("IsSpectator", false) then continue end
        v:Spawn()
    end
end

function GM:PlayerCanPickupWeapon(ply, wep)
    local class = wep:GetClass()
    return CurTime() >= weaponUnlockTime or class == "weapon_hl1_crowbar" or class == "weapon_hl1_glock"
end

function GM:EndGame()
	timer.Remove( "MyGamemodeTimer" )

    CurRoundState = 2

    self:UpdateRoundClient()

	self:StartEndOfRoundCamera()
    timer.Simple(5,function()
        MapVote.Start(30, false, 12, "hldm_")
    end)
end

function GM:SpawnWeaponBox(victim, pos, weaponClass)
    local wepbox = ents.Create("hl1_weaponbox")
    if IsValid(wepbox) then
        if weaponClass == nil or weaponClass == "weapon_hl1_crowbar" or weaponClass == "weapon_hl1_glock" then return end
        if weaponClass then
            wepbox.Weapon = weaponClass
        end
        wepbox:SetPos(pos + Vector(0,0,10))
        wepbox:Spawn()
    end
end

function GM:DoPlayerDeath(ply,attacker, dmginfo)

    ply:AddDeaths( 1 )

	if ( attacker:IsValid() && attacker:IsPlayer() ) then

		if ( attacker == ply ) then
			attacker:AddFrags( -1 )
		else
			attacker:AddFrags( 1 )
		end

	end
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        --print(wep:GetClass())
    end
    ply.LastWeapon = wep:GetClass()
    ply.allowgibs = false

    local hp = ply:GetMaxHealth()
    local dmgtype = dmginfo:GetDamageType()

    local isGibType = bit.band(dmgtype, bit.bor(DMG_BLAST, DMG_SHOCK, DMG_ENERGYBEAM)) ~= 0

    if isGibType then

        ply.allowgibs = true
            
        local effectdata = EffectData()
        effectdata:SetOrigin(ply:GetPos())
        effectdata:SetMagnitude(dmginfo:GetDamage())
        util.Effect("hgibs", effectdata)
    else
        if ( !dmginfo:IsDamageType( DMG_REMOVENORAGDOLL ) ) then
		    ply:CreateRagdoll()
	    end
    end
end

function GM:PlayerDeath(victim, inflictor, attacker)
	
    victim.NextSpawnTime = CurTime() + 3

    if game.GetMap() == "hldm_crossfire" then
        if IsValid(inflictor) and IsValid(attacker) then
            if inflictor:GetClass() == "rpg_missile" and attacker:GetClass() == "func_tankrocket" then
                if attacker:MapCreationID() == 1367 and IsValid(GAMEMODE.MortarButtonOwner.left) then
                    attacker = self.MortarButtonOwner.left
                    attacker:AddFrags(1)
                elseif attacker:MapCreationID() == 1452 and IsValid(self.MortarButtonOwner.right) then
                    attacker = self.MortarButtonOwner.right
                    attacker:AddFrags(1)
                end
            end
        end
    end

    --print("Attacker in INIT", attacker)

    local fraglimit = GetConVar("hldm_fraglimit"):GetInt()
    if IsValid(attacker) and attacker:IsPlayer() and CurRoundState == 1 then
        if attacker:Frags() >= fraglimit then
            self:EndGame()
        end
    end

    local deathPos = victim:GetPos()

    local weaponClass = nil
    if IsValid(victim) and victim.LastWeapon then
        weaponClass = victim.LastWeapon
    end
    self:SpawnWeaponBox(victim, deathPos, weaponClass)

end

local OrigCleanUpMap = game.CleanUpMap
local isMapCleaning = false

function game.CleanUpMap(...)
    isMapCleaning = true
    local result = OrigCleanUpMap(...)
    isMapCleaning = false
    return result
end

function AreVectorsClose(vec1, vec2, tolerance)
	tolerance = tolerance or 1
    
    if vec1:Distance(vec2) <= tolerance then
        return true
    end
    
    return false
end

function GM:StartGameTimer()
    timer.Remove( "MyGamemodeTimer" )
	local timeLeft = GetConVar("hldm_timelimit"):GetInt()

	  timer.Create("MyGamemodeTimer", 1, 0, function()
		

        if timeLeft > 0 then
            timeLeft = timeLeft - 1
		else 
			self:EndGame()
        end

        net.Start("UpdateTime")

        net.WriteInt(timeLeft, 16)

        net.Broadcast()
    end)
end

cvars.AddChangeCallback("hldm_timelimit", function(name, old, new)
    if GAMEMODE and GAMEMODE.StartGameTimer then
        GAMEMODE:StartGameTimer()
    end
end)

function GM:PlayerUse(ply,ent)
	if IsSpectator(ply) then
        return false 
    end
end

function GM:Initialize()

    for convar, value in pairs(self.Config) do
        RunConsoleCommand(convar, value)     
    end

	self:WaitingForPlayers()

end

function GM:ShutDown()
    for convar, value in pairs(self.Config) do
        local cconvar = GetConVar(convar)
        local default = cconvar:GetDefault()
        RunConsoleCommand(convar, default)     
    end
end

function GM:PlayerDisconnected()

    timer.Simple(0.1, function()
        self:CheckRoundEndConditions()   
        self:CheckRoundStartConditions()  
	end)
	
end

--[[ function GM:CheckRoundStartConditions(force)
    if force != true then force = false end
    if CurRoundState == 1 and not force then
        return 
    end

    local alivePlayers = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not IsSpectator(ply) then
            alivePlayers = alivePlayers + 1
        end
    end
    local minPlayers = GetConVar("hldm_minplayers"):GetInt()

    if alivePlayers >= minPlayers then

        CurRoundState = 3 --начало раунда
        self:UpdateRoundClient()

        local a_self = self 
 
        timer.Create("RoundStartTimer", 13, 1, function()
        
            local currentAlivePlayers = 0
            for _, ply in ipairs(player.GetAll()) do
                if not IsSpectator(ply) then
                    currentAlivePlayers = currentAlivePlayers + 1
                end
            end

            if currentAlivePlayers >= minPlayers and CurRoundState != 1 then
                a_self:StartRound()
            else
                a_self:WaitingForPlayers()
            end
        end)

		 timer.Simple(10, function()
            
            if CurRoundState != 1 and timer.Exists("RoundStartTimer") then
				for _, ply in pairs(player.GetAll()) do
                    if ply:GetNWBool("IsSpectator", false) then continue end
					ply:Freeze(true)
            	end
            end
        end)

    else
        self:WaitingForPlayers()
    end
end ]]

function GM:CheckRoundStartConditions(force)
    if CurRoundState == 1 and not force then return end

    local minPlayers = GetConVar("hldm_minplayers"):GetInt()

    local count = 0
    for _, ply in ipairs(player.GetAll()) do
        if IsSpectator(ply) == false then
            count = count + 1
        end
    end

    if count < minPlayers then
        self:WaitingForPlayers()
        return
    end

    if CurRoundState == 2 and not force then return end

    CurRoundState = 3 
    self:UpdateRoundClient()

    if force then
        self:StopEndOfRoundCamera()
        MapVote.Cancel()
    end

    timer.Simple(10, function()
        if CurRoundState != 3 then return end 

        for _, ply in ipairs(player.GetAll()) do
            if IsSpectator(ply) == false then
                ply:Freeze(true)
            end
        end
    end)

    timer.Create("RoundStartTimer", 13, 1, function()
        if count >= minPlayers and CurRoundState != 1 then
            self:StartRound()
        else
            self:WaitingForPlayers()
        end
    end)
end


cvars.AddChangeCallback("hldm_minplayers", function(name, old, new)
    if GAMEMODE and GAMEMODE.CheckRoundStartConditions then
        GAMEMODE:CheckRoundStartConditions(true)
    end
end)

function GM:CheckRoundEndConditions()
    
    if CurRoundState != 1 then
        return
    end

    local alivePlayers = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not IsSpectator(ply) then
            alivePlayers = alivePlayers + 1
        end
    end


    if alivePlayers <= 1 then
        self:WaitingForPlayers()
    end
end

function GM:UpdateRoundClient()
	net.Start( "roundstate" )
    net.WriteInt(CurRoundState, 3)
    net.Broadcast()
end

function GM:PlayerInitialSpawn(ply)

    ply.LastSpawn = math.random(1,#self.SpawnsInOrder)

	ply:SetNWBool("IsSpectator", false)
    ply:CrosshairEnable()
	net.Start( "roundstate" )
    net.WriteInt(CurRoundState, 3)
	net.Send(ply)
    if CurRoundState ~= 3 and CurRoundState ~= 2 then timer.Simple(1, function() self:CheckRoundStartConditions() end) end
end

function GM:StartEndOfRoundCamera()

    local cameraPosition, cameraAngle = nil,nil
    local curmap = game.GetMap() 

    if EndPosOnMaps == nil then
        
    elseif EndPosOnMaps[curmap] == nil then

    else
        cameraPosition = EndPosOnMaps[curmap].pos
        cameraAngle = EndPosOnMaps[curmap].ang 
    end
    
    if cameraPosition == nil then
        local cameras = ents.FindByClass("point_camera") 
        
        if #cameras > 0 then
            cameraPosition = cameras[1]:GetPos()
            cameraAngle = cameras[1]:GetAngles()
        end
    end

    if cameraPosition ~= nil then
        net.Start("RoundEndCamera_SetState")
            net.WriteBool(true)
            net.WriteVector(cameraPosition)
            net.WriteAngle(cameraAngle)
        net.Broadcast()
    else
        print("CameraFailed, no point_camera or valid position found!")
    end
end

function GM:StopEndOfRoundCamera()

--[[     for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:DrawViewModel(true)
        end
    end ]]
    
    net.Start("RoundEndCamera_SetState")
    net.WriteBool(false)
    net.Broadcast()
end


function GM:PlayerSay(ply,text)
    return text
end

function GM:GetFallDamage(ply,speed)
    if speed < 650 then return 0 end
    return 10
end


function GM:PlayerFootstep(ply, pos, foot, soundName, volume)
    if not IsValid(ply) or not ply:OnGround() then return end
    
    if ply.NextFootstepTime and CurTime() < ply.NextFootstepTime then
        return true 
    end

    if ply.NoSteps == true then return true end

    local footpos = pos
    if foot == 1 then
        footpos = footpos + Vector(0,-20,0)
    else
        footpos = footpos + Vector(0,10,0)
    end

    local tr = util.QuickTrace(footpos, Vector(0, 0, -50), ply)
    if not tr.Hit then return end

    local material = string.lower(util.GetSurfacePropName(tr.SurfaceProps))
    local customSounds = HLDM_SOUNDS.Footsteps[material]
    if customSounds == nil then customSounds = HLDM_SOUNDS.Footsteps["default"] end
    
    if customSounds != nil then
        local chosenSound = table.Random(customSounds)
        ply:EmitSound(chosenSound, 75, 100, 1, CHAN_AUTO)
        return true
    else
        return 
    end
    
    return true
end

hook.Add("KeyPress", "jumpcuston", function(ply, key)
    if !ply:Alive() then return end
    if key == IN_JUMP and ply:OnGround() then
        local pos = ply:GetPos()
        local tr = util.QuickTrace(pos, Vector(0, 0, -100), ply)
        
        if tr.Hit then
            local material = string.lower(util.GetSurfacePropName(tr.SurfaceProps))
            local customSounds = HLDM_SOUNDS.Footsteps[material]
            if customSounds == nil then customSounds = HLDM_SOUNDS.Footsteps["default"] end
            if customSounds then
                local chosenSound = table.Random(customSounds)
                ply:EmitSound(chosenSound, 75, 100, 1, CHAN_AUTO)
            end
        end

        ply.NextFootstepTime = CurTime() + 0.25 
    end

    if key == IN_SPEED then
        ply.NoSteps = true
    end
end)

hook.Add("KeyRelease", "speedcustom", function(ply, key)
    if key == IN_SPEED then
        ply.NoSteps = false
    end
end)

function GM:EntityTakeDamage(target, dmginfo)
    if target:IsPlayer() and target:Health() > 0 then

        local damage = dmginfo:GetDamage()

        if damage <= 0 then return end

        local effectdata = EffectData()

        effectdata:SetOrigin(dmginfo:GetDamagePosition())

        effectdata:SetMagnitude(damage)

        util.Effect("oldblood", effectdata)
    end
end

function GM:ScalePlayerDamage( ply, hitgroup, dmginfo )
	 if ( hitgroup == HITGROUP_HEAD ) then
		dmginfo:ScaleDamage( 2 )
 	 else
		dmginfo:ScaleDamage( 1 )  
	 end
end

function GM:OnDamagedByExplosion()
end