#!/bin/bash


. ${PWD}/script/param.txt

anat_base=$(basename ${anat[0]})

anat_noext="$(remove_ext $anat_base)"

mkdir -p anat
cd anat

N4BiasFieldCorrection -d 3 -i ${anat[0]} -o $anat_noext'_N4.nii.gz' 
DenoiseImage -d 3 -i $anat_noext'_N4.nii.gz'  -o $anat_noext'_N4_dn.nii.gz' 
ImageMath  3 $anat_noext'_N4_dn.nii.gz' TruncateImageIntensity $anat_noext'_N4_dn.nii.gz' 0.05 0.999 
#T=$(fslstats $anat_noext'_N4_dn.nii.gz' -p 98)
#z=$(bc <<< "$T / $thr")
#RATS_MM $anat_noext'_N4_dn.nii.gz' $anat_noext'_brain_mask_MM.nii.gz' -t $z -v 400


antsBrainExtraction_short.sh -d 3 -a $anat_noext'_N4_dn.nii.gz' -e ${standard} -m ${standard_mask} -o std_mask

cp std_maskBrainExtractionMask.nii.gz $anat_noext'_brain_mask.nii.gz'
mv std_maskBrain* std_mask/

fslmaths $anat_noext'_N4.nii.gz' -mul $anat_noext'_brain_mask.nii.gz' $anat_noext'_brain.nii.gz'


if [ -f "$anat_mask" ]
then
fslmaths $anat_mask -binv -mul $anat_noext'_brain_mask.nii.gz' $anat_noext'_brain_mask.nii.gz'
fi


mkdir -p reg
antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output reg/anat2std --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform [${standard},$anat_noext'_N4_dn.nii.gz',1] --transform Rigid[0.1] --metric MI[${standard},$anat_noext'_N4_dn.nii.gz',1,32,Regular,0.25] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[0.1] --metric MI[${standard},$anat_noext'_N4_dn.nii.gz',1,32,Regular,0.25] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox

antsApplyTransforms -i $anat_noext'_N4_dn.nii.gz' -r ${standard} -t reg/anat2std0GenericAffine.mat  -o $anat_noext'_lin.nii.gz'
antsApplyTransforms -i $anat_noext'_brain_mask.nii.gz' -r ${standard} -t reg/anat2std0GenericAffine.mat  -o $anat_noext'_brain_mask_lin.nii.gz'

antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output reg/anat2std --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --transform SyN[0.1,3,0] --metric CC[${standard},$anat_noext'_lin.nii.gz',1,4] --convergence [50x25x10x5,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox -x [${standard_mask},$anat_noext'_brain_mask_lin.nii.gz']

#antsIntroduction_short.sh -d 3 -i $anat_noext"_brain.nii.gz" -o anat2template -r $template_brain_high -m 24x16x8
#WarpTimeSeriesImageMultiTransform 4 $anat_noext'_N4.nii.gz' $anat_noext'_deformed.nii.gz' -R $standard reg/anat/reg/anat2std0GenericAffine.mat

antsApplyTransforms -i $anat_noext'_N4_dn.nii.gz' -r ${standard} -t reg/anat2std0GenericAffine.mat -t reg/anat2std0Warp.nii.gz -o $anat_noext'_2std.nii.gz'

#antsApplyTransforms -i $anat_noext'_2std.nii.gz' -r ${template} -t $standard2ABIlin -t $standard2ABInlin -o $anat_noext'_2abi.nii.gz'

ComposeMultiTransform 3 ${anat2temp} -R ${template} $standard2ABInlin $standard2ABIlin -R ${standard} reg/anat2std0Warp.nii.gz reg/anat2std0GenericAffine.mat

ComposeMultiTransform 3 ${anat2temp_inv} -R ${standard} -i reg/anat2std0GenericAffine.mat reg/anat2std0InverseWarp.nii.gz  -R $anat_noext'_N4_dn.nii.gz' -i $standard2ABIlin $standard2ABInlin_inv  

antsApplyTransforms -i $anat_noext'_N4_dn.nii.gz' -r ${template} -t ${anat2temp} -o $anat_noext'_2abi.nii.gz'
antsApplyTransforms -i ${template} -r $anat_noext'_N4_dn.nii.gz' -t ${anat2temp_inv} -o template2anat.nii.gz


slicer $anat_noext'_2std.nii.gz' ${standard} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer ${standard} $anat_noext'_2std.nii.gz' -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png anat2standard.png; rm -f sl?.png highres2standard2.png

rm highres2standard1.png

slicer $anat_noext'_2abi.nii.gz' $template -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer $template $anat_noext'_2abi.nii.gz' -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png anat2template.png; rm -f sl?.png highres2standard2.png

rm highres2standard1.png

cp $anat_noext'_N4_dn.nii.gz' reg/

cd ..

