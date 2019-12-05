bids_base='/project/4180000.18/Rest_AD1'
bids_original=$bids_base'/BIDS'
bids_preprocessing=$bids_base'/preprocessing'
script_dir=$bids_base'/script/MouseMRIPrep/prep'
bids_template=$bids_base'/anat_template'

template='/home/traaffneu/joagra/my_templates/MRI_exvivo_template_200um.nii'
template_brain='/home/traaffneu/joagra/my_templates/MRI_exvivo_template_200um_skullstripped.nii'
template_mask='/home/traaffneu/joagra/my_templates/mask_200um.nii'
template_atlas='/home/traaffneu/joagra/my_templates/atlas/ABI_atlas_reduced_200um.nii.gz'
standard=$bids_template'/template.nii.gz'
standard_mask=$bids_template'/template_mask.nii.gz'
standard2ABIlin=$bids_template'/transform/std2abi0GenericAffine.mat'
standard2ABInlin=$bids_template'/transform/std2abi0Warp.nii.gz'
standard2ABInlin_inv=$bids_template'/transform/std2abi0InverseWarp.nii.gz'


#Anat parameters 
make_template=true  #use previously made study-specific anatomical template
anat_script='anat_norm.sh'
anat_base='*_T2w.nii.gz'
anat_base_mask='*_T2w_mask.nii.gz'
thr=4 
anat2std_lin='anat/reg/anat2std0GenericAffine.mat'
anat2std_nlin='anat/reg/anat2std1Warp.nii.gz'
anat2std_nlin_inv='anat/reg/anat2std1InverseWarp.nii.gz'
anat2temp='reg/anat2abi.nii.gz'
anat2temp_inv='reg/abi2anat_inv.nii.gz'

#FMRI paramters
func_script='func_norm.sh'
func_script2='func_rs.sh'
func_base='*_task-rest_acq-EPI*.nii.gz'
task='/home/traaffneu/joagra/my_script/design_fsl10sON/design.mat'
contrast='/home/traaffneu/joagra/my_script/design_fsl10sON/design.con'
drICA='/home/traaffneu/joagra/my_templates/atlas/drICA'
sba='/home/traaffneu/joagra/my_templates/atlas/SBA_roi'
TR=1.5
FWHM=0.35
fbot=0.01 
ftop=0.25

#DWI parameters  !!! DWI not yet implementd
#dwi_script='dwi_norm.sh'
#dwi_base='*_dwi.nii.gz'
#b0=5 

if [ "make_template"==true ]; then
mkdir -p $bids_template'/data'
mkdir -p $bids_template'/script'
cp $script_dir'/anat_template.sh' $bids_template'/script/anat_template.sh'
chmod +x $bids_template'/script/anat_template.sh'
fi

cd $bids_original

ls -d */ | while read subject
do 
cd $subject
ls -d */ | while read session
do 
cd $session
echo "now doing subject "$subject" and session "$session


outdir=$bids_preprocessing'/'$subject$session

mkdir -p $outdir/script

#set the template
echo "root_dir="${outdir} > $outdir/script/param.txt
echo "template_dir="${bids_template} >> $outdir/script/param.txt
echo "template="${template} >> $outdir/script/param.txt
echo "template_brain="${template_brain} >> $outdir/script/param.txt
echo "template_mask="${template_mask} >> $outdir/script/param.txt
echo "template_atlas="${template_atlas} >> $outdir/script/param.txt
echo "standard="${standard} >> $outdir/script/param.txt
echo "standard_mask="${standard_mask} >> $outdir/script/param.txt
echo "standard2ABIlin="${standard2ABIlin} >> $outdir/script/param.txt
echo "standard2ABInlin="${standard2ABInlin} >> $outdir/script/param.txt
echo "standard2ABInlin_inverse="${standard2ABInlin_inv} >> $outdir/script/param.txt

#set subject and session name
echo "subject="${subject%/} >> $outdir/script/param.txt
echo "session="${session%/} >> $outdir/script/param.txt

#other parameters
echo "thr="${thr} >> $outdir/script/param.txt

echo "cd "$outdir > $outdir/script/run.sh


#prepare options for anatomical scans
anat=$(ls ${PWD}/anat/$anat_base 2>/dev/null)
if [ "$anat" ]; then 
anat=${anat[0]}
echo "anat="$anat >> $outdir/script/param.txt 
cp $script_dir'/'$anat_script $outdir/script/
echo $outdir/script/$anat_script >> $outdir/script/run.sh
echo "anat2std_lin="$outdir$anat2std_lin >> $outdir/script/param.txt
echo "anat2std_nlin="$outdir$anat2std_nlin >> $outdir/script/param.txt
echo "anat2std_nlin_inv="$outdir$anat2std_nlin_inv >> $outdir/script/param.txt
echo "anat2temp="$anat2temp >> $outdir/script/param.txt
echo "anat2temp_inv="$anat2temp_inv >> $outdir/script/param.txt
  if [ "make_template"==true ]; then
  cp $anat $bids_template'/data/'${subject%/}${session%/}'.nii.gz'
  fi

else
echo "No anatomical scan found for "$subject" and session "$session
break
fi

#add anat_mask to params
anat_mask=$(ls ${PWD}/anat/$anat_base_mask 2>/dev/null)
if [ "$anat_mask" ]; then 
anat_mask=${anat_mask[0]}
echo "anat_mask="$anat_mask >> $outdir/script/param.txt 
fi



#prepare options for DWI scans
#dwi=$(ls ${PWD}/dwi/$dwi_base 2>/dev/null)
#if [ "$dwi" ]; then 
#echo "dwi=("$dwi")" >> $outdir/script/param.txt 
#echo "b0="${b0} >> $outdir/script/param.txt 
#cp $script_dir'/'$dwi_script $outdir/script/
#echo $outdir/script/$dwi_script >> $outdir/script/run.sh
#else
#echo "No DWI scan found for "$subject" and session "$session
#fi


#prepare options for FUNC scans
func=$(ls ${PWD}/func/$func_base 2>/dev/null)
if [ "$func" ]; then 
echo "func=("$func")" >> $outdir/script/param.txt 
echo "task="${task} >> $outdir/script/param.txt
echo "contrast="${contrast} >> $outdir/script/param.txt
echo "drICA="${drICA} >> $outdir/script/param.txt
echo "sba="${sba} >> $outdir/script/param.txt
echo "TR="${TR} >> $outdir/script/param.txt
echo "FWHM="${FWHM} >> $outdir/script/param.txt
echo "fbot="${fbot} >> $outdir/script/param.txt
echo "ftop="${ftop} >> $outdir/script/param.txt
cp $script_dir'/'$func_script $outdir/script/
echo $outdir/script/$func_script >> $outdir/script/run.sh

echo "cd "$outdir > $outdir/script/run2.sh
cp $script_dir'/'$func_script2 $outdir/script/
echo $outdir/script/$func_script2 >> $outdir/script/run2.sh
#else
#echo "No FUNC scan found for "$subject" and session "$session
fi


chmod +x $outdir/script/run.sh
chmod +x $outdir/script/run2.sh

cd $outdir
#qsub -N $subject -l 'procs=1,mem=4gb,walltime=01:00:00' ${PWD}/script/run.sh


cd $bids_original'/'$subject
done

cd $bids_original
done


if [ "make_template"==true ]; then
cd $bids_template
qsub 'procs=1,mem=10gb,walltime=02:00:00' ${PWD}/script/anat_template.sh
fi
