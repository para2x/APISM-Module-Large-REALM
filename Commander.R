# This files does the REALM by talking to my python codes  for generating the basic polygons
# then using my R code for making weather files and soils and finally Running apsimRegion
# Run this code with admin premission
#--------------------------------------------------------- 0- SETUP (Loading libraries & etc)
library(foreign)
library(sp)
library(APSIM)
library(readr)
library(RSQLite)
library(broom)
library(rgdal)
library(tidyverse)
library(xml2)
rm(list = ls())
setwd("C:/Users/Para2x/Dropbox/Hamze Dokoohaki/Projects/Large-scale APSIM Simulation/REAL-Biochar")
#---------------------------------------------------------0- Input params
# This the address of the tiff file of the region or state
Maddress <- "C:/Users/Para2x/Dropbox/Hamze Dokoohaki/Projects/Large-scale APSIM Simulation/REAL-Biochar/Data/IA"
inras<-"IA.tif" # state
inMask<-"\"E:/Bayesian Network/OutputRasters/CF/CF15/IA_CFB15_pRR_A750.tif\"" #mask for the state
Weather.Domain<-as.character(2500) # in square miles
#---
# This needs to be stright from gssurgo - 3 tables comp, Horz and mukey in a dbf format - SOil properties will be extracted form this
SoilDB.add<-"C:/Users/Para2x/Desktop/RegionTest/soildb"
#nameR is the name that we set for soil toolbox of the region 
nameR<-"IA"
#---
APSIM.dir<-"C:/Program Files (x86)/Apsim77-r3632/"# Where is APSIM directory
#--- seeting up the input for the factorial and each simulation
inputs<-list(clock=c('1/1/1980','31/12/2016'), # setting the clock
             Biochar=list(Rate=c(0,5000,15000),BAD='04/02/1981'), #biochar application rate
             crop=list(crop='maize',
                       density=8,
                       depth=30,
                       somcrop='maize',
                       cultivar='B_110',
                       row_spacing=750), #crop properties
             residue=list(cnr=75,
                          mass=2500),
             Nit=list(NAR=200,Depth=30),
             outputs=c('mm/dd/yyyy as date', 'yield', 'biomass','leach_no3','ocCal'))
#-------------------------------------------------------- 1- Generating the basic polygons
#Runing the code for raster to dissolved poly
address<-paste("",Maddress,"",sep="\"") # getting it ready to be sent to command prompt
  system(paste('python','PyCode/REALM_Input_Generator.py',address,inras,inMask), wait = T, invisible = F)
#-------------------------------------------------------- 2-Now we need to put it in REALM
#Runing the code for making simulation units 
address.dissolved<-paste0(strsplit(inras,"\\.")[[1]][1],"_REALMPoly") # this is created by python as the name of the raster "IA" + "_REALMPoly"
diss_add<-paste("",paste0(Maddress,"/",address.dissolved),"",sep="\"")
  system(paste('python','PyCode/REALM.py',diss_add,Weather.Domain), wait = T, invisible = F)
#-------------------------------------------------------- 3-Lookuptable, soil and weather using REALM output
#---------------------------- Soil
#if no soil was procduced .. look into the function and change the 'gridcode' to 'GRIDCODE'
source('RCode/SoilMaker.R')
  MyR.Add<-paste0(Maddress,"/",address.dissolved,"/","REALMOutput")#my region address
  REALM_SoilMaker(SoilDB.add,MyR.Add,nameR)
#---------------------------- Weather
source('RCode/WeatherMaker.R')
  REALM_WeatherMaker(MyR.Add,nameR="IA",start_yr=1980)
#---------------------------- Lookuptable
source('RCode/LookupTableMaker.R')
  REALM_LUTMaker(MyR.Add,nameR="IA")
#------------------------------Yoooo hooo - if you're here it means that everthing is ready to be sent to APSIMRegion
#------------------------------------------------------- 4-APSIMRegion
# Before this step the APSIMRegion site-package updated by Hamze needs to be installed.
# APSIMRegion part by itself needs to follow these steps: 1-Install 2-PreProcess 3-Masterdb
source('RCode/PreprocessMaker.R')
  REALM_PreprocessMaker(nameR,APSIM.dir,outputdir=getwd(),inputs)
