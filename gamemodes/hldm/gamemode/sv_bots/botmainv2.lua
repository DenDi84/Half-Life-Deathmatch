local ItemPriority = {
    ["weapon_hl1_rpg"] = 100,
    ["weapon_hl1_gauss"] = 95,
    ["weapon_hl1_egon"] = 95,
    ["weapon_hl1_crossbow"] = 85,
    ["weapon_hl1_mp5"] = 80,
    ["weapon_hl1_shotgun"] = 80,
    ["weapon_hl1_357"] = 85,
    ["weapon_hl1_hornetgun"] = 70,
    ["weapon_hl1_glock"] = 50,
    ["weapon_hl1_crowbar"] = 10,

    ["weapon_hl1_handgrenade"] = 65,
    ["weapon_hl1_satchel"] = 70,
    ["weapon_hl1_tripmine"] = 60,
    ["weapon_hl1_snark"] = 55,

    ["hl1_item_healthkit"] = 90,
    ["hl1_item_battery"] = 85,
    ["hl1_item_longjump"] = 75,

    ["hl1_ammo_9mmar"] = 30,
    ["hl1_ammo_9mmbox"] = 30,
    ["hl1_ammo_9mmclip"] = 25,
    ["hl1_ammo_357"] = 35,
    ["hl1_ammo_argrenades"] = 40,
    ["hl1_ammo_buckshot"] = 35,
    ["hl1_ammo_crossbow"] = 40,
    ["hl1_ammo_gaussclip"] = 45,
    ["hl1_ammo_rpgclip"] = 50,
}

local THINK_INTERVAL = 0.5
local PATH_RECALC_INTERVAL = 1.0

local COMBAT_RANGE = 1000
local ITEM_PICKUP_RANGE = 22
local SEARCH_RADIUS = 2000

local BotData = {}

local function GetBotData(bot)
    local idx = bot:EntIndex()
    if not BotData[idx] then
        BotData[idx] = {
            target = nil,
            istargetobsession = false,
            path = nil,
            nextThink = 0,
            nextPathCalc = 0,
            unreachableTargets = {},
            nextStrafe = 0,
            strafeDir = 0,
            nextCombatJump = 0,
            ladderDirection = 0,
            ladderJumpTime = nil,
            scoreBias = math.Rand(0.7, 1.3),
            lastStuckCheckPos = nil,
            lastStuckCheckTime = 0,
            stuckDuration = 0,
            unstuckUntil = 0,
            unstuckYaw = 0,
        }
    end
    return BotData[idx]
end

hook.Add("PlayerDisconnected", "SmartBot_Cleanup", function(ply)
    if ply:IsBot() then
        BotData[ply:EntIndex()] = nil
    end
end)

local function FindPath(startPos, endPos)
    local startArea = navmesh.GetNearestNavArea(startPos)
    local endArea = navmesh.GetNearestNavArea(endPos)

    if not IsValid(startArea) or not IsValid(endArea) then
        return nil
    end

    if startArea == endArea then
        return { endArea }
    end

    local openSet = { startArea }
    local openSetLookup = {}
    local cameFrom = {}
    local gScore = {}
    local fScore = {}

    local startID = startArea:GetID()
    gScore[startID] = 0
    fScore[startID] = startPos:DistToSqr(endPos)
    openSetLookup[startID] = true

    local iterations = 0
    local maxIterations = 300

    while #openSet > 0 do
        iterations = iterations + 1
        if iterations > maxIterations then break end

        local current = nil
        local lowestF = math.huge
        local currentIndex = -1

        for i, area in ipairs(openSet) do
            local score = fScore[area:GetID()] or math.huge
            if score < lowestF then
                lowestF = score
                current = area
                currentIndex = i
            end
        end

        if not IsValid(current) then break end
        if current == endArea then
            local path = { current }
            while cameFrom[current:GetID()] do
                current = cameFrom[current:GetID()]
                table.insert(path, 1, current)
            end
            return path
        end

        table.remove(openSet, currentIndex)
        openSetLookup[current:GetID()] = nil

        for _, neighbor in pairs(current:GetAdjacentAreas()) do

            if IsValid(neighbor) and current:IsConnected(neighbor) then

                local nID = neighbor:GetID()
                local cID = current:GetID()

                local dist = current:GetCenter():DistToSqr(neighbor:GetCenter())
                local tentative_gScore = (gScore[cID] or math.huge) + dist

                if tentative_gScore < (gScore[nID] or math.huge) then
                    cameFrom[nID] = current
                    gScore[nID] = tentative_gScore
                    fScore[nID] = tentative_gScore + neighbor:GetCenter():DistToSqr(endPos)

                    if not openSetLookup[nID] then
                        table.insert(openSet, neighbor)
                        openSetLookup[nID] = true
                    end
                end
            end
        end

        for _, ladder in pairs(current:GetLadders()) do
            if IsValid(ladder) then
                local neighbor = nil
                if ladder:GetBottomArea() == current then
                    neighbor = ladder:GetTopForwardArea()
                    if not IsValid(neighbor) then neighbor = ladder:GetTopLeftArea() end
                    if not IsValid(neighbor) then neighbor = ladder:GetTopRightArea() end
                else
                    neighbor = ladder:GetBottomArea()
                end

                if IsValid(neighbor) then
                    local nID = neighbor:GetID()
                    local cID = current:GetID()

                    local edgeCost = current:GetCenter():DistToSqr(neighbor:GetCenter())
                    local tentative_gScore = (gScore[cID] or math.huge) + edgeCost

                    if tentative_gScore < (gScore[nID] or math.huge) then
                        cameFrom[nID] = current
                        gScore[nID] = tentative_gScore
                        fScore[nID] = tentative_gScore + neighbor:GetCenter():DistToSqr(endPos)

                        if not openSetLookup[nID] then
                            table.insert(openSet, neighbor)
                            openSetLookup[nID] = true
                        end
                    end
                end
            end
        end
    end
