AddCSLuaFile()

SWEP.PrintName 				= "AR1 OISAW"
SWEP.Author 				= "TankNut"

SWEP.RenderGroup 			= RENDERGROUP_OPAQUE

SWEP.Spawnable 				= true
SWEP.Category 				= "Combine Arms"

SWEP.Slot 					= 2
SWEP.SlotPos 				= 6

SWEP.DrawWeaponInfoBox 		= false
SWEP.DrawCrosshair 			= true

SWEP.ViewModelFOV 			= 54

SWEP.ViewModel 				= Model("models/tanknut/weapons/c_ar1_saw.mdl")
SWEP.WorldModel 			= Model("models/tanknut/weapons/w_ar1_saw.mdl")

SWEP.UseHands 				= true

SWEP.Primary.ClipSize 		= 60
SWEP.Primary.DefaultClip 	= 180
SWEP.Primary.Ammo 			= "AR2"
SWEP.Primary.Automatic 		= true

SWEP.Secondary.ClipSize 	= -1
SWEP.Secondary.DefaultClip 	= -1
SWEP.Secondary.Ammo 		= ""
SWEP.Secondary.Automatic 	= false

SWEP.HoldType 				= "ar2"

SWEP.Damage 				= 8
SWEP.FireRate 				= 60 / 800

SWEP.Spread 				= 2
SWEP.SlowSpread 			= 1

SWEP.RecoilTime 			= 6
SWEP.RecoilKick 			= 3

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

function SWEP:PrimaryAttack()
	if self:GetInReload() or not self:CanPrimaryAttack() then
		return
	end

	local ply = self:GetOwner()

	ply:SetAnimation(PLAYER_ATTACK1)
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

	self:TakePrimaryAmmo(1)

	local slow = ply:KeyDown(IN_ATTACK2)

	local baseSpread = slow and self.SlowSpread or self.Spread
	local spread = math.rad(baseSpread * 0.5)

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

	self:EmitSound("NPC_FloorTurret.Shoot")

	if self:GetFireStart() == 0 then
		self:SetFireStart(CurTime())
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

	if IsValid(ply) and ply:IsPlayer() and (not ply:KeyDown(IN_ATTACK) or self:GetInReload()) then
		self:SetFireStart(0)
	end
end

if CLIENT then
		function SWEP:CalcViewModelView(vm, oldPos, oldAng, pos, ang)
		return LocalToWorld(Vector(-2, 0, -0.5), Angle(), pos, ang)
	end
end