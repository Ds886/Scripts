#region Constants

# Constants
$C_DOMAINNAME="proj.com"
$C_WINSNAME = "PROJ"

#endregion Constants

#region Formatting

# Format DC path based on $C_DOMAINNAME
function fncFormatDC
{
    [string]$DC = "DC=$C_DOMAINNAME".Replace(".",",DC=")
    return $DC
}

# Format OU path based on a given OU path as "Sub...SubSubOU.SubOU.OU" for example Users.Test
function fncFormatOU
{
    param([string]$strOU)
      [string]$OU= [string]$( "OU=$strOU").Replace(".",",OU=")
    return $OU
}

# Format the path fully
function fncFormatFinalString
{
     param([string]$strOU)
   
    return [string]$("$(fncFormatOU $strOU),$(fncFormatDC)")
}

#endregion Formatting


#region Assistent function for creation of Users based on CSV

# Check if OU path exists based on a given the syntax of the OU path as "Sub...SubSubOU.SubOU.OU" for example Users.Test
function fncCheckIfOUExist
{
    Param
    ( [string]$strOU)
        
    return [adsi]::Exists("LDAP://$(fncFormatFinalString $strOU)")

}

# Create OU recusivly in the main path of the domain given the syntax of the OU path as "Sub...SubSubOU.SubOU.OU" for example Users.Test
Function fncRecurseCreateOU
{
    param([string]$strOU)
    $arrOU = $strOU.Split('.')
    $strPath="$(fncFormatDC)"
    for ($nCurrOU=$($arrOU.Length-1); $nCurrOU -gt -1; $nCurrOU--)
    {
        try
        {
            $strPath =  "OU=$($arrOU[$nCurrOU])" + ',' + $strPath
            if($(fncCheckIfOUExist $arrOU[$nCurrOU]) -eq $false)
            {
                mkdir "AD:\$strPath"
            }
        }

        catch{}
    }
}

# Function To add a single user
Function fncAddUser
{
    param([string]$strUserName,  
          [string]$strFirstName,
          [string]$strLastName, 
          [string]$strPassword,  
          [string]$strOU)
  
    if($(fncCheckIfOUExist $strOU) -eq $false)
    {
       fncRecurseCreateOU $strOU
    }

    New-ADUser  -SamAccountName $strUserName `
                -UserPrincipalName "$strUserName@$C_DOMAINNAME" `
                -Name "$strFirstName $strLastName" `
                -GivenName "$strFirstName" `
                -Surname "$strLastName" `
                -Enabled $true `
                -DisplayName "$strFirstName $strLastName" `
                -Path $(fncFormatFinalString $strOU) `
                -AccountPassword $(ConvertTo-SecureString $strPassword -AsPlainText -Force)
}

#endregion Assistent function for creation based on CSV

# Import from CSV 
#===========================================================================
# Example Of the CSV Format:
#===========================================================================
# fname,lname,uname,pass,ou
# [First Name],[Last Name],[User Name],[Password],[Sub...SubSubOU.SubOU.OU]
Function fncImportUsersFromCSV
{
    param([string]$strPath)
    $csv = Import-Csv $strPath
    foreach ($usrCurrUser in $csv)
    {
        try
        {
            fncAddUser $usrCurrUser.uname $usrCurrUser.fname  $usrCurrUser.lname $usrCurrUser.pass $usrCurrUser.ou
            echo("User $($usrCurrUser.uname) has been created at $(fncFormatDC $usrCurrUser.ou)")
        }
        catch
        {
            echo("User $($usrCurrUser.uname) at $(fncFormatDC $usrCurrUser.ou) has failed due to $($_.Exception.Message)")
        } 
    }
}