end

local function IsItemReachable(bot, item)
    local botPos = bot:GetPos()
    local itemPos = item:GetPos()

    local botArea = navmesh.GetNearestNavArea(botPos)
    local itemArea = navmesh.GetNearestNavArea(itemPos,false,10)

    if not IsValid(botArea) or not IsValid(itemArea) then
        return false
    end

    local path = FindPath(botPos, itemPos)

    if path and #path > 0 then
        local pathLength = 0
        for i = 1, #path - 1 do
            pathLength = pathLength + path[i]:GetCenter():Distance(path[i + 1]:GetCenter())
        end

        local directDist = botPos:Distance(itemPos)

        if pathLength > directDist * 3 then
            return false
        end

        return true
    end

    return false
end

local function ScoreItem(ent, botPos, botHealth, botArmor, distanceDivisor, scoreBias)
    local class = ent:GetClass()
    local dist = botPos:DistToSqr(ent:GetPos())
    local priority = ItemPriority[class] or 15

    if class == "hl1_item_healthkit" then
        if botHealth == 100 then return -math.huge end
        priority = priority + math.abs(botHealth - 100)
        if botHealth < 50 then priority = priority + 50 end

    elseif class == "hl1_item_battery" then
        if botArmor == 100 then return -math.huge end
        priority = priority + math.abs(botArmor - 100)
        if botArmor < 50 then priority = priority + 40 end
    end

    priority = priority * (scoreBias or 1.0) + math.Rand(-10, 10)

    return priority - (dist / distanceDivisor)
end

local function CanBotPickup(bot, ent)
    if not IsValid(ent) then return false end

    local class = ent:GetClass()
    local isWeapon = string.StartWith(class, "weapon_hl1_")
    local isItem   = string.StartWith(class, "hl1_item_")
    local isAmmo   = string.StartWith(class, "hl1_ammo_")

    if not (isWeapon or isItem or isAmmo) then return false end
    if ent.Pickable == false then return false end
    if IsValid(ent:GetOwner()) then return false end

    if isAmmo and ent.AmmoType and ent.MaxAmmo and bot:GetAmmoCount(ent.AmmoType) >= ent.MaxAmmo then
        return false
    end

    if isWeapon and bot:HasWeapon(class) then
        local ammoType = ent:GetPrimaryAmmoType()
        local maxAmmo = ent.MaxAmmo
        if maxAmmo and bot:GetAmmoCount(ammoType) >= maxAmmo then return false end
    end

    if class == "hl1_item_longjump" and bot:GetLongJump() then return false end

    return true
end

