AddCSLuaFile()

SWEP.PrintName 				= "AR3 OISAW"
SWEP.Author 				= "TankNut"

SWEP.RenderGroup 			= RENDERGROUP_OPAQUE

SWEP.Spawnable 				= true
SWEP.Category 				= "Combine Arms"

SWEP.Slot 					= 2
SWEP.SlotPos 				= 7

SWEP.DrawWeaponInfoBox 		= false
SWEP.DrawCrosshair 			= true

SWEP.ViewModelFOV 			= 54

SWEP.ViewModel 				= Model("models/tanknut/weapons/c_ar3.mdl")
SWEP.WorldModel 			= Model("models/tanknut/weapons/w_ar3.mdl")

SWEP.UseHands 				= true

SWEP.Primary.ClipSize 		= 100
SWEP.Primary.DefaultClip 	= 300
SWEP.Primary.Ammo 			= "AR2"
SWEP.Primary.Automatic 		= true

SWEP.Secondary.ClipSize 	= -1
SWEP.Secondary.DefaultClip 	= -1
SWEP.Secondary.Ammo 		= ""
SWEP.Secondary.Automatic 	= false

SWEP.HoldType 				= "smg"

SWEP.Damage 				= 14
SWEP.FireRate 				= 60 / 500

SWEP.Spread 				= 1.5

SWEP.RecoilTime 			= 2
SWEP.RecoilKick 			= 0.5

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "InReload")

	self:NetworkVar("Float", 0, "FireStart")
end

function SWEP:Deploy()
	self:SetHoldType(self.HoldType)
	self:SetFireStart(0)
end

function SWEP:Holster()
	self:StopFiring()

	return true
end

function SWEP:OnRemove()
	self:StopFiring()
end

function SWEP:PrimaryAttack()
	if self:GetInReload() or not self:CanPrimaryAttack() then
		self:StopFiring()

		return
	end

	local ply = self:GetOwner()

	ply:SetAnimation(PLAYER_ATTACK1)
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

	self:TakePrimaryAmmo(1)

	local spread = math.rad(self.Spread * 0.5)

	self:FireBullets({
		Attacker = ply,
		Damage = self.Damage,
		TracerName = "AR2Tracer",
		Dir = ply:GetAimVector(),
		Spread = Vector(spread, spread, spread),
		Src = ply:GetShootPos(),
		Callback = function(attacker, tr, dmg)
			local effectdata = EffectData()

			effectdata:SetOrigin(tr.HitPos + tr.HitNormal)
			effectdata:SetNormal(tr.HitNormal)

			util.Effect("AR2Impact", effectdata)
		end
	})

	if self:GetFireStart() == 0 then
		self:StartFiring()
	end

	if ply:IsPlayer() then
		if slow then
			self:ViewKick(ply, self.RecoilKick * 0.25, self.RecoilTime * 2)
		else
			self:ViewKick(ply, self.RecoilKick, self.RecoilTime)
		end
	end

	if slow then
		self:SetNextPrimaryFire(CurTime() + self.FireRate * 2)
	else
		self:SetNextPrimaryFire(CurTime() + self.FireRate)
	end
end

function SWEP:StartFiring()
	self:SetFireStart(CurTime())
	self:EmitSound("NPC_Hunter.FlechetteShootLoop")

	hook.Add("Move", self, function(ent, ply, mv)
		if ply == ent:GetOwner() then
			local speed = ply:GetWalkSpeed()

			mv:SetMaxSpeed(speed)
			mv:SetMaxClientSpeed(speed)
		end
	end)
end

function SWEP:StopFiring()
	if self:GetFireStart() == 0 then
		return
	end

	self:SetFireStart(0)
	self:StopSound("NPC_Hunter.FlechetteShootLoop")
	self:EmitSound("tanknut/tyrant_attackend.wav")

	hook.Remove("Move", self)

	self:SetNextPrimaryFire(CurTime() + 0.5)
end

function SWEP:ViewKick(ply, kick, time)
	local min = Angle(0.2, 0.2, 0.1)
	local perc = math.min(CurTime() - self:GetFireStart(), time) / time

	ply:ViewPunchReset(10)

	local ang = Angle(
		-(min.p + (kick * perc)),
		-(min.y + (kick * perc) / 3),
		min.r + (kick * perc) / 8
	)

	if math.random(0, 1) == 1 then
		ang.y = -ang.y
	end

	if math.random(0, 1) == 1 then
		ang.z = -ang.z
	end

	ply:ViewPunch(ang * 0.5)
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
	if self:GetInReload() or self:Clip1() == self.Primary.ClipSize then
		return
	end

	local ply = self:GetOwner()

	if ply:IsPlayer() then
		local ammo = ply:GetAmmoCount(self.Primary.Ammo)

		if ammo <= 0 then
			return
		end
	end

	self:StopFiring()

	ply:SetAnimation(PLAYER_RELOAD)
	self:SendWeaponAnim(ACT_VM_RELOAD)

	self:SetInReload(true)
	self:SetNextPrimaryFire(CurTime() + self:SequenceDuration())
end

function SWEP:Think()
	local ply = self:GetOwner()

	if self:GetInReload() and CurTime() > self:GetNextPrimaryFire() then
		self:SetInReload(false)

		local amt = math.min(ply:GetAmmoCount(self.Primary.Ammo), self.Primary.ClipSize)

		self:SetClip1(amt)

		ply:RemoveAmmo(amt, self.Primary.Ammo)
	end

	if IsValid(ply) and ply:IsPlayer() and not ply:KeyDown(IN_ATTACK) then
		if self:GetFireStart() != 0 and (not game.SinglePlayer() or SERVER) then
			self:StopFiring()
		end

		self:SetFireStart(0)
	end
end

if CLIENT then
		function SWEP:CalcViewModelView(vm, oldPos, oldAng, pos, ang)
		return LocalToWorld(Vector(-2, 0, -0.5), Angle(), pos, ang)
	end
end