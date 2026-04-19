Fraglimit = CreateConVar("hldm_fraglimit",30, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY},"Set the fraglimit",0)
Timelimit = CreateConVar("hldm_timelimit",240, {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY},"Set the timelimit",0)
MinPlayers = CreateConVar("hldm_minplayers",4,{FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Set minplayers to begin game", nil,nil,minplayerscheck)

concommand.Add("hldm_restartround",function(ply,cmd,args)
    if ply:IsValid() and not ply:IsAdmin() then return end
    GAMEMODE:CheckRoundStartConditions(true)  
end)

if SERVER then
    concommand.Add("hldm_gotospec",function(ply,cmd,args)

        if not IsValid(ply) then return end
        local currentStatus = IsSpectator(ply)
        local newStatus = not currentStatus 

        if newStatus then
        
            SetPlayerSpectator(ply, true)
                
            timer.Simple(0.1, function() 
                if IsValid(ply) and IsSpectator(ply) then
                    SwitchSpectatorTarget(ply, true) 
                end
            end)
        else
            SetPlayerSpectator(ply, false)
            ply:Spawn()
        end 
        
    end)
end

VocoderType = CreateClientConVar("hldm_vocoder","female",true,false,"You can select the type of vocoder between Male and Female (the thing which counts from 10 to 1 on begining of round)")
HLDM_PlayerModel = CreateClientConVar("hldm_cl_playermodel", "models/player/hl1/player.mdl", true, true, "HLDM Custom Playermodel")