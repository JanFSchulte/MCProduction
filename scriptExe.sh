#!/bin/bash
BASE=$PWD

echo "================= CMSRUN starting jobNum=$1 ====================" | tee -a job.log

echo "================= CMSRUN setting up CMSSW_7_1_45_patch3 ===================="| tee -a job.log

source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc6_amd64_gcc481

if [ -r CMSSW_7_1_45_patch3/src ] ; then 
     echo release CMSSW_7_1_45_patch3 already exists
else
    scram p CMSSW CMSSW_7_1_45_patch3
fi

cd CMSSW_7_1_45_patch3/src
eval `scram runtime -sh`

echo "========= install pythia 8.2.3 ====="
curl -s --insecure http://home.thep.lu.se/~torbjorn/pythia8/pythia8230.tgz --retry 2 --create-dirs -o pythia8230.tgz
tar xvfz pythia8230.tgz
rm pythia8230.tgz
cd pythia8230/    
./configure --enable-shared  --with-hepmc2=/cvmfs/cms.cern.ch/slc6_amd64_gcc481/external/hepmc/2.06.07-ddibom --with-lhapdf6=/cvmfs/cms.cern.ch/slc6_amd64_gcc481/external/lhapdf/6.2.1-ddibom2
make -j 2
export PYTHIA_BASE=$PWD 
cd ..
cat $CMSSW_BASE/config/toolbox/$SCRAM_ARCH/tools/selected/pythia8.xml | sed -e "s%/cvmfs/cms.cern.ch/slc6_amd64_gcc481/external/pythia8/226-ddibom8%$PYTHIA_BASE%g" > pythia8.xml
mv pythia8.xml $CMSSW_BASE/config/toolbox/$SCRAM_ARCH/tools/selected/
scram setup pythia8
eval `scram runtime -sh`
mkdir -p GeneratorInterface
scp -r /cvmfs/cms.cern.ch/slc6_amd64_gcc481/cms/cmssw-patch/CMSSW_7_1_45_patch3/src//GeneratorInterface/Pythia8Interface/ GeneratorInterface/
scramv1 b -j 2
eval `scram runtime -sh`

cd $BASE

echo "================= CMSRUN starting GEN-SIM step ====================" | tee -a job.log
cmsRun -j genSim_step.log genSim_step.py jobNum=$1 nEvents=500 mH=125

echo "================= CMSRUN setting up CMSSW_8_0_35 ===================="| tee -a job.log
export SCRAM_ARCH=slc6_amd64_gcc530

if [ -r CMSSW_8_0_35/src ] ; then 
 echo release CMSSW_8_0_35 already exists
else
  scram p CMSSW CMSSW_8_0_35
fi

cd CMSSW_8_0_35/src
eval `scram runtime -sh`
cd $BASE

echo "================= CMSRUN starting DIGI-RAW step ====================" | tee -a job.log
cmsRun -j digiRaw_step.log digiRaw_step.py nEvents=500

echo "================= CMSRUN starting RECO-AOD step ====================" | tee -a job.log
cmsRun -j recoAOD_step.log recoAOD_step.py nEvents=500

echo "================= CMSRUN setting up CMSSW_9_4_17  ===================="| tee -a job.log

export SCRAM_ARCH=slc6_amd64_gcc630
if [ -r CMSSW_9_4_17 /src ] ; then 
    echo release CMSSW_9_4_17  already exists
else
    scram p CMSSW CMSSW_9_4_17 
fi
cd CMSSW_9_4_17/src
eval `scram runtime -sh`

cd $BASE

echo "================= CMSRUN starting MiniAOD step  ====================" | tee -a job.log
cmsRun -e -j FrameworkJobReport.xml miniAOD_step.py nEvents=500

echo "================= CMSRUN finished ====================" | tee -a job.log