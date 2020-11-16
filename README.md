# CollectorDummyData

This Powershell script has been designed with a main idea: export data ina CSV file masking sensitive information.  

Basically we need to configure the parameters:

## Connectivity

- **$server** = "xxxxx.database.windows.net" // Azure SQL Server name
- **$user** = "xxxxxx" // User Name
- **$passwordSecure** = "xxxxxx" // Password
- **$Db** = "xxxxxx"      // Database Name
- **$Folder** = $true     // Folder where the exported files will be saved and also the file that contains the instrucctions to mask data.

## AMS_Instruct.SQL

This file contains a line per table that the script will be export, every line needs to have table_name and column(s) name that you want to mask, for example, 
mytable,column2,column3
mytable2,column5,column6
  
## Executing this Powershell script, it will be done:
- Per every line of AMS_Instruct.SQL
  + For each interaction: 
    + Connect to the database. 
    + Export the tabla using CSV format and for every column that you have in the AMS_INSTRUCT.SQL the process will replace the output by the text "1". For example, 
    ++ You have the following AMS_Instruct.SQL with following definition Clients,Firstname,SurName
    ++ The table has 4 columns, IdCustomer, Age, FirstName and SurName
    ++ The export process will run the following TSQL select Id, Age, 1 as FirstName,1 as Surname from Clients
         
      
Enjoy!
