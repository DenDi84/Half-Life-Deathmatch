function EFFECT:Init(data)
    local pos = data:GetOrigin()
    pos.z = pos.z + 48

    local damage = data:GetMagnitude()

    local damageFactor = 1
    local numParticles = 5
    local sizeBonus = math.Clamp(damage / 20, 0, 5)
    local velocityBonus = math.Clamp(damage*2, 0, 400)

    numParticles = math.Clamp(numParticles, 2, 15)

    local gibModels = {
        "models/gibs/gib_b_bone.mdl",
        "models/gibs/gib_b_gib.mdl",
        "models/gibs/gib_legbone.mdl",
        "models/gibs/gib_lung.mdl",
        "models/gibs/gib_skull.mdl" 
    }

    for i = 1, numParticles do
        local gib = ClientsideModel(gibModels[i], RENDERGROUP_OPAQUE)

        if IsValid(gib) then
            gib:SetPos(pos)
            gib:SetAngles(AngleRand())
            gib:SetModelScale(0.8)
            gib:PhysicsInit(SOLID_VPHYSICS)
            
            if not IsValid(gib:GetPhysicsObject()) then
                local meshes = util.GetModelMeshes(gib:GetModel())
                if meshes and #meshes > 0 then
                    local verts = {}
                    for _, mesh in pairs(meshes) do
                        for _, v in pairs(mesh.triangles) do
                            table.insert(verts, v.pos)
                        end
                    end
                    gib:PhysicsInitConvex(verts, "flesh")
                else
                    gib:PhysicsInitSphere(8, "flesh")
                end
            end

            gib:SetSolid(SOLID_VPHYSICS)
            gib:SetMoveType(MOVETYPE_VPHYSICS)
            gib:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

            gib:AddCallback("PhysicsCollide", function(collider, data)
                if math.random() < 0.5 then
                    local startPos = data.HitPos + data.HitNormal
                    local endPos = data.HitPos - data.HitNormal
                    util.Decal("HLDM_Blood_" .. math.random(1, 7), startPos, endPos)
                end 
            end)

            local phys = gib:GetPhysicsObject()
            if IsValid(phys) then
                phys:Wake()
                phys:SetVelocity(VectorRand() * (math.Rand(100, 200) + velocityBonus))
                phys:AddAngleVelocity(VectorRand() * 600)
            end

            SafeRemoveEntityDelayed(gib, math.Rand(4, 7))

        end
    end
end


function EFFECT:Think()
    return false
end

function EFFECT:Render()
end


