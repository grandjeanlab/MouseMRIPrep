#!/bin/bash



. ${PWD}/script/param.txt

for i in "${func[@]}"
do

func_base=$(basename $i)

func_noext="$(remove_ext $func_base)"


cd func/$func_noext

WarpTimeSeriesImageMultiTransform 4 filtered_func_data_clean.nii.gz filtered_func_data_clean_reg.nii.gz -R $template ${anat2temp} reg/func2anat1Warp.nii.gz reg/func2anat0GenericAffine.mat

mkdir -p NA 
fslmeants -i filtered_func_data_clean_reg.nii.gz -o NA/${func_noext}'_ts' -m ${template_mask} --label=${template_atlas}

mkdir -p ReHo
3dReHo -inset filtered_func_data_clean.nii.gz -prefix ReHo/${func_noext}'_reho.nii.gz' -mask mask_dil.nii.gz
WarpTimeSeriesImageMultiTransform 4 ReHo/${func_noext}'_reho.nii.gz' ReHo/${func_noext}'_reho_reg.nii.gz' -R $template ${anat2temp} reg/func2anat1Warp.nii.gz reg/func2anat0GenericAffine.mat

mkdir -p drICA
ls $drICA | while read ica
do
fsl_glm -i filtered_func_data_clean_reg.nii.gz -o drICA/${func_noext}'_'$(remove_ext $ica)'.txt' -m ${template_mask} -d ${drICA}/${ica} --demean

fsl_glm -i filtered_func_data_clean_reg.nii.gz -d drICA/${func_noext}'_'$(remove_ext $ica)'.txt' -m ${template_mask} -o drICA/${func_noext}'_'$(remove_ext $ica)'.nii.gz' --out_z=drICA/${func_noext}'_'$(remove_ext $ica)'_Z.nii.gz' --demean
done


mkdir -p SBA
ls $sba/*.nii.gz | while read SB
do
SB_base=$(basename $SB)
SB_noext="$(remove_ext $SB_base)"

fslmeants -i filtered_func_data_clean_reg.nii.gz -o SBA/${func_noext}'_'${SB_noext}'.txt' -m ${SB}

fsl_glm -i filtered_func_data_clean_reg.nii.gz -d SBA/${func_noext}'_'${SB_noext}'.txt' -m ${template_mask}  --out_z=SBA/${func_noext}'_'${SB_noext}'_Z.nii.gz' --demean
done

cd ../..
done


