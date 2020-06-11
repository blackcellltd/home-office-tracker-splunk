# Home Office Tracker for Splunk Enterprise, Free and Light versions.
 
This is a script for installing and configuring Splunk Universal Forwarder and Sysmon for home office monitoring. Additionally the script also tweaks the Group Policy and Audit Policy, to make sure the data forwarded to splunk is as useful as possible. The individual installers and config files are hosted on our site (https://sep2-repo.blackcell.hu/tracker/data.zip) and downloaded as a zip file.


# Usage

You must do the necessary port forwarding to make your Splunk deployment server accessible to the clients you are installing to (default deployment serverver port is 8089).

Prameters:
- SplunkHost		
	>Specify the Splunk deployment server host name or IP address.
- SplunkPort
	>Specify the Splunk deployment server port.
- Confirm
	>Confirm you want to run this script.
- h	
	>Display the help text.


For our home office SOC as a service visit https://blackcell.io/home-office-security-operation-centre/.
