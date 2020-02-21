#Parameter section
[CmdletBinding()]
Param(
    [Parameter(HelpMessage='Definieren der Größe des gesamten Datentopfes')]
        [Int64]$MaxFolderSize=2GB,
    [Parameter(HelpMessage='Definieren der Anzahl an Dateien. Die tatsächliche Anzahl kann um +/- 10% variieren, da ein Zufallsalgorithmus verwendet wird.')]
        [int]$FileCount = 3000,
    [Parameter(HelpMessage='Definieren der Anzahl der PI-Mitarbeiter')]
        [int]$employee = 10,
    [Parameter(HelpMessage='Definieren des Wurzelverzeichnisses, in dem die Daten verändert werden sollen')]
        [String]$folder="C:\TestDir"
)

#Variable section
$_str=$folder.split("\")
$vol=$_str[0]+"\"
$root= Join-Path -Path $vol -ChildPath $_str[1]
$homedir= Join-Path -Path $root -ChildPath "Home"
$profile = Join-Path -Path $root -ChildPath "Profile"
$data = Join-Path -Path $root -ChildPath "Daten"
$FileTypeExtensions = @("docx","xlsx","jpg","png","pptx","mdb","pst","ldf","bkp")
$prf = @("Desktop","Dokumente","Bilder","Downloads","Musik","Kontakte")

#Function section
#create logging
Set-Variable logFile -Scope Script
function LogInfo($message) {
    $date=Get-Date
    $outContent = "[$date]`tInfo`t`t$message`n"
    Add-Content "Log\$Script:logFile" $outContent
}

function LogError($message) {
    $date=get-date
    $outContent = "[$date]`tError`t`t$message`n"
    Add-Content "Log\$Script:logFile" $outContent
}

function LogSkip($message) {
    $date=get-date
    $outContent = "[$date]`tSkip`t`t$message`n"
    Add-Content "Log\$Script:logFile" $outContent
}

function ConfigureLogger() {
    if ((Test-Path Log) -eq $false) {
        $LogFolderCreationObj=New-Item -Name Log -type directory
    }
    $date=Get-Date -UFormat "%Y-%m-%d %H-%M-%S"
    $script:logFile="CreateDemoData_$date.log"
    Add-Content "Log\$logfile" "Date`t`t`tCategory`t`tDetails"
}

#create folder structure
function CreateDirectory {
    if (Test-Path $homedir) { 
        LogError ("$homedir does already exist, nothing to do")
    }
    else {
        $NULL = New-Item -ItemType Directory -Path $homedir
        [int]$i=0
        Do {            
            $userhome = Join-Path $homedir -ChildPath "Userhome_$i"
            $NULL = New-Item -ItemType Directory -Path $userhome
            $i++
            LogInfo ("$homedir and specific $userhome created")            
        }
        until ($i -eq $employee)        
    }
    if (Test-Path $profile) {
        LogError ("$profile does already exist, nothing to do")
    }
    else {
        $NULL = New-Item -ItemType Directory -Path $profile
        [int]$i=0
        Do {
            $userprofile = Join-Path $profile -ChildPath "Userprofile_$i"
            $prf | foreach {
                $_tmp = Join-Path $userprofile -ChildPath $_
                $NULL = New-Item -ItemType Directory -Path $_tmp
            }
            $i++
            LogInfo ("$profile and specific $userprofile created")            
        }
        until ($i -eq $employee)        
    }
    if (Test-Path $data) { 
        LogError ("$data does already exist, nothing to do")
    }
    else {
        $NULL = New-Item -ItemType Directory -Path $data
        LogInfo ("$data created")   
    }
}

#create Dataload
function CreateLoad {
    [int]$i=0
    [int]$_avg =$MaxFolderSize / $FileCount
    [int]$_avgmin = $_avg-(($_avg/100)*10)
    [int]$_avgmax = $_avg+(($_avg/100)*10)

    while ($TotalFileSize -lt $MaxFolderSize) {
        $_dir = (ls $root -dir -r).FullName| ? { $_ -ne "$homedir" -and $_ -ne "$profile" } | get-random
        $_nam = [guid]::NewGuid()
        #$_nam = ([System.IO.Path]::GetRandomFileName()).Split(‘.’)[0]
        $_fty = $FileTypeExtensions | get-random
        $_fil = $_dir+"\"+$_nam+"."+$_fty
        $_siz = get-random -Minimum $_avgmin -Maximum $_avgmax
        $TotalFileSize=$TotalFileSize + $_siz
        $file = [io.file]::Create($_fil)
        $file.SetLength($_siz)
        $file.Close()
        
    }
    
    $count=(Get-ChildItem -File -Path $root -Recurse | Measure-Object -Property Name).count
    $p=(get-location).Path
    Write-output "Done, $count Files created. Logfile created in $p\Log"
    LogInfo ("$count files created")
}

#script
ConfigureLogger
CreateDirectory
CreateLoad
