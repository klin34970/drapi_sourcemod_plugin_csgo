// Created by Crowbar 0.24.0.0

$modelname "weapons\arms\v_charger_arms.mdl"

$bodygroup "arms"
{
	studio "v_charger_arms_reference.smd"
}


$cdmaterials "weapons\arms\"
$cdmaterials ""

// This list shows the VMT files used in the SMD files.
// "models\infected\charger\charger_diffuse.vmt"

$attachment "attach_camera" "ValveBiped.bip_base" 0 74.9 -0.57 rotate -90 -90 0

$surfaceprop "default"

$contents "solid"

// Only set this if you know what it does, and need it for special circumstances, such as with gibs.
// $illumposition -23.037 -31.594 -31.981

// $bbox -2.72 -48.007 -70 65.908 1.934 6.037

// $cbox is probably not used anymore
// $cbox 0 0 0 0 0 0

// The hitbox info below was automatically generated when compiled because no hitbox info was provided.
// $hboxset "default"
// $hbox 0 "ValveBiped.bip_spine_3" -1.54938 -5.102886 -4.074768 0 0 0
// $hbox 0 "ValveBiped.bip_collar_R" -14.53615 0 0 0 14.205188 1.665646
// $hbox 0 "ValveBiped.bip_upperArm_R" -7.006961 -0.93732 -8.44121 7.204134 24.808748 10.842306
// $hbox 0 "ValveBiped.bip_lowerArm_R" -6.821221 -14.387232 -8.881102 7.513758 19.941742 9.124662
// $hbox 0 "ValveBiped.bip_hand_R" -6.785752 -12.126613 -8.552611 8.589525 9.806702 7.290882
// $hbox 0 "ValveBiped.bip_thumb_1_R" -2.211843 0 -2.190898 1.994334 4.820634 2.457019
// $hbox 0 "ValveBiped.bip_index_1_R" -1.672235 -0.277059 -2.715347 2.124893 5.584386 1.632915
// $hbox 0 "ValveBiped.bip_middle_1_R" -0.920174 0 -2.264005 1.996063 5.746594 1.888159
// $hbox 0 "ValveBiped.bip_ring_1_R" -1.309334 -0.111414 -1.424311 1.725755 5.194787 2.742114
// $hbox 0 "ValveBiped.bip_pinky_1_R" -1.180509 -0.190627 -1.50149 2.242725 4.777935 1.998207
// $hbox 0 "ValveBiped.bip_ulna_r" -6.848053 -7.094582 -7.231843 6.730008 6.689084 8.640387
// $hbox 0 "ValveBiped.bip_bicep_R" -6.087352 -2.884604 -8.148812 6.799708 19.805426 10.403458

