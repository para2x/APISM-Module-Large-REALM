REALM_LUTMaker<-function(MyR.Add,nameR="IA",sow_start="5-May"){
  Tble<-read.dbf(file.path(MyR.Add,list.files(path = MyR.Add, pattern = "*.dbf$", all.files = T)[1]), as.is = FALSE)
  Tble$FID_2<-c(0:(nrow(Tble)-1))
  Tble%>%
  select(point_id=FID_2,lon=xCentroid,lat=yCentroid,soil_code=gridcode)%>%
    mutate(lat=as.numeric(lat),lon=as.numeric(lon))->Tble
#- other stuff
  Tble$sow_start<-sow_start
  Tble$rams_row<-4
  Tble$rams_col<-4
  Tble$climateDiv='Central'
  Tble$state<-nameR
#--- reading soils.xml - I'm reading the soil names from soil file
  data <- read_xml(paste0(nameR,".soils"))%>% xml_find_all("//Soil")%>%xml_attr("name")
  
do.call("rbind",data%>%
    map(function(row){
    cbind(t((strsplit(row,"\\+")[[1]])%>%as.character()),row)
  }))%>%as.data.frame( stringsAsFactors=F)->soilprop
  
names(soilprop)<-c("soil_code","Sand","Clay","CEC","Soilname")
soilprop$soil_code<-as.numeric(soilprop$soil_code)
#- joining
Tble%>%right_join(soilprop,by="soil_code")%>%select(-soil_code,-Sand,-Clay,-CEC)%>%select(point_id,
                                                                                          lat,
                                                                                          lon,
                                                                                          rams_row,
                                                                                          rams_col,
                                                                                          climateDiv,
                                                                                          state,
                                                                                          soil_code=Soilname,
                                                                                          sow_start
                                                                                          )->Tble
  




write.table(format(Tble, digits=2),paste0(nameR,"_LookUp",".csv"),dec=".",sep=",",quote=F,row.names = F)
}
