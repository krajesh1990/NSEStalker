rdtomysql <- function
### This functions saves the data content of the file given by filename to the mysql table tablename of database corresponding to the connection
(connection,
### connection with the MySQL server
 filename,
### filename: name of the csv file or the complete path in case it is not located in your current working directory
 tablename)
### tablename: table name in database corrosponding to connection
 
{
  data <- read.table(filename,header = T, sep = ",")
  if(dbExistsTable(connection, tablename)){
   dbWriteTable(connection, name =tablename, value=data, append = T)
  }
  else   dbWriteTable(connection, name = tablename, value=data)  
  
}

fldrtomysql <- function
### This functions takes saves the contents of all the csv file in the folder folderpath in the table tablename.
(connection,
### connection with the MySQL server
folderpath,
### This functions takes saves the contents of all the csv file in the folder folderpath in the table tablename.
tablename)

{
  temp <- getwd()
  setwd(folderpath)
  names <-dir()
  setwd(temp)
  for (name in names)
  {
    string =substr(name,nchar(name)-3,nchar(name))
    if (string == ".csv")  
    rdtomysql(connection,paste(folderpath,"/",name,sep=""),tablename)
  }
}

extract <- function
### This function is our purpose specific because it extracts only the csv file whose name it derives from the zip folder name.
### This function extracts the csv file corresponding to the zip folder name, given by infldrpath, to the folder targetfldrpath.
(infldrpath,
### infldrpath: the path of the folder containing the zip. The path ends with the name of the zip folder.
 targetfldrpath)
### targetfldrpath: path of the folder to extract to.

{
  pathvector= strsplit(infldrpath, "/")[[1]]
  fldrname = pathvector[length(pathvector)]
  temp <- getwd()
  setwd(substr(infldrpath,1,nchar(infldrpath) - nchar(fldrname)-1))
  filename = substr(fldrname, 1, length(fldrname)-4) 
  zip.file.extract(filename,zipname =fldrname,dir =targetfldrpath)
  setwd(temp)
}

extractall <- function
### This function extracts all zip folders contained in the folder infldrpath to the targetfolder.
(infldrpath,
### infldrpath: path of the folder including folder name
targetfldrpath)
### targetfldrpath: path of the folder to extract to.

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

