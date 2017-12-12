library(daymetr) # load the package
library(tidyverse)
is.leapyear=function(year){
  #http://en.wikipedia.org/wiki/Leap_year
  return(((year %% 4 == 0) & (year %% 100 != 0)) | (year %% 400 == 0))
}
#############
WeatherGen_APSIM<-function(lat=42,long=-92.2625,fileName="metfile.met",
                           start_yr = 2000,end_yr = NULL,comments=NULL){
  if(is.null(end_yr)) end_yr = as.numeric(format(Sys.time(), "%Y"))-1
  ##downloading the metfile
  ss<-download_daymet(site = "Daymet", lat =lat , lon =long ,
    start_yr = start_yr, end_yr = end_yr,
    internal = "data.frame", quiet =T) 
  # simple preprocessing and selecting and renaming
  wdata<-ss$data%>%select(year,day=yday,radn=srad..W.m.2.,maxt=tmax..deg.c.,mint=tmin..deg.c.,rain=prcp..mm.day.,dayL=dayl..s.)
  wdata$radn<-(wdata$radn*wdata$dayL)/1e6
  wdata<-wdata%>%select(-dayL)
  
  wdata2<-do.call("rbind",lapply(unique(wdata$year), function(yeari){
    tmp<-wdata%>%filter(year==yeari)
    if(is.leapyear(unique(tmp$year))){
      tmp<-rbind(tmp,tail(tmp,1))
      tmp[nrow(tmp),2]<-366
    }
    tmp
  }))
  
  ## estimaitng TavAmp
  data<-wdata
  data$month <- lubridate::month(as.Date(paste(data$year, data$day,sep = "-"), format = "%Y-%j"))
  data$meanDayT <- (data$maxt + data$mint)/2
  mmt <- plyr::ddply(data, "month", function(df) mean(df$meanDayT))
  if (nrow(mmt) != 12) print("WARNING: At least 12 months of data is required to generate tav and amp. Values may be inaccurate.")
  ############ Small function for wrtting metfile adopted by APSIM package
  con <- file(fileName, "w")
  writeLines("[weather.met.weather]", con)
  writeLines("", con)
  for (i in 1:length(comments)) writeLines(comments[i], con)
  writeLines("", con)
  writeLines(paste("Latitude =", lat), con)
  writeLines(paste("Longitude =", long), con)
  writeLines("", con)
  writeLines(paste("tav =", max(mmt$V1) - min(mmt$V1)), con)
  writeLines(paste("amp =", mean(mmt$V1)), con)
  writeLines("", con)
  writeLines(paste(names(wdata), sep = "", collapse = " "), con)
  writeLines(paste( c("()", "()", "(MJ/m^2/day)", "(oC)", "(oC)", "(mm)"), sep = "", collapse = " "), con)
  write.table(wdata2, file = con, quote = FALSE, row.names = FALSE, col.names = FALSE)
  close(con)
  #cat("Finish writting the met file !")
}

