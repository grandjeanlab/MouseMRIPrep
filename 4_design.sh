
bids_preprocessing='/project/4180000.15/rsfmri/preprocessing'


cd $bids_preprocessing

ls -d */ | while read subject
do 
cd $subject
ls -d */ | while read session
do 
cd $session
echo "now doing subject "$subject" and session "$session

qsub -l 'procs=1,mem=4gb,walltime=01:00:00' ${PWD}/script/run2.sh

cd $bids_preprocessing'/'$subject
done

cd $bids_preprocessing
done

