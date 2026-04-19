AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

local function pathcost(ent, area, fromArea, ladder, elevator, length)

    if ( !IsValid( fromArea ) ) then

		-- first area in path, no cost
		return 0
	
	else
	
		if ( !ent.loco:IsAreaTraversable( area ) ) then
			-- our locomotor says we can't move here
			return -1
		end

		-- compute distance traveled along path so far
		local dist = 0

		if ( IsValid( ladder ) ) then
			dist = ladder:GetLength()
		elseif ( length > 0 ) then
			-- optimization to avoid recomputing length
			dist = length
		else
			dist = ( area:GetCenter() - fromArea:GetCenter() ):GetLength()
		end

		local cost = dist + fromArea:GetCostSoFar()

		-- check height change
		local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
		if ( deltaZ >= ent.loco:GetStepHeight() ) then
			if ( deltaZ >= ent.loco:GetMaxJumpHeight() ) then
				-- too high to reach
				return -1
			end

			-- jumping is slower than flat ground
			local jumpPenalty = 5
			cost = cost + jumpPenalty * dist
		elseif ( deltaZ < -ent.loco:GetDeathDropHeight()*2 ) then
			-- too far to drop
			return -1
		end

		return cost
    end

end

function ENT:Initialize()

	self:SetModel( "models/player.mdl" )
    self:SetNoDraw(true)
    self:SetSolid(SOLID_NONE)

    --Nado obyavit' vse porametri zdes' potom
    self.TargetPos = Vector(0,0,0)
    self.curNode = 2

    self.TraceFilter = {}
	
	
end


function ENT:GenPath()
    self.P = Path("Follow")
    self.P:Compute(self, self.TargetPos, function(area, fromArea, ladder, elevator, length)
        return pathcost(self, area, fromArea, ladder, elevator, length)
    end)

    while IsValid(self.P) do
        if self.TargetPos then
            self.P:Compute(self, self.TargetPos, function(area, fromArea, ladder, elevator, length)
                return pathcost(self, area, fromArea, ladder, elevator, length)
            end)
        end
        self.curNode = 2
        coroutine.wait(1)
        coroutine.yield()
    end

end

function ENT:RunBehaviour()

	while ( true ) do							-- Here is the loop, it will run forever
        if IsValid(self.TargetPos) then
            self:GenPath()
        end						

		coroutine.yield()
		-- The function is done here, but will start back at the top of the loop and make the bot walk somewhere else
	end

end

function ENT:OnInjured() return false end
function ENT:OnKilled()  return false end
function ENT:IsNPC()     return false end
function ENT:Health()    return 0 end