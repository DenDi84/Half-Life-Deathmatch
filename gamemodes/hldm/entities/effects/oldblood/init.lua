function EFFECT:Init(data)
    local pos = data:GetOrigin()

    local damage = data:GetMagnitude()

    local damageFactor = 1
    local numParticles = math.floor(damage / damageFactor) + 2
    local sizeBonus = math.Clamp(damage / 20, 0, 5)
    local velocityBonus = math.Clamp(damage * 2, 0, 400)

    numParticles = math.Clamp(numParticles, 2, 50)


    local emitter = ParticleEmitter(pos)

    for i = 1, numParticles do
        local particle = emitter:Add("particles/oldblood", pos)

        if (particle) then

            particle:SetVelocity(VectorRand() * (math.Rand(50, 100) + velocityBonus))
            particle:SetDieTime(math.Rand(0.7, 1.8))
            particle:SetStartAlpha(255)
            particle:SetEndAlpha(0)
            particle:SetStartSize(math.Rand(1, 5)+sizeBonus)
            particle:SetEndSize(0)
            particle:SetRoll(math.Rand(0, 360))
            particle:SetRollDelta(math.Rand(-3, 3))
            particle:SetColor(150, 0, 0)
            particle:SetGravity(Vector(0, 0, -600))
            particle:SetAirResistance(100)
            particle:SetCollide(true)
            particle:SetBounce(0.3)
        end
    end

    emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end


--local particle = emitter:Add("decals/{blood9", pos)