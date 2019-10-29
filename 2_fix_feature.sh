
bids_preprocessing='/project/4180000.15/SSFO/preprocessing_SSFO'


cd $bids_preprocessing

ls -d */ | while read subject
do 
cd $subject
ls -d */ | while read session
do 
cd $session'/func'
echo "now doing subject "$subject" and session "$session

ls -d */ | while read func
do
cd $func

/opt/matlab/R2018b/bin/matlab -nojvm -nodisplay -nodesktop -nosplash -r "addpath('/home/traaffneu/joagra/bin/fix'); addpath('/opt/fsl/5.0.9/etc/matlab'); fix_1a_extract_features('./'); quit;" | qsub -N $subject -l 'procs=1,mem=1gb,walltime=00:15:00'


cd $bids_preprocessing'/'$subject$session'/func'
done


cd $bids_preprocessing'/'$subject
done

cd $bids_preprocessing
done