#If I'm here it means I'm almost done - Just need to go to the simulation folder and click run all.
  #--------------------------------------------------- 5- Aggregate outputs
    # We then need to aggregate our simulation results
  #masterdb
source('RCode/MasterDbMaker.R')
  # second argument is the total number of factorials
  REALM_MasterDbMaker(nameR,3)
 #------------------------------------------------------- 6- reading the outputs and craeting the raster
  # The way that masterdb is developed causes a problem with no3. So I have my own function in the next section
  ## connecting to DB and reading the outputs
  con<-dbConnect(drv=RSQLite::SQLite(),
                 dbname=paste0(nameR,"_Sims/Simulations/Simulations.sqlite"))
  outs <- dbGetQuery(conn=con,
                     statement=paste("SELECT * FROM '", dbListTables(con)[[1]], "'", sep=""))
  ### Reading the polygons produced by REALM
  states = readOGR(paste0(Maddress,"/",address.dissolved,"/REALMOutput/",strsplit(inras,"\\.")[[1]][1],"_merged.shp"),
                   "IA_merged", stringsAsFactors=FALSE)
  
  states@data$id = rownames(states@data)
  dbDisconnect(con)
  
#------------------- Going through all the runs
  lapply(unique(outs$run_id), function(run_idi){
        outs%>%group_by(point_id,run_id)%>%
          dplyr::summarise(ocCal=mean(ocCal))%>%dplyr::rename(id=point_id)%>%
          filter(run_id==run_idi)->out.plot.ready
      #--Producing the raster output
      ## 
      write.dbf(as.data.frame(out.plot.ready),paste0(MyR.Add,"/tmpout.dbf"))
        system(paste('python','PyCode/Rasterizer.py',
                     paste("",paste0(Maddress,"/",address.dissolved,"/","REALMOutput"),"",sep="\""),
                     "ocCal",## Put what I estimated above
                     paste0("SOC250_",run_idi)),
               wait = T, invisible = F)
  })
#-------------------------------------------------------------------------------------------
#--------------------------------- Doing the same for another param like no3
#-------------------------------------------------------------------------------------------
available.sims<-grep("*data",list.dirs(path = paste0(nameR,"_Sims/Simulations"))  
                     ,value = T)
#-- reading the sqlite databases
Alldf<-available.sims%>%
          map_df(function(dirs){
            #--finding run_id
                  runid<-strsplit(dirs,"/")[[1]][3]
            # reading data from db      
                  tmpcon<-dbConnect(drv=RSQLite::SQLite(),
                                 dbname=paste0(dirs,"/apsimData.sqlite"))
                  outstmp <- dbGetQuery(conn=tmpcon,
                                     statement=paste("SELECT * FROM '", dbListTables(tmpcon)[[1]], "'", sep=""))
                  #summarising base on point, run and year
                  outstmp%>%mutate(run_id=runid,Year=as.numeric(format(as.Date(date),format="%Y")))%>%
                    select(point_id,run_id,Year,leach_no3)%>%
                    group_by(point_id,run_id,Year)%>%
                    summarise(no3=sum(as.numeric(leach_no3),na.rm=T))->outstmp
                  dbDisconnect(tmpcon)
                  
                  outstmp
          })

#---------------- making the raster
lapply(unique(Alldf$run_id), function(run_idi){
  Alldf%>%group_by(point_id,run_id)%>%
    dplyr::summarise(no3=sum(no3))%>%dplyr::rename(id=point_id)%>%
    filter(run_id==run_idi)->out.plot.ready
  #--Producing the raster output
  ## 
  write.dbf(as.data.frame(out.plot.ready),paste0(MyR.Add,"/tmpout.dbf"))
  system(paste('python','PyCode/Rasterizer.py',
               paste("",paste0(Maddress,"/",address.dissolved,"/","REALMOutput"),"",sep="\""),
               "no3",# just change this variable and put whatever you made in summarise 5 lines above
               paste0("NO3250_",run_idi)),
         wait = T, invisible = F)
})
