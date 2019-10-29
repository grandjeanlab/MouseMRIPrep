#!/bin/bash



. ${PWD}/script/param.txt

anat_base=$(basename $anat)
anat_noext="$(remove_ext $anat_base)"
anat_N4=$root_dir'anat/'$anat_noext'_N4.nii.gz'
anat_mask=$root_dir'anat/'$anat_noext'_brain_mask.nii.gz'

for i in "${func[@]}"
do

func_base=$(basename $i)

func_noext="$(remove_ext $func_base)"
func_noext_full="$(remove_ext $i)"

mkdir -p func/$func_noext
cd func/$func_noext


mkdir glm
cd glm

cp $task ./ 
cp $contrast ./

fsl_glm -i ../filtered_func_data_clean -d design.mat -c design.con -o func_beta -m ../mask_dil --demean --out_cope=func_COPE --out_z=func_zstat --out_res=func_res --vxt=../mc/motion.1D

fslmaths func_zstat -thr 2.3 -bin t_pos_mask
fslmaths func_zstat -mul -1 -thr 2.3 -bin t_neg_mask

fslmeants -i ../filtered_func_data_clean -m t_pos_mask.nii.gz -o ts_pos
fslmeants -i ../filtered_func_data_clean -m t_neg_mask.nii.gz -o ts_neg
fslmeants -i func_res -m t_pos_mask.nii.gz -o res

Vest2Text design.mat design.txt
paste ts_pos ts_neg res design.txt >> ts_merge.1d

1dplot -one -title POSITIVE-resp -ps -norm2 -png ../1d_response -demean ts_merge.1d[0,3]
1dplot -one -title NEGATIVE-resp -norm2 -png ../1d_neg_response -demean ts_merge.1d[1,3]
1dplot -one -title residual-resp -norm2 -png ../1d_residual -demean ts_merge.1d[2,3]

overlay 0 0 ../example_func_N4 -a func_zstat 2.3 5 func_zstat -2.3 -5 tmp_ovl
slicer tmp_ovl -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png ../response.png; rm -f sl?.png
rm tmp_ovl.nii.gz
cd ..


antsApplyTransforms -i glm/func_COPE.nii.gz -r ${template} -t ${anat2temp} -t reg/func2anat1Warp.nii.gz -t reg/func2anat0GenericAffine.mat -o ${func_noext}'_COPE_reg.nii.gz' 

antsApplyTransforms -i glm/func_zstat.nii.gz -r ${template} -t ${anat2temp} -t reg/func2anat1Warp.nii.gz -t reg/func2anat0GenericAffine.mat -o ${func_noext}'_zstat_reg.nii.gz'


#WarpTimeSeriesImageMultiTransform 4 glm/func_COPE.nii.gz ${func_noext}'_COPE_reg.nii.gz' -R $template $anat2std_nlin $anat2std_lin reg/func2anatAffine.txt

#WarpTimeSeriesImageMultiTransform 4 glm/func_zstat.nii.gz ${func_noext}'_zstat_reg.nii.gz' -R $template $anat2std_nlin $anat2std_lin reg/func2anatAffine.txt

overlay 0 0 $template -a ${func_noext}'_zstat_reg.nii.gz' 2.3 5 ${func_noext}'_zstat_reg.nii.gz' -2.3 -5 tmp_ovl
slicer tmp_ovl -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png reg_response.png; rm -f sl?.png
rm tmp_ovl.nii.gz


cd ../..
done


