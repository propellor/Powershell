## Purpose:  Script server configuration and database objects.
## Required:  You will need the scriptsqlconfig.exe to be in the same directory as this script. https://github.com/billgraziano/ScriptSqlConfig or https://scriptsqlconfig.codeplex.com/documentation 
## Required:  SQLPS modules
## Sam Greene:  samuelgreene@gmail.com
## 11/13/2014

## Important !!!!!!!!!!!!!!!!
##
## Be sure to include any CMS groups (folders) you want to pull in the $groups array.  If you don't have any groups, you probably need to modify this script.
##
## !!!!!!!!!!!!!!!!

function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

function Get-ScriptName
{
  $ScriptName = [Environment]::GetCommandLineArgs()[0]
}

$scriptDir = Get-ScriptDirectory
$scriptname = Get-ScriptName

try{
Import-Module sqlps -DisableNameChecking #load the SQLPS functionality for getting the registered servers
}

catch{ "PS Import Error, no problem: $_";}

try{
Import-Module SSIS -DisableNameChecking 
}

catch{ "SSIS Import Error, Holdup: $_";
Exit;
}


try{
Set-Location -path SQLSERVER:\

cd 'sqlregistration\central management server group\<server>%5C<instance>'
Get-Location
}
catch{ "Unable to set path to management server: $_";
& $scriptDir\ErrorEmail.ps1  -DestinationDatabase $DestinationDatabase -scriptdirectory $scriptdirectory
Exit;
}

#You'll probably want to change these
#Groups are folders in SQL CMS
$groups = @('Development','Production','DR')
$CMSSserver = '<SQL Server CMS>'
$ScriptUserDir = 1

#These will remain the same 
$CMD = 'ScriptSqlConfig.exe'
$serverFlag = '/server'
$dirFlag = '/dir'
$dirbase = $scriptDir

$CMD = join-path $dirbase $CMD
$diroutput = Join-Path $dirbase "sqlconfigs"

if ($ScriptUserDir -eq 1) { $ScriptUserDirFlag = '/databases'} else {$ScriptUserDirFlag = ''}

#Get the CMS server first, it is not listed in the cms server - this is a bit of a pain!
    
    $servername = $CMSSserver -replace "\\","_"
	Write-Output $CMD $serverFlag $servername $dirFlag `"$diroutput\$servername`" $ScriptUserDirFlag
	& $CMD $serverFlag $CMSSserver $dirFlag `"$diroutput\$servername`" $ScriptUserDirFlag

$groups | ForEach-Object { 
    $sqlpspath = 'SQLSERVER:\sqlregistration\Central Management Server Group\<server>%5C<instance>\'+$_
	get-childitem $sqlpspath -Recurse |
	
	# Sample command:  scriptsqlconfig.exe /Server SQL01 /Dir 'c:\temp\sqlconfigs\SQL01'
	Foreach-object { 
	$servername = $_.ServerName -replace "\\","_"

	Write-Output CMD $serverFlag $_.ServerName $dirFlag `"$diroutput\$servername`" $ScriptUserDirFlag

	 & $CMD $serverFlag $_.ServerName $dirFlag `"$diroutput\$servername`" $ScriptUserDirFlag
	
	}
}



###
###
#	
###
###