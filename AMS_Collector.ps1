#----------------------------------------------------------------
# Application: Anonymize data V.1
# Propose: Export the data that PII will be not send
#----------------------------------------------------------------

#----------------------------------------------------------------
#Parameters 
#----------------------------------------------------------------
param($server = "", #ServerName parameter to connect 
      $user = "", #UserName parameter  to connect
      $passwordSecure = "", #Password Parameter  to connect
      $Db = "", #DBName Parameter  to connect
      $Folder = "c:\AMS_Export") #Folder Paramater to save the csv files 


#----------------------------------------------------------------
#Function to connect to the database using a retry-logic
#----------------------------------------------------------------

Function GiveMeConnectionSource()
{ 
  for ($i=1; $i -lt 10; $i++)
  {
   try
    {
      logMsg( "Connecting to the database...Attempt #" + $i) (1)
      $SQLConnection = New-Object System.Data.SqlClient.SqlConnection 
      $SQLConnection.ConnectionString = "Server="+$server+";Database="+$Db+";User ID="+$user+";Password="+$password+";Connection Timeout=60" 
      $SQLConnection.Open()
      logMsg("Connected to the database...") (1)
      return $SQLConnection
      break;
    }
  catch
   {
    logMsg("Not able to connect - Retrying the connection..." + $Error[0].Exception) (2)
    Start-Sleep -s 5
   }
  }
}

#--------------------------------------------------------------
#Create a folder 
#--------------------------------------------------------------
Function CreateFolder
{ 
  Param( [Parameter(Mandatory)]$Folder ) 
  try
   {
    $FileExists = Test-Path $Folder
    if($FileExists -eq $False)
    {
     $result = New-Item $Folder -type directory 
     if($result -eq $null)
     {
      logMsg("Imposible to create the folder " + $Folder) (2)
      return $false
     }
    }
    return $true
   }
  catch
  {
   return $false
  }
 }

#-------------------------------
#Create a folder 
#-------------------------------
Function DeleteFile{ 
  Param( [Parameter(Mandatory)]$FileName ) 
  try
   {
    $FileExists = Test-Path $FileNAme
    if($FileExists -eq $True)
    {
     Remove-Item -Path $FileName -Force 
    }
    return $true 
   }
  catch
  {
   return $false
  }
 }

#--------------------------------
#Log the operations
#--------------------------------
function logMsg
{
    Param
    (
         [Parameter(Mandatory=$true, Position=0)]
         [string] $msg,
         [Parameter(Mandatory=$false, Position=1)]
         [int] $Color
    )
  try
   {
    $Fecha = Get-Date -format "yyyy-MM-dd HH:mm:ss"
    $msg = $Fecha + " " + $msg
    Write-Output $msg | Out-File -FilePath $LogFile -Append
    $Colores="White"
    $BackGround = 
    If($Color -eq 1 )
     {
      $Colores ="Cyan"
     }
    If($Color -eq 3 )
     {
      $Colores ="Yellow"
     }

     if($Color -eq 2)
      {
        Write-Host -ForegroundColor White -BackgroundColor Red $msg 
      } 
     else 
      {
        Write-Host -ForegroundColor $Colores $msg 
      } 


   }
  catch
  {
    Write-Host $msg 
  }
}

#--------------------------------
#The Folder Include "\" or not???
#--------------------------------

