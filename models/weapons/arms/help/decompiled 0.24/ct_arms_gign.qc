// Created by Crowbar 0.24.0.0

$modelname "weapons/ct_arms_gign.mdl"

$bodygroup "arms"
{
	studio "ct_arms_gign_reference.smd"
}


$cdmaterials "models\weapons\v_models\arms\"

// This list shows the VMT files used in the SMD files.
// "ct_arms_gign.vmt"

$surfaceprop "default"

$contents "solid"

// Only set this if you know what it does, and need it for special circumstances, such as with gibs.
// $illumposition 0 -3.323 29.025

// $bbox -4.413 -28.742 0 11.059 28.742 58.051

// $cbox is probably not used anymore
// $cbox 0 0 0 0 0 0

// The hitbox info below was automatically generated when compiled because no hitbox info was provided.
// $hboxset "default"
// $hbox 0 "v_weapon.Bip01_L_Forearm" -7.751448 -3.373259 -2.859724 10.295582 2.611079 2.917569
// $hbox 0 "v_weapon.Bip01_L_Hand" -2.141037 -1.4199 -2.458781 5.50617 1.559433 2.270895
// $hbox 0 "v_weapon.Bip01_L_Finger0" -1.714511 -0.781547 -1.021373 2.482851 2.003305 1.664856
// $hbox 0 "v_weapon.Bip01_L_Finger01" -0.109368 -0.758341 -0.841453 1.741115 0.748973 0.650764
// $hbox 0 "v_weapon.Bip01_L_Finger02" -0.954726 -0.722828 -0.841453 1.427368 0.562585 0.722784
// $hbox 0 "v_weapon.Bip01_L_Finger1" -0.09339 -1.142609 -0.799064 1.562063 0.73894 0.687419
// $hbox 0 "v_weapon.Bip01_L_Finger2" -0.475312 -0.924112 -0.80782 2.31347 1.01176 0.864162
// $hbox 0 "v_weapon.Bip01_L_Finger3" -9.562076 -1.132153 -1.304083 1.846163 1.734349 1.39205
// $hbox 0 "v_weapon.Bip01_L_Finger4" -0.568448 -0.998852 -0.669783 1.297307 0.702713 0.770874
// $hbox 0 "v_weapon.Bip01_L_ForeTwist" -7.751448 -3.375314 -2.863971 11.567156 2.60975 2.914866
// $hbox 0 "v_weapon.Bip01_R_Forearm" -7.751461 -3.373233 -2.917564 10.295586 2.611108 2.859729
// $hbox 0 "v_weapon.Bip01_R_Hand" -2.141057 -1.41989 -2.270966 5.506164 1.559432 2.458711
// $hbox 0 "v_weapon.Bip01_R_Finger0" -1.71454 -0.781488 -1.664868 2.48283 2.00337 1.02136
// $hbox 0 "v_weapon.Bip01_R_Finger01" -0.109392 -0.758275 -0.650776 1.741095 0.749039 0.841443
// $hbox 0 "v_weapon.Bip01_R_Finger02" -0.954752 -0.722759 -0.722795 1.427347 0.562652 0.84144
// $hbox 0 "v_weapon.Bip01_R_Finger1" -0.093395 -1.142602 -0.687493 1.562059 0.738946 0.798991
// $hbox 0 "v_weapon.Bip01_R_Finger2" -0.47531 -0.92411 -0.864237 2.313472 1.01176 0.807745
// $hbox 0 "v_weapon.Bip01_R_Finger3" -9.562076 -1.132141 -1.392122 1.846174 1.734356 1.304032
// $hbox 0 "v_weapon.Bip01_R_Finger4" -0.568428 -0.998849 -0.770941 1.297323 0.702712 0.669717
// $hbox 0 "v_weapon.Bip01_R_ForeTwist" -7.751461 -3.375288 -2.914861 11.567157 2.609779 2.863975

