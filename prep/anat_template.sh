cd data

jobIDs=""
count=""

ls . | while read line
do
line_noext="$(remove_ext $line)"
exe=" ${ANTSPATH}/N4BiasFieldCorrection -d 3 -i $line -o $line_noext'_N4.nii.gz'"
qscript="job_${count}_qsub.sh"
echo "cd" ${PWD} >> $qscript
echo "$exe" >> $qscript

id=`qsub -N BiasFieldCorrection -v ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1,LD_LIBRARY_PATH=$LD_LIBRARY_PATH,ANTSPATH=$ANTSPATH -l 'procs=1,mem=8gb,walltime=01:00:00'| awk '{print $1}'`
jobIDs="$jobIDs $id"
sleep 0.5
((count++))
done


${ANTSPATH}/waitForPBSQJobs.pl 1 60 $jobIDs

# Returns 1 if there are errors
if [ ! $? -eq 0 ]; then
echo "qsub submission failed - jobs went into error state"
exit 1;
fi




buildtemplateparallel_short.sh -d 3 -n 0 -c 1 -j 10 -m 24x16x8 -r 1 -o 00 *_N4.nii.gz 

cp 00template.nii.gz ../template.nii.gz

cd ..



antsBrainExtraction_short.sh -d 3 -a template.nii.gz -e /home/traaffneu/joagra/my_templates/MRI_exvivo_template_100um.nii -m /home/traaffneu/joagra/my_templates/mask_100um.nii -o ./
mv BrainExtractionMask.nii.gz template_mask.nii.gz

#alternative to antsBrainExtraction using RATS
#RATS_MM -t 70 -v 450 template.nii.gz template_mask.nii.gz

mkdir -p transform 

antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output transform/std2abi --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform [/home/traaffneu/joagra/my_templates/MRI_exvivo_template_100um.nii,template.nii.gz,1] --transform Rigid[0.1] --metric MI[/home/traaffneu/joagra/my_templates/MRI_exvivo_template_100um.nii,template.nii.gz,1,32,Regular,0.25] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[0.1] --metric MI[/home/traaffneu/joagra/my_templates/MRI_exvivo_template_100um.nii,template.nii.gz,1,32,Regular,0.25] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox -x [/home/traaffneu/joagra/my_templates/mask_100um.nii,template_mask.nii.gz] | qsub -l 'procs=1,mem=10gb,walltime=02:00:00'

antsApplyTransforms -i template.nii.gz -r /home/traaffneu/joagra/my_templates/MRI_exvivo_template_100um.nii -t transform/std2abi0GenericAffine.mat -o template_lin.nii.gz -v 

antsApplyTransforms -i template_mask.nii.gz -r /home/traaffneu/joagra/my_templates/MRI_exvivo_template_100um.nii -t transform/std2abi0GenericAffine.mat -o template_mask_lin.nii.gz -v -n NearestNeighbor

antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output transform/std2abi --transform SyN[0.1,3,0] --metric CC[/home/traaffneu/joagra/my_templates/MRI_exvivo_template_100um.nii,template_lin.nii.gz,1,4] --convergence [100x70x50x20,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox -x [/home/traaffneu/joagra/my_templates/mask_100um.nii,template_mask_lin.nii.gz]

antsApplyTransforms -i template.nii.gz -r /home/traaffneu/joagra/my_templates/MRI_exvivo_template_100um.nii -t transform/std2abi0GenericAffine.mat -t transform/std2abi0Warp.nii.gz -o template_nlin.nii.gz -v 

antsApplyTransforms -i template_mask.nii.gz -r /home/traaffneu/joagra/my_templates/MRI_exvivo_template_100um.nii -t transform/std2abi0GenericAffine.mat -t transform/std2abi0Warp.nii.gz -o template_nlin_mask.nii.gz -v -n NearestNeighbor
