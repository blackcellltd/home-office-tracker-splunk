param($SplunkHost, $SplunkPort, [switch]$Confirm, [switch]$h)

if ($h) {
	Write-Host "This script installs and configures Sysmon and Splunk Forwarder in addition to configuring the Group policy and the Audit Policy for home office log monitoring. Creates a backup of the Group Policy before overwriting."
	Write-Host "Usage:"
	Write-Host "-SplunkHost`t" -ForegroundColor "green" -NoNewline
	Write-Host "Specify the Splunk Instace host name or IP address."
	Write-Host "-SplunkPort`t" -ForegroundColor "green" -NoNewline
	Write-Host "Specify the Splunk Instace port."
	Write-Host "-Confirm`t" -ForegroundColor "green" -NoNewline
	Write-Host "Confirm you want to run this script."
	Write-Host "-h`t`t" -ForegroundColor "green" -NoNewline
	Write-Host "Display this help text."
	break
	}

if (!$Confirm) {
	Write-Host "Please confirm you would like to run this script. By running this script audit logs of your computer are sent to your employer. This script is provided `"as-is`", we are not responsible for the changes made to your system. `n[Y] : accept" -ForegroundColor "Yellow"
	$accept = Read-Host
	
	if ($accept -ne "y" -and $accept -ne "Y"){
	break
	}
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
	
	if ($fh.hash -eq $hash) {
		
		if (!$SplunkHost -or !$SplunkPort){
			Write-Host 'Input your Splunk Host (Leave Empty for default):' -NoNewline -ForegroundColor "Yellow"
			$SplunkHost = Read-Host
			Write-Host 'Input your Splunk Port (Leave Empty for default):' -NoNewline -ForegroundColor "Yellow"
			$SplunkPort = Read-Host
			if (!$SplunkHost){
				$SplunkHost = "ho.blackcell.io"
			}
			if (!$SplunkPort) {
				$SplunkPort = "58089"
			}
		}
		
		Write-Host "`nUnzipping`n" -ForegroundColor "Green"
		Expand-Archive -Path '.\data.zip' -DestinationPath '.\temp'

		Write-Host "Installing Sysmon" -ForegroundColor "Green"
		.\temp\Sysmon.exe -accepteula -i ".\temp\z-AlphaVersion-ep.xml" | Out-Null

		Write-Host "Backing Up Group Policy`n" -ForegroundColor "Green"
		$oggp = $Env:windir + "\System32\GroupPolicy"
		Compress-Archive -Path $oggp -DestinationPath ".\GroupPolicyBackup" -CompressionLevel "Optimal"

		Write-Host "Copying Group Policy`n" -ForegroundColor "Green"
		$gp = $Env:windir + "\System32"
		cp -force -recurse ".\temp\GroupPolicy" $gp

		Write-Host "Setting Logging Policy`n" -ForegroundColor "Green"
		$db = $Env:windir + "\security\local.sdb"
		secedit.exe /configure /db $db /cfg .\temp\secpol.inf | Out-Null
		Auditpol /restore /file:.\temp\audit.ini | Out-Null
		gpupdate /force | Out-Null

		Write-Host "Installing Splunk Forwarder (this may take a while)`n" -ForegroundColor "Green"
		cd temp
		$msi = $Env:windir + "\System32\msiexec.exe"
		$al ="/i splunkforwarder.msi AGREETOLICENSE=Yes DEPLOYMENT_SERVER=" + $SplunkHost + ':' + $SplunkPort + " /quiet"
		Start-Process $msi -ArgumentList $al -Wait
		cd ..

		#waiting for splunk service to appear
		$ProcessActive = Get-Process splunkd -ErrorAction SilentlyContinue
		while($ProcessActive -eq $null){
		Start-Sleep -s 5
		$ProcessActive = Get-Process splunkd -ErrorAction SilentlyContinue
		}


		Write-Host "Cleaning up`n" -ForegroundColor "Green"
		del '.\temp' -force -recurse

		Write-Host "Installation complete" -ForegroundColor "Green"
		start-sleep -Seconds 2

	} else {
		throw "The installation file `"data.zip`" is corrupt or missing."
	}
}