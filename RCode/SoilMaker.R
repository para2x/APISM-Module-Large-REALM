source('RCode/Util/SoilMaker_Function.R')
source('RCode/Util/SoilProfile_Consolidation.R')

REALM_SoilMaker<-function(SoilDB.add,MyR.Add,nameR="SoilToolbox"){

    ############################ Read the whole state
    mu <-read.dbf(list.files(SoilDB.add,"*Mukey.dbf$",include.dirs=T,full.names = T))
    comp<-read.dbf(list.files(SoilDB.add,"*Comp.dbf$",include.dirs=T,full.names = T))
    horizon<-read.dbf(list.files(SoilDB.add,"*Horz.dbf$",include.dirs=T,full.names = T))
    ##--------------------------- Read the region
    Regionmu <-read.dbf(list.files(MyR.Add,"*merged.dbf$",include.dirs=T,full.names = T))%>%
      select(gridcode)
    #------------------------------------------------------
    #### Full joining the mukeys with components - now for each mukey we may have multiple components
    #which each may have multiple horizonz (I'm not doind anything with horizonz now)
    mu%>%select(OBJECTID,mukey,muname,farmlndcl)%>%mutate(mukey=as.numeric(as.character(mukey)))%>%
      full_join(comp%>%
                  select(mukey,cokey,comppct_r,compname,compkind,slope_r,runoff,elev_r,albedodry1)%>%mutate(mukey=as.numeric(as.character(mukey))),
                by=c("mukey"="mukey"))%>%mutate(mukey=as.numeric(mukey))%>%filter(mukey%in%unique(Regionmu$gridcode))->mu_comp#If this is active we filter for a region . otherwise it's gonna be whole state
    #-----------------------------------------------------------------------------------------------------
    res.soil<-NULL
    j<-0
    ListofSoils<-lapply(unique(mu_comp$mukey),
                        function(mukeyi){
           cat(mukeyi,"-",round(j/length(unique(mu_comp$mukey)),2)*100,"\n")
           j<<-j+1
           ## fiding all the hozrizons for the mukey and compononts
           mu.horizins<-mu_comp%>%filter(mukey==mukeyi)%>%inner_join(horizon,#%>%
                            #select(chkey,cokey,hzdepb_r,om_r,sandtotal1,claytotal1,ksat_r,ph1to1h2o1,wthirdbar1,wfifteen_1,dbtenthbar,awc_r),
                            by=("cokey"="cokey"))
           
                mu.horizins%>%
             select(mukey,cokey,hzdepb_r,comppct_r,sandtotal1,om_r,dbovendry1,wsatiated1,
                    claytotal1, ksat_r, ph1to1h2o1, wthirdbar1, wfifteen_1,cec7_r)%>%
             filter(comppct_r>10)%>%
             arrange(hzdepb_r)->arrangL
             
             
           #########################
           Avg.horizon<-mu.horizins%>%
                  select(wfifteen_1,wthirdbar1,ph1to1h2o1,om_r,sandtotal1,claytotal1,dbovendry1,wsatiated1)%>%
                  summarise_all(funs(mean(.,na.rm=T))) # finding the most dominant component
                
         if(nrow(arrangL)>0 & (sum(c(arrangL[1,7],arrangL[1,12],arrangL[1,13]))>0.5)){
             Domin.compo<-soillayer_consolidator(arrangL)
             
             Domin.compo$wsat[which(Domin.compo$wsat==0)]<-as.numeric(Avg.horizon$wsatiated1)/100
             Domin.compo$wpwp[which(Domin.compo$wpwp==0)]<-as.numeric(Avg.horizon$wfifteen_1)/100
             Domin.compo$wfc[which(Domin.compo$wfc==0)]<-as.numeric(Avg.horizon$wthirdbar1)/100
             Domin.compo$sand[which(Domin.compo$sand==0)]<-as.numeric(Avg.horizon$sandtotal1)/100
             Domin.compo$clay[which(Domin.compo$clay==0)]<-as.numeric(Avg.horizon$claytotal1)/100
             
            
             if(is.null(res.soil)) res.soil<<-Domin.compo
         }else{
               Domin.compo<-res.soil
         }
              nlayers<-nrow(Domin.compo) ## number of layers
             ################### Putting data into the APSIM soil file genetor function
             soil<-APSIMsoil_Generator(soilname=paste0(unique(mu.horizins$mukey)),
                                 FractionFull=0.8,
                                 AirDry=rep(0.03,nlayers),
                                 Thickness=c(Domin.compo$depth[1],diff(Domin.compo$depth))*10,
                                 BD=replcae_na(Domin.compo$db,Avg.horizon$dbovendry1),
                                 LL15=replcae_na(Domin.compo$wpwp,Avg.horizon$wthirdbar1/100), ## if is na replace with average
                                 DUL=replcae_na(Domin.compo$wfc,Avg.horizon$wthirdbar1/100),
                                 SAT=replcae_na(Domin.compo$wsat,Avg.horizon$wsatiated1/100),#estimate saxton rep(theta_s_estimate(Domin.compo$wfc,Domin.compo$sand,Domin.compo$clay,Domin.compo$om),1),
                                 PH=replcae_na(Domin.compo$pH,Avg.horizon$ph1to1h2o1),
                                 OC=replcae_na(Domin.compo$om,Avg.horizon$om_r)*0.65, #om to oc
                                 LL=replcae_na(Domin.compo$wpwp/100,Avg.horizon$wfifteen_1),
                                 KL=rep(0.1,nlayers),
                                 XF=rep(1,nlayers),
                                 FBiomi = rep(0.025,nlayers),
                                 FInerti = rep(0.75,nlayers),
                                 NH4i=rep(0,nlayers),
                                 sand=replcae_na(Domin.compo$sand,Avg.horizon$sand),
                                 clay=replcae_na(Domin.compo$clay,Avg.horizon$clay),
                                 CEC=replcae_na(Domin.compo$cec,Avg.horizon$cec),
                                 soilt=unique(mu.horizins$muname),
                                 commenti=paste("This soil is created by Hamze Dokoohaki - hamzed@iastate.edu ",
                                                paste0(c(Avg.horizon$sandtotal1,Avg.horizon$claytotal1),collapse = " "),"\n",unique(mu.horizins$muname))
                                   ) # ende apsim soil generator
         
             
       
       return(soil)
    })## end e lapply function
    #-------------------------------------------------------------------------------------------------------------
    ################ Putting all the soils in a file and saving it as a soil file
    if(length(ListofSoils)>0){
      folder = xmlNode("folder", attrs = c("version"="36","creator"="Apsim 7.7-r3632","name" ="Soils-ms"))
      ## adding soils one by one
      for(i in 1:length(ListofSoils)){
        cat(i,"-- \n")
        if(!is.null(ListofSoils[[i]]))folder[[i]]<-ListofSoils[[i]]
      }
      # saving as a soil file
      saveXML(folder, paste0(nameR,".soils"),prefix="")
      cat("Soil was created ....")
    }

}# end of function

