############ deprecated
##############
soillayer_consolidator<-function(ddf){
  dff<-data.frame() ## for collecting the output
  #layers<-unique(ddf$hzdepb_r)## how many layers we have ? 
  #---- chanign it to a uniform shape
  layers<-c(5,seq(10,120,10))
  for (id in 1:length(layers)){ # for each layer
    depth<-layers[id] #and for this depth
    ddf%>%
      split(.$cokey)%>% ## checking different components seperatly
      map_df(.%>%arrange(hzdepb_r)%>%filter(hzdepb_r>=depth)%>% # finding the min depth from lower depth - closet lower depth # this finds its share in the current layer
               filter(hzdepb_r==min(hzdepb_r)))%>%
      mutate(sand=(sandtotal1*comppct_r)/(sum(comppct_r,na.rm=T)),
             clay=(claytotal1*comppct_r)/(sum(comppct_r,na.rm=T)),
             om=(om_r*comppct_r)/(sum(comppct_r,na.rm=T)),
             ksat=(ksat_r*comppct_r)/(sum(comppct_r,na.rm=T)),
             pH=(ph1to1h2o1*comppct_r)/(sum(comppct_r,na.rm=T)),
             wpwp=(wfifteen_1*comppct_r)/(sum(comppct_r,na.rm=T)),
             wfc=(wthirdbar1*comppct_r)/(sum(comppct_r,na.rm=T)),
             db=(dbovendry1*comppct_r)/(sum(comppct_r,na.rm=T)),
             wsat=(wsatiated1*comppct_r)/(sum(comppct_r,na.rm=T)),
             cec=(cec7_r*comppct_r)/(sum(comppct_r,na.rm=T)))%>%
      summarise(depth=depth,
                sand=round(sum(sand,na.rm=T),2)/100,
                clay=round(sum(clay,na.rm=T),2)/100,
                om=round(sum(om,na.rm=T),2),
                ksat=round(sum(ksat,na.rm=T),2),
                pH=round(sum(pH,na.rm=T),2),
                wpwp=round(sum(wpwp,na.rm=T),2)/100,
                wfc=round(sum(wfc,na.rm=T),2)/100,
                wsat=round(sum(wsat,na.rm=T),2)/100,
                db=round(sum(db,na.rm=T),2),
                cec=round(sum(cec,na.rm=T),2))->higher
    
    dff<-rbind(dff,higher )
  }
 
  return(dff)
}
##############length(layers)
 # soillayer_consolidator(arrangL)