function GiveMeFolderName([Parameter(Mandatory)]$FolderSalida)
{
  try
   {
    $Pos = $FolderSalida.Substring($FolderSalida.Length-1,1)
    If( $Pos -ne "\" )
     {return $FolderSalida + "\"}
    else
     {return $FolderSalida}
   }
  catch
  {
    return $FolderSalida
  }
}

#--------------------------------
#Validate Param
#--------------------------------
function TestEmpty($s)
{
if ([string]::IsNullOrWhitespace($s))
  {
    return $true;
  }
else
  {
    return $false;
  }
}

#--------------------------------
#Separator
#--------------------------------

function GiveMeSeparator
{
Param([Parameter(Mandatory=$true)]
      [System.String]$Text,
      [Parameter(Mandatory=$true)]
      [System.String]$Separator)
  try
   {
    [hashtable]$return=@{}
    $Pos = $Text.IndexOf($Separator)
    $return.Text= $Text.substring(0, $Pos) 
    $return.Remaining = $Text.substring( $Pos+1 ) 
    return $Return
   }
  catch
  {
    $return.Text= $Text
    $return.Remaining = ""
    return $Return
  }
}

try
{
Clear

#--------------------------------
#Check the parameters.
#--------------------------------

if (TestEmpty($server)) { $server = read-host -Prompt "Please enter a Server Name" }
if (TestEmpty($user))  { $user = read-host -Prompt "Please enter a User Name"   }
if (TestEmpty($passwordSecure))  
    {  
    $passwordSecure = read-host -Prompt "Please enter a password"  -assecurestring  
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSecure))
    }
else
    {$password = $passwordSecure} 
if (TestEmpty($Db))  { $Db = read-host -Prompt "Please enter a Database Name"  }
if (TestEmpty($Folder)) {  $Folder = read-host -Prompt "Please enter a Destination Folder (Don't include the past \) - Example c:\QdsExport" }

Function Remove-InvalidFileNameChars {

param([Parameter(Mandatory=$true,
    Position=0,
    ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true)]
    [String]$Name
)

return [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '')}

#--------------------------------
#Run the process
#--------------------------------


logMsg("Creating the folder " + $Folder) (1)
   $result = CreateFolder($Folder) #Creating the folder that we are going to have the results, log and zip.
   If( $result -eq $false)
    { 
     logMsg("Was not possible to create the folder") (2)
     exit;
    }
logMsg("Created the folder " + $Folder) (1)

$sFolderV = GiveMeFolderName($Folder) #Creating a correct folder adding at the end \.

$LogFile = $sFolderV + "AMS_Export.Log"    #Logging the operations.
$ZipFile = $sFolderV + "AMS_Export.Zip"    #compress the zip file.
$File    = $sFolderV + "AMS_Instruct.SQL"  #Tables to export and columns to hide

logMsg("Deleting Log and Zip File") (1)
   $result = DeleteFile($LogFile) #Delete Log file
   $result = DeleteFile($ZipFile) #Delete Zip file that contains the results
logMsg("Deleted Log and Zip File") (1)

logMsg("Reading the instrucction file") (1)
$ExistFile= Test-Path $File
if($ExistFile -eq 1)
   {
    $query = @(Get-Content $File) 
    logMsg("Instrucction file Info "+$query) (1)
   }
else
   {
    logMsg("The file that contains the instucctions doesn't exist") (2)
    exit;
   }
logMsg("Read the instrucction file") (1)  


logMsg("Executing the query to obtain the tables of query store..")  (1)

   $SQLConnectionSource = GiveMeConnectionSource #Connecting to the database.
   if($SQLConnectionSource -eq $null)
    { 
     logMsg("It is not possible to connect to the database") (2)
     exit;
    }

logMsg("Processing the tables selected.." ) (1) 
for ($iQuery=0; $iQuery -lt $query.Count; $iQuery++) 
 {
  
  $return= GiveMeSeparator $query[$iQuery] ","
  $StateTmp  = [System.Collections.ArrayList]@()
  $Table = $return.text
  $Column = $return.Remaining
  $SQL=""
  while($true)
  {
     if( TestEmpty($Column) ) {break} 
     $return= GiveMeSeparator $Column ","
     $StateTmp.Add($return.text) | Out-null
     $Column=$return.Remaining
  }
  $SQLCommandExiste = New-Object System.Data.SqlClient.SqlCommand
  $SQLCommandExiste.CommandTimeout = 60
  $SQLCommandExiste.Connection=$SQLConnectionSource
  $SQLCommandExiste.CommandText = "select top 1 * from [" + $Table + "]"
  $Reader = $SQLCommandExiste.ExecuteReader(); #Executing the Recordset
  logMsg("Executed the query to obtain the definition of the table.." + $Table) (1)
  $SQL="select"
  while($Reader.Read())
   {
    for ($iColumn=0; $iColumn -lt $Reader.FieldCount; $iColumn++) 
     {
       $bFound=$False
       for ($iEsta=0; $iEsta -lt $StateTmp.Count; $iEsta++) 
       {
         If($StateTmp[$iEsta] -eq $Reader.GetName($iColumn).ToString())
         {
           $bFound=$true
          break;
         }
       }
       If($bFound -eq $true)
       {
          $Row = " 1 as [" + $Reader.GetName($iColumn).ToString() +"]"
       }
       If($bFound -eq $false)
       {
          $Row = $Reader.GetName($iColumn).ToString()
       }
       $SQL = $SQL + " "+ $Row +","
    }
   }
   logMsg("Closing the recordset") (1)
   $Reader.Close();
   
   $SQL = $SQL.Substring(0,$SQL.Length-1) + " FROM " + $Table
   logMsg("Syntax for definition of the table.." + $Table + "-" + $SQL) (1)
   $command = New-Object System.Data.SqlClient.SqlCommand
   $command.CommandText = $SQL
   $command.Connection = $SQLConnectionSource
    
   $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
   $SqlAdapter.SelectCommand = $command
   $DataSet = New-Object System.Data.DataSet
   logMsg("Exporting the data.." + $Table + "-" + $SQL) (1)
   $DataReturned = $SqlAdapter.Fill($DataSet)
   $Table = Remove-InvalidFileNameChars($Table)
   $FileBCP = $sFolderV + "AMS_" + $Table + ".CSV"
   $DataReturned = $DataSet.Tables[0] | Export-Csv $FileBCP -NoTypeInformation -Encoding UTF8
   logMsg("Exporting the data.." + $Table + "-" + $SQL + " file " + $FileBCP) (1)
  } 
   logMsg("Closing the connection..") (1)
   $SQLConnectionSource.Close() 
   Remove-Variable password
   logMsg("Zipping the content to " + $Zipfile) (1)
      $result = Compress-Archive -Path $Folder\*.log,$Folder\*.csv -DestinationPath $ZipFile
   logMsg("Zipped the content to " + $Zipfile + "--" + $result )  (1)
   logMsg("AMS Collector Script was executed correctly")  (1)
}
catch
  {
    logMsg("AMS Collector Script was executed incorrectly ..: " + $Error[0].Exception) (2)
  }
finally
{
   logMsg("AMS Collector Script finished - Check the previous status line to know if it was success or not") (2)
} 
