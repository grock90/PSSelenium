# PSSelenium
PowerShell Selenium Module

PSSelenium was created out of a necessity to perform WebUI testing within Chrome and other popular browsers.  The goal of this module was to execute a test workflow: pull latest, build and peform acceptance tests all from within powershell.  For IE, this was easily accomplished using comObjects that are natively supported; however, there is no native support for the other popular browsers. 

PSSelenium module extends to PowerShell ISE making it easy to create acceptance tests quickly.  It also allows the creator to focus on the test--workflow and element selectors--instead of implementing all of the Selenium WebDriver actions.  Both CSS and XPath are supported methods for finding elements within the DOM to further perform supported Selenium WebDriver actions. 

# SETUP

1.  Create a Selenium Folder in your powershell modules directory
2.  Copy Selenium.psm1 into the location from Step 1
3.  Open a new ISE or powershell editor
4.  Add the this line at the top of every script: Import-Module -Name Selenium 

# Sample 

    Import-Module ..\..\Selenium.psm1
    $AcceptanceTests = {
      Test-Case "ShouldFindCheesecakeFactoryImageFromBingSearch" {
          #redirect browers to target page
          Open-WebPage  "www.bing.com"
  
          #verify page loaded by title
          Validate-ElementExists -Selector Css -Value "#sb_form_q"
          Wait-UntilElementVisible -Selector Css -Value "#sb_form_q"
  
          #insert text into a control on the page using xpath
          Insert-Text -Selector XPath -Value ".//*[@id='sb_form_q']" -string "Cheesecake Factory"
  
          #click a control using css selector
          Click-Item -Selector Css -Value "#sb_form_go"
  
  
          #validate control exists on the page
          Wait-UntilElementVisible -Selector Css -Value ".b_entityTitle"
  
          #validate text on page
          Validate-TextExists -Selector Css -Value ".b_entityTitle" -ExpectedText "The Cheesecake Factory"
      }
    }

    $results = Invoke-TestCase -testsAsWarnings $true -baseUrl "https://" -TestCases $AcceptanceTests
    New-SummaryReport -TestResults $results
