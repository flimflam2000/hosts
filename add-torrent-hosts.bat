:: TL;DR version:
:: Right click this file and "Run as administrator", restart your web browser
:: and you should have access to all your favourite torrent websites again.
::
:: The long version:
:: This script modifies your hosts file to include the domain name/IP address
:: mapping for the torrent websites that are being blocked by da gubment. This
:: won't work if your ISP is really serious about cracking down on pirates and
:: has implemented more than a DNS-level block but we know that's all that
:: Telstra and TPG are doing so it'll probably work. If you want to know more
:: about how this works, google "hosts file" and "DNS". You will probably have
:: to restart your web browser after running this script for it to take effect.
::
:: IP addresses are pulled from ipaddress.com in a hacky fashion. The script
:: can safely be run multiple times to keep addresses up-to-date - it cleans
:: out previous modifications to the hosts file on every run. Can also be run
:: with an argument "undo" to only clean out previous modifications and not add
:: any new entries.
::
:: Because the hosts file is a protected system file and we want to modify it,
:: this script must be run as administrator. This means right-click on the
:: (this) .bat file and click "Run as administrator". And then when Windows asks
:: you if you want to allow the "Windows Command Processor" to make changes to
:: your computer, click yes. P.s. generally don't do this for anything you
:: download off the innernets unless you trust the person you got it from.
::
:: We have this PowerShell-batch-file abomination to get around the default
:: PowerShell execution policy which prohibits running scripts. We echo the
:: PowerShell code into a temporary file and run it with
:: -ExecutionPolicy Bypass. If you're going to modify the PowerShell code,
:: remember to escape special batch file characters: ()<>| and possibly others
:: (but it seems like special characters don't have to be escaped in string
:: literals).

@echo off
set PSFILE=%USERPROFILE%\__temp.ps1

(
echo $ErrorActionPreference = "Stop"
echo.
echo $undo = $FALSE
echo if ^($args.Length -eq 0^) {
echo     # Normal mode, do nothing
echo } elseif ^($args[0] -eq "undo"^) {
echo     $undo = $TRUE
echo } else {
echo     write-error "Usage: add-torrent-hosts.bat [undo]"
echo     exit 1
echo }
echo.
echo if ^(-not ^(^([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent^(^)^).IsInRole^([Security.Principal.WindowsBuiltInRole]"Administrator"^)^)^) {
echo     $host.ui.WriteErrorLine^("This script requires administrator privileges"^)
echo     $host.ui.WriteErrorLine^("Right click on the file and select 'Run as administrator'"^)
echo     exit 1
echo }
echo.
echo try {
echo     $hostsFile = "C:\Windows\System32\drivers\etc\hosts"
echo     $backupFile = "$hostsFile-backup"
echo     $tempFile = "$hostsFile-temp"
echo     $htmlFile = $env:USERPROFILE + "\__temp.html"
echo.
echo     $hostNames = @^(
echo         "thepiratebay.org",
echo         "torrentz.eu",
echo         "torrenthound.com",
echo         "isohunt.to",
echo         "solarmovie.to"
echo     ^)
echo.
echo     # Pick a name for the backup file that doesn't already exist.
echo     $backupSuffix = 1
echo     while ^(test-path ^($backupFile + $backupSuffix^)^) {
echo         $backupSuffix++
echo     }
echo     $backupFile += $backupSuffix
echo.
echo     # Get the contents of the hosts file, skipping over lines that were added
echo     # by previous runs of this script.
echo     $lines = get-content $hostsFile
echo     $outLines = @^(^)
echo     $inTorrentHosts = $FALSE
echo     foreach ^($line in $lines^) {
echo         if ^($line.StartsWith("# BEGIN TORRENT HOSTS"^)^) {
echo             $inTorrentHosts = $TRUE
echo         } elseif ^($line.StartsWith("# END TORRENT HOSTS"^)^) {
echo             $inTorrentHosts = $FALSE
echo         } elseif ^($inTorrentHosts^) {
echo             # Skip
echo         } else {
echo             $outLines += $line
echo         }
echo     }
echo.
echo     if ^(-not $undo^) {
echo         $client = new-object System.Net.WebClient
echo         $outLines += "# BEGIN TORRENT HOSTS ##########################################################"
echo         foreach ^($hostName in $hostNames^) {
echo             if ^(test-path $htmlFile^) {
echo                 remove-item $htmlFile
echo             }
echo             $client.DownloadFile^("http://$hostName.ipaddress.com/", $htmlFile^)
echo             $htmlLines = get-content $htmlFile
echo             $address = ""
echo             # Regex the IP address out of the html. If ipaddress.com ever
echo             # changes these pages this regex will have to be updated.
echo             # Also, special characters in strings apparently don't need to
echo             # be escaped.
echo             foreach ^($htmlLine in $htmlLines^) {
echo                 if ^($htmlLine -match "^<tr><th>IP Address:</th><td>([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)</td></tr>$"^) {
echo                     $address = $Matches[1]
echo                     break
echo                 }
echo             }
echo             if ^($address -eq ""^) {
echo                 $host.ui.WriteErrorLine^("Failed to find IP address for $hostName"^)
echo             } else {
echo                 write-output "$hostName : $address"
echo                 $outLines += "$address $hostName"
echo             }
echo         }
echo         $outLines += "# END TORRENT HOSTS ############################################################"
echo     }
echo.
echo     # Backup the old hosts file and write out a new one.
echo     copy-item $hostsFile $backupFile
echo     # Can't use out-file because it writes a UTF BOM which we don't want
echo     [IO.File]::WriteAllLines^($tempFile, $outLines^)
echo     move-item -force $tempFile $hostsFile
echo.
echo     write-host "Completed successfully!" -foregroundcolor "green"
echo } catch {
echo     $host.ui.WriteErrorLine^($_.Exception.Message^)
echo }
echo read-host "Press enter to exit" ^| out-null
)> %PSFILE%

powershell -ExecutionPolicy Bypass -File %PSFILE% %*
del %PSFILE%
