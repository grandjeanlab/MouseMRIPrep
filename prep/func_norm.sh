#!/bin/bash



. ${PWD}/script/param.txt

anat_base=$(basename $anat)
anat_noext="$(remove_ext $anat_base)"
anat_N4=$root_dir'anat/'$anat_noext'_N4_dn.nii.gz'
anat_mask=$root_dir'anat/'$anat_noext'_brain_mask.nii.gz'

for i in "${func[@]}"
do

func_base=$(basename $i)

func_noext="$(remove_ext $func_base)"
func_noext_full="$(remove_ext $i)"

mkdir -p func/$func_noext
cd func/$func_noext

3dDespike -q -nomask -prefix prefiltered_func_data.nii.gz $i



#carry motion correction
mkdir -p mc
cd mc
3dvolreg -zpad 1 -linear -prefix prefiltered_func_data_mcf.nii.gz -1Dfile motion.1D -maxdisp1D maxdisp.1D ../prefiltered_func_data.nii.gz
fsl_tsplot -i motion.1D -t '3dvolreg estimated rotations (radians)' -u 1 --start=1 --finish=3 -a roll,pitch,yaw -w 640 -h 144 -o rot.png 
fsl_tsplot -i motion.1D -t '3dvolreg estimated translations (mm)' -u 1 --start=4 --finish=6 -a dS,dL,dP -w 640 -h 144 -o trans.png
cp motion.1D prefiltered_func_data_mcf.par
cd ..

#carry intensity thresholding and functional image masking
fslmaths mc/prefiltered_func_data_mcf -Tmean example_func
N4BiasFieldCorrection -d 3 -i example_func.nii.gz -o example_func_N4.nii.gz
DenoiseImage -d 3 -i example_func_N4.nii.gz  -o example_func_N4_dn.nii.gz 
ImageMath  3 example_func_N4_dn.nii.gz TruncateImageIntensity example_func_N4_dn.nii.gz 0.05 0.999 

antsBrainExtraction_short.sh -d 3 -a example_func_N4_dn.nii.gz -e ${anat_N4} -m ${anat_mask} -o anat_mask
cp anat_maskBrainExtractionMask.nii.gz mask.nii.gz
mv anat_maskBrain* anat_mask/
fslmaths mask.nii.gz -dilM -bin mask_dil.nii.gz
fslmaths example_func_N4_dn.nii.gz -mul mask_dil.nii.gz mean_func.nii.gz



mkdir -p reg

cp $root_dir'/anat/reg/'* reg/
fslmaths $anat_N4 -mul $anat_mask reg/highres.nii.gz

#antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output reg/func2anat --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform [${anat_N4},example_func_N4_dn.nii.gz,1] --transform Rigid[0.1] --metric MI[/${anat_N4},example_func_N4_dn.nii.gz,1,32,Regular,0.25] --convergence [100x50x25x10,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform SyN[0.1,3,0] --metric CC[${anat_N4},example_func_N4_dn.nii.gz,1,4] --convergence [8x4x2x2,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox -x [${anat_mask},mask.nii.gz]

antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output reg/func2anat --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform [${anat_N4},example_func_N4_dn.nii.gz,1] --transform Rigid[0.1] --metric MI[${anat_N4},example_func_N4_dn.nii.gz,1,32,Regular,0.25] --convergence [100x50x25x10,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox 

antsApplyTransforms -i example_func_N4_dn.nii.gz -r ${anat_N4} -t reg/func2anat0GenericAffine.mat -o reg/func2anat_lin_deformed.nii.gz
antsApplyTransforms -i mask.nii.gz -r ${anat_N4} -t reg/func2anat0GenericAffine.mat -o reg/mask_lin.nii.gz

antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output reg/func2anat --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --transform SyN[0.1,3,0] --metric CC[${anat_N4},reg/func2anat_lin_deformed.nii.gz,1,4] --convergence [20x10x5x2,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox -x [${anat_mask},reg/mask_lin.nii.gz]


ComposeMultiTransform 3 reg/func2anat.nii.gz -R ${anat_N4} reg/func2anat0Warp.nii.gz reg/func2anat0GenericAffine.mat
ComposeMultiTransform 3 reg/func2anat_inv.nii.gz -R example_func_N4_dn.nii.gz -i reg/func2anat0GenericAffine.mat reg/func2anat0InverseWarp.nii.gz
#ComposeMultiTransform 3 reg/epi2temp_inv.nii.gz -R example_func_N4_dn.nii.gz -i reg/func2anat0GenericAffine.mat reg/func2anat0InverseWarp.nii.gz -R ${anat_N4} ${anat2temp_inv}

antsApplyTransforms -i example_func_N4_dn.nii.gz -r ${anat_N4} -t reg/func2anat.nii.gz -o reg/func2anatdeformed.nii.gz


#EPI2template transform
antsApplyTransforms -i example_func_N4_dn.nii.gz -r ${template} -t ${anat2temp} -t reg/func2anat0Warp.nii.gz -t reg/func2anat0GenericAffine.mat -o example_func_reg.nii.gz 
#template2EPI transform
#antsApplyTransforms -i ${template} -r example_func_N4_dn.nii.gz -t ${anat2temp_inv} -o reg/template2EPI.nii.gz
antsApplyTransforms -i ${template} -r $anat_N4 -t ${anat2temp_inv} -o temp2anat.nii.gz
antsApplyTransforms -i temp2anat.nii.gz -r example_func_N4_dn.nii.gz -t reg/func2anat_inv.nii.gz -o reg/template2EPI.nii.gz
rm temp2anat.nii.gz


3dBandpass -mask mask_dil.nii.gz -prefix prefiltered_func_data_tempfilt.nii.gz $fbot $ftop mc/prefiltered_func_data_mcf.nii.gz 
fslmaths prefiltered_func_data_tempfilt -add example_func filtered_func_data
imrm tempMean
rm -rf prefiltered_func_data*

melodic --report -i filtered_func_data -m mask_dil --tr=${TR} -d 20 




slicer reg/func2anatdeformed.nii.gz $anat_N4 -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer $anat_N4 reg/func2anatdeformed.nii.gz -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png epi2anat.png; rm -f sl?.png highres2standard2.png
rm highres2standard1.png

slicer example_func_reg.nii.gz $template -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer $template example_func_reg.nii.gz -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png epi2template.png; rm -f sl?.png highres2standard2.png
rm highres2standard1.png

fix -f ./
#/opt/matlab/R2018b/bin/matlab -nojvm -nodisplay -nodesktop -nosplash -r "addpath('/home/traaffneu/joagra/bin/fix'); addpath('/opt/fsl/5.0.9/etc/matlab'); fix_1a_extract_features('./');"

cd ../..
done


