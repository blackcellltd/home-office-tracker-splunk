param([switch]$h)

if ($h) {
	Write-Host "This script uninstalls Sysmon and Splunk Forwarder in addition to reverting the Group policy should the backup file still be in the directory the script is run from."
	Write-Host "Usage:"
	Write-Host "-h`t`t" -ForegroundColor "green" -NoNewline
	Write-Host "Display this help text."
	break
	}
	
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
		Write-Host "This script must be run as an administrator." -ForegroundColor "Red"
		start-sleep -Seconds 2
} else {

	$hash = [char[]](Invoke-WebRequest "https://sep2-repo.blackcell.hu/tracker/data.zip.sha256").content -join ''

	if (Test-Path ".\data.zip"){
		$fh = Get-FileHash ".\data.zip" -Algorithm "SHA256"
	} else {
		Write-Host "Downloading additional assets" -ForegroundColor "Green"
		Invoke-WebRequest "https://sep2-repo.blackcell.hu/tracker/data.zip" -OutFile ".\data.zip"
		$fh = Get-FileHash ".\data.zip" -Algorithm "SHA256"
	}
}

	if ($fh.hash -eq $hash) {
		Write-Host "Unzipping`n" -ForegroundColor "green"
		Expand-Archive -Path '.\data.zip' -DestinationPath '.\temp'

		Write-Host "Uninstalling Sysmon" -ForegroundColor "green"
		.\temp\Sysmon.exe -u | Out-Null

		
		Write-Host "Uninstalling Splunk Forwarder (This may take a while)`n" -ForegroundColor "green"
		cd temp
		$msi = $Env:windir + "\System32\msiexec.exe"
		Start-Process $msi -ArgumentList "/x splunkforwarder.msi /quiet" -Wait -Verbose
		cd ..

		
		if (Test-Path ".\GroupPolicyBackup.zip"){
			Write-Host "Restoring Group Policy`n" -ForegroundColor "green"
			$gp = $Env:windir + "\System32"
			Expand-Archive ".\GroupPolicyBackup.zip" $gp -Force
			gpupdate /force | Out-Null
		}


		Write-Host "Cleaning up`n" -ForegroundColor "green"
		del ".\temp" -force -recurse 
		if (Test-Path ".\GroupPolicyBackup.zip"){
			del ".\GroupPolicyBackup.zip" -force
		}
		del ".\data.zip" -force


		Write-Host "Uninstall Complete" -ForegroundColor "green"
		start-sleep -Seconds 2

	} else {
		throw "The installation file `"data.zip`" is corrupt or missing."
	}