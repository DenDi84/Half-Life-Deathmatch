local meta = FindMetaTable("Player")

function meta:GetLongJump()
	return self:GetNW2Bool("LongJump")
end

if SERVER then
    function meta:SetLongJump(b, silent)
		silent = silent or false
		self:SetNW2Bool("LongJump", b)
		if b and !silent then
			EmitSentence("HEV_A1", self:GetPos(), self:EntIndex(), CHAN_VOICE, 0.3)
			--[[timer.Simple(.5, function()
				if IsValid(self) and self:Alive() and self:GetLongJump() then
					self:SendScreenHint(1)
				end
			end)--]]
		end
	end


end

function meta:SetActAbsVelocity(vel)
	self:SetNW2Vector("ActAbsVelocity", vel)
end

function meta:GetActAbsVelocity(fallback)
	fallback = fallback or Vector()
	return self:GetNW2Vector("ActAbsVelocity", fallback)
end

function meta:GetLastSpawn()
    return self.LastSpawn
end

function meta:SetLastSpawn(num)
    self.LastSpawn = num
end

if not CLIENT then return end


local isForcedToCrouch = false
hook.Add("PlayerBindPress", "ClientForcedCrouchButton", function(ply, bind, pressed)
    if ply ~= LocalPlayer() or not pressed or bind ~= "+duck" then return end

    if not ply:IsOnGround() then
        isForcedToCrouch = true
    end
end)

hook.Add("CreateMove", "ClientForcedCrouchEnforce", function(cmd)
    local ply = LocalPlayer()
    
    if not IsValid(ply) or not ply:Alive() then
        isForcedToCrouch = false
        return
    end
    
    if isForcedToCrouch then
        if ply:IsOnGround() then
            isForcedToCrouch = false
        else
            cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_DUCK))
        end
    end
end)