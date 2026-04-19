if CLIENT then return end

function SetPlayerSpectator(ply, isSpectator)
    if not IsValid(ply) then return end
    
    ply:SetNWBool("IsSpectator", isSpectator)
    
    if isSpectator then
        
        ply:StripWeapons()
        ply:SetMoveType(MOVETYPE_NOCLIP)
        ply:SetSolid(SOLID_NONE) 
        ply:SetCollisionGroup(COLLISION_GROUP_DEBRIS) 
        ply:DrawViewModel(false) 
    else
        
        ply:SetMoveType(MOVETYPE_WALK)
        ply:SetSolid(SOLID_BBOX)
        ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
        ply:DrawViewModel(true)
        ply:UnSpectate() 
    end
end

function IsSpectator(ply)
    if not IsValid(ply) then return false end
    return ply:GetNWBool("IsSpectator", false)
end

local SpectatorData = 0
local SpectatorModes = {OBS_MODE_CHASE, OBS_MODE_IN_EYE, OBS_MODE_ROAMING}

function GetValidSpectatorTargets()
    local targets = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and not IsSpectator(ply) then
            table.insert(targets, ply)
        end
    end
    return targets
end

local SpectatorKeysDown = {}
_G.SpectatorTargetIndex = _G.SpectatorTargetIndex or {}

function SwitchSpectatorTarget(ply, bForward)
    if not IsSpectator(ply) then return end

    local targets = GetValidSpectatorTargets()
    
    if #targets == 0 then
        ply:Spectate(OBS_MODE_ROAMING)
        _G.SpectatorTargetIndex[ply:SteamID()] = nil
        return
    end

    local currentIndex = _G.SpectatorTargetIndex[ply:SteamID()] or 0
    local newIndex

    if bForward then
        newIndex = currentIndex + 1
        if newIndex > #targets then
            newIndex = 1
        end
    else
        newIndex = currentIndex - 1
        if newIndex < 1 then
            newIndex = #targets
        end
    end
    
    _G.SpectatorTargetIndex[ply:SteamID()] = newIndex
    
    newTarget = targets[newIndex]
    
    if IsValid(newTarget) then
        ply:SpectateEntity(newTarget)
        ply:Spectate(ply.CurrentSpectatorMode or OBS_MODE_ROAMING)
    end
end

function SwitchSpectatorMode(ply)
    if not IsValid(ply) then return end
    

    local currentMode = ply.CurrentSpectatorMode or OBS_MODE_ROAMING
    local nextMode

    if currentMode == OBS_MODE_ROAMING then
        nextMode = OBS_MODE_CHASE
    elseif currentMode == OBS_MODE_CHASE then
        nextMode = OBS_MODE_IN_EYE
    else
        nextMode = OBS_MODE_ROAMING
    end

    ply.CurrentSpectatorMode = nextMode
    ply:Spectate(nextMode)
end

hook.Remove("KeyPress", "SpectatorSwitchKeyPress")
hook.Add("KeyPress", "SpectatorSwitchKeyPress", function(ply, key)

    if not IsSpectator(ply) then return end

    SpectatorKeysDown[ply] = SpectatorKeysDown[ply] or {}
    if SpectatorKeysDown[ply][key] then return end
    SpectatorKeysDown[ply][key] = true

    if key == IN_ATTACK then
        SwitchSpectatorTarget(ply, true)
    elseif key == IN_ATTACK2 then
        SwitchSpectatorTarget(ply, false)
    elseif key == IN_JUMP then
        SwitchSpectatorMode(ply)
        SwitchSpectatorTarget(ply,true)
    end
end)

hook.Remove("KeyRelease", "SpectatorSwitchKeyRelease")
hook.Add("KeyRelease", "SpectatorSwitchKeyRelease", function(ply, key)
    if not IsSpectator(ply) then return end
    
    if SpectatorKeysDown[ply] then
        SpectatorKeysDown[ply][key] = false
    end
end)

hook.Add("PlayerSpawn", "ExitSpectatorModeOnSpawn", function(ply)
    if IsSpectator(ply) then
        SetPlayerSpectator(ply, false)
    end
end)