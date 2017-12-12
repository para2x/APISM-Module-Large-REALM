########################
source('RCode/Util/UtilXML.R')
##############
APSIMsoil_Generator<-function(soilname="TestSoil", FractionFull="0.3", Latitude=0, Longitude=0, BD=c(1.3,1.32,1.32), Thickness=c(100,200,300),
                              AirDry=c(0.03,0.032,0.032), LL15=c(0.13,0.132,0.132),DUL=c(0.3,0.32,0.32),SAT=c(0.43,0.432,0.432),
                              LL=c(0.13,0.132,0.132),KL=c(0.3,0.32,0.32),XF=c(0.95,0.9,0.753),OC=c(1.2,0.82,0.83),PH=c(8.2,8.2,8.3),
                              commenti="This soil is created by Hamze Dokoohaki - hamzed@iastate.edu",soilt="",FBiomi=c(0.025),
                              FInerti=c(0.7),
                              NO3i=NULL,NH4i=NULL,CEC=c(1,2,3),sand=c(1,2,3),clay=c(1,2,3)
                              ){

############### making the top root xml
      soil = xmlNode("Soil", attrs = c("name" =paste0(soilname,"+",
                                                      round(mean((sand),na.rm=T),2)*100,"+",
                                                      round(mean((clay),na.rm=T),2)*100,"+",
                                                      round(as.integer(mean((CEC),na.rm=T)),2)
                                                      )
                                       )
                     )
      ############################## Initial water 
      InitialWater<-list(RelativeTo="ll15",
                         FractionFull=FractionFull,
                         PercentMethod="EvenlyDistributed"
      )
      InitialWaterxml<-listToXml(InitialWater,"InitialWater")
      xmlAttrs(InitialWaterxml)<-list(name="Initial water")
      ######################## Basic water properties
      Water<-list(Thickness=valuemaker(Thickness),
                  BD=valuemaker(BD),
                  AirDry=valuemaker(AirDry),
                  LL15=valuemaker(LL15),
                  DUL=valuemaker(DUL),
                  SAT=valuemaker(SAT)
      )
      Waterxml<-listToXml(Water,"Water")
      #### SoilCrop
      soilc<-list(Thickness=valuemaker(Thickness),
                  LL=valuemaker(LL),
                  KL=valuemaker(KL),
                  XF=valuemaker(XF)
      )
      soilcxml<-listToXml(soilc,"SoilCrop")
      xmlAttrs(soilcxml)<-list(name="maize")
      Waterxml[[7]]<-soilcxml
      #######################################SoilWater
      SoilWater<-list(SummerCona=3.5,
                      SummerU=6,
                      SummerDate="1-Apr",
                      WinterCona=3.5,
                      WinterU=6,
                      WinterDate="1-Nov",
                      DiffusConst=40,
                      DiffusSlope=16,
                      Salb=0.05,
                      CN2Bare=85,
                      CNRed=20,
                      CNCov=0.8,
                      Thickness=valuemaker(Thickness),
                      SWCON=valuemaker(rep(1,length(DUL)))
      )
      SoilWaterxml<-listToXml(SoilWater,"SoilWater")
      ################################### Soil orgabic matter
      SoilOrganicMatter<-list(RootCN=35,
                              RootWt=100,
                              SoilCN=12,
                              EnrACoeff=3.5,
                              EnrBCoeff=6,
                      Thickness=valuemaker(Thickness),
                      OC=valuemaker(OC),
                      FBiom=valuemaker(FBiomi),
                      FInert=valuemaker(FInerti)
      )
      SoilOrganicMatterxml<-listToXml(SoilOrganicMatter,"SoilOrganicMatter")
      ################################### Analysis
      Analysis<-list(Thickness=valuemaker(Thickness),
                     PH=valuemaker(PH),
                     CEC=valuemaker(CEC),
                     ParticleSizeSand=valuemaker(sand),
                     ParticleSizeClay=valuemaker(clay)
      )
      Analysisxml<-listToXml(Analysis,"Analysis")
      ################################### Sample
      Sample<-list(Thickness=valuemaker(Thickness),
                   NO3=if(is.null(NO3i)){valuemaker(OC)}else{valuemaker(NO3i)},
                   NH4=if(is.null(NH4i)){valuemaker(OC)}else{valuemaker(NH4i)}
      )
      Samplexml<-listToXml(Sample,"Sample")
      xmlAttrs(Samplexml)<-list(name="Initial nitrogen")
      Samplexml[[4]]<-xmlNode("Date", attrs = c("type" = "date", description = "Sample date:"))
      #############################combining
      soil[[1]]<-xmlNode("Comments",commenti, attrs = c("type" = "multiedit", description = "Comments"))
      soil[[2]]<-InitialWaterxml
      soil[[3]]<-xmlNode("SoilType","", attrs = c(description = ""))
      soil[[4]]<-xmlNode("Latitude",Latitude, attrs = c(description = "Latitude (WGS84)"))
      soil[[5]]<-xmlNode("Longitude",Longitude)
      soil[[6]]<-xmlNode("DataSource","gSSURGO", attrs = c("type" = "multiedit", description = "Data source"))
      soil[[7]]<-Waterxml
      soil[[8]]<-SoilWaterxml
      soil[[9]]<-SoilOrganicMatterxml
      soil[[10]]<-Analysisxml
      soil[[11]]<-Samplexml
      ####### putting it in folder
return(soil)
}

########## Estimate the saturated water content from saxton and rawls
theta_s_estimate<-function(FC,S,C,OM){
  t1<-0.278*S+0.034*C+0.022*OM-(0.018*(S*OM))-(0.027*(C*OM))-(0.584*(S*C))+0.078

  t<-t1+(0.636*(t1)-0.107)

  return(FC+t-0.097*S+0.043)
}
#############################
replcae_na<-function(vect,repl){
  if(length(which(is.na(vect)))>0){
    vect[which(is.na(vect))]<-repl
  }
  if(all(vect==0)) vect<-rep(repl,length(vect))
  return(vect)
}

#######################
#folder = xmlNode("folder", attrs = c("version"="36","creator"="Apsim 7.7-r3632","name" ="Soils"))
#folder[[1]]<-APSIMsoil_Generator(DUL = c(0.35,0.35,0.35))
#folder[[2]]<-APSIMsoil_Generator(DUL = c(0.315,0.35,0.35))
#saveXML(folder, "test2.soils",prefix="")
