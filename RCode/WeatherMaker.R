###########
source('RCode/Util/Daymetr_WeatherGen.R')
###########################
# The input file geodatabase
REALM_WeatherMaker<-function(MyR.Add,nameR="MyRegion",start_yr=1980){
#----------------------------------------------------------- Converting the UTM to Lat long for datmey
  ## reading dbf files
  dff<-read.dbf(file.path(MyR.Add,list.files(path = MyR.Add, pattern = "*.dbf$", all.files = T)[1]), as.is = FALSE)
  dff$FID_2<-c(0:(nrow(dff)-1))
  ###   #https://gis.stackexchange.com/questions/17638/how-to-cluster-spatial-data-in-r
  #### Loop through mukeys
  j<-0
  AllPoints<-lapply(dff$FID_2,function(MKEY){
    
    dd<-dff%>%filter(FID_2==MKEY)
    colcut<-ncol(dd)
    xy<-SpatialPointsDataFrame(coords=dd[,c(colcut-2,colcut-1)],
                               proj4string=CRS("+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"),
                               data=dd[,c(1:(colcut-2))]%>%as.data.frame())%>%
      spTransform(CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))
    j<<-j+1
    return(xy@coords)
  })
  pointss<-do.call("rbind",AllPoints)
  names(pointss)<-c('Xc','Yc')
  allstate<-cbind(dff[,-c(6,7)],pointss)
#------------------------------------------------------------------- Downloading from Daymet and converting to APSIMmet file
state<-paste0(nameR,"")
## creating a folder for the state
#if(!dir.exists(state)) dir.create(paste0("",state))
#setwd(paste0("",state))
#for each mukey
j<-0
#unique(allstate$MUKEY)
lapply(allstate$FID_2,function(ID){
  subdd<-allstate%>%filter(FID_2==ID)
         WeatherGen_APSIM(lat=unique(subdd$yCentroid),long=unique(subdd$xCentroid),fileName=paste0(state,
                                                                                                 "-",unique(subdd$FID_2),".met"),
                   comments = c("! This met file is created by Hamze Dokoohaki - hamzed@iastate.edu",
                                 "! This file is generated using weather information extracted from http://daymet.ornl.gov/",
                                  paste0("! ",Sys.Date()),
                                paste0("! ORIG_FID=",paste(as.character(subdd$FID_2),collapse = " "))
                                ),start_yr=start_yr
                   )

})
###### zipping the met files using system command
zip(paste0(state,".zip"),list.files(".",".met$"))
#zipCmd = paste("zip -r ", paste0(state,".zip"), " .", sep='')
#system(zipCmd, invisible = TRUE)
## if zip file exist start cleaning
if(file.exists(paste0(state,".zip"))) unlink(list.files(".","*.met$"))

}