local function FindBestItem(bot, entList, distanceDivisor, data)
    local botPos = bot:GetPos()
    local botHealth = bot:Health()
    local botArmor = bot:Armor()
    local scoreBias = data.scoreBias or 1.0
    local currentTarget = data.target

    local bestItem = nil
    local bestScore = -math.huge

    for _, ent in ipairs(entList) do
        if not IsValid(ent) then continue end
        if data.unreachableTargets[ent] then continue end
        if not CanBotPickup(bot, ent) then continue end

        local score = ScoreItem(ent, botPos, botHealth, botArmor, distanceDivisor, scoreBias)

        if bot:VisibleVec(ent:WorldSpaceCenter()) then
            score = score + 25
        end

        if IsValid(currentTarget) and ent == currentTarget then
            score = score + 30
        end

        if score > bestScore then
            bestScore = score
            bestItem = ent
        end
    end

    return bestItem
end

local function GetBestAimPosition(bot, target)
    local center = target:WorldSpaceCenter()

    if bot:VisibleVec(center) then return center end

    local head = target:GetShootPos()
    if bot:VisibleVec(head) then return head end
    return center
end

local function GetBestTarget(bot)
    local botPos = bot:GetPos()
    local botHealth = bot:Health()
    local botArmor = bot:Armor()

    local data = GetBotData(bot)

    for ent, time in pairs(data.unreachableTargets or {}) do
        if CurTime() > time then
            data.unreachableTargets[ent] = nil
        end
    end

    local isArmed = false
    for _, wep in ipairs(bot:GetWeapons()) do
        local class = wep:GetClass()
        if class ~= "weapon_hl1_crowbar" and class ~= "weapon_hl1_glock" then
            local priority = ItemPriority[class] or 0
            if priority >= 70 then
                isArmed = true
                break
            end
        end
    end

    local mateTarget = nil
    if bot.BestFriend then
        -- Find the mate
        local mate = nil
        for _, p in ipairs(player.GetAll()) do
            if p ~= bot and p.BestFriend and p:Alive() and not p:GetNWBool("IsSpectator", false) then
                mate = p
                break
            end
        end

        if mate then
            local mateData = GetBotData(mate)
            if IsValid(mateData.target) and mateData.target:IsPlayer() and mateData.target:Alive() then
                mateTarget = mateData.target
            end
        end
    end

    local bestEnemy = nil
    local minEnemyDist = math.huge

    for _, ply in ipairs(player.GetAll()) do
        if ply ~= bot and ply:Alive() and not ply:GetNWBool("IsSpectator", false) then
            -- DO NOT ATTACK MATE
            if bot.BestFriend and ply.BestFriend then continue end

            local dist = botPos:DistToSqr(ply:GetPos())

            if (bot:Visible(ply) or bot:VisibleVec(ply:GetShootPos())) and dist < minEnemyDist then
                minEnemyDist = dist
                bestEnemy = ply
            end
        end
    end

    if IsValid(bestEnemy) then
        return bestEnemy
    end

    if isArmed and IsValid(mateTarget) then
        return mateTarget
    end

    local nearbyEnts = ents.FindInSphere(botPos, SEARCH_RADIUS)
    local bestItem = FindBestItem(bot, nearbyEnts, 10000, data)

    if IsValid(bestItem) then
        return bestItem
    end

    if isArmed and mate and mate:Alive() then
        if botPos:DistToSqr(mate:GetPos()) > (1500 * 1500) then
            return mate
        end
    end

    local fallbackEnemy = nil
    local fallbackDist = math.huge

    for _, ply in ipairs(player.GetAll()) do
        if ply ~= bot and ply:Alive() and not ply:GetNWBool("IsSpectator", false) then
            if bot.BestFriend and ply.BestFriend then continue end
            if data.unreachableTargets and data.unreachableTargets[ply] then continue end

            local dist = botPos:DistToSqr(ply:GetPos())
            if dist < fallbackDist then
                fallbackDist = dist
                fallbackEnemy = ply
            end
        end
    end

    if IsValid(fallbackEnemy) then
        return fallbackEnemy
    end

    local allEnts = ents.GetAll()
    local bestAnyItem = FindBestItem(bot, allEnts, 50000, data)

    return bestAnyItem
end