// NOTE: The following commented-out $definebone lines might be needed, as is often the case for view models. When needed, simply remove the two slashes '//' from the start of each line.
// $definebone "v_weapon" "" 1.119423 -11.058979 0 1.570796 0 0 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Forearm" "" 15.369723 1.698037 50.59407 0.012942 0.750851 0.007472 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Hand" "v_weapon.Bip01_L_Forearm" 10.295582 0 -0.000008 -1.563505 -0.043612 -0.02168 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger0" "v_weapon.Bip01_L_Hand" 1.149525 0.416496 -1.414116 1.407288 0.320852 0.235478 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger01" "v_weapon.Bip01_L_Finger0" 1.26388 0.000002 0 0 0 -0.00852 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger02" "v_weapon.Bip01_L_Finger01" 1.188942 0 0 0 0 -0.00852 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger1" "v_weapon.Bip01_L_Hand" 3.77376 0.133224 -0.970574 0.009201 0.142462 0.005942 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger11" "v_weapon.Bip01_L_Finger1" 1.433462 0 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger12" "v_weapon.Bip01_L_Finger11" 1.019157 0.000011 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger2" "v_weapon.Bip01_L_Hand" 3.799513 0.014957 -0.039958 -0.008703 -0.034651 0.022689 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger21" "v_weapon.Bip01_L_Finger2" 1.774878 0.000004 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger22" "v_weapon.Bip01_L_Finger21" 1.008844 -0.000004 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger3" "v_weapon.Bip01_L_Hand" 3.632767 0.059055 0.757493 -0.016389 -0.163096 0.042929 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger31" "v_weapon.Bip01_L_Finger3" 1.500137 0 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger32" "v_weapon.Bip01_L_Finger31" 0.905663 0.000004 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger4" "v_weapon.Bip01_L_Hand" 3.323332 0.233746 1.479075 -0.032424 -0.324218 0.031462 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger41" "v_weapon.Bip01_L_Finger4" 0.9631 0.000008 -0.000001 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger42" "v_weapon.Bip01_L_Finger41" 0.682898 0 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_ForeTwist" "" 15.369723 1.698037 50.59407 0.019773 0.750851 0.007472 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Forearm" "" -15.369725 1.697995 50.59407 3.128651 0.750851 3.134124 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Hand" "v_weapon.Bip01_R_Forearm" 10.295586 0 0 1.563505 0.043612 -0.02168 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger0" "v_weapon.Bip01_R_Hand" 1.149519 0.4165 1.414117 -1.407288 -0.320852 0.235478 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger01" "v_weapon.Bip01_R_Finger0" 1.263882 0 -0.000004 0 0 -0.00852 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger02" "v_weapon.Bip01_R_Finger01" 1.188942 -0.000001 0.000004 0 0 -0.00852 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger1" "v_weapon.Bip01_R_Hand" 3.773754 0.133224 0.970574 -0.009201 -0.142462 0.005942 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger11" "v_weapon.Bip01_R_Finger1" 1.43346 0 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger12" "v_weapon.Bip01_R_Finger11" 1.019159 -0.000004 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger2" "v_weapon.Bip01_R_Hand" 3.799515 0.014961 0.039958 0.008703 0.034651 0.022689 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger21" "v_weapon.Bip01_R_Finger2" 1.774879 0 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger22" "v_weapon.Bip01_R_Finger21" 1.008842 -0.000004 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger3" "v_weapon.Bip01_R_Hand" 3.632763 0.059052 -0.757493 0.016389 0.163096 0.042929 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger31" "v_weapon.Bip01_R_Finger3" 1.500134 0 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger32" "v_weapon.Bip01_R_Finger31" 0.905661 0 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger4" "v_weapon.Bip01_R_Hand" 3.323326 0.233749 -1.479075 0.032424 0.324218 0.031462 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger41" "v_weapon.Bip01_R_Finger4" 0.963102 0.000008 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger42" "v_weapon.Bip01_R_Finger41" 0.682896 0 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_ForeTwist" "" -15.369725 1.697995 50.59407 3.12182 0.750851 3.134124 0 0 0 0 0 0




$sequence "idle" "ct_arms_gign_anims\idle.smd" {
	fps 30
}

$bonemerge "v_weapon"
$bonemerge "v_weapon.Bip01_L_Forearm"
$bonemerge "v_weapon.Bip01_L_Hand"
$bonemerge "v_weapon.Bip01_L_Finger0"
$bonemerge "v_weapon.Bip01_L_Finger01"
$bonemerge "v_weapon.Bip01_L_Finger02"
$bonemerge "v_weapon.Bip01_L_Finger1"
$bonemerge "v_weapon.Bip01_L_Finger11"
$bonemerge "v_weapon.Bip01_L_Finger12"
$bonemerge "v_weapon.Bip01_L_Finger2"
$bonemerge "v_weapon.Bip01_L_Finger21"
$bonemerge "v_weapon.Bip01_L_Finger22"
$bonemerge "v_weapon.Bip01_L_Finger3"
$bonemerge "v_weapon.Bip01_L_Finger31"
$bonemerge "v_weapon.Bip01_L_Finger32"
$bonemerge "v_weapon.Bip01_L_Finger4"
$bonemerge "v_weapon.Bip01_L_Finger41"
$bonemerge "v_weapon.Bip01_L_Finger42"
$bonemerge "v_weapon.Bip01_L_ForeTwist"
$bonemerge "v_weapon.Bip01_R_Forearm"
$bonemerge "v_weapon.Bip01_R_Hand"
$bonemerge "v_weapon.Bip01_R_Finger0"
$bonemerge "v_weapon.Bip01_R_Finger01"
$bonemerge "v_weapon.Bip01_R_Finger02"
$bonemerge "v_weapon.Bip01_R_Finger1"
$bonemerge "v_weapon.Bip01_R_Finger11"
$bonemerge "v_weapon.Bip01_R_Finger12"
$bonemerge "v_weapon.Bip01_R_Finger2"
$bonemerge "v_weapon.Bip01_R_Finger21"
$bonemerge "v_weapon.Bip01_R_Finger22"
$bonemerge "v_weapon.Bip01_R_Finger3"
$bonemerge "v_weapon.Bip01_R_Finger31"
$bonemerge "v_weapon.Bip01_R_Finger32"
$bonemerge "v_weapon.Bip01_R_Finger4"
$bonemerge "v_weapon.Bip01_R_Finger41"
$bonemerge "v_weapon.Bip01_R_Finger42"
$bonemerge "v_weapon.Bip01_R_ForeTwist"

