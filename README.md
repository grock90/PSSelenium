# PSSelenium
Powerhsell Selenium Module

This was created out of a necessity to perform WebUI testing within Firefox and Chrome.  I wanted to be able to pull, build, deploy and peform acceptance tests all within powershell.  This was easily accomplished for IE using comObject, however, there is no native support for the other popular browsers. 


# SETUP

1.  Create a Selenium Folder in your powershell modules directory
2.  Copy Selenium.psm1 into the location from Step 1
3.  Open a new ISE or powershell editor
4.  Add the this line at the top of every script: Import-Module -Name Selenium 

