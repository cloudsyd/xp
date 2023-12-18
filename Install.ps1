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

Restart-Computer -Force

}
$block > C:\tmp\setup.ps1

$Tr= New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(180)
$Us= "$Username"
$p= $Password
$Ac= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "C:\tmp\setup.ps1"
Register-ScheduledTask -TaskName "t" -Trigger $Tr -User $Us -Password $p -Action $Ac -RunLevel Highest

Start-Sleep -Seconds 2400
exit 0


    Start-Sleep -Seconds 5
}
until ($false)