local function SelectBestWeapon(bot)
    local data = GetBotData(bot)
    if CurTime() < (data.nextWeaponCheck or 0) then return end
    data.nextWeaponCheck = CurTime() + 0.5

    local currentWeapon = bot:GetActiveWeapon()
    local currentScore = -1

    if IsValid(currentWeapon) then
        currentScore = ItemPriority[currentWeapon:GetClass()] or 0
        if currentWeapon:Clip1() == 0 and currentWeapon:GetMaxClip1() > 0 and currentWeapon:Ammo1() == 0 then
            currentScore = 0
        end
    end

    local bestWeapon = nil
    local bestScore = -1

    for _, weapon in ipairs(bot:GetWeapons()) do
        local class = weapon:GetClass()
        local score = ItemPriority[class] or 0

        if weapon:Clip1() == 0 and weapon:GetMaxClip1() > 0 and weapon:Ammo1() == 0 then
            score = 0
            if class == "weapon_hl1_crowbar" then score = 10 end
        end

        if score > bestScore then
            bestScore = score
            bestWeapon = weapon
        end
    end

    if IsValid(bestWeapon) and bestWeapon ~= currentWeapon then
        if bestScore > currentScore then
            bot:SelectWeapon(bestWeapon:GetClass())
        end
    end
end

