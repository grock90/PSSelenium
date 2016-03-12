    Import-Module .\Selenium.psm1
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