# PSSelenium
Powerhsell Selenium Module

This was created out of a necessity to perform WebUI testing within Firefox and Chrome.  I wanted to be able to pull, build, deploy and peform acceptance tests all within powershell.  This was easily accomplished for IE using comObject, however, there is no native support for the other popular browsers. 


# SETUP

1.  Create a Selenium Folder in your powershell modules directory
2.  Copy Selenium.psm1 into the location from Step 1
3.  Open a new ISE or powershell editor
4.  Add the this line at the top of every script: Import-Module -Name Selenium 

#Sample Script
Import-Module -Name Selenium 
        
$AcceptanceTests = {
    Test-Case "ShouldFindCheesecakeFactoryImageFromBingSearch" {
        #redirect browers to target page
        Navigate-ToPage "www.bing.com"

        #verify page loaded by title
        Validate-PageHasTitle "Bing"

        #insert text into a control on the page using xpath
        Insert-Text -Selector XPath -Value ".//*[@id='sb_form_q']" -string "Cheesecake"

        #insert text into a control on the page using css
        Insert-Text -Selector Css -Value "#sb_form_q" -string " Factory"

        #click a control using css selector
        Click-Item -Selector Css -Value "#sb_form_go"

        #validate control exists on the page
        Validate-ElementExists -Selector Css -Value ".sgt.rms_img"
        
        #validate text on page
        Validate-ElementTextExists -Selector Css -Value ".b_caption>p" -ExpectedText "US chain of full-service restaurants"
    }
}

$results = Invoke-TestCase -testsAsWarnings $true -baseUrl "https://" -TestCases $AcceptanceTests
Create-SummaryReport -TestResults $results
