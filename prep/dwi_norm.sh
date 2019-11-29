#leftover codes. Not meant to be running just yet


eddy_correct ../$dwi $dwi_noext'_eddy.nii' 0

3dresample -inset $dwi_noext'_eddy.nii'[0..$b0] -prefix b0.nii.gz 
fslmaths b0.nii.gz -Tmean b0_tmean.nii.gz


anat_reg=$bids_preprocessing'/'$subject'/'$session'/anat/reg'

####comment if doing EPI to standard directly
cp -r $anat_reg ./
anat="$(ls reg/*$anatomical)"

antsIntroduction.sh -d 3 -i b0_tmean.nii.gz -o dwi2anat -r $anat -t RA -s CC

mv dwi2anat* reg/

outfile=${subject%/}'_'${session%/}'_b0_reg.nii.gz'
WarpTimeSeriesImageMultiTransform 4 b0_tmean.nii.gz ${outfile} -R $template reg/anat2templateWarp.nii.gz reg/anat2templateAffine.txt reg/dwi2anatAffine.txt



slicer reg/dwi2anatdeformed.nii.gz $anat -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer $anat reg/dwi2anatdeformed.nii.gz -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png dwi2anat_lin.png; rm -f sl?.png highres2standard2.png
rm highres2standard1.png

slicer ${subject%/}'_'${session%/}'_b0_reg.nii.gz' $template -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer $template ${subject%/}'_'${session%/}'_b0_reg.nii.gz' -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png dwi2template.png; rm -f sl?.png highres2standard2.png
rm highres2standard1.png


#compute dtifit

anat_mask=$bids_preprocessing'/'$subject$session'anat/'${subject%/}'_'${session%/}$anatomical_mask
WarpTimeSeriesImageMultiTransform 4 $anat_mask brain_mask.nii.gz -R b0_tmean.nii.gz -i reg/dwi2anatAffine.txt

dtifit -k $dwi_noext'_eddy.nii' -o dtifit -m brain_mask.nii.gz -r ../$dwi_noext'.bvec' -b ../$dwi_noext'.bval'

WarpTimeSeriesImageMultiTransform 4 dtifit_FA.nii.gz ${subject%/}'_'${session%/}'_dtifit_FA_reg.nii.gz' -R $template reg/anat2templateWarp.nii.gz reg/anat2templateAffine.txt reg/dwi2anatAffine.txt

WarpTimeSeriesImageMultiTransform 4 dtifit_MD.nii.gz ${subject%/}'_'${session%/}'_dtifit_MD_reg.nii.gz' -R $template reg/anat2templateWarp.nii.gz reg/anat2templateAffine.txt reg/dwi2anatAffine.txt
