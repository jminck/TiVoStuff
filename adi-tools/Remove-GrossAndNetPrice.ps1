
<#
    .SYNOPSIS
        This script is an example VOD preprocessor step prior to WFM ingest
    .DESCRIPTION
 
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
# load helper functions
. .\AdiPrepFunctions.ps1

Write-Log -Message "|--------------Starting script--------------------|" -logFile $logFile
Write-Log -Message $script -logFile $logFile
Write-Host working with folder $folder logging to $logfile
Write-Log -Message "ADI files found: $adifiles" -logFile $logFile
if ($runall -eq $true){$confirmation = "a"} else{ $confirmation = $null}

$adifiles = Get-ChildItem -Recurse $folder -Filter *.xml
$c = 0
Write-Host working with folder $folder
if ($runall -eq $true){$confirmation = "a"} else{ $confirmation = $null}

foreach ($adifile in $adifiles) {
    if ($confirmation -ne "a") {
        $confirmation = Read-Host "Are you Sure You Want To Proceed: ((y)es/(n)o/(a)ll)"
    }
    if (($confirmation -eq 'y') -or ($confirmation -eq 'a')) {
        $c++
        Write-Host working with file $c - $adifile.FullName
        $xml = [xml](Get-Content $adifile.FullName)
        $element = "Gross_price"
        $v_gp = $xml.ADI.Asset.Metadata.App_Data | Where-Object { $_.Name -eq $element }
        if ($v_gp.count -gt 1) {
            Write-Log -Message "Found multiple Gross_price" -logFile $logFile
            foreach ($v in $v_gp ) {
                Write-Log -Message "removing Gross_price $v.value" -logFile $logFile
                $v.ParentNode.RemoveChild($v)
            }
        }
        else {
            $v_gp.ParentNode.RemoveChild($v_gp)
        }

        $element = "Net_price"
        $v_np = $xml.ADI.Asset.Metadata.App_Data | Where-Object { $_.Name -eq $element }
        if ($v_np.count -gt 1) {
            Write-Log -Message "Found multiple Net_price" -logFile $logFile
            foreach ($v in $v_np ) {
                Write-Log -Message "removing Net_price $v.value" -logFile $logFile
                $v.ParentNode.RemoveChild($v)
            }
        }
        else {
            $v_np.ParentNode.RemoveChild($v_np)
        }

        $xml.Save($adifile.fullname)
        $adifile.fullname
    }
}




