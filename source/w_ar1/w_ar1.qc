$modelname "tanknut/weapons/w_ar1.mdl"

$body base "w_ar1_weapon_ref.smd"
$body upgrade "w_ar1_upgrade1.smd"

$surfaceprop "weapon"

$contents "solid"

$illumposition 0 0 0 "ValveBiped.Weapon_bone"

$cdmaterials "models\weapons\w_Irifle\"
$cdmaterials "models\props_combine\"
$cdmaterials "models\combine_turrets\"
$cdmaterials "models\Combine_Turrets\Ceiling_turret\"
$cdmaterials "models\tanknut\weapons\"

$attachment "muzzle" "ValveBiped.Base" 17.80 1.68 5.09 rotate -0 0 0

$definebone "ValveBiped.Bip01_R_Hand" "" 0.267086 -10.171796 -2.589517 10.879189 92.49725 -176.250683 0 0 0 0 0 0
$definebone "ValveBiped.Weapon_bone" "ValveBiped.Bip01_R_Hand" 5 -1.5 -4.999998 -0.000001 0 0 0 0 0 0 0 0
$definebone "ValveBiped.Base" "ValveBiped.Bip01_R_Hand" 0 0 0 10.88 2.50 176.25 // Had to reverse out the rotations from the first bone, fuck me sideways

$sequence "idle" {
	"w_ar1_anims\idle.smd"
	activity "ACT_VM_IDLE" 1
	fadein 0.2
	fadeout 0.2
	fps 30
	loop
}

$sequence "attack1" {
	"w_ar1_anims\attack1.smd"
	activity "ACT_RANGE_ATTACK_SMG1" 1
	{ event AE_NPC_MUZZLEFLASH 0 "COMBINE MUZZLE" }
	{ event 3007 0 }
	fadein 0.2
	fadeout 0.2
	fps 20
}

$sequence "attackoffcenter" {
	"w_ar1_anims\attackoffcenter.smd"
	{ event AE_NPC_MUZZLEFLASH 0 "COMBINE MUZZLE" }
	{ event 3007 0 }
	fadein 0.2
	fadeout 0.2
	fps 20
}

$collisionmodel "w_ar1_phys.smd"
{
	$mass 8
	$inertia 1
	$damping 0
	$rotdamping 0
	$rootbone " "
}