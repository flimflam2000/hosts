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
:: If the IP address for any of these hosts ever changes, this fix will stop
:: working and you'll probably get some confusing error message when you try to
:: visit the site whose address changed. You can fix it by updating the IP
:: addresses in this script and then re-running it. You can always get the
:: current IP address for a host by going to <hostname>.ipaddress.com, where
:: <hostname> is the name of the host you want. E.g. to find the IP address of
:: thepiratebay.org, go to thepiratebay.org.ipaddress.com.
::
:: Because the hosts file is a protected system file and we want to modify it,
:: this script must be run as administrator. This means right-click on the
:: (this) .bat file and click "Run as administrator". And then when Windows asks
:: you if you want to allow the "Windows Command Processor" to make changes to
:: your computer, click yes. P.s. generally don't do this for anything you
:: download off the innernets unless you trust the person you got it from.
::
:: If the script is run with "undo", it removes the torrent hosts and doesn't
:: add any new ones.
::
:: We have this PowerShell-batch-file abomination to get around the default
:: PowerShell execution policy which prohibits running scripts. We echo the
:: PowerShell code into a temporary file and run it with
:: -ExecutionPolicy Bypass. If you're going to modify the PowerShell code
:: remember to escape special batch file characters: ()<>| and possibly others.

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
echo try {
echo     $hostsFile = "C:\Windows\System32\drivers\etc\hosts"
echo     $backupFile = "$hostsFile-backup"
echo     $tempFile = "$hostsFile-temp"
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
echo         # This is the guts of the script - if you want to add more hosts or
echo         # update an IP address, this is where you do it.
echo         $outLines += "# BEGIN TORRENT HOSTS ##########################################################"
echo         $outLines += "104.31.19.30    thepiratebay.org"
echo         $outLines += "85.195.102.27   torrentz.eu"
echo         $outLines += "104.31.18.30    torrenthound.com"
echo         $outLines += "104.23.200.30   isohunt.to"
echo         $outLines += "72.52.4.119     solarmovie.to"
echo         $outLines += "# END TORRENT HOSTS ############################################################"
echo     }
echo.
echo     # Backup the old hosts file and write out a new one.
echo     copy-item $hostsFile $backupFile
echo     # Can't use out-file because it writes a UTF BOM which we don't want
echo     [IO.File]::WriteAllLines^($tempFile, $outLines^)
echo     move-item -force $tempFile $hostsFile
echo.
echo     #get-content $hostsFile
echo     #write-host ""
echo     write-host "Completed successfully!" -foregroundcolor "green"
echo } catch {
echo     $host.ui.WriteErrorLine^($_.Exception.Message^)
echo }
echo read-host "Press enter to exit" ^| out-null
)> %PSFILE%

powershell -ExecutionPolicy Bypass -File %PSFILE% %*
del %PSFILE%
