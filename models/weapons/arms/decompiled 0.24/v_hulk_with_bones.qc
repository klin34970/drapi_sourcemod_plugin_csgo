// Created by Crowbar 0.24.0.0

$modelname "player/z4e/hulk/hulk.mdl"

$bodygroup "arms"
{
	studio "v_hulk_with_bones.smd"
}


$cdmaterials "models\v_models\Infected\"

// This list shows the VMT files used in the SMD files.
// "ZGuard_b.vmt"

$surfaceprop "default"

$contents "solid"

// Only set this if you know what it does, and need it for special circumstances, such as with gibs.
// $illumposition -0.092 1.059 44.841

// $bbox -6.503 -31.606 32.923 4.385 31.422 56.758

// $cbox is probably not used anymore
// $cbox 0 0 0 0 0 0

// The hitbox info below was automatically generated when compiled because no hitbox info was provided.
// $hboxset "default"
// $hbox 0 "v_weapon.Bip01_L_ForeTwist" -4.375088 -1.037044 -0.989174 11.916835 3.782918 4.300682
// $hbox 0 "v_weapon.Bip01_L_Hand" -2.172382 -2.201776 -3.864237 9.378228 5.817722 2.039023
// $hbox 0 "v_weapon.Bip01_L_Finger0" -0.590882 0 -0.668192 0.794329 1.084513 0.418635
// $hbox 0 "v_weapon.Bip01_L_Forearm" -4.309991 -0.873259 -0.155361 5.815207 3.845915 4.323746
// $hbox 0 "v_weapon.Bip01_R_Forearm" -5.246089 -0.557482 -3.369838 10.295593 4.696099 2.171668
// $hbox 0 "v_weapon.Bip01_R_Hand" -0.893577 -1.768258 -1.847584 9.885194 4.762049 4.212978
// $hbox 0 "v_weapon.Bip01_R_Finger0" -0.726489 0 -1.23143 2.578813 2.162966 1.235577
// $hbox 0 "v_weapon.Bip01_R_Finger01" -0.270648 -0.389693 -0.763836 1.830208 1.437749 0.664489
// $hbox 0 "v_weapon.Bip01_R_Finger02" 0 -0.612925 -0.921615 5.003118 1.277305 0.664478
// $hbox 0 "v_weapon.Bip01_R_Finger1" 0 -0.407554 -0.557171 1.433478 1.109637 0.654721
// $hbox 0 "v_weapon.Bip01_R_Finger12" 0 -0.664894 -0.293971 5.218414 2.70034 1.08721
// $hbox 0 "v_weapon.Bip01_R_Finger2" -0.880026 -0.415254 -2.527931 2.677796 1.749144 0.4535
// $hbox 0 "v_weapon.Bip01_R_Finger21" 0 -0.628036 -2.655796 3.400189 1.264055 0.901609
// $hbox 0 "v_weapon.Bip01_R_Finger22" 0 -0.530783 -1.932731 5.270887 2.085385 2.408406
// $hbox 0 "v_weapon.Bip01_R_Finger4" -1.328551 -0.124138 -0.510301 0 1.201819 0.632114
// $hbox 0 "v_weapon.Bip01_R_ForeTwist" -5.246089 -0.784022 -3.352004 11.946063 4.708857 2.189757

// NOTE: The following commented-out $definebone lines might be needed, as is often the case for view models. When needed, simply remove the two slashes '//' from the start of each line.
// $definebone "v_weapon.Bip01_L_ForeTwist" "" 15.369723 1.698037 50.59407 -0.032436 0.804761 -0.059057 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Hand" "v_weapon.Bip01_L_ForeTwist" 10.29557 0.000002 -0.000015 -1.615865 -0.026159 -0.02168 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger0" "v_weapon.Bip01_L_Hand" 1.149523 0.416489 -1.414113 1.975473 0.444313 1.090961 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Finger4" "v_weapon.Bip01_L_Hand" 3.323336 0.233749 1.479075 0.04342 0.319607 -0.683771 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_L_Forearm" "" 15.369723 1.698037 50.59407 0.019773 0.750851 0.007472 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Forearm" "" -15.369725 1.697995 50.59407 3.128651 0.750851 3.134124 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Hand" "v_weapon.Bip01_R_Forearm" 10.295593 -0.000002 -0.000011 1.615865 0.043612 -0.02168 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger0" "v_weapon.Bip01_R_Hand" 1.149504 0.4165 1.414117 -1.691001 -0.679973 0.668293 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger01" "v_weapon.Bip01_R_Finger0" 1.263885 0.000008 -0.000004 -0.002084 0.018564 -0.057729 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger02" "v_weapon.Bip01_R_Finger01" 1.188942 0 0.000011 0 0 -0.00852 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger1" "v_weapon.Bip01_R_Hand" 3.773748 0.133228 0.970574 -0.046773 -0.481376 0.282616 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger11" "v_weapon.Bip01_R_Finger1" 1.433478 -0.000023 -0.000011 -0.033888 0.140397 -0.007562 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger12" "v_weapon.Bip01_R_Finger11" 1.019152 -0.000008 0.000001 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger2" "v_weapon.Bip01_R_Hand" 3.7995 0.014973 0.039958 0.038409 -0.320098 0.118597 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger21" "v_weapon.Bip01_R_Finger2" 1.774879 0 -0.000001 -0.019252 0.175605 0.225266 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger22" "v_weapon.Bip01_R_Finger21" 1.008854 -0.000015 0 0 0 0.112545 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger3" "v_weapon.Bip01_R_Hand" 3.63275 0.059048 -0.757493 0.008189 -0.149015 0.264274 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger31" "v_weapon.Bip01_R_Finger3" 1.500134 0 -0.000002 -0.008853 0.036486 -0.072527 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger32" "v_weapon.Bip01_R_Finger31" 0.90567 0.000011 0 0 0 0.025279 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_Finger4" "v_weapon.Bip01_R_Hand" 3.323328 0.233753 -1.479074 0.20266 -0.033959 0.013742 0 0 0 0 0 0
// $definebone "v_weapon.Bip01_R_ForeTwist" "" -15.369725 1.697995 50.59407 3.12182 0.750851 3.134124 0 0 0 0 0 0

$sectionframes 30 30




$sequence "idle" "v_hulk_with_bones.smd" {
	fps 30
}

