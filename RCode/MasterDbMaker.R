REALM_MasterDbMaker<-function(nameR,inputs){
  if(!dir.exists(paste0(nameR,"_Sims"))) dir.create(paste0(nameR,"_Sims"))
  maincode<-read_lines("PyCode/masterRunDb.py")
  rest<-paste0("# Run if module is run as a program
if __name__ == '__main__':
  experiment = 'Simulations'
  masterDbPath = '{exp}/{exp}.sqlite'.format(exp=experiment)
  gridLutPath = '",paste0(nameR,"_LookUp.csv"),"'
  startRun = 1
  endRun = ",inputs,"
  update_masterDb(masterDbPath, gridLutPath, startRun, endRun)
               ")
  maincode[length(maincode)+1]<-rest
  #------------------------------------------ Creating the Sim folder
  #----- 1- creating the preproessing
  write_lines(maincode,paste0(paste0(nameR,"_Sims"),"/masterDb.py"))
  #-- Running masterdb
  setwd(paste0(nameR,"_Sims"))
  system(paste('python',paste0("masterDb.py")), wait = T, invisible = F)
  setwd("../")
}