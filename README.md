# PSSelenium
Powerhsell Selenium Module

This was created out of a necessity to perform WebUI testing within Firefox and Chrome.  I wanted to be able to pull, build, deploy and peform acceptance tests all within powershell.  This was easily accomplished for IE using comObject, however, there is no native support for the other popular browsers. 


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
