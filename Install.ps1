$tmp = "C:\tmp\"

# Pattern match the installer name since it changes with every version.
$in = Get-ChildItem $tmp -Recurse -Include "Milestone XProtect VMS Products *.exe"

# Pattern match the license file name since it could be change with every version.
$license = Get-ChildItem $tmp -Recurse -Include "*.lic"

# Generate arguments file for the installer in order to use custom user parameters
$aP = Start-Process $in.FullName -ArgumentList "--generateargsfile=$tmp" -PassThru
Wait-Process $aP.Id

# Read the newly created arguments file
$argumentsXml = [System.Xml.XmlDocument](Get-Content "$($tmp)Arguments.xml")

# Define the arguments and their values as a hashtable
$newArguments = @{
    "SQL-KEEP-DATA" = "no"
}

foreach ($keys in $newArguments.Keys) {
$ar = $argumentsXml.ArgumentsXmlV2.Arguments.Argument | Where-Object { $_.Name -eq $keys }

if ($ar) {
    # Update the value of the existing argument
    $ar.Value = $newArguments[$keys]
}
else {
# Create a new argument object
$ar = $argumentsXml.CreateElement("Argument", $argumentsXml.DocumentElement.NamespaceURI)

# Create Name, Description, and Value elements and set their inner text
$name = $argumentsXml.CreateElement("Name", $argumentsXml.DocumentElement.NamespaceURI)
$name.InnerText = $keys

$description = $argumentsXml.CreateElement("Description", $argumentsXml.DocumentElement.NamespaceURI)
$description.InnerText = "" # You can add a description for each argument in the hashtable if needed

$value = $argumentsXml.CreateElement("Value", $argumentsXml.DocumentElement.NamespaceURI)
$value.InnerText = $newArguments[$keys]

# Append Name, Description, and Value elements as children to the new Argument element
$ar.AppendChild($name)
$ar.AppendChild($description)
$ar.AppendChild($value)

# Add the new argument to the Arguments collection
$argumentsXml.ArgumentsXmlV2.Arguments.AppendChild($ar)
  }
}

# Save arguments file with modified user data
$argumentsXml.Save("$($tmp)Arguments.xml");
