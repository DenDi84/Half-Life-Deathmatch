util.AddNetworkString("Killfeed_AddEntry")

GM.MortarButtonOwner = GM.MortarButtonOwner or {}

hook.Add("PlayerDeath", "SendKillfeedEntry", function(victim, inflictor, attacker)

    if not IsValid(victim) then
        return
    end
    if game.GetMap() == "hldm_crossfire" then
        if IsValid(inflictor) and IsValid(attacker) then
            if inflictor:GetClass() == "rpg_missile" and attacker:GetClass() == "func_tankrocket" then
                if attacker:MapCreationID() == 1367 and IsValid(GAMEMODE.MortarButtonOwner.left) then
                    attacker = GAMEMODE.MortarButtonOwner.left
                elseif attacker:MapCreationID() == 1452 and IsValid(GAMEMODE.MortarButtonOwner.right) then
                    attacker = GAMEMODE.MortarButtonOwner.right
                end
            end
        end
    end

    local victimName = victim:Nick()
    local attackerName = "The World"
    local weaponClass = "worldspawn" 

    if IsValid(attacker) and attacker:IsPlayer() then
        if attacker == victim then
            attackerName = "" 
            
        else
            attackerName = attacker:Nick()
            local wep = attacker:GetActiveWeapon()
            if IsValid(wep) then
                weaponClass = wep:GetClass()
            end
           
        end
    else
        
    end


    if IsValid(inflictor) and inflictor ~= attacker then
        
        weaponClass = inflictor:GetClass()
    end

    local iconName = WEAPON_ICONS[weaponClass]

    if not iconName then
        iconName = "skull"
    end
    
    net.Start("Killfeed_AddEntry")
        net.WriteString(attackerName)
        net.WriteString(victimName)
        net.WriteString(iconName)
    net.Broadcast()


end)

timer.Simple(0,function()

    if game.GetMap() == "hldm_crossfire" then
    GAMEMODE.MortarButtonOwner = { left , right }

        hook.Add("PlayerUse", "Who Touched it Last", function(ply, ent)
            if ent:GetClass() == "func_button" then
                if ent:MapCreationID() == 1453 then
                    GAMEMODE.MortarButtonOwner.right = ply
                elseif ent:MapCreationID() == 1450 then
                    GAMEMODE.MortarButtonOwner.left = ply
                end
            end
        end)
    end

end)