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

#Create a config file to get ScreenShotRepo
$Date = Get-Date -Format yyyy-dd-MMThh_mm_ss
$ScreenshotRepo = Join-Path $env:USERPROFILE\Pictures -ChildPath $Date
if((Test-Path $ScreenshotRepo) -ne $true){
    New-Item -Path $ScreenshotRepo -Name $Date -ItemType Directory
}

function Get-ScreenShot($Driver,$Name){
    $Screenshot = $Driver.GetScreenshot()
    $ssDate = Get-Date -Format yyyy-dd-MM-Thh_mm_ss
    $ssName = "$Name`_$ssDate.png"
    $ImageFormat = [System.Drawing.Imaging.ImageFormat]::Png
    $Screenshot.SaveAsFile("$ScreenshotRepo\$ssName",$ImageFormat)
    Write-Host -BackgroundColor Yellow -ForegroundColor Black "Screenshot captured $ScreenshotRepo"
}
function Write-Exception([scriptblock] $testScriptToExecute){
	try 
	{
		& $testScriptToExecute
	}
	catch 
	{
		if ($script:testsAsWarnings) 
		{
			$theErrorMessage = $error[0]
			Write-Warning $theErrorMessage
		}
		else 
		{
			throw
		}
	} 
	finally 
	{
		Dispose-AcceptanceTests
	}
}
function Invoke-Command($storyName, [ScriptBlock]$testScript){
	$result = New-Object AcceptanceTestResult
	$result.StoryTitle = $storyName
	$result.Passed = $false
	try 
	{
		if ($script:driver -ne $null) {
			& $testScript			
		}
		$result.Passed = $true
	}
	catch{
		$result.ErrorMessage = $_
        Get-ScreenShot -Driver $script:driver -Name $storyName
	}
	finally{
		$script:acceptanceTestResults.Results.Add($result)
	}
}
function Dispose-AcceptanceTests() {
	if ($script:driver -ne $null) { 
		$script:driver.Quit()
	}
}
function Create-URL($path){	
	return $baseUrl + $path
}
function Test-Case($name, [ScriptBlock] $fixture){
	Write-Host "`n-------------------------------------------------------------"
	Write-Host $name
	Write-Host "-------------------------------------------------------------`n"
	Invoke-Command $name $fixture
}
function Navigate-ToPage([string]$WebPage){
	if ($script:driver -ne $null) { 
		$url = Create-URL $WebPage
		Write-Host "Navigating to $url"
		$script:driver.Navigate().GoToUrl($url) 
	}
}
function Insert-Text(){
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
		Write-Host "Typing '$string' into $Selector`:$Value"
		$script:driver.FindElement($SeleniumClass).SendKeys($string)
	}
}
function Click-Item(){
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
}
function Validate-ElementExists(){
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
function Hover-OverElement(){
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
function Wait-UnitlElementVisible(){
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
        $SleepTime = 500
        do
        {
            Start-Sleep -Milliseconds $SleepTime
            $SleepTime += 250
        }
        until ($script:driver.FindElement($SeleniumClass) -ne $null -or $SleepTime -eq 10000)
		if ($SleepTime -eq 10000) {
			Throw "$Value doesn't exist" 
		}
	}
}
function Validate-PageHasTitle() {
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
function Validate-IsSecureRequest(){
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
    $webDriverDir = "D:\Selenium\net40"
    
    Set-Location $webDriverDir
    Get-ChildItem -Path $webDriverDir -Filter "*.dll" | foreach { Add-Type -Path "$webDriverDir\$_" }
	#ls -Name "$webDriverDir\*.dll"	|	foreach { Add-Type -Path "$webDriverDir\$_"  }
	
	$script:testsAsWarnings = $testsAsWarnings;

	$capabilities = New-Object OpenQA.Selenium.Remote.DesiredCapabilities
	$capabilityValue = @("--ignore-certificate-errors")
	$capabilities.SetCapability("chrome.switches", $capabilityValue)
	$options = New-Object OpenQA.Selenium.Chrome.ChromeOptions
	$script:driver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($options)
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
function Invoke-TestCase([bool]$testsAsWarnings, $baseUrl, [string]$TestCases){
	$scriptBlock = [scriptblock]::Create($TestCases)
	$acceptanceTestResults = Invoke-Test -baseUrl $baseUrl -scriptBlockToExecute $scriptBlock -testsAsWarnings $testsAsWarnings	

	return $acceptanceTestResults		
}
function Create-SummaryReport($TestResults){
	$TestResults.Results | Select-Object -Property Passed, Storytitle, ErrorMessage| Out-GridView 
}
