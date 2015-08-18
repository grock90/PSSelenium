<#
.Synopsis
   Powershell Selenium Module 
.DESCRIPTION
   Gives powershell the ability to utilize Selenium API within powershell scripts.
.EXAMPLE
   Import-Module Selenium
#>

Add-Type @"
using System.Collections.Generic;

public class AcceptanceTestResults
{
 private IList<AcceptanceTestResult> acceptanceTestResults = new List<AcceptanceTestResult>();

 public IList<AcceptanceTestResult> Results { 
 get { return acceptanceTestResults; }
 } 

 public int Errors {get; set;} 
}

public class AcceptanceTestResult
{
 public string StoryTitle {get; set;} 
 public bool Passed {get; set;} 
 public string ErrorMessage {get; set;}
}
"@    

$script:driver = $null
$script:baseUrl = $null
$script:acceptanceTestResults = $null
$script:testsAsWarnings = $true
$Global:ScreenshotRepo = Join-Path -Path $ENV:PUBLIC -childpath "\Pictures"

function Get-ScreenShot{
    <#
        .Synopsis
           Get-ScreenShot generates a screen shot during test execution. 
        .DESCRIPTION
           Provides the ability to capture a screenshot during test execution.  By default this is done
           anytime an error is generated during a test.  
        .EXAMPLE
           Get-Screenshot -Driver $script:Driver -Name <name>
    #>
    param(
		[ValidateNotNull()]
		$Driver,
        [ValidateNotNull()]
		$Name

    )
    $Date = Get-Date -Format yyyy-dd-MMThh_mm_ss
    $ScreenshotRepo = Join-Path -Path $Global:ScreenshotRepo -ChildPath $Date

    if(!(Test-Path $ScreenshotRepo)){
        New-Item -Path $ScreenshotRepo -Name $Date -ItemType Directory
    }
    $Screenshot = $Driver.GetScreenshot()
    $ssDate = Get-Date -Format yyyy-dd-MM-Thh_mm_ss
    $ssName = "$Name`_$ssDate.png"
    $ssFile = Join-path -Path $ScreenshotRepo -childpath $ssName
    $ImageFormat = [System.Drawing.Imaging.ImageFormat]::Png
    $Screenshot.SaveAsFile("$ssFile",$ImageFormat)
    Write-Host -BackgroundColor Yellow -ForegroundColor Black "Screenshot captured $ScreenshotRepo"
    Invoke-Item $ScreenshotRepo
}
function Write-Exception{

    param(
		[ValidateNotNull()]
		[scriptblock] $testScriptToExecute
    )

	try 
	{
		& $testScriptToExecute
	}
	catch 
	{
		if ($script:testsAsWarnings) 
		{
			$theErrorMessage = $error[0]
            if($theErrorMessage -ne $null){
               Write-Warning $theErrorMessage
            }
            else{ Get-ScreenShot -Driver $script:driver -Name Exception } 

           
		}
		else 
		{
			throw
		}
	} 
	finally 
	{
		Remove-AcceptanceTests
	}
}
function Invoke-StoryScript{
    param(
		[ValidateNotNull()]
		$storyName,
        [ValidateNotNull()]
        [ScriptBlock]$testScript
    )
	$result = New-Object AcceptanceTestResult
	$result.StoryTitle = $storyName
	$result.Passed = $false
	try 
	{
		if ($script:driver -ne $null) {
			& $testScript			
		}
		$result.Passed = $true
      
        Write-Host -ForegroundColor Green "`n`nTEST PASSED!"
        
	}
	catch{
		$result.ErrorMessage = $_
        Get-ScreenShot -Driver $script:driver -Name $storyName
        Write-Error $result.ErrorMessage
        Write-Host -ForegroundColor White -BackgroundColor Red "TEST FAILED!"

	}
	finally{
		$script:acceptanceTestResults.Results.Add($result)
        $result.ErrorMessage
	}
}
function Remove-AcceptanceTests{
	if ($script:driver -ne $null) { 
		$script:driver.Quit()
	}
}
function New-Url{
    param(
		[ValidateNotNull()]
		$path
    )
	return $baseUrl + $path
}
function Test-Case{
    <#
        .Synopsis
           Test-Case is used to pass defined tests cases to the execution engine. 
        .DESCRIPTION
           Provide a method to define tests for execution.  
        .EXAMPLE
           Test-Case "ShouldExecuteThisTest" { <test case actions> } 
    #>
    param(
		[ValidateNotNull()]
		$name,
		[ValidateNotNull()]
		[ScriptBlock]$fixture
	)
	Write-Host "`n-------------------------------------------------------------"
	Write-Host $name
	Write-Host "-------------------------------------------------------------`n"
	Invoke-StoryScript $name $fixture
}
function Open-WebPage{
    <#
        .Synopsis
           Open-WebPage opens browser to the defined webpage based on the base url. 
        .DESCRIPTION
           Uses the base url and appends value to the end of the url string.  
        .EXAMPLE
           Open-Webpage "corptest"
    #>
    param(
	    [ValidateNotNull()]
	    [string]$WebPage
    )	
if ($script:driver -ne $null) { 
		$url = New-Url $WebPage
		Write-Host "Navigating to $url"
		$script:driver.Navigate().GoToUrl($url) 
	}
}
function Insert-Text{
        <#
        .Synopsis
           Insert-Text puts string value provided into the targeted element. 
        .DESCRIPTION
           Provides a method to enter text into a textbox element. It will always clear the field first
           and put in the string value provided.  
        .EXAMPLE
           Insert-Text -Selector css -Value "#id" -string "Tester-100"
    #>
	param(
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [Validateset('XPath','Css')]
		$Selector,
		[ValidateNotNull()]
		$Value,
		[ValidateNotNull()]
		$string
	)
    switch ($Selector)
    {
        'XPath'{$SeleniumClass = [OpenQA.Selenium.By]::XPath($Value)}
        'Css'{$SeleniumClass = [OpenQA.Selenium.By]::CssSelector($Value)}
    }

	if ($script:driver -ne $null) { 
        $script:driver.FindElement($SeleniumClass).clear()
		Write-Host "Typing <$string> into $Selector`:$Value"
        Start-Sleep -Milliseconds 300
        $script:driver.FindElement($SeleniumClass).SendKeys($string)
	}
    else {
        Throw "$Selector`:$Value does not exist: $SeleniumClass"
    }

    

}
function Click-Item{
    <#
        .Synopsis
           Click-Item performs a click method on a defined element. 
        .DESCRIPTION
           Provides the ability to click an element on a webpage based on the target provided.  
        .EXAMPLE
           Click-Item -Selector Css -Value "#rememberMe"
    #>
    param(
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [Validateset('XPath','Css')]
		$Selector,
		[ValidateNotNull()]
		$Value
    )
    switch ($Selector)
    {
        'XPath'{$SeleniumClass = [OpenQA.Selenium.By]::XPath($Value)}
        'Css'{$SeleniumClass = [OpenQA.Selenium.By]::CssSelector($Value)}
    }
	
    if ($script:driver -ne $null) { 
		Write-Host "Clicking-Item $Selector`:$Value"
		$script:driver.FindElement($SeleniumClass).Click()
	}
    else {
        Throw "$Selector`:$Value does not exist: $SeleniumClass"
    }
}
function Assert-ConfirmationPresent{
    param(
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [Validateset('XPath','Css')]
		$Selector,
		[ValidateNotNull()]
		$Value
    )
    switch ($Selector)
    {
        'XPath'{$SeleniumClass = [OpenQA.Selenium.By]::XPath($Value)}
        'Css'{$SeleniumClass = [OpenQA.Selenium.By]::CssSelector($Value)}
    }
	
    if ($script:driver -ne $null) { 
		Write-Host "Clicking-Item $Selector`:$Value"
		$script:driver.assertConfirmationPresent()
	}
    else {
        Throw "$Selector`:$Value does not exist: $SeleniumClass"
    }


}
function Validate-ElementExists{
    <#
        .Synopsis
          Validate-ElementExists checks the currently loaded page for a specified element. 
        .DESCRIPTION
           Provides the ability to verify that an element exists on the page.  
        .EXAMPLE
           Validate-ElementExists -Selector Css -Value "#username[value='$Global:Id']"
    #>
        param(
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [Validateset('XPath','Css')]
		$Selector,
		[ValidateNotNull()]
		$Value
    )
    switch ($Selector)
    {
        'XPath'{$SeleniumClass = [OpenQA.Selenium.By]::XPath($Value)}
        'Css'{$SeleniumClass = [OpenQA.Selenium.By]::CssSelector($Value)}
    }
	if ($script:driver -ne $null) { 
		if ($script:driver.FindElement($SeleniumClass) -ne $null) {
			Write-Host "Validated $Selector`:$Value exists"
		}
		else {
			Throw "$Value doesn't exist" 
		}
	}
}
function Hover-Element{

        param(
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [Validateset('XPath','Css')]
		$Selector,
		[ValidateNotNull()]
		$Value
    )
    switch ($Selector)
    {
        'XPath'{$SeleniumClass = [OpenQA.Selenium.By]::XPath($Value)}
        'Css'{$SeleniumClass = [OpenQA.Selenium.By]::CssSelector($Value)}
    }
	if ($script:driver -ne $null) { 
		$HoverElement = $script:driver.FindElement($SeleniumClass) 
        if ($HoverElement -ne $null) {
            $HoverElement.Click().Build().Perform()
		}
		else {
			Throw "$Value doesn't exist" 
		}
	}
}
function Validate-TextExists{
    <#
        .Synopsis
          Validate-TextExists checks the currently loaded page for text within a specified element  . 
        .DESCRIPTION
           Provides the ability to verify that an element exists on the page.  
        .EXAMPLE
           Validate-TextExists -Selector Css -Value "#username[value='$Global:Id']"
    #>
        param(
        #selector to find validate element text
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [Validateset('XPath','Css')]
		$Selector,
        
        #xpath or css selector for element
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
		$Value,

        #Expected string to validate against returned string
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        $ExpectedText
        
    )
    switch ($Selector)
    {
        'XPath'{$SeleniumClass = [OpenQA.Selenium.By]::XPath($Value)}
        'Css'{$SeleniumClass = [OpenQA.Selenium.By]::CssSelector($Value)}
    }
	if ($script:driver -ne $null) { 
        $StringExists = $script:driver.FindElement($SeleniumClass).Text
		if ($StringExists -ne $null -and $StringExists.Contains("$ExpectedText")) {
            Write-Host "Validated '$Selector`:$Value' contains '$ExpectedText'"
		}
		else {
			Throw "$Selector`:$Value does not contain '$ExpectedText'"  
		}
	}
}
function Validate-IntGreaterThan{
        param(
        #selector to find validate element text
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [Validateset('XPath','Css')]
		$Selector,
        
        #xpath or css selector for element
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
		$Value,

        #Expected string to validate against returned string
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        $ExpectedValue
        
    )
    switch ($Selector)
    {
        'XPath'{$SeleniumClass = [OpenQA.Selenium.By]::XPath($Value)}
        'Css'{$SeleniumClass = [OpenQA.Selenium.By]::CssSelector($Value)}
    }
	if ($script:driver -ne $null) { 
        $StringExists = $script:driver.FindElement($SeleniumClass).Text
		if ($StringExists -ne $null -and $StringExists.Contains("$ExpectedText")) {
            Write-Host "Validated '$Selector`:$Value' contains '$ExpectedText'"
		}
		else {
			Throw "$Selector`:$Value does not contain '$ExpectedText'"  
		}
	}
}
function Wait-UntilElementVisible{
        param(
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [Validateset('XPath','Css')]
		$Selector,
		[ValidateNotNull()]
		$Value
    )
    switch ($Selector)
    {
        'XPath'{$SeleniumClass = [OpenQA.Selenium.By]::XPath($Value)}
        'Css'{$SeleniumClass = [OpenQA.Selenium.By]::CssSelector($Value)}
    }
	if ($script:driver -ne $null) { 
        Write-Host "Waiting on Element $Selector`:$Value"
        $SleepTime = 10
        do
        {
            Start-Sleep -Milliseconds $SleepTime
            $SleepTime += 10
        }
        until ($script:driver.FindElement($SeleniumClass) -ne $null -or $SleepTime -eq 10000)
		if ($SleepTime -eq 10000) {
			Throw "$Selector`:$Value does not exist $SeleniumClass" 
		}
	}
    $SleepTime = 0
}
function Wait-Until{
        param(
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]

        [ValidateNotNull()]
		$TimeInSec
    )

	if ($script:driver -ne $null) {
            Write-Host "Sleeping for $TimeInSec seconds" 
            Start-Sleep -Seconds $TimeInSec 
	}

}
function Validate-PageHasTitle{
	Param(
		[Parameter(Mandatory=$true)] 
		$titleToValidate
	)

	if ($script:driver -ne $null) {
		if(!($titleToValidate -ieq $script:driver.Title)){
			Throw "$($script:driver.Title) doesn't contain $titleToValidate"
		}
		Write-Host "Validated page has title '$titleToValidate'"
	}
}
function Validate-IsSecureRequest{
	$currentURL = New-Object System.Uri($script:driver.Url)
	$isSecure = ($currentURL.Scheme -ieq "https")
	
	if(!($isSecure)){
		throw "$currentURL is not using HTTPS"
	}
	Write-Host "Validated request is using HTTPS"
}
function Invoke-Test{
	param(
		[ValidateNotNull()]
		$baseUrl,
		[ValidateNotNull()]
		$scriptBlockToExecute,
		[bool]
		$testsAsWarnings
	)
	
	Write-Host "Initializing acceptance tests..."
    $webDriverDir = "$PSScriptRoot/2.45.0/net40/"
    
    Set-Location $webDriverDir
    Get-ChildItem -Path $webDriverDir -Filter "*.dll" | % { Add-Type -Path "$webDriverDir\$_" }
	
	
	$script:testsAsWarnings = $testsAsWarnings;
	<# TODO: update this to be SWITCH driven with a PSvariable

    $capabilities = New-Object OpenQA.Selenium.Remote.DesiredCapabilities
	$capabilityValue = @("--ignore-certificate-errors")
	$capabilities.SetCapability("chrome.switches", $capabilityValue)
    
    #>

	$options = New-Object OpenQA.Selenium.Chrome.ChromeOptions
	$script:driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver #($options)
	$script:driver.Manage().Timeouts().ImplicitlyWait([System.TimeSpan]::FromSeconds(20)) | Out-Null
	
	if (!$baseUrl.StartsWith("http", [System.StringComparison]::InvariantCultureIgnoreCase)) {
		$baseUrl = "http://" + $baseUrl
	}
	if (!$baseUrl.EndsWith("/")) {
		$baseUrl = $baseUrl + "/"
	}	
	$script:baseUrl = $baseUrl
	$script:acceptanceTestResults = New-Object AcceptanceTestResults
	
	Write-Exception $scriptBlockToExecute

	return $script:acceptanceTestResults
}
function Invoke-TestCase{
	param (
		[ValidateNotNull()]
		[bool]$testsAsWarnings,
		[ValidateNotNull()]
		$baseUrl,
		[ValidateNotNull()]
		[string]$TestCases
	)
	$scriptBlock = [scriptblock]::Create($TestCases)
	$acceptanceTestResults = Invoke-Test -baseUrl $baseUrl -scriptBlockToExecute $scriptBlock -testsAsWarnings $testsAsWarnings	

	return $acceptanceTestResults		
}
function New-SummaryReport{
	param (
		[Parameter(Mandatory=$true)] 
		$TestResults
	)
    $FileDate = Get-Date -Format yyyy-dd-MMThh_mm_ss
    $ReportFile = Join-Path -Path $Global:ScreenshotRepo -ChildPath "$FileDate.html"
    if(!(Test-Path $ScreenshotRepo)){
        New-Item -Path $ScreenshotRepo -Name $Date -ItemType Directory
    }

    $TestCount = $TestResults.Results.Count
    $TestsFailed = ($TestResults.Results.Passed | ? { $_ -eq  $false}).Count
    $TestsPassed = ($TestResults.Results.Passed | ? { $_ -eq  $true}).Count
    Write-Host -ForegroundColor Green "Test Results from $TestCount tests: `nPassed: $TestsPassed" 
    if($TestsFailed -gt 0){ Write-Host -ForegroundColor Red "Failed: $TestsFailed" } 
    
	$TestResults.Results | Select-Object -Property Passed, Storytitle, ErrorMessage | Out-GridView 
    $TestResults.Results | Select-Object -Property Passed, Storytitle, ErrorMessage | ConvertTo-Html | Out-File -FilePath $ReportFile -Force
}
function Send-Keys{
    param(
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [Validateset('XPath','Css')]
		$Selector,
		[ValidateNotNull()]
		$Value,
        [ValidateNotNull()]
		$Keys
        
    )
    switch ($Selector)
    {
        'XPath'{$SeleniumClass = [OpenQA.Selenium.By]::XPath($Value)}
        'Css'{$SeleniumClass = [OpenQA.Selenium.By]::CssSelector($Value)}
    }
	
    if ($script:driver -ne $null) { 
		Write-Host "Clicking-Item $Selector`:$Value"
		$script:driver.FindElement($SeleniumClass).SendKeys($Keys)
	}
    else {
        Throw "$Selector`:$Value does not exist: $SeleniumClass"
    }


}
