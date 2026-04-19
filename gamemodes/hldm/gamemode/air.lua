hook.Add("SetupMove", "AirStrafingMovement", function(ply, mv, cmd)
    if not ply:OnGround() then
        
        local vel = mv:GetVelocity()
        local velXY = Vector(vel.x, vel.y, 0)
        local speed = velXY:Length()
        
        if speed < 10 then return end
        
        local viewAngles = mv:GetMoveAngles()
        local viewDir = viewAngles:Forward()
        viewDir.z = 0
        viewDir:Normalize()

        local forwardMove = mv:GetForwardSpeed()
        local sideMove = mv:GetSideSpeed()

        if math.abs(sideMove) < 1 then return end
        if math.abs(forwardMove) > 1 then return end

        local viewDir = mv:GetMoveAngles():Forward()
        viewDir.z = 0
        viewDir:Normalize()
        
        local right = Vector(viewDir.y, viewDir.x, 0)
        local wishDir = right * sideMove
        wishDir:Normalize()

        local velDir = velXY:GetNormalized()

        local dotProduct = velDir:Dot(wishDir)
        dotProduct = math.Clamp(dotProduct, -1, 1)
        local angleDeg = math.deg(math.asin(dotProduct))

        if angleDeg < 0 then return end
        
        local accelSpeed = 1130 - speed * dotProduct
        
        if accelSpeed > 0 then
            local accelMag = 130 * FrameTime()

            if accelMag > accelSpeed then
                accelMag = accelSpeed
            end

            local accelVec = wishDir * accelMag

            local newVel = vel + accelVec
            mv:SetVelocity(newVel)
        end
    end
end)