hook.Add("StartCommand", "SmartBot_AI", function(ply, cmd)
    if not ply:IsBot() or not ply:Alive() then return end
    if GetConVar("bot_zombie"):GetInt() > 0 then return end

    cmd:ClearButtons()

    local data = GetBotData(ply)
    local curTime = CurTime()
    local botPos = ply:GetPos()

    if curTime > data.nextThink then
        data.nextThink = curTime + THINK_INTERVAL

        local opportunistic = nil
        for _, ent in ipairs(ents.FindInSphere(botPos, 150)) do
            if CanBotPickup(ply, ent) and not (data.unreachableTargets and data.unreachableTargets[ent]) then
                local score = ScoreItem(ent, botPos, ply:Health(), ply:Armor(), 10000, data.scoreBias or 1.0)
                if score > 0 then
                    if not opportunistic or botPos:DistToSqr(ent:GetPos()) < botPos:DistToSqr(opportunistic:GetPos()) then
                        opportunistic = ent
                    end
                end
            end
        end

        local newTarget
        if IsValid(opportunistic) then
            newTarget = opportunistic
        else
            newTarget = GetBestTarget(ply)
        end

        if newTarget ~= data.target then
            data.target = newTarget
            data.nextPathCalc = 0
        end

        SelectBestWeapon(ply)
    end

    if curTime > data.lastStuckCheckTime + 1.5 then
        if data.lastStuckCheckPos and botPos:DistToSqr(data.lastStuckCheckPos) < 900 then
            data.stuckDuration = data.stuckDuration + 1.5

            if data.stuckDuration >= 3.0 then
                if IsValid(data.target) then
                    data.unreachableTargets = data.unreachableTargets or {}
                    data.unreachableTargets[data.target] = CurTime() + 15
                    data.target = nil
                    data.path = nil
                    data.nextThink = 0
                    data.nextPathCalc = 0
                end
                data.stuckDuration = 0
                data.unstuckUntil = curTime + 1.5
                data.unstuckYaw = math.random(0, 360)

            elseif data.stuckDuration >= 1.5 then
                if data.unstuckUntil < curTime then
                    data.unstuckUntil = curTime + 1.0
                    data.unstuckYaw = math.random(0, 360)
                end
            end
        else
            data.stuckDuration = 0
        end

        data.lastStuckCheckPos = Vector(botPos.x, botPos.y, botPos.z)
        data.lastStuckCheckTime = curTime
    end

    if curTime > data.nextPathCalc and IsValid(data.target) then
        data.nextPathCalc = curTime + PATH_RECALC_INTERVAL

        local startArea = navmesh.GetNearestNavArea(botPos)

        if not IsValid(startArea) then
             print("Bot off navmesh - pathing delayed")
             data.path = nil
        else
            local newPath = FindPath(botPos, data.target:GetPos())

            if newPath then
                local myArea = navmesh.GetNearestNavArea(botPos)
                if IsValid(myArea) and newPath[1] == myArea and #newPath > 1 then
                    table.remove(newPath, 1)
                end
                data.path = newPath
            else
                data.path = nil
                if IsValid(data.target) then
                    data.unreachableTargets = data.unreachableTargets or {}
                    data.unreachableTargets[data.target] = CurTime() + 10
                    data.target = nil
                    data.nextThink = 0
                end
            end
        end
    end

    if not IsValid(data.target) then
        cmd:ClearMovement()
        cmd:ClearButtons()
        return
    end

    local targetPos = data.target:GetPos()
    local moveToPos = targetPos

    if data.path and #data.path > 0 then
        local nextArea = data.path[1]

        if IsValid(nextArea) then
            local nextPos

            if #data.path == 1 then
                nextPos = targetPos
            elseif #data.path >= 2 and IsValid(data.path[2]) then
                local areaAfter = data.path[2]
                local edgePoint = nextArea:GetClosestPointOnArea(areaAfter:GetCenter())

                local pullTarget = areaAfter:GetCenter()
                nextPos = LerpVector(0.3, edgePoint, pullTarget)
                nextPos.z = edgePoint.z
            else
                nextPos = nextArea:GetCenter()
            end

            local dist2D = (Vector(botPos.x, botPos.y, 0) - Vector(nextPos.x, nextPos.y, 0)):LengthSqr()

            if nextArea:Contains(botPos + Vector(0, 0, 5)) or dist2D < 1600 then
                table.remove(data.path, 1)
            else
                moveToPos = nextPos
            end

            data.navLookPos = Vector(moveToPos.x, moveToPos.y, moveToPos.z)

            if math.abs(nextPos.z - botPos.z) < 40 then
                moveToPos.z = botPos.z + 64
            else
                moveToPos.z = nextPos.z
            end
        else
            table.remove(data.path, 1)
        end
    end

    local navLookPos = data.navLookPos or moveToPos

    local aimPos = navLookPos
    local turnSpeed = 0.1
    local snapPitch = false

    if data.target:IsPlayer() and (ply:Visible(data.target) or ply:VisibleVec(data.target:GetShootPos())) then
        aimPos = GetBestAimPosition(ply, data.target)
        local combatAimAngle = (aimPos - ply:GetShootPos()):Angle()
        local pitchDiff = math.abs(math.AngleDifference(math.NormalizeAngle(combatAimAngle.p), math.NormalizeAngle(ply:EyeAngles().p)))
        if pitchDiff > 30 then
            turnSpeed = 0.8
        else
            turnSpeed = 0.5
        end
        debugoverlay.Line(ply:GetShootPos(), aimPos, 0.1, Color(0, 183, 255))
    else
        local lookDir = (navLookPos - ply:GetShootPos()):GetNormalized()
        local useableEnt = nil

        local pathTrace = util.TraceHull({
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + lookDir * 150,
            mins = Vector(-16, -16, -16),
            maxs = Vector(16, 16, 16),
            filter = ply
        })

        if pathTrace.Hit and IsValid(pathTrace.Entity) then
            local class = pathTrace.Entity:GetClass()
            if string.find(class, "door") or string.find(class, "button") or string.find(class, "plat") then
                useableEnt = pathTrace.Entity
            end
        end

        if not IsValid(useableEnt) then
            local moveDir2D = (moveToPos - ply:GetShootPos()):GetNormalized()
            local pathTrace2 = util.TraceHull({
                start = ply:GetShootPos(),
                endpos = ply:GetShootPos() + moveDir2D * 150,
                mins = Vector(-20, -20, -32),
                maxs = Vector(20, 20, 32),
                filter = ply
            })

            if pathTrace2.Hit and IsValid(pathTrace2.Entity) then
                local class = pathTrace2.Entity:GetClass()
                if string.find(class, "door") or string.find(class, "button") or string.find(class, "plat") then
                    useableEnt = pathTrace2.Entity
                end
            end
        end

        local pathGoesUp = false
        if IsValid(data.target) then
            local destZ = data.target:GetPos().z
            if data.path and #data.path > 0 and IsValid(data.path[2]) then
                destZ = data.path[2]:GetCenter().z
            end
            pathGoesUp = destZ > (botPos.z + 40)
        end
        local nearbyButton = nil
        if pathGoesUp then
            for _, ent in ipairs(ents.FindInSphere(ply:GetShootPos(), 250)) do
                if IsValid(ent) and string.find(ent:GetClass(), "button") then
                    if not nearbyButton or ply:GetShootPos():DistToSqr(ent:WorldSpaceCenter()) < ply:GetShootPos():DistToSqr(nearbyButton:WorldSpaceCenter()) then
                        nearbyButton = ent
                    end
                end
            end
        end

        if IsValid(nearbyButton) then
            useableEnt = nearbyButton
        end

        if IsValid(useableEnt) then
            aimPos = useableEnt:WorldSpaceCenter()
            turnSpeed = 1.0
            snapPitch = true
            debugoverlay.Line(ply:GetShootPos(), aimPos, 0.1, Color(255, 255, 0))
        end
    end

    local aimAngle = (aimPos - ply:GetShootPos()):Angle()
    aimAngle.p = math.NormalizeAngle(aimAngle.p)
    aimAngle.y = math.NormalizeAngle(aimAngle.y)
    aimAngle.r = 0

    local currentAngle = ply:EyeAngles()

    local curP = math.NormalizeAngle(currentAngle.p)
    local aimP = math.NormalizeAngle(aimAngle.p)
    local curY = math.NormalizeAngle(currentAngle.y)
    local aimY = math.NormalizeAngle(aimAngle.y)

    local diffP = math.AngleDifference(aimP, curP)
    local diffY = math.AngleDifference(aimY, curY)

    local fractionP = math.Clamp(math.abs(diffP) / 60, 0, 1)
    local fractionY = math.Clamp(math.abs(diffY) / 60, 0, 1)
    if fractionP >= 0.95 then fractionP = 1 end
    if fractionY >= 0.95 then fractionY = 1 end

    local easeP = math.ease.OutQuad(fractionP)
    local easeY = math.ease.OutQuad(fractionY)

    local baseSpeed = turnSpeed * 50

    local speedP = 4 + (baseSpeed * easeP)
    local speedY = 2 + (baseSpeed * easeY)

    local pitch
    if snapPitch then
        pitch = aimP
    else
        pitch = math.Approach(curP, aimP, speedP)
    end
    pitch = math.Clamp(pitch, -89, 89)

    local yaw = math.ApproachAngle(currentAngle.y, aimAngle.y, speedY)

    local smoothAngle = Angle(pitch, yaw, 0)

    debugoverlay.Line(ply:GetShootPos(), ply:GetShootPos() + smoothAngle:Forward() * 1000, 0.1, Color(255, 0, 119))

    cmd:SetViewAngles(smoothAngle)
    ply:SetEyeAngles(smoothAngle)

    if ply:GetMoveType() == MOVETYPE_LADDER then

        if not data.ladderJumpTimer then
            data.ladderJumpTimer = CurTime() + 5
        end

        if CurTime() > data.ladderJumpTimer then
            data.ladderJumpTimer = nil

            cmd:SetButtons(IN_JUMP)

            cmd:SetForwardMove(-200)

            return
        end

        local destinationZ = 0
        if data.path and #data.path > 0 and IsValid(data.path[1]) then
            destinationZ = data.path[1]:GetCenter().z
        elseif IsValid(data.target) then
            destinationZ = data.target:GetPos().z
        end

        local myZ = ply:GetPos().z
        local targetPitch = 0

        if (data.ladderDirection or 0) == 0 then
            if destinationZ > myZ then
                data.ladderDirection = -89
            else
                data.ladderDirection = 89
            end
        end

        targetPitch = data.ladderDirection

        local currentAng = ply:EyeAngles()
        local newPitch = math.ApproachAngle(currentAng.p, targetPitch, FrameTime() * 300)

        local ladderYaw = currentAng.y
        local nearestArea = navmesh.GetNearestNavArea(botPos)

        if IsValid(nearestArea) then
            local ladders = nearestArea:GetLadders()
            if ladders and #ladders > 0 then
                local nearestLadder = nil
                local nearestDist = math.huge

                for _, ladder in pairs(ladders) do
                    if IsValid(ladder) then
                        local ladderCenter = (ladder:GetTop() + ladder:GetBottom()) / 2
                        local dist = botPos:DistToSqr(ladderCenter)
                        if dist < nearestDist then
                            nearestDist = dist
                            nearestLadder = ladder
                        end
                    end
                end

                if IsValid(nearestLadder) then
                    local ladderNormal = nearestLadder:GetNormal()
                    ladderYaw = (ladderNormal * -1):Angle().y
                end
            end
        end

        local finalAng = Angle(newPitch, ladderYaw, 0)

        cmd:SetViewAngles(finalAng)
        ply:SetEyeAngles(finalAng)

        cmd:SetForwardMove(200)
        cmd:SetSideMove(0)

        cmd:SetButtons(IN_FORWARD)

        return
    else
        data.ladderJumpTimer = nil
        data.ladderDirection = 0
    end

    local distToTarget = botPos:DistToSqr(targetPos)

    local stopDistance = ITEM_PICKUP_RANGE * ITEM_PICKUP_RANGE
    if data.target:IsPlayer() and ply:Visible(data.target) then
        if data.target.BestFriend and ply.BestFriend then
            stopDistance = 300 * 300
        else
            local dist2D = (Vector(botPos.x, botPos.y, 0) - Vector(targetPos.x, targetPos.y, 0)):LengthSqr()
            distToTarget = dist2D

            if ply:GetActiveWeapon():GetClass() == "weapon_hl1_crowbar" then
                stopDistance = COMBAT_RANGE * 3
            elseif ply:GetActiveWeapon():GetClass() == "weapon_hl1_shotgun" then
                stopDistance = COMBAT_RANGE * 100
            else
                stopDistance = COMBAT_RANGE * COMBAT_RANGE
            end
        end
    end

    if distToTarget > stopDistance then
        local moveDir = (moveToPos - botPos):GetNormalized()

        local viewForward = smoothAngle:Forward()
        local viewRight = smoothAngle:Right()

        local fwdMove = moveDir:Dot(viewForward) * 400
        local sideMove = moveDir:Dot(viewRight) * 400

        cmd:SetForwardMove(fwdMove)
        cmd:SetSideMove(sideMove)

        local pathGoesUp = false
        if IsValid(data.target) then
            local destZ = data.target:GetPos().z
            if data.path and #data.path > 0 and IsValid(data.path[1]) then
                destZ = data.path[1]:GetCenter().z
            end
            pathGoesUp = destZ > (botPos.z + 40)
        end

        local nearbyButton = nil
        if pathGoesUp then
            for _, ent in ipairs(ents.FindInSphere(ply:GetShootPos(), 200)) do
                if IsValid(ent) and string.find(ent:GetClass(), "button") then
                    if not nearbyButton or ply:GetShootPos():DistToSqr(ent:WorldSpaceCenter()) < ply:GetShootPos():DistToSqr(nearbyButton:WorldSpaceCenter()) then
                        nearbyButton = ent
                    end
                end
            end
        end

        local useTrace = util.TraceLine({
            start = ply:GetShootPos(),
            endpos = ply:GetShootPos() + smoothAngle:Forward() * 90,
            filter = ply
        })

        if useTrace.Hit and IsValid(useTrace.Entity) then
            local class = useTrace.Entity:GetClass()
            if string.find(class, "button") then
                if pathGoesUp then
                    cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_USE))
                end
            elseif not IsValid(nearbyButton) then
                if string.find(class, "door") or string.find(class, "plat") then
                    cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_USE))
                end
            end
        end

        if moveToPos.z > (botPos.z + 18) and botPos:DistToSqr(moveToPos) < 5000 and ply:GetMoveType() ~= MOVETYPE_LADDER then
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP))
        end

        local traceForward = util.TraceLine({
            start = botPos + Vector(0, 0, 15),
            endpos = botPos + smoothAngle:Forward() * 40 + Vector(0, 0, 15),
            filter = ply
        })
        if traceForward.Hit and traceForward.HitNormal.z < 0.7 and ply:GetMoveType() ~= MOVETYPE_LADDER then
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP))

        end

        if curTime < (data.unstuckUntil or 0) or ply:GetVelocity():Length() < 2 and ply:GetMoveType() ~= MOVETYPE_LADDER then
            local unstuckAng = Angle(0, data.unstuckYaw or 0, 0)
            local unstuckDir = unstuckAng:Forward()
            local unstuckFwd = unstuckDir:Dot(smoothAngle:Forward()) * 400
            local unstuckSide = unstuckDir:Dot(smoothAngle:Right()) * 400
            cmd:SetForwardMove(unstuckFwd)
            cmd:SetSideMove(unstuckSide)
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP))
        end

        if data.path and data.path[1] and IsValid(data.path[1]) then
            if data.path[1]:HasAttributes(NAV_MESH_JUMP) then
                cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP))
            end
        end

        if data.path and data.path[1] and IsValid(data.path[1]) then
            if data.path[1]:HasAttributes(NAV_MESH_CROUCH) then
                cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_DUCK))
            end
        end

        local currentArea = navmesh.GetNearestNavArea(botPos)
        if IsValid(currentArea) and currentArea:HasAttributes(NAV_MESH_CROUCH) then
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_DUCK))
        end

         if ply:GetLongJump() then
            local isJumpArea = false
            if data.path and data.path[1] and IsValid(data.path[1]) then
                 if data.path[1]:HasAttributes(NAV_MESH_JUMP) then
                    isJumpArea = true
                 end
            end

            local isFarTarget = false
            if distToTarget > 500 * 500 and ply:OnGround() then
                 isFarTarget = true
            end

            local isCombatJump = false
            if data.target:IsPlayer() and distToTarget < 800 * 800 and distToTarget > 200 * 200 and CurTime() > (data.nextCombatJump or 0) then
                 if ply:GetVelocity():Length2D() > 250 then
                    isCombatJump = true
                 end
            end

            if (isJumpArea or isFarTarget or isCombatJump) and ply:OnGround() and ply:GetVelocity():Length2D() > 200 then

                 if not data.doingLongJump then
                    cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_DUCK))
                    cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_JUMP)))
                    data.doingLongJump = true
                    data.longJumpTimer = CurTime() + 0.1

                    if isCombatJump then
                        data.nextCombatJump = CurTime() + math.random(2, 5)
                    end
                 elseif CurTime() < data.longJumpTimer then
                    cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP))
                    cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_DUCK)))
                 else
                    data.doingLongJump = false
                 end
            else
                data.doingLongJump = false
            end
         end

    else
        cmd:ClearMovement()

        local isMate = data.target:IsPlayer() and data.target.BestFriend and ply.BestFriend
        local isVisible = data.target:IsPlayer() and not isMate and (ply:Visible(data.target) or ply:VisibleVec(data.target:GetShootPos()))

        if isVisible then

            local aimSpot = GetBestAimPosition(ply, data.target)
            local trace = util.TraceLine({
                start = ply:GetShootPos(),
                endpos = aimSpot,
                filter = ply
            })

            if not trace.Hit or trace.Entity == data.target then
                local aimDir = (aimSpot - ply:GetShootPos()):GetNormalized()
                local lookDir = cmd:GetViewAngles():Forward()
                local dot = aimDir:Dot(lookDir)

                if dot > 0.9 then
                    cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_ATTACK))
                end
            end

            if trace.Hit and trace.Entity:GetClass() == "func_breakable_surf" then
                cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_ATTACK))
            end

            if curTime > (data.nextStrafe or 0) then
                data.nextStrafe = curTime + math.Rand(0.2, 1)

                local roll = math.random(1, 3)
                if roll == 1 then data.strafeDir = -400
                elseif roll == 2 then data.strafeDir = 400
                else data.strafeDir = 0 end
            end

            cmd:SetSideMove(data.strafeDir or 0)
        end
    end

    if IsValid(data.target) then
        debugoverlay.Line(ply:GetShootPos(), data.target:WorldSpaceCenter(), 0.1, Color(255, 0, 0), true)
        debugoverlay.Text(data.target:WorldSpaceCenter(), "TARGET", 0.1)
    end

    if data.path then
        local lastPos = botPos
        for _, area in ipairs(data.path) do
            if IsValid(area) then
                local nextPos = area:GetCenter()
                debugoverlay.Line(lastPos + Vector(0,0,10), nextPos + Vector(0,0,10), 0.1, Color(0, 255, 0), true)
                lastPos = nextPos
            end
        end
    end
