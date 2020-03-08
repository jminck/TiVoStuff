
<#
    .SYNOPSIS
        This script is an example VOD preprocessor step prior to WFM ingest
    .DESCRIPTION
        Convert-PitchedAssets recurses through a VOD catcher share and adds TiVo VOD required ADI extensions
        to the asset metadata, as well as renaming the ADI file and its parent folder into the convention
        required by TiVO VOD
#>

$script = $script:MyInvocation.MyCommand.name
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
Set-Location $ScriptDir

if ($null -eq $logFile)
{
    $logFile = ".\adiprep_$script" + (Get-Date -Format yyyy-MM-dd) + ".log"
}
if ($null -eq $folder)
{
    $folder = "/tmp/assets/out/vp11/TVOD"
}
if ($null -eq $addcategory)
{
    $addcategory = $true
}
if ($null -eq $packagename)
{
    $packagename = "super-svod"
}

# load helper functions
. .\AdiPrepFunctions.ps1

Write-Log -Message "|--------------Starting script--------------------|" -logFile $logFile
Write-Log -Message $script -logFile $logFile
Write-Host working with folder $folder
if ($runall -eq $true){$confirmation = "a"} else{ $confirmation = $null}
$adifiles = Get-ChildItem -Recurse $folder -Filter *.xml
$c = 0
foreach ($adifile in $adifiles) {
    if ($confirmation -ne "a") {
        $confirmation = Read-Host "Are you Sure You Want To Proceed: ((y)es/(n)o/(a)ll)"
    }
    if (($confirmation -eq 'y') -or ($confirmation -eq 'a')) {
        $update = $false
        $c += 1
        Write-Host working with file $c - $adifile.FullName
        $xml = [xml](Get-Content $adifile.FullName)
        $grossprice = $xml.SelectNodes("//ADI/Asset/Metadata/App_Data[@Name='Gross_price']").value
        if ($null -eq $grossprice) { $grossprice = 0.00 }
        Add-SvodPackage -xml $xml -packagename $packagename -grossprice $grossprice.ToString()
        if ($addcategory) {
            $cats = $xml.SelectNodes("//ADI/Asset/Metadata/App_Data[@Name='Category']")
            $testcategory = "TiVo/SVOD"
            foreach ($cat in $cats) {
                if ($cat.value -match $testcategory) {
                    $cat.value = "$testcategory/$packagename" #update existing category
                    Write-Host $testcategory already exists, updating
                    $update = $true
                }
            }
            if ($update -ne $true) {
                [xml]$childnode = "<App_Data App='MOD' Name='Category' Value='" + "$testcategory/$packagename" + "'/>"
                $xml.SelectNodes("//AMS[@Asset_Class='title']").ParentNode.AppendChild($xml.ImportNode($childnode.App_Data, $true))
            }
        }
        $xml.Save($adifile.fullname)
        $adifile.fullname
    }
}


