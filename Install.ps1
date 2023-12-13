param (
[string]
$Username,

[string]
$Password
)

$block = {
$tmp = "C:\tmp\";

$installer = Get-ChildItem $tmp `
-Recurse `
-Include "Milestone XProtect VMS Products *.exe";
$license = Get-ChildItem $tmp `
-Recurse `
-Include "*.lic";

# Generate arguments file for the installer in order to use custom user parameters
$argumentProcess = Start-Process $installer.FullName `
-ArgumentList "--generateargsfile=$tmp" `
-PassThru `
-Verb runAs
Wait-Process $argumentProcess.Id

# Read the newly created arguments file
$argumentsXml = [System.Xml.XmlDocument](Get-Content "$($tmp)Arguments.xml")

# Define the arguments and their values as a hashtable
$newArguments = @{
"SQL-KEEP-DATA" = "no"
}

foreach ($newArgument in $newArguments.Keys) {
$elementArgument = $argumentsXml.ArgumentsXmlV2.Arguments.Argument | Where-Object { $_.Name -eq $newArgument }

if ($elementArgument) {
# Update the value of the existing argument
$elementArgument.Value = $newArguments[$newArgument]
} 
else
{
# Create a new argument object
$newElement = $argumentsXml.CreateElement("Argument", $argumentsXml.DocumentElement.NamespaceURI)

# Create Name, Description, and Value elements and set their inner text
$nameElement = $argumentsXml.CreateElement("Name", $argumentsXml.DocumentElement.NamespaceURI)
$nameElement.InnerText = $newArgument

$descriptionElement = $argumentsXml.CreateElement("Description", $argumentsXml.DocumentElement.NamespaceURI)
$descriptionElement.InnerText = ""

$valueElement = $argumentsXml.CreateElement("Value", $argumentsXml.DocumentElement.NamespaceURI)
$valueElement.InnerText = $newArguments[$newArgument]

# Append Name, Description, and Value elements as children to the new Argument element
$newElement.AppendChild($nameElement)
$newElement.AppendChild($descriptionElement)
$newElement.AppendChild($valueElement)

# Add the new argument to the Arguments collection
$argumentsXml.ArgumentsXmlV2.Arguments.AppendChild($newElement)
}
}

# Save arguments file with modified user data
$argumentsXml.Save("$($tmp)Arguments.xml");

$installProcess = Start-Process $installer.FullName `
  -ArgumentList "--quiet --license=$($license.FullName) --arguments=$($tmp)Arguments.xml" `
  -PassThru;
Wait-Process $installProcess.Id

# Check return code from the VMS installation
# If error code is 0 everything went fine.
# If error code is 3010 it means that system needs to be restarted.
$installerLog = "$env:ProgramData\Milestone\Installer\installer.log"
$errorContent = (Get-Content $installerLog)[-1].Split(' ')[-1]
$result = If ($errorContent -eq 0 -or $errorContent -eq 3010) { "true" } Else { "false" }

if ($result -eq "false")
{
throw "Error occured during the installation of Milestone XProtect - please check the logs for more information"
}

Restart-Computer -Force

}
$block > C:\tmp\setup.ps1

# Convert the password to a secure string
$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force

# Create a credential object
$c = New-Object System.Management.Automation.PSCredential($Username, $securePassword)

# Start the PowerShell process with the specified script and credentials
$sP = Start-Process PowerShell -ArgumentList "-File C:\tmp\setup.ps1" `
-Credential $c `
-PassThru `
-Wait;

# Check the exit code
if ($sP.ExitCode -ne 0) {
    # If the exit code is not 0, stop the process
    Stop-Process -Id $sP.Id
} else {
    Write-Host "Installation completed successfully."
}
