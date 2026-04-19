DeriveGamemode("base")

GM.Name = "HLDM"
GM.Author = "DenDi85"
GM.Email = "N/A"
GM.Website = "N/A"

include("player.lua")
include("air.lua")
include("mapvote.lua")
include("concommands.lua")
include("sh_spec.lua")

local GM = GM or GAMEMODE

PLAYERMODELS = {}

HLDM_SOUNDS = HLDM_SOUNDS or {}

HLDM_SOUNDS.Footsteps = {
    ["default"] = {
        "player/footsteps/pl_step1.wav",
        "player/footsteps/pl_step2.wav",
        "player/footsteps/pl_step3.wav",
		"player/footsteps/pl_step4.wav"
    },
	["rock"] = {
        "player/footsteps/pl_step1.wav",
        "player/footsteps/pl_step2.wav",
        "player/footsteps/pl_step3.wav",
		"player/footsteps/pl_step4.wav"
    },
	["concrete"] = {
        "player/footsteps/pl_step1.wav",
        "player/footsteps/pl_step2.wav",
        "player/footsteps/pl_step3.wav",
		"player/footsteps/pl_step4.wav"
    },
	["concrete_block"] = {
        "player/footsteps/pl_step1.wav",
        "player/footsteps/pl_step2.wav",
        "player/footsteps/pl_step3.wav",
		"player/footsteps/pl_step4.wav"
    },
    ["dirt"] = {
        "player/footsteps/pl_dirt1.wav",
        "player/footsteps/pl_dirt2.wav",
        "player/footsteps/pl_dirt3.wav",
		"player/footsteps/pl_dirt4.wav"
	},
	["gravel"] = {
        "player/footsteps/pl_dirt1.wav",
        "player/footsteps/pl_dirt2.wav",
        "player/footsteps/pl_dirt3.wav",
		"player/footsteps/pl_dirt4.wav"
	},
	["wood"] = {
        "player/footsteps/pl_wood1.wav",
        "player/footsteps/pl_wood2.wav",
        "player/footsteps/pl_wood3.wav",
		"player/footsteps/pl_wood4.wav"
	},
	["metal"] = {
        "player/footsteps/pl_metal1.wav",
        "player/footsteps/pl_metal2.wav",
        "player/footsteps/pl_metal3.wav",
		"player/footsteps/pl_metal4.wav"
	},
	["metalpanel"] = {
        "player/footsteps/pl_metal1.wav",
        "player/footsteps/pl_metal2.wav",
        "player/footsteps/pl_metal3.wav",
		"player/footsteps/pl_metal4.wav"
	},
	["metal_box"] = {
        "player/footsteps/pl_metal1.wav",
        "player/footsteps/pl_metal2.wav",
        "player/footsteps/pl_metal3.wav",
		"player/footsteps/pl_metal4.wav"
	},
	["metalgrate"] = {
        "player/footsteps/pl_metal1.wav",
        "player/footsteps/pl_metal2.wav",
        "player/footsteps/pl_metal3.wav",
		"player/footsteps/pl_metal4.wav"
	}
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

SpawnsInOrder = {}

function GM:InitPostEntity()
    self.SpawnsInOrder = {}

    local spawns = ents.FindByClass("info_player_start")

    for _, ent in ipairs(spawns) do
        if IsValid(ent) then
            table.insert(self.SpawnsInOrder, {
                pos = ent:GetPos(),
                ang = ent:GetAngles()
            })
        end
    end
end

hook.Add("Initialize", "RegisterMyBlood", function()
	
    for i = 1, 7 do
        game.AddDecal("HLDM_BLOOD_" .. i, "decals/hldmblood" .. i)
    end
end)

net.Receive("PlayerModel", function(len, ply)

	local received_string = net.ReadString()

	if string.StartsWith(received_string, "models/player/hl1/") then
		PLAYERMODELS[ply:Name()] = received_string
	end

end)

modelFiles = file.Find("models/player/hl1/*.mdl", "GAME")
local function IsSpawnClear(spawnPos)
    local radius = 5776 -- 72 

    for _, otherPly in ipairs(player.GetAll()) do
        if IsValid(otherPly) and otherPly:Alive() then 
            if otherPly:GetPos():DistToSqr(spawnPos) <= radius then
                return false 
            end
        end
    end
    return true 
end

local function SpawnDecider(ply, spawnsList)
    spawnsList = spawnsList or {}
    local allspawns = #spawnsList
    
    if allspawns == 0 then return 1 end 

    local plyLastSpawn = ply.LastSpawn or 1
    local nextspawn = 1

    for attempt = 1, 5 do
        nextspawn = plyLastSpawn + math.random(1, 5)
        if nextspawn > allspawns then
            nextspawn = nextspawn % allspawns
            if nextspawn == 0 then nextspawn = allspawns end
        end

        if IsSpawnClear(spawnsList[nextspawn].pos) then
            ply.LastSpawn = nextspawn
            return nextspawn
        end
    end

    for i = 1, allspawns do
        if IsSpawnClear(spawnsList[i].pos) then
            ply.LastSpawn = i
            return i
        end
    end
    ply.LastSpawn = nextspawn
    return nextspawn
end

function GM:PlayerSpawn(ply)

	local client_model = ply:GetInfo("hldm_cl_playermodel")
	local pmodel

	if client_model and client_model ~= "" then
		pmodel = client_model
	else
		pmodel = "models/player/hl1/player.mdl"
	end

	local is_model_valid = false

	for k, v in pairs(modelFiles) do
		local model_in_list = "models/player/hl1/" .. v
		
		if pmodel == model_in_list then
			is_model_valid = true 
			break 
		end
	end
	if not is_model_valid then pmodel = "models/player/hl1/player.mdl" end

	local runspeed, walkspeed = 160, 270
	local gravity = GetConVarNumber("sv_gravity")
	local jumppower = math.sqrt(2 * gravity * 45.0)

	local start_weapons = {"weapon_hl1_crowbar", "weapon_hl1_glock"}
	for _,v in pairs(start_weapons) do
		ply:Give(v)
	end
	if ply:IsBot() then
		pmodel = ply.BotPM or "models/player/hl1/player.mdl"
	end
	local spawnpos = SpawnDecider(ply, self.SpawnsInOrder)

	ply:SetModel(pmodel)
	if self.SpawnsInOrder and self.SpawnsInOrder[spawnpos] then
		ply:SetPos(self.SpawnsInOrder[spawnpos].pos)
		ply:SetEyeAngles(self.SpawnsInOrder[spawnpos].ang)
	end
	ply:SetRunSpeed(runspeed)
	ply:SetWalkSpeed(walkspeed)
	ply:SetJumpPower(jumppower)
	ply:SetCrouchedWalkSpeed(.4)
	ply:SetDuckSpeed(.4)
	ply:SetUnDuckSpeed(.15)
	ply:SetLongJump()
	ply:SetMaxSpeed(3500)
	ply:SetGravity(1)
	ply:EmitSound("gsrchud/default/gunpickup2.wav", 85, 100, 1, CHAN_ITEM)

	ply:CrosshairEnable()
end

function GM:PlayerStepSoundTime( ply, iType, bWalking )

	local fStepTime = 350
	local fMaxSpeed = ply:GetMaxSpeed()
	local dir = ply:GetVelocity():GetNormalized():Dot(ply:GetForward())

	if ( iType == STEPSOUNDTIME_NORMAL || iType == STEPSOUNDTIME_WATER_FOOT ) then
		
		if ( fMaxSpeed <= 180 ) then
			fStepTime = 450
			if dir < 0 then
				fStepTime = fStepTime / 1.25
			end
		elseif ( fMaxSpeed <= 300 ) then
			fStepTime = 330
		else
			fStepTime = 320
		end
	
	elseif ( iType == STEPSOUNDTIME_ON_LADDER ) then
	
		fStepTime = 450
	
	elseif ( iType == STEPSOUNDTIME_WATER_KNEE ) then
	
		fStepTime = 600
	
	end
	
	if ( ply:Crouching() ) then
		fStepTime = fStepTime*1.25
	end
	
	return fStepTime
	
end

local PLAYER_LONGJUMP_SPEED = 350
local DOLONGJUMP

local function DoCrouchTrace(origin, endpos)
	endpos = endpos or Vector()
	local plyTable = player.GetAll()
	local tr = util.TraceHull({
		start = origin,
		endpos = origin + endpos,
		filter = plyTable,
		mask = MASK_PLAYERSOLID,
		mins = Vector(-16, -16, 0),
		maxs = Vector(16, 16, 72)
	})
	return tr
end

function GM:SetupMove(ply, move, cmd)
	if hook.Run("ShouldLockMovement") then
		move:SetMaxClientSpeed(0.1)
		return
	end

	if ply:Alive() and ply:GetMoveType() == MOVETYPE_WALK and !ply:OnGround() and ply:WaterLevel() < 1 then
		local tr = DoCrouchTrace(move:GetOrigin())
		if !tr.Hit then
			local crouchOffset = Vector(0,0,16)
			if !ply:Crouching() and cmd:KeyDown(IN_DUCK) then
				tr = DoCrouchTrace(move:GetOrigin(), -crouchOffset)
				move:SetOrigin(tr.HitPos)
				if tr.Hit then
					move:SetOrigin(move:GetOrigin() - crouchOffset)
				end
			end
			if ply:Crouching() and move:KeyReleased(IN_DUCK) then
				tr = DoCrouchTrace(move:GetOrigin(), crouchOffset)
				move:SetOrigin(tr.HitPos)
			end
		end
	end

	-- barnacle fix
	if ply:GetMoveType() == MOVETYPE_FLY then
		ply:SetMoveType(MOVETYPE_NONE)
		move:SetVelocity(Vector(0,0,0))
	end

	if self.NewChapterDelay and self.NewChapterDelay > CurTime() then
		move:SetMaxClientSpeed(0.1)
	end
	
	if ply:OnGround() and move:KeyDown(IN_USE) then
		local vel = move:GetVelocity()
		vel.x = vel.x / 64
		vel.y = vel.y / 64
		move:SetVelocity(vel)
	end
	
	if ply:GetLongJump() and !ply:Crouching() and move:GetMaxClientSpeed() >= 1 then
		if move:KeyPressed(IN_DUCK) then
			ply.LongJumpTime = CurTime() + .25
		end
		if ply.LongJumpTime and ply.LongJumpTime > CurTime() and move:KeyPressed(IN_JUMP) and move:GetVelocity():Length() > 50 and ply:OnGround() then
			DOLONGJUMP = true
		end
	end
	
	-- gravity prediction fix
	-- if SERVER then
		-- local grav = ply:GetGravity()
		-- if grav != ply:GetNWFloat("Gravity") then
			-- ply:SetNWFloat("Gravity", grav)
		-- end
	-- else
		-- local grav = ply:GetNWFloat("Gravity")
		-- if grav != ply:GetGravity() then
			-- ply:SetGravity(grav)
		-- end
	-- end
end

function GM:FinishMove(ply, move)
	local vel = move:GetVelocity()
	if DOLONGJUMP then
		for i = 1, 2 do
			vel[i] = move:GetAngles():Forward()[i] * PLAYER_LONGJUMP_SPEED * 1.6
		end
		vel[3] = math.sqrt(2 * 800 * 56.0)
		move:SetVelocity(vel)
		ply:SetViewPunchAngles(Angle(-5, 0, 0))
		
		DOLONGJUMP = nil
	end
	ply:SetActAbsVelocity(vel)
end

function GM:ShowHelp(ply)
   if IsValid(ply) then
      ply:ConCommand("hldm_mainmenu")
   end
end

function GM:UpdateAnimation( ply, velocity, maxSeqGroundSpeed )

    if self.BaseClass.UpdateAnimation then
        self.BaseClass.UpdateAnimation( self, ply, velocity, maxSeqGroundSpeed )
    else
        local len = velocity:Length()
        local rate = len / maxSeqGroundSpeed
        if len > 0.2 then
            ply:SetPlaybackRate( rate )
        else
            ply:SetPlaybackRate( 1.0 )
        end
    end

    local currRate = ply:GetPlaybackRate()
    
    local slowFactor = .7
    
    ply:SetPlaybackRate( currRate * slowFactor )
    

end

function GM:EntityEmitSound(snd)
	if snd.SoundName == "player/pl_drown1.wav" then
		return false
	end
end