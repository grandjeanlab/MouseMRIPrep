
bids_preprocessing='/project/4180000.15/rsfmri/preprocessing'

. ${PWD}/../../script/param.txt

classifier='/project/4180000.15/rsfmri/classifier/mediso/mediso.RData'
fix_thr=20
fix_output='fix4melview_mediso_thr20.txt'
hp=100

cd $bids_preprocessing

ls -d sub-jgrAesMEDISO*/ | while read subject
do 
cd $subject
ls -d */ | while read session
do 
cd $session'/func'
echo "now doing subject "$subject" and session "$session

ls -d */ | while read func
do
cd $func

fix -c ./ ${classifier} ${fix_thr}

#fix -a ${fix_output} -m -h 100

tail -n 1 ${fix_output} | sed 's/\[//g' | sed 's/\]//g' | sed 's/,//g' > .fix

/opt/matlab/R2018b/bin/matlab -nojvm -nodisplay -nodesktop -nosplash -r "addpath('/home/traaffneu/joagra/bin/fix'); addpath('/opt/fsl/5.0.9/etc/matlab'); fix_3_clean('.fix', 0, 1, 100); quit;" | qsub -l 'procs=1,mem=1gb,walltime=00:15:00'



cd $bids_preprocessing'/'$subject$session'/func'
done


cd $bids_preprocessing'/'$subject
done

cd $bids_preprocessing
done

