# PSSelenium
PowerShell Selenium Module

PSSelenium was created out of a necessity to perform WebUI testing within Chrome and other popular browsers.  The goal of this module was to execute a test workflow: pull latest, build and peform acceptance tests all from within powershell.  For IE, this was easily accomplished using comObjects that are natively supported; however, there is no native support for the other popular browsers. 

PSSelenium module extends to PowerShell ISE making it easy to create acceptance tests quickly.  It also allows the creator to focus on the test--workflow and element selectors--instead of implementing all of the Selenium WebDriver actions.  Both CSS and XPath are supported methods for finding elements within the DOM to further perform supported Selenium WebDriver actions. 

# SETUP

1.  Create a Selenium Folder in your powershell modules directory
2.  Copy Selenium.psm1 into the location from Step 1
3.  Edit line 493 in selenium.psm1 to reflect the location of Selenium WebDrivers:  $webDriverDir = "$PSScriptRoot/2.45.0/net40/"
4.  Open a new ISE or powershell editor
5.  Add the this line at the top of every script: Import-Module -Name Selenium 

# Sample 

        Import-Module ..\..\Selenium.psm1
        $AcceptanceTests = {
            Test-Case "ShouldFindCheesecakeFactoryByNameInBingSearch" {
            #redirect browers to target page
            Open-WebPage  "www.bing.com"
            
            #Wait total of 30sec to find element by Css selector, further validate element exist in DOM 
            Wait-UntilElementVisible -Selector Css -Value "#sb_form_q"
            Validate-ElementExists -Selector Css -Value "#sb_form_q"
            
            #Insert text into a control on the page using xpath
            Insert-Text -Selector XPath -Value ".//*[@id='sb_form_q']" -string "Cheesecake Factory"
            
            #Click a control using css selector
            Click-Item -Selector Css -Value "#sb_form_go"
            
            #Wait for 30sec to find element by Css selector
            Wait-UntilElementVisible -Selector Css -Value ".b_entityTitle"
            
            #Validate Element css element contains text (supports regex)
            Validate-TextExists -Selector Css -Value ".b_entityTitle" -ExpectedText "The Cheesecake Factory"
            }
            Test-Case "ShouldBeYourNextPSSeleniumTest" {
            Open-WebPage "www.google.com"
            }  
        }
        
        #Invoke the test-case(s) defined in the AcceptanceTest script block 
        $results = Invoke-TestCase -testsAsWarnings $true -baseUrl "https://" -TestCases $AcceptanceTests
        
        #Create a summary 
        New-SummaryReport -TestResults $results
