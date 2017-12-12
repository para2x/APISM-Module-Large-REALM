REALM_PreprocessMaker<-function(nameR,APSIM.dir,outputdir,inputs){
  if(!dir.exists(paste0(nameR,"_Sims"))) dir.create(paste0(nameR,"_Sims"))
  
  content<-paste0("#!/usr/bin/env python
# -*- coding: utf-8 -*-
  #==============================================================================
  # main file for creating apsimRegion experiments
  #==============================================================================
  
import os
from apsimRegions.preprocess.configMaker import create_many_config_files
from apsimRegions.preprocess.apsimPreprocess import preprocess_many
from apsimRegions.preprocess.batch import create_run_all_batchfile

def main():
  experimentName = 'Simulations'
  outputDir = '",paste0(outputdir,"/",nameR,"_Sims/"),"{0}'.format(experimentName)
  # validArgs are 'resolution','crop','model','crit_fr_asw', 'sowStart', or 'soilName'
  factorials = {'BAR':[",paste(sapply(inputs$Biochar$Rate,function(x){paste0("'",x,"'")}),collapse =  ", "),"]}
  otherArgs = {'metFileDir':'../../../metfiles/%(met)s',\
  'gridLutPath':'",paste0(nameR,"_LookUp.csv"),"',\
  'apsimModelDir':'",paste0(APSIM.dir,'Model'),"',\
  'soilDataPath':'",paste0(APSIM.dir,"UserInterface/ToolBoxes/",nameR,".soils"),"',\
  'model':'",nameR,"',\
  'clockStart':'",inputs$clock[1],"',\
  'clockEnd':'",inputs$clock[2],"', \
  'crop':'",inputs$crop$crop,"', \
  'density':'",inputs$crop$density,"',\
  'depth':'",inputs$crop$depth,"',\
  'somcrop':'",inputs$crop$somcrop,"',\
  'cnr':'",inputs$residue$cnr,"',
  'mass':'",inputs$residue$mass,"',
  'cultivar':'",inputs$crop$cultivar,"',\
  'row_spacing':'",inputs$crop$row_spacing,"',\
  'FertDepth':'",inputs$Nit$Depth,"',\
  'FertAmt':'",inputs$Nit$NAR,"',\
  'BAD':'",inputs$Biochar$BAD,"',\
  'outputVariables':'",paste(inputs$outputs,collapse =  ", "),"'}
  
  # create directory if it doesn't exist
  if not os.path.isdir(outputDir):
    os.mkdir(outputDir)
  
  # create config files
  print 'Creating configuration files...'
  runs = create_many_config_files(outputDir, factorials, otherArgs)
  
  # create apsim files
  print 'Saving .apsim and .bat files...'
  preprocess_many(outputDir, runs.keys()[0], runs.keys()[-1])
  
  # create run all batchfile
  create_run_all_batchfile(outputDir, runs, experimentName)
  
  # feedback
  print \"All files saved to:\",outputDir
  print 'Folder', ': Variable'
  for key in runs.keys():
    print '{0:6} : {1}'.format(key, runs[key])
  
  # save text file of run data
  if not os.path.isfile(os.path.join(outputDir,'readme.txt')):
    mode = 'w'
  else:
    mode = 'a'
    
  with open(os.path.join(outputDir,'readme.txt'),mode=mode) as f:
    f.write('Folder : Variable')
    for key in runs.keys():
      f.write('{0:6} : {1}'.format(key, runs[key]))
    f.write('')
  
  print '***** Done! *****'
  
  # Run main() if module is run as a program
if __name__ == '__main__':
  main()
  ")
  #------------------------------------------ Creating the Sim folder
  #----- 1- creating the preproessing
  write_lines(content,paste0(paste0(nameR,"_Sims"),"/Preprocess.py"))
  #---- Copying the other reuiqred files
  file.copy(list.files(".",nameR),paste0(paste0(nameR,"_Sims/"),list.files(".",nameR)))
  #- Unzip weather
  unzip(paste0(paste0(nameR,"_Sims/"),nameR,".zip"),exdir=paste0(nameR,"_Sims/metfiles/",nameR))
  #- Copy soil to toolbox
  file.copy(paste0(nameR,".soils"),paste0(APSIM.dir,'UserInterface/ToolBoxes/',nameR,'.soils'))
  #-- Running preprocessing
  system(paste('python',paste0(nameR,"_Sims/Preprocess.py")), wait = T, invisible = F)
}