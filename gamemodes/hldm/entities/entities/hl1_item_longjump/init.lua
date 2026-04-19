AddCSLuaFile("shared.lua")
include('shared.lua')

function ENT:Initialize()
	--[[if !self:IsInWorld() then
		self:Remove()
	end
	while !self:IsInWorld() do
		pos.y = pos.y + 20
		self:SetPos(pos)
	end--]]
	self:SetModel("models/w_longjump.mdl")
	self:SetMoveType(MOVETYPE_FLYGRAVITY)
	self:SetSolid(SOLID_NONE)

	self:SetTrigger(true)
	self:UseTriggerBounds(true, 12)
	self.Pickable = true
end

function ENT:Touch(ent)
	if IsValid(ent) then
		if ent:IsPlayer() and ent:Alive() and self.Pickable then
			self:Pickup(ent)
		end
	end
end

function ENT:Pickup(ply)
	if ply:IsSuitEquipped() and !ply:GetLongJump() then
		ply:SetLongJump(true)		
		self:EmitSound( "hl1/fvox/bell.wav" )
		if self:ItemShouldRespawn() then
			self:RespawnItem()
		else
			self:Remove()
		end
		self.Pickable = false
	end
end