end)

concommand.Add("hldm_addbot", function(ply, cmd, args)
    if not ply:IsAdmin() then return end
    RunConsoleCommand("bot")
end)

concommand.Add("hldm_addspecialbots", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local names = {"Mave", "Rick"}
    local index = 0

    local function SpawnNext()
        index = index + 1
        local name = names[index]
        if not name then return end

        -- снимок ботов до спавна
        local before = {}
        for _, bot in ipairs(player.GetBots()) do
            before[bot] = true
        end

        RunConsoleCommand("bot")

        timer.Simple(0.2, function()
            local found = false
            for _, bot in ipairs(player.GetBots()) do
                if IsValid(bot) and not before[bot] then
                    bot:SetNWString("SpecialBotName", name)
                    bot.BestFriend = true
                    found = true
                    break
                end
            end

            SpawnNext()
        end)
    end

    SpawnNext()
    Maverick = true
end)

concommand.Add("hldm_removeallbots", function(ply, cmd, args)
    if not ply:IsAdmin() then return end
    for _, bot in ipairs(player.GetBots()) do
        bot:Kick()
    end
end)

hook.Add("PlayerInitialSpawn","ChoosePM",function(ply)
    if ply:IsBot() then
        local randPM = math.random(0, #modelFiles) or 1
        if modelFiles[randPM] != nil then
            ply.BotPM = "models/player/hl1/" .. modelFiles[randPM]
        else
            ply.BotPM = "models/player/hl1/player.mdl"
        end
    end
end)