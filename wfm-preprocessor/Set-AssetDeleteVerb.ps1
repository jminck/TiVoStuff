
<#
    .SYNOPSIS
        This script updates asset version fore reimport
    .DESCRIPTION
        This script wil increment the Version_Major of all assets in the ADI file, and update the asset's folder name with a new timestamp
        to allow the asset to be re-ingest after a failed attempt to ingest, or other correction made to ADI data.
#>

# load helper functions
. ./PreprocessorFunctions.ps1

$logFile = "./setassetdeleteverb-" + (Get-Date -Format yyyy-MM-dd) + ".log"
$adifiles = Get-ChildItem -Recurse "/assets/Armstrong/catcher/Dropbox/HXHT*" -Include *.xml
Write-Log -Message "ADI files found: $adifiles.Count" -logFile $logFile

$confirmation = $null

foreach ($adifile in $adifiles)
    {
        write-host "processing $adifile"
        if ($confirmation -ne "a")
        {
        $confirmation = Read-Host "Are you Sure You Want To Proceed: ((y)es/(n)o/(a)ll)"
        }
        if (($confirmation -eq 'y') -or ($confirmation -eq 'a')) {
            $xml = [xml](Get-Content $adifile)
            #rev version number
            [int]$version = $xml.ADI.Metadata.AMS.Version_Major
            $version++
            $props = $xml.SelectNodes("//AMS") 
            foreach ($vmaj in $props) {$vmaj.SetAttribute("Verb","DELETE")}
            $xml.Save($adifile)
            $assetid = $xml.SelectNodes("//AMS[@Asset_Class='title']").Asset_ID
            $timestamp = (get-date -Format yyyyMMdd) + "T" + (get-date -Format hhmmss) + "Z"
            $newfolder = "delete_" + $assetid + "_" + $timestamp 
            $folder = $adifile.directoryname
            #add wfmready file if missing
            $wfmreadyfile =  $adifile.DirectoryName + "/" + $adifile.Name.toupper().Replace(".XML",".wfmready")
            if (!(Test-Path $wfmreadyfile))
            { 
                New-Item $wfmreadyfile -ItemType File
            }
            rename-item $folder $newfolder  
            start-sleep -Milliseconds 100      
        }
    }
