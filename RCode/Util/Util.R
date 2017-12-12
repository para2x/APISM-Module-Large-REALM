library(tools)
job <- grep("^JobRunner", readLines(textConnection(system('tasklist', intern = TRUE))), value = TRUE) # finding the pid of the job runners
if(length(job)>0){ # if there is job runner running
  PIDS<-(read.table(text = job))
  pskill(PIDS$V2)

}
