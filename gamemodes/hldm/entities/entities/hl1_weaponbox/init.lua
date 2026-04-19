AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.PickupSound = "items/9mmclip1.wav"

function ENT:Initialize()
	self:SetModel("models/w_weaponbox.mdl")
	self:SetMoveType(MOVETYPE_FLYGRAVITY)
	self:SetSolid(SOLID_NONE)

	self:SetTrigger(true)
	self:UseTriggerBounds(true, 12)
end

function ENT:Touch(ent)
	if IsValid(ent) then
		if ent:IsPlayer() and ent:Alive() then
			self:Pickup(ent)
		end
	end
end

function ENT:Pickup(ply)
	if not self.Weapon or self.Weapon == "" then return end
	if not ply:IsSuitEquipped() then return end

	self:Remove()

	if ply:HasWeapon(self.Weapon) then
		local wep = ply:GetWeapon(self.Weapon)
		if not IsValid(wep) then return end

		local ammoType = (wep.Primary and wep.Primary.Ammo) or wep.AmmoType
		local ammoCount = ply:GetAmmoCount(ammoType)
		local ammoMax = wep.Primary.MaxAmmo 
		local giveAmount = wep.Primary.ClipSize 

		if cvars.Bool("hl1_sv_clampammo") then
			giveAmount = math.min(ammoMax - ammoCount, giveAmount)
		end

		if giveAmount > 0 then
			ply:GiveAmmo(giveAmount, ammoType)
		end

		ply:EmitSound(self.PickupSound, 85, 100, 1, CHAN_ITEM)
		return
	end
	ply._ignore_weapon_equip = (ply._ignore_weapon_equip or 0) + 1
	ply:Give(self.Weapon)
	timer.Simple(0.1, function()
		if IsValid(ply) then
			ply._ignore_weapon_equip = math.max(ply._ignore_weapon_equip - 1, 0)
		end
	end)
end