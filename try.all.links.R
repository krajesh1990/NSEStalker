library(timeDate)
library(fBasics)
library(fImport)
library("RCurl")
library(bitops)
library(methods)
library(RMySQL)

m <- dbDriver("MySQL")
#conn<-dbConnect(
#m,
### The name of the connection
#dbname = "nsedb",      
### The name of database to connect
#user = "root",
### The username for MySQL
#password = "intern123", 
### The password for MySQL
#host = "localhost")
### The host for MySQL 

### For logging downloading using connection
mylog <- file(
"log.csv",
### Name of the Log file
"w")  
### writing privileges

mylog2 <- file("log2.csv", "w")  ##<< For logging the files written to database

### Function takes the start date and the end date for the period for which you want to make the 
### the database.
get.bhavcopy<-function(
### The function to run the main process
a,
### The starting date in yyyy-mm-dd format
b
### The starting date in yyyy-mm-dd format
)
{
  holiday<-read.csv("holiday.csv")
  tS = timeSequence(from = a, to = b, by = "day")
  char<-as.character(tS)
  day<-dayOfWeek(tS)
  trading<-as.character(seq(length(char)))   ##<<  The trading days
  settlement<-as.character(seq(length(char))) ##<<  The settlement days
  reason<-as.character(seq(length(char)))    ##<<  Reason for being a holiday
  mont<-as.character(seq(length(char)))      ##<< Month
  year<-as.character(seq(length(char)))       
  date<-as.character(seq(length(char)))
  equity<-as.character(seq(length(char)))        ##<<  URLs for equities
  derivative<-as.character(seq(length(char)))    ##<<  URLs for derivatives
  atom<-atoms(tS)
  for (i in 1:length(tS))
  {
    if(atom[i,2]==1) mont[i]<-"JAN"
    if(atom[i,2]==2) mont[i]<-"FEB"
    if(atom[i,2]==3) mont[i]<-"MAR"
    if(atom[i,2]==4) mont[i]<-"APR"
    if(atom[i,2]==5) mont[i]<-"MAY"
    if(atom[i,2]==6) mont[i]<-"JUN"
    if(atom[i,2]==7) mont[i]<-"JUL"
    if(atom[i,2]==8) mont[i]<-"AUG"
    if(atom[i,2]==9) mont[i]<-"SEP"
    if(atom[i,2]==10) mont[i]<-"OCT"
    if(atom[i,2]==11) mont[i]<-"NOV"
    if(atom[i,2]==12) mont[i]<-"DEC"
    year[i]<-atom[i,1]
    date[i]<-atom[i,3]
  }
  ### Marking all the Weekends as holidays
  for(i in 1:length(char))    
  {
    if(day[i]=="Sat" || day[i]=="Sun")
    {
      trading[i]<-"Holiday"
      settlement[i]<-"Holiday"
      reason[i]<-"Weekend"
    }
    else
    {
      trading[i]<-"Working Day"
      settlement[i]<-"Working Day"
      reason[i]<-""
    }

  ### Marking all the holidays as as listed in holiday.csv
    for(j in 1:nrow(holiday))     
    {
      if(as.character(char[i]) == as.character(holiday[j,1]))
      {
        trading[i]<-"Holiday"
        settlement[i]<-"Holiday"
        reason[i]<-as.character(holiday[j,3])
      }
    }
  }
### creating URLs 
  for(i in 1:length(tS))
  {
   # if(trading[i]=="Working Day"||settlement[i]=="Working Day")  ##<< Creating URLs for working days
   # {
      if(as.integer(date[i])<10)   ##<<  Checking for the dates less than 10 and concatinating 0 
      {
        equity[i]<-as.character(composeURL("www.nseindia.com/content/historical/EQUITIES/",year[i],"/",mont[i],"/cm0",date[i],mont[i],year[i],"bhav.csv.zip"))
        derivative[i]<-as.character(composeURL("www.nseindia.com/content/historical/DERIVATIVES/",year[i],"/",mont[i],"/fo0",date[i],mont[i],year[i],"bhav.csv.zip"))
      }
      else
      {
        equity[i]<-as.character(composeURL("www.nseindia.com/content/historical/EQUITIES/",year[i],"/",mont[i],"/cm",date[i],mont[i],year[i],"bhav.csv.zip"))
        derivative[i]<-as.character(composeURL("www.nseindia.com/content/historical/DERIVATIVES/",year[i],"/",mont[i],"/fo",date[i],mont[i],year[i],"bhav.csv.zip"))
      }
  }
  
  ### Downloading the zipped files for equitites
  sapply(
  equity,
  ### Vector having the URLs for the equities
  downloadE)

  ### Downloading the zipped files for derivatives

  sapply(derivative,
  ### Vector having the URLs for the derivatives
  downloadD)
  
  w<-getwd()
  extractall(w,w)  ##<< Calling the 
  close(mylog)  ##<< Closing the download log connection
  close(mylog2)  ##<< Closing the database connection 
}

### Adding the data from files into the database
fldrtomysql <- function(
### Reades all the .csv files and calls rdtomysql() function
connection,
folderpath)
### folderpath: path of the folder
{
  temp <- getwd()
  setwd(folderpath)
  names <-dir()
  setwd(temp)
  for (name in names)
  {
    
    type<-substr(name,1,2)  ##<< first two letter decide if its a future and options or equities
    string =substr(name,nchar(name)-3,nchar(name))
    if (string == ".csv") 
    {
      if(type=="cm"){
      
      rdtomysql(connection,paste(folderpath,"/",name,sep=""),"equity")
      } 
      if(type=="fo") {
      
      rdtomysql(connection,paste(folderpath,"/",name,sep=""),"fo")
      }
    
   }
  
  }
}
### Adds a csv to the database
rdtomysql <- function(connection, filename, tablename)
{
  data <- read.table(filename,header = T, sep = ",")  ##<<  reads the data plus an extra NULL column
  data$X<- NULL     ##<<  deleting an extra column read
  connection= conn
  ### Writing log - 3 fields - time , type , the file added
  cat(as.character(timestamp()),"adding to DB ", filename, "\n",file = mylog2, sep = ",")
  if(tablename=="equity")
  {
    ifelse(dbExistsTable(connection, tablename),dbWriteTable(connection, name =tablename, value=data, append = T),dbWriteTable(connection, name = tablename, value=data))

  }  
    
  if(tablename=="fo")
  {

    dataf<-data[grep("XX", data$OPTION_TYP, ignore.case=T),]  ##<< seperating the rows corresponding to Future
    dataf$STRIKE_PR<- NULL   ##<< deleting unused column STRIKE_PR from futures 
    dataf$OPTION_TYP<-NULL   ##<< deleting unused column OPTION_TYP from futures
    datao<- data[data$STRIKE_PR >0,]  ##<< seperating the rows corresponding to Options
    ifelse(dbExistsTable(connection, "future"),dbWriteTable(connection, name ="future", value=dataf, append = T),dbWriteTable(connection, name = "future", value=dataf))
    ifelse(dbExistsTable(connection, "options"),dbWriteTable(connection, name ="options", value=datao, append = T),dbWriteTable(connection, name = "options", value=datao))
  }  
  
}

### Downloading Derivative file from the URL and name the file
downloadD<-function(sURL)
{
  #Sys.sleep(poisson())
 tryCatch( if(!is.na(sURL))
  {
    
    options(HTTPUserAgent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6;en-US; rv:1.9.2.12) Gecko/20101026 Firefox/3.6.12")
    tContent <- getURLContent(sURL, verbose = TRUE, useragent = getOption("HTTPUserAgent"))
    cat(as.character(timestamp()),"  downloading ", sURL,"\n",file = mylog, sep = ",")
    attributes(tContent) = NULL
    t<-nchar(sURL)
    c<-substr(sURL, t-22 ,t)
    writeBin(tContent, c )    
  } ,
  error=function(e) {
  cat(as.character(timestamp()),"  URL NOT FOUND ", sURL,"\n",file = mylog, sep = ",")
 } )
}
### Downloading Equity file from the URL and name the file
downloadE<-function(sURL)
{
  tryCatch(
 # Sys.sleep(poisson())
  if(!is.na(sURL))
  {
    
    options(HTTPUserAgent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6;en-US; rv:1.9.2.12) Gecko/20101026 Firefox/3.6.12")
    tContent <- getURLContent(sURL, verbose = TRUE, useragent = getOption("HTTPUserAgent"))
    attributes(tContent) = NULL
    cat(as.character(timestamp()),"downloading ", sURL, "\n",file = mylog, sep = ",")
    t<-nchar(sURL)
    c<-substr(sURL, t-22 ,t)
    writeBin(tContent, c )    
  } , error=function(e) 
  {
  cat(as.character(timestamp()),"  URL NOT FOUND ", sURL,"\n",file = mylog, sep = ",")
  }
    )
}

### Gives an integer following the poisson distribution with parameter 4
poisson<- function()
{
  k = 0
  p = 1.0
  L <-exp(-4)
  while (p >= L)  
  {
    k<-k+1
    x1 <- runif(1, 0, 1)
    p <- p*x1
  }
  k<- k-1
  return (k)
}

### Extracts all the zip files in the mentioned folder to target folder path
extractall <- function(infldrpath,targetfldrpath)
{
  temp <- getwd()
  setwd(infldrpath)
  names <-dir()
  setwd(temp)
  for (name in names)
  {
    string =substr(name,nchar(name)-7,nchar(name))
    if (string == ".csv.zip")  
    extract(paste(infldrpath,"/",name,sep = ""),targetfldrpath)
  }
}
### Extracts a single named zip file
extract <- function(infldrpath, targetfldrpath)
{
  pathvector= strsplit(infldrpath, "/")[[1]]
  fldrname = pathvector[length(pathvector)]
  temp <- getwd()
  setwd(substr(infldrpath,1,nchar(infldrpath) - nchar(fldrname)-1))
  filename = substr(fldrname, 1, length(fldrname)-4) # avoiding ".zip"
  zip.file.extract(filename,zipname =fldrname,dir =targetfldrpath)
  setwd(temp)
}