// NOTE: The following commented-out $definebone lines might be needed, as is often the case for view models. When needed, simply remove the two slashes '//' from the start of each line.
// $definebone "ValveBiped.bip_base" "" 0 0 0 1.570796 0 0 0 0 0 0 0 0
// $definebone "ValveBiped.bip_spine_3" "ValveBiped.bip_base" 0 69.352837 -0.571241 -2.27013 0 0 0 0 0 0 0 0
// $definebone "ValveBiped.bip_collar_R" "ValveBiped.bip_spine_3" -1.54938 -5.102886 -4.074768 2.485408 -0.790177 -1.448758 0 0 0 0 0 0
// $definebone "ValveBiped.bip_upperArm_R" "ValveBiped.bip_collar_R" -0.000061 11.987242 0.000029 2.900223 0.048897 -2.078111 0 0 0 0 0 0
// $definebone "ValveBiped.bip_lowerArm_R" "ValveBiped.bip_upperArm_R" 0 20.10931 -0.000001 -0.107006 0.05419 0.002661 0 0 0 0 0 0
// $definebone "ValveBiped.bip_hand_R" "ValveBiped.bip_lowerArm_R" 0 19.941742 0 -0.151357 0.024826 -0.000001 0 0 0 0 0 0
// $definebone "ValveBiped.bip_thumb_0_R" "ValveBiped.bip_hand_R" 2.899853 -0.471045 -4.331209 -0.449452 -0.559881 -0.709305 0 0 0 0 0 0
// $definebone "ValveBiped.bip_thumb_1_R" "ValveBiped.bip_thumb_0_R" -0.000027 2.54332 0.000025 0.221028 0 0 0 0 0 0 0 0
// $definebone "ValveBiped.bip_index_0_R" "ValveBiped.bip_hand_R" 1.551407 3.956632 -3.900799 2.6959 -1.367576 -3.120852 0 0 0 0 0 0
// $definebone "ValveBiped.bip_index_1_R" "ValveBiped.bip_index_0_R" 0 2.741434 -0.000004 -0.256296 0 0 0 0 0 0 0 0
// $definebone "ValveBiped.bip_middle_0_R" "ValveBiped.bip_hand_R" 1.401108 3.639808 -1.202112 2.031148 -1.35583 -2.447084 0 0 0 0 0 0
// $definebone "ValveBiped.bip_middle_1_R" "ValveBiped.bip_middle_0_R" 0.000003 2.810953 0.000008 -0.256296 0 0 0 0 0 0 0 0
// $definebone "ValveBiped.bip_ring_0_R" "ValveBiped.bip_hand_R" 1.335663 3.182098 1.418085 0.980184 -1.251585 -1.41525 0 0 0 0 0 0
// $definebone "ValveBiped.bip_ring_1_R" "ValveBiped.bip_ring_0_R" -0.000004 2.663269 0.000046 -0.256296 0 0 0 0 0 0 0 0
// $definebone "ValveBiped.bip_pinky_0_R" "ValveBiped.bip_hand_R" 1.344769 1.881122 3.809586 1.120331 -1.20308 -1.47734 0 0 0 0 0 0
// $definebone "ValveBiped.bip_pinky_1_R" "ValveBiped.bip_pinky_0_R" 0.000011 2.315662 -0.000084 -0.256296 0 0 0 0 0 0 0 0
// $definebone "ValveBiped.bip_ulna_r" "ValveBiped.bip_lowerArm_R" 0 9.722963 0 -0.151357 0.024826 -0.000001 0 0 0 0 0 0
// $definebone "ValveBiped.bip_bicep_R" "ValveBiped.bip_upperArm_R" 0 8.540291 -0.000001 -0.107004 -0.053713 0.014246 0 0 0 0 0 0

$sectionframes 30 120




$sequence "idle" "v_charger_arms_anims\idle.smd" {
	fps 30
	activity "ACT_VM_IDLE" 1
	loop
}

$sequence "idle_layer" "v_charger_arms_anims\idle_layer.smd" {
	fps 30
	activity "ACT_VM_IDLE_LAYER" 1
	delta
}

$sequence "deploy" "v_charger_arms_anims\deploy.smd" {
	fps 30
	activity "ACT_VM_DEPLOY" 1
}

$sequence "deploy_layer" "v_charger_arms_anims\deploy_layer.smd" {
	fps 30
	activity "ACT_VM_DEPLOY_LAYER" 1
	delta
}

$sequence "melee" "v_charger_arms_anims\melee.smd" {
	fps 30
	activity "ACT_VM_PRIMARYATTACK" 1
}

$sequence "melee_layer" "v_charger_arms_anims\melee_layer.smd" {
	fps 30
	activity "ACT_VM_PRIMARYATTACK_LAYER" 1
	delta
}

$sequence "melee02" "v_charger_arms_anims\melee02.smd" {
	fps 30
	activity "ACT_VM_SHOOT" 1
}

$sequence "melee02_layer" "v_charger_arms_anims\melee02_layer.smd" {
	fps 30
	activity "ACT_VM_SHOOT_LAYER" 1
	delta
}

$sequence "melee03" "v_charger_arms_anims\melee03.smd" {
	fps 30
	activity "ACT_VM_SHOOT" 1
}

$sequence "melee03_layer" "v_charger_arms_anims\melee03_layer.smd" {
	fps 30
	activity "ACT_VM_SHOOT_LAYER" 1
	delta
}

