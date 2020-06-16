import argparse
import subprocess
from GENtemplate import template

runTemplate = '''cmsRun %s jobNum=$1
cmsRun step2_DIGI.py
cmsRun step3_RECO.py
cmsRun -e -j FrameworkJobReport.xml step4_MINIAOD.py
'''

crabTemplate = '''from CRABClient.UserUtilities import config
config = config()

config.General.requestName     = 'ADD_%s_M%dTo%s_2017'
config.General.workArea        = 'crab'
config.General.transferOutputs = True
config.General.transferLogs    = False

config.JobType.pluginName  = 'PrivateMC'
config.JobType.psetName    = 'step4_MINIAOD_Fake.py'
config.JobType.maxMemoryMB = 3500
config.JobType.inputFiles  = ['%s','%s','step2_DIGI.py','step3_RECO.py','step4_MINIAOD.py']

config.JobType.scriptExe   ='%s'
#config.JobType.numCores    = 8

config.Data.splitting   = 'EventBased'
config.Data.unitsPerJob = 300
config.Data.totalUnits  = 150000
config.Data.outLFNDirBase = '/store/user/jschulte/'
config.JobType.outputFiles  = ['step4.root']
config.Data.publication = True
config.Data.outputPrimaryDataset = 'ADDGravToLL_LambdaT-%s_M-%dTo%s_13TeV-pythia8'
config.Data.outputDatasetTag     = 'RunIIAutumn18MiniAOD-102X_upgrade2018_realistic_v15-v1'
config.JobType.allowUndistributedCMSSW=True
config.section_("Site")
#config.Site.blacklist = ['T2_US_Caltech','T2_US_Florida','T2_US_MIT','T2_US_Nebraska','T2_US_Vanderbilt','T2_US_Wisconsin']
#config.Site.whitelist = ['T2_US_Purdue']
config.Site.storageSite = 'T2_US_Purdue'
# this is needed in order to prevent jobs overflowing to blacklisted sites
config.section_("Debug")
config.Debug.extraJDL = ['+CMS_ALLOW_OVERFLOW=False']
'''


parser = argparse.ArgumentParser(description='Process some integers.')
parser.add_argument('--submit', action='store_true', default=False)
args = parser.parse_args()

Lambdas = [4000,5000,6000,7000,8000,9000,10000,11000,12000,100000]
names = ['4000','5000','6000','7000','8000','9000','10000','11000','12000','100000']
#Lambdas = [9000]
#names = ['9000TeV']


massLow = 2800
massHigh = -1

for index, L in enumerate(Lambdas):

	upName = str(massHigh)
	if massHigh == -1:
		upName = "Inf"

	config = template%(L,massLow,upName,L,massLow,massHigh)

	configName = "step1_GEN-SIM_LambdaT%s_M%dTo%s.py"%(names[index],massLow,upName)

	open(configName, 'wt').write(config)
 

	runSH = runTemplate%(configName)
	runSHName = 'runProduction_%s_M%dTo%s.sh'%(names[index],massLow,upName)
	open(runSHName, 'wt').write(runSH)


	crabCfg = crabTemplate%(names[index],massLow,upName,runSHName,configName,runSHName,names[index],massLow,upName)
	crabCfgName = "crabConfig_%s_M%dTo%s.py"%(names[index],massLow,upName)
	open(crabCfgName, 'wt').write(crabCfg)

	if args.submit:
		subprocess.call(['crab','submit',crabCfgName])
