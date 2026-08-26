<# :
@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "SCRIPT_PATH=%~f0"
set "TI_LAUNCH_LOG=%TEMP%\TI_Launcher_%RANDOM%%RANDOM%.log"
set "TI_MAIN_LOG=%TEMP%\TI_Main.log"
set "PSH=powershell.exe"

if /i "%~1"=="/show" goto :TI_VISIBLE_MODE
if /i "%~1"=="/visible" goto :TI_VISIBLE_MODE

goto :TI_HIDDEN_CHECK

:TI_VISIBLE_MODE
shift
goto :TI_BUILD_ARGS_FINAL

:TI_HIDDEN_CHECK
if defined TI_HIDDEN_RELAUNCHED goto :TI_BUILD_ARGS_FINAL
if /i "%~1"=="/silent" shift
if /i "%~1"=="/hidden" shift

:TI_SILENT_RELAUNCH
set "TI_HIDDEN_RELAUNCHED=1"
set "TI_FORCE_HIDDEN=1"
set "TI_REMARGS="

:TI_ARGLOOP_RELAUNCH
if "%~1"=="" goto :TI_ARGLOOP_RELAUNCH_DONE
set TI_REMARGS=%TI_REMARGS% "%~1"
shift
goto :TI_ARGLOOP_RELAUNCH

:TI_ARGLOOP_RELAUNCH_DONE
set "TI_HIDE_BOOT=%TEMP%\TI_HideBoot_%RANDOM%%RANDOM%.ps1"
>"%TI_HIDE_BOOT%" echo param([string]$SelfPath,[Parameter(ValueFromRemainingArguments=$true)][string[]]$ForwardArgs)
>>"%TI_HIDE_BOOT%" echo $q = [char]34
>>"%TI_HIDE_BOOT%" echo $fmt = foreach ($a in $ForwardArgs) {
>>"%TI_HIDE_BOOT%" echo     $s = [string]$a
>>"%TI_HIDE_BOOT%" echo     $sb = New-Object System.Text.StringBuilder
>>"%TI_HIDE_BOOT%" echo     [void]$sb.Append($q)
>>"%TI_HIDE_BOOT%" echo     $n = 0
>>"%TI_HIDE_BOOT%" echo     foreach ($ch in $s.ToCharArray()) {
>>"%TI_HIDE_BOOT%" echo         if ($ch -eq '\') { $n = $n + 1 }
>>"%TI_HIDE_BOOT%" echo         elseif ($ch -eq $q) { [void]$sb.Append('\' * ($n*2 + 1)); [void]$sb.Append($q); $n = 0 }
>>"%TI_HIDE_BOOT%" echo         else { if ($n -gt 0) { [void]$sb.Append('\' * $n); $n = 0 }; [void]$sb.Append($ch) }
>>"%TI_HIDE_BOOT%" echo     }
>>"%TI_HIDE_BOOT%" echo     if ($n -gt 0) { [void]$sb.Append('\' * ($n*2)) }
>>"%TI_HIDE_BOOT%" echo     [void]$sb.Append($q)
>>"%TI_HIDE_BOOT%" echo     $sb.ToString()
>>"%TI_HIDE_BOOT%" echo }
>>"%TI_HIDE_BOOT%" echo $argStr = ($fmt -join ' ')
>>"%TI_HIDE_BOOT%" echo if ($argStr) { Start-Process -WindowStyle Hidden -FilePath $SelfPath -ArgumentList $argStr -WorkingDirectory $PWD.Path } else { Start-Process -WindowStyle Hidden -FilePath $SelfPath -WorkingDirectory $PWD.Path }

"%PSH%" -WindowStyle Hidden -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TI_HIDE_BOOT%" "%SCRIPT_PATH%" %TI_REMARGS% >nul 2>&1
del /f /q "%TI_HIDE_BOOT%" >nul 2>&1
exit /b

:TI_BUILD_ARGS_FINAL
set "TI_REMARGS="

:TI_ARGLOOP_FINAL
if "%~1"=="" goto :TI_ARGLOOP_FINAL_DONE
set TI_REMARGS=%TI_REMARGS% "%~1"
shift
goto :TI_ARGLOOP_FINAL
:TI_ARGLOOP_FINAL_DONE

:TI_SILENT_DONE
>>"%TI_LAUNCH_LOG%" echo [%date% %time%] Starting: "%SCRIPT_PATH%"

set "TI_BOOT=%TEMP%\TI_Boot_%RANDOM%%RANDOM%.ps1"

>"%TI_BOOT%" echo param([string]$SelfPath,[Parameter(ValueFromRemainingArguments=$true)][string[]]$ForwardArgs)
>>"%TI_BOOT%" echo $ErrorActionPreference = 'Stop'
>>"%TI_BOOT%" echo $env:SCRIPT_PATH = $SelfPath
>>"%TI_BOOT%" echo $q = [char]34
>>"%TI_BOOT%" echo $qq = ([string]$q)+([string]$q)
>>"%TI_BOOT%" echo $fmt = foreach ($a in $ForwardArgs) {
>>"%TI_BOOT%" echo     $s = [string]$a
>>"%TI_BOOT%" echo     if ($s.IndexOf($q) -ge 0) { $s = $s -replace ([string]$q), $qq }
>>"%TI_BOOT%" echo     if ($s -match '\s') { $s = ([string]$q) + $s + ([string]$q) }
>>"%TI_BOOT%" echo     $s
>>"%TI_BOOT%" echo }
>>"%TI_BOOT%" echo $script:param = ($fmt -join ' ')
>>"%TI_BOOT%" echo $env:TI_FORCE_HIDDEN = $env:TI_FORCE_HIDDEN
>>"%TI_BOOT%" echo iex ([System.IO.File]::ReadAllText($env:SCRIPT_PATH, [System.Text.Encoding]::UTF8))

"%PSH%" -WindowStyle Hidden -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TI_BOOT%" "%SCRIPT_PATH%" %TI_REMARGS% >>"%TI_LAUNCH_LOG%" 2>&1
set "RC=%ERRORLEVEL%"

del /f /q "%TI_BOOT%" >nul 2>&1

if not "%RC%"=="0" goto :TI_PSH_ERROR
exit /b

:TI_PSH_ERROR
"%PSH%" -WindowStyle Hidden -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "try { Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue; [System.Windows.Forms.MessageBox]::Show('TrustedInstaller başlatılamadı. Log: %TI_MAIN_LOG% ve %TI_LAUNCH_LOG%','TI Launcher Error',0,16) ^| Out-Null } catch {}" >nul 2>&1
exit /b
#>

$ErrorActionPreference = 'Stop'
$global:TI_MainLog = "$env:TEMP\TI_Main.log"
if (-not $script:param) { $script:param = '' }
if (($script:param -eq '') -and $args -and $args.Count -gt 0) {
$q=[char]34; $qq=([string]$q)+([string]$q)
$fmt=($args | ForEach-Object { $s=[string]$_; if($s.IndexOf($q) -ge 0){ $s=$s -replace ([string]$q), $qq }; if($s -match '\s'){ $s=([string]$q)+$s+([string]$q) }; $s })
$script:param = ($fmt -join ' ')
}

#region TI_CORE_A
$global:TI_ProgressScript = @"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Dpi {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
'@
[Dpi]::SetProcessDPIAware() | Out-Null

Add-Type @'
using System;
using System.Runtime.InteropServices;
public class IconLoader {
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern int ExtractIconEx(
        string file,
        int index,
        IntPtr[] large,
        IntPtr[] small,
        int icons
    );
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
}
'@

`$form = New-Object System.Windows.Forms.Form
`$form.Size = New-Object System.Drawing.Size(420,150)
`$form.StartPosition = 'CenterScreen'
`$form.FormBorderStyle = 'None'
`$form.TopMost = `$true
`$form.ShowInTaskbar = `$false
`$form.BackColor = [System.Drawing.Color]::FromArgb(32,32,32)
`$form.Opacity = 0

# DWMWA_WINDOW_CORNER_PREFERENCE (Win11+) gives anti-aliased corners;
# GraphicsPath region clipping (fallback) is hard-edged and looks jagged.
`$dwmRounded = `$false
try {
`$pref = 2 # DWMWCP_ROUND
if ([IconLoader]::DwmSetWindowAttribute(`$form.Handle, 33, [ref]`$pref, 4) -eq 0) { `$dwmRounded = `$true }
} catch {}
if (-not `$dwmRounded) {
`$radius = 14
`$path = New-Object System.Drawing.Drawing2D.GraphicsPath
`$path.AddArc(0,0,`$radius,`$radius,180,90)
`$path.AddArc(`$form.Width-`$radius,0,`$radius,`$radius,270,90)
`$path.AddArc(`$form.Width-`$radius,`$form.Height-`$radius,`$radius,`$radius,0,90)
`$path.AddArc(0,`$form.Height-`$radius,`$radius,`$radius,90,90)
`$path.CloseFigure()
`$form.Region = New-Object System.Drawing.Region(`$path)
}

`$layout = New-Object System.Windows.Forms.TableLayoutPanel
`$layout.Dock = 'Fill'
`$layout.RowCount = 2
`$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent',60)))
`$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent',40)))
`$form.Controls.Add(`$layout)

`$top = New-Object System.Windows.Forms.Panel
`$top.Dock = 'Fill'
`$layout.Controls.Add(`$top,0,0)

`$large = New-Object IntPtr[] 1
`$small = New-Object IntPtr[] 1
[IconLoader]::ExtractIconEx(
"`$env:SystemRoot\System32\imageres.dll",
-78,
`$large,
`$small,
1
) | Out-Null

`$iconBmp = [System.Drawing.Icon]::FromHandle(`$large[0]).ToBitmap()

`$iconBox = New-Object System.Windows.Forms.PictureBox
`$iconBox.Size = New-Object System.Drawing.Size(26,26)
`$iconBox.Location = New-Object System.Drawing.Point(24,18)
`$iconBox.SizeMode = 'Zoom'
`$iconBox.Image = `$iconBmp
`$top.Controls.Add(`$iconBox)

try { `$lang = (Get-UICulture).Name } catch { `$lang = [System.Globalization.CultureInfo]::CurrentUICulture.Name }
`$isTr = `$lang -like "tr-*"

`$labelMain = New-Object System.Windows.Forms.Label
`$labelMain.Text = `$env:TI_PROGRESS_MSG
`$labelMain.ForeColor = 'White'
`$labelMain.Font = New-Object System.Drawing.Font("Segoe UI",10)
`$labelMain.AutoSize = `$false
`$labelMain.Width = `$form.Width
`$labelMain.Height = 20
`$labelMain.TextAlign = 'MiddleCenter'
`$labelMain.Location = New-Object System.Drawing.Point(0,16)
`$top.Controls.Add(`$labelMain)
`$labelSub = New-Object System.Windows.Forms.Label
`$labelSub.Text = `$env:TI_PROGRESS_SUB
`$labelSub.ForeColor = [System.Drawing.Color]::FromArgb(220,220,220)
`$labelSub.Font = New-Object System.Drawing.Font("Segoe UI",9)
`$labelSub.AutoSize = `$false
`$labelSub.Width = `$form.Width
`$labelSub.Height = 40
`$labelSub.TextAlign = 'TopCenter'
`$labelSub.Location = New-Object System.Drawing.Point(0,42)
`$top.Controls.Add(`$labelSub)

`$progressPanel = New-Object System.Windows.Forms.Panel
`$progressPanel.Dock = 'Fill'
`$layout.Controls.Add(`$progressPanel,0,1)

`$segmentCount = 16
`$segmentWidth = 18
`$segmentHeight = 14
`$segmentGap = 6

`$totalWidth = (`$segmentCount * `$segmentWidth) + ((`$segmentCount - 1) * `$segmentGap)
`$startX = (`$form.Width - `$totalWidth) / 2
`$y = 12

`$segments = @()

for (`$i=0; `$i -lt `$segmentCount; `$i++) {
`$seg = New-Object System.Windows.Forms.Panel
`$seg.Width  = `$segmentWidth
`$seg.Height = `$segmentHeight
`$seg.Left   = `$startX + (`$i * (`$segmentWidth + `$segmentGap))
`$seg.Top    = `$y
`$seg.BackColor = [System.Drawing.Color]::FromArgb(70,70,70)
`$progressPanel.Controls.Add(`$seg)
`$segments += `$seg
}

`$credit = New-Object System.Windows.Forms.Label
`$credit.Text = "by Abdullah ERTÜRK"
`$credit.ForeColor = [System.Drawing.Color]::FromArgb(170,170,170)
`$credit.Font = New-Object System.Drawing.Font("Segoe UI",9)
`$credit.AutoSize = `$true
`$credit.Anchor = 'Top,Right'
`$progressPanel.Controls.Add(`$credit)

function Set-CreditPos {
    try {
        `$credit.Top  = `$y + `$segmentHeight + 6
        `$credit.Left = [Math]::Max(0, (`$startX + `$totalWidth) - `$credit.PreferredWidth)
    } catch {}
}
Set-CreditPos

`$progressPanel.Add_Resize({
`$totalWidth = (`$segmentCount * `$segmentWidth) + ((`$segmentCount - 1) * `$segmentGap)
`$startX = (`$progressPanel.Width - `$totalWidth) / 2
foreach (`$i in 0..(`$segments.Count-1)) {
`$segments[`$i].Left = `$startX + (`$i * (`$segmentWidth + `$segmentGap))
}
Set-CreditPos
})

`$script:index = 0
`$timer = New-Object System.Windows.Forms.Timer
`$timer.Interval = 120
`$timer.Add_Tick({
for (`$i=0; `$i -lt `$segments.Count; `$i++) {
if (`$i -le `$script:index) {
`$segments[`$i].BackColor = [System.Drawing.Color]::FromArgb(80,200,120)
} else {
`$segments[`$i].BackColor = [System.Drawing.Color]::FromArgb(70,70,70)
}
}
`$script:index++
if (`$script:index -ge `$segments.Count) { `$script:index = 0 }
})

`$fade = New-Object System.Windows.Forms.Timer
`$fade.Interval = 25
`$fade.Add_Tick({
if (`$form.Opacity -lt 0.95) {
`$form.Opacity += 0.08
} else {
`$fade.Stop()
}
})

`$form.Add_Shown({
`$fade.Start()
`$timer.Start()
})

# Fail-safe: self-close if the elevation chain never comes back to kill this window.
`$watchdog = New-Object System.Windows.Forms.Timer
`$watchdog.Interval = 90000
`$watchdog.Add_Tick({ try { `$watchdog.Stop() } catch {}; try { `$form.Close() } catch {} })
`$watchdog.Start()

`$fade.Start()
`$timer.Start()

[void]`$form.ShowDialog()
"@

function Log($m) {
try { "[{0:u}] {1}" -f (Get-Date), $m | Out-File $global:TI_MainLog -Append -Encoding utf8 } catch {}
}
Log "=== Script start ==="

# Process-wide DPI awareness so the dialogs (Show-TopMostChoiceDialog,
# Show-TIInfoBox, Show-TopMostOptionDialog) render crisp instead of being
# bitmap-stretched by Windows on high-DPI displays.
try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class TIDpi {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
"@ -ErrorAction SilentlyContinue
    [TIDpi]::SetProcessDPIAware() | Out-Null
} catch {}

trap {
Log "ERROR: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
try {
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
[System.Windows.Forms.MessageBox]::Show("Hata: $($_.Exception.Message)`nLog: $global:TI_MainLog", "TI Launcher Error", 0, 16) | Out-Null
} catch {}
exit 1
}

try {
$systemLang = (Get-UICulture).Name
} catch {
$systemLang = [System.Globalization.CultureInfo]::CurrentUICulture.Name
}
$isTurkish = $systemLang -like "tr-*"
Log "Lang: $systemLang (TR=$isTurkish)"

if ($isTurkish) {
$msg = @{
Title = "Trusted Installer"
PopupTitle = "Trusted Installer Launcher"
        PopupMsg = "Dosya veya klasörleri bu script üzerine sürükleyerek çalıştırın."
PopupYes = "$([char]0x25B6)  Çalıştır"
PopupNo = "$([char]0x2699)  Kur / Kaldır / Güncelle"
ChoiceTitle = "Seçim"
InstallSuccess = "Kurulum tamamlandı"
InstallError = "Kurulum hatası!`n`n"
UninstallTitle = "Kaldır"
UninstallMsg = "Sistem entegrasyonunu kaldırmak veya güncellemek istiyor musunuz?`n`nKaldır: Mevcut sistemi temizler.`nGüncelle: Mevcut sistemi temizleyip güncel script'i tekrar kurar."
UninstallSuccess = "Kaldırma tamamlandı!"
UninstallError = "Kaldırma hatası!`n`n"
SuccessTitle = "Başarılı"
ErrorTitle = "Hata"
MenuText = "Trusted Installer Yetkisiyle Aç"
PleaseWaitSub = "Lütfen bekleyiniz"

PleaseWait = "Trusted Installer etkinleştiriliyor"
}
} else {
$msg = @{
Title = "Trusted Installer"
PopupTitle = "Trusted Installer Launcher"
        PopupMsg = "Drag and drop files or folders onto this script to run it."
PopupYes = "$([char]0x25B6)  Run"
PopupNo = "$([char]0x2699)  Install / Uninstall / Update"
ChoiceTitle = "Choice"
InstallSuccess = "Installation complete!`n`n'Open with Trusted Installer' is now in context menu."
InstallError = "Installation error!`n`n"
UninstallTitle = "Uninstall"
UninstallMsg = "Do you want to uninstall or update the system integration?`n`nUninstall: Removes the current integration.`nUpdate: Removes the current integration and reinstalls the script."
UninstallSuccess = "Uninstallation complete!"
UninstallError = "Uninstallation error!`n`n"
SuccessTitle = "Success"
PleaseWaitSub = "Please wait"

ErrorTitle = "Error"
MenuText = "Open with Trusted Installer Privileges"
PleaseWait = "Activating Trusted Installer"
}
}

#endregion TI_CORE_A


#region TI_CORE_OTHER
function BuildPs1Command {
param(
[Parameter(Mandatory=$true)][string]$Action,
[Parameter(Mandatory=$true)][string]$FilePath,
[switch]$X86
)

$p = $FilePath
if ($p -match '^\s*"(.*)"\s*$') { $p = $matches[1] }
$pEsc = $p -replace '"','""'

$useX86 = $false
if ($X86) { $useX86 = $true }
if ($Action -and ($Action.ToLower() -like '*x86*')) { $useX86 = $true }

$psExe = if ($useX86) { "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" } else { "powershell.exe" }
$iseExe = if ($useX86) { "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell_ise.exe" } else { "powershell_ise.exe" }

$hidden = $false
try { if ($env:TI_FORCE_HIDDEN -and $env:TI_FORCE_HIDDEN -eq '1') { $hidden = $true } } catch {}
$ws = if ($hidden) { '-WindowStyle Hidden -NoLogo' } else { '' }

switch ($Action.ToLower()) {
'ps-run' { return "$psExe $ws -NoProfile -ExecutionPolicy Bypass -File `"$pEsc`"".Trim() }
'ps-admin' { return "$psExe $ws -NoProfile -ExecutionPolicy Bypass -File `"$pEsc`"".Trim() }
'ps-ti' { return "$psExe $ws -NoProfile -ExecutionPolicy Bypass -File `"$pEsc`"".Trim() }
'ise-open' { return "`"$iseExe`" `"$pEsc`"" }
'ise-admin' { return "`"$iseExe`" `"$pEsc`"" }
'ise-ti' { return "`"$iseExe`" `"$pEsc`"" }
'ise-open-x86' { return "`"$iseExe`" `"$pEsc`"" }
'ise-admin-x86' { return "`"$iseExe`" `"$pEsc`"" }
'ise-ti-x86' { return "`"$iseExe`" `"$pEsc`"" }
'notepad-open' { return "notepad.exe `"$pEsc`"" }
'notepad-admin' { return "notepad.exe `"$pEsc`"" }
'notepad-ti' { return "notepad.exe `"$pEsc`"" }
default { return "$psExe $ws -NoProfile -ExecutionPolicy Bypass -File `"$pEsc`"".Trim() }
}
}

#endregion TI_CORE_OTHER

#region TI_CORE_SHORTCUT
function Resolve-ShortcutTarget {
param(
[Parameter(Mandatory=$true)][string]$ShortcutPath
)

$result = @{
TargetPath = $null
Arguments = $null
WorkingDirectory = $null
ResolvedTargetPath = $null
ResolutionMethod = $null
}

$shell = New-Object -ComObject WScript.Shell
$sc = $shell.CreateShortcut($ShortcutPath)

$targetPath = $sc.TargetPath
$arguments = $sc.Arguments
$workingDir = $sc.WorkingDirectory

$result.TargetPath = $targetPath
$result.Arguments = $arguments
$result.WorkingDirectory = $workingDir

function _clean([string]$p) {
if (-not $p) { return $null }
$pp = $p.Trim()
if ($pp -match '^\s*"(.*)"\s*$') { $pp = $matches[1] }
try { $pp = ($pp -replace '[\p{C}]','').Trim() } catch {}
try { $pp = [Environment]::ExpandEnvironmentVariables($pp) } catch {}
return $pp
}

function _leafExists([string]$p) {
if (-not $p) { return $false }
try {
if (Test-Path -LiteralPath $p -PathType Leaf) { return $true }
} catch {}
try {
if ([System.IO.File]::Exists($p)) { return $true }
} catch {}
return $false
}

$tp = _clean $targetPath
$wd = _clean $workingDir

if ($tp -and (_leafExists $tp)) {
$result.ResolvedTargetPath = $tp
$result.ResolutionMethod = 'TargetPath'
return [pscustomobject]$result
}

if ($tp -and $wd -and (Test-Path $wd -PathType Container)) {
try {
$candidate = Join-Path $wd $tp
if (_leafExists $candidate) {
$result.ResolvedTargetPath = $candidate
$result.ResolutionMethod = 'WorkingDirectory+RelativeTarget'
return [pscustomobject]$result
}
} catch {}
}

if ($tp -and $wd -and (Test-Path $wd -PathType Container)) {
try {
$leaf = Split-Path $tp -Leaf
if ($leaf -and ($leaf.ToLower().EndsWith('.exe'))) {
$candidate = Join-Path $wd $leaf
if (_leafExists $candidate) {
$result.ResolvedTargetPath = $candidate
$result.ResolutionMethod = 'WorkingDirectory+LeafExe'
return [pscustomobject]$result
}
}
} catch {}
}

try {
$scDir = Split-Path -Parent $ShortcutPath
$leaf = $null
if ($tp) { $leaf = Split-Path $tp -Leaf }
if (-not $leaf -and $arguments) {
if ($arguments -match '(?i)([A-Za-z]:\\[^\"]+\.exe)') { $leaf = Split-Path $matches[1] -Leaf }
}
if ($scDir -and $leaf) {
$candidate = Join-Path $scDir $leaf
if (_leafExists $candidate) {
$result.ResolvedTargetPath = $candidate
$result.ResolutionMethod = 'ShortcutDirectory+LeafExe'
return [pscustomobject]$result
}
}
} catch {}

try {
$leaf = $null
if ($tp) { $leaf = Split-Path $tp -Leaf }
if ($leaf -and $leaf.ToLower().EndsWith('.exe')) {
if ($wd) {
$found = Find-FileByNameInDir -Directory $wd -FileName $leaf
if ($found) {
$result.ResolvedTargetPath = $found
$result.ResolutionMethod = 'SearchInWorkingDirectory'
return [pscustomobject]$result
}

$foundR = Find-FileByNameRecursive -Root $wd -FileName $leaf -MaxDepth 4 -MaxDirs 600
if ($foundR) {
$result.ResolvedTargetPath = $foundR
$result.ResolutionMethod = 'RecursiveSearchInWorkingDirectory'
return [pscustomobject]$result
}
}
$scDir = Split-Path -Parent $ShortcutPath
if ($scDir) {
$found2 = Find-FileByNameInDir -Directory $scDir -FileName $leaf
if ($found2) {
$result.ResolvedTargetPath = $found2
$result.ResolutionMethod = 'SearchInShortcutDirectory'
return [pscustomobject]$result
}
}

try {
$common = @(
$env:USERPROFILE,
(Join-Path $env:USERPROFILE 'Desktop'),
(Join-Path $env:USERPROFILE 'Downloads'),
(Join-Path $env:USERPROFILE 'Documents')
) | Where-Object { $_ -and (Test-Path $_ -PathType Container) }

foreach ($c in $common) {
$ff = Find-FileByNameInDir -Directory $c -FileName $leaf
if ($ff) {
$result.ResolvedTargetPath = $ff
$result.ResolutionMethod = "CommonFolders:$c"
return [pscustomobject]$result
}
}
} catch {}
}
} catch {}

function Find-FileByNameRecursive {
param(
[Parameter(Mandatory=$true)][string]$Root,
[Parameter(Mandatory=$true)][string]$FileName,
[int]$MaxDepth = 4,
[int]$MaxDirs = 500
)

try {
if (-not (Test-Path $Root -PathType Container)) { return $null }

$q = New-Object 'System.Collections.Generic.Queue[object]'
$q.Enqueue([pscustomobject]@{ Path = $Root; Depth = 0 })
$dirCount = 0

while ($q.Count -gt 0) {
$cur = $q.Dequeue()
$dir = $cur.Path
$depth = [int]$cur.Depth

try {
$m = Get-ChildItem -LiteralPath $dir -File -Filter $FileName -ErrorAction SilentlyContinue | Select-Object -First 1
if ($m) { return $m.FullName }
} catch {}

if ($depth -ge $MaxDepth) { continue }

try {
$subs = Get-ChildItem -LiteralPath $dir -Directory -ErrorAction SilentlyContinue
foreach ($sd in $subs) {
$dirCount++
if ($dirCount -ge $MaxDirs) { break }
$q.Enqueue([pscustomobject]@{ Path = $sd.FullName; Depth = $depth + 1 })
}
} catch {}

if ($dirCount -ge $MaxDirs) { break }
}
} catch {}

return $null
}

# --- Shell shortcut fallback (Control Panel, etc.) ---
try {
if ((-not $result.ResolvedTargetPath -or $result.ResolvedTargetPath.Trim() -eq '') -and (-not $tp -or $tp.Trim() -eq '')) {
$scName = $null
try { $scName = [System.IO.Path]::GetFileNameWithoutExtension($ShortcutPath) } catch {}
$explorerExe = $null
try { $explorerExe = Join-Path $env:WINDIR 'explorer.exe' } catch { $explorerExe = "$env:WINDIR\\explorer.exe" }

# If shortcut doesn't expose TargetPath but has shell-style Arguments, open via Explorer
if ($result.Arguments -and $result.Arguments.Trim() -ne '') {
$argTrim = $result.Arguments.Trim()
if ($argTrim -match '(?i)^(shell:|shell:::)') {
$result.ResolvedTargetPath = $explorerExe
$result.ResolutionMethod = 'ShellArguments'
} elseif ($argTrim -match '^::\{') {
$result.ResolvedTargetPath = $explorerExe
$result.Arguments = 'shell:::' + ($argTrim.TrimStart(':'))
$result.ResolutionMethod = 'ShellArguments'
}
}

# Common shell shortcuts where WScript.Shell returns empty TargetPath
$knownShell = @{
'Control Panel' = 'shell:ControlPanelFolder'
'Denetim Masası' = 'shell:ControlPanelFolder'
}

if ($scName -and $knownShell.ContainsKey($scName)) {
$result.ResolvedTargetPath = $explorerExe
if (-not $result.Arguments -or $result.Arguments.Trim() -eq '') { $result.Arguments = $knownShell[$scName] }
$result.ResolutionMethod = 'KnownShellShortcut'
}

# Last resort: query link metadata via Shell.Application ExtendedProperty
if (-not $result.ResolvedTargetPath -or $result.ResolvedTargetPath.Trim() -eq '') {
try {
$shellApp = New-Object -ComObject Shell.Application
$folder = $shellApp.Namespace((Split-Path -Parent $ShortcutPath))
$item = $null
if ($folder) { $item = $folder.ParseName((Split-Path -Leaf $ShortcutPath)) }
if ($item) {
$tpp = $item.ExtendedProperty('System.Link.TargetParsingPath')
if (-not $tpp -or $tpp.Trim() -eq '') {
# some Windows builds expose slightly different property names
try { $tpp = $item.ExtendedProperty('System.Link.TargetParsingPathRaw') } catch {}
}

if ($tpp -and $tpp.Trim() -ne '') {
$tpp = $tpp.Trim()
if ($tpp -match '^(?i)[A-Za-z]:\\' -and (_leafExists $tpp)) {
$result.ResolvedTargetPath = $tpp
$result.ResolutionMethod = 'ExtendedProperty:TargetParsingPath'
} else {
# Shell namespace / CLSID style target: open via explorer
$result.ResolvedTargetPath = $explorerExe
if (-not $result.Arguments -or $result.Arguments.Trim() -eq '') {
if ($tpp -match '^::\{') {
$result.Arguments = 'shell:::' + ($tpp.TrimStart(':'))
} else {
$result.Arguments = $tpp
}
}
$result.ResolutionMethod = 'ExtendedProperty:ShellPath'
}
}
}
} catch {}
}
}
} catch {}

return [pscustomobject]$result
}

#endregion TI_CORE_SHORTCUT

$ps1Action = $null
try {
if ($param -and ($param -match '(?i)(?:^|\s)/ps1action[:=]([^\s\"]+)')) {
$ps1Action = $matches[1]
Log "Detected ps1Action from param: $ps1Action"

function Find-FileByNameInDir {
param(
[Parameter(Mandatory=$true)][string]$Directory,
[Parameter(Mandatory=$true)][string]$FileName
)
try {
if (-not (Test-Path -LiteralPath $Directory -PathType Container)) { return $null }
$match = Get-ChildItem -LiteralPath $Directory -File -Filter $FileName -ErrorAction SilentlyContinue | Select-Object -First 1
if ($match) { return $match.FullName }
} catch {}
return $null
}

$ps1Path = $null
if ($param -match '(?i)"([^"]+\.ps1)"') {
$ps1Path = $matches[1]
} elseif ($param -match '(?i)([A-Za-z]:\\[^\s]+\.ps1)') {
$ps1Path = $matches[1]
}

# Fallback: strip ps1action prefix from $param and try to detect a valid .ps1 path
try {
$tmp2 = $param
if ($tmp2 -match '(?i)^\s*/ps1action[:=][^\s\"]+\s+(.+)$') { $tmp2 = $matches[1] }
$tmp2 = ($tmp2 | Out-String).Trim()
if ($tmp2 -match '^\s*"(.*)"\s*$') { $tmp2 = $matches[1] }
# If extra tokens exist, take the trailing drive-path that ends with .ps1
if ($tmp2 -match '(?i)([A-Za-z]:\\\\.*\\.ps1)\s*$') { $tmp2 = $matches[1] }
if ((-not $ps1Path) -and $tmp2 -and (Test-Path -LiteralPath $tmp2)) { $ps1Path = $tmp2 }
} catch {}

# Fallback: try to detect from PowerShell args array
try {
if (-not $ps1Path -and $args -and $args.Count -gt 0) {
$cand = ($args | Where-Object { $_ -and ($_ -notmatch '^/ps1action[:=]') -and ($_ -match '(?i)\\.ps1$') } | Select-Object -First 1)
if ($cand -and (Test-Path -LiteralPath $cand)) { $ps1Path = $cand }
}
} catch {}


if ((-not $ps1Path) -or ($ps1Path -and (-not (Test-Path -LiteralPath $ps1Path)))) {
try {
$tmp = $param
if ($tmp -match '(?i)^\s*/ps1action[:=][^\s\"]+\s+(.+)$') { $tmp = $matches[1] }
$tmp = ($tmp | Out-String).Trim()
if ($tmp -match '^\s*"(.*)"\s*$') { $tmp = $matches[1] }
if ($tmp -and ($tmp -match '(?i)\.ps1$') -and (Test-Path -LiteralPath $tmp)) {
$ps1Path = $tmp
}
} catch {}
try {
if ((-not $ps1Path) -and $tmp) {
$leaf = [System.IO.Path]::GetFileName($tmp)
$parent = Split-Path -Parent $tmp
if ($leaf -and ($leaf -match '(?i)\.ps1$')) {
if ($parent -and (Test-Path -LiteralPath $parent -PathType Container)) {
$found = Find-FileByNameInDir -Directory $parent -FileName $leaf
if ($found) { $ps1Path = $found }
}
if (-not $ps1Path) {
$desktop = Join-Path $env:USERPROFILE 'Desktop'
if (Test-Path -LiteralPath $desktop -PathType Container) {
$found2 = Find-FileByNameRecursive -Root $desktop -FileName $leaf -MaxDepth 6 -MaxDirs 2500
if ($found2) { $ps1Path = $found2 }
}
}
}
}
} catch {}
try {
$rebuilt = (($args | Where-Object { $_ -and ($_ -notmatch '^/ps1action[:=]') }) -join ' ')
if ($rebuilt -and ($rebuilt -match '(?i)\.ps1$') -and (Test-Path -LiteralPath $rebuilt)) {
$ps1Path = $rebuilt
}
} catch {}
if ($ps1Path -and (Test-Path -LiteralPath $ps1Path)) {
$param = $ps1Path
Log "Using ps1 path from param: $ps1Path"
} else {
Log "ps1Action detected but could not extract existing ps1 path from param. param=$param"
}
}
}
} catch {
Log "ps1Action parse from param failed: $($_.Exception.Message)"
}

if (-not $ps1Action) {
try {
$argvAll = [Environment]::GetCommandLineArgs()
foreach ($a in $argvAll) {
if ($a -match '^/ps1action[:=](.+)$') { $ps1Action = $matches[1] }
}
if ($ps1Action) { Log "Detected ps1Action from argv fallback: $ps1Action" }
} catch {}
}

#region TI_CORE_RUNASTI
function RunAsTI {
param(
$cmd,
$targetName,  # İşlem yapılan dosya/klasör yolu veya adı (isteğe bağlı)
$workDir = $null  # Kısayolun WorkingDirectory (varsa)
)
    $id = "TI_Payload_" + [guid]::NewGuid().ToString('N')
    $sid = ((whoami /user) -split ' ')[-1]
if (!$cmd -or ($cmd -and $cmd.Trim() -eq '')) { $cmd = 'cmd.exe' }

if ($cmd -match '\$param=.*SCRIPT_PATH') { $cmd = 'cmd.exe' }

$logFile = "$env:TEMP\TI_Error.log"
"=== Debug Log ===" | Out-File $logFile
"Command: $cmd" | Out-File $logFile -Append
"SID: $sid" | Out-File $logFile -Append
"Time: $(Get-Date)" | Out-File $logFile -Append

if ($targetName) {
if ($isTurkish) {
$msg.PleaseWait = "Trusted Installer etkinleştiriliyor"
} else {
$msg.PleaseWait = "Activating Trusted Installer"
}
} else {
if ($isTurkish) {
$msg.PleaseWait = "Trusted Installer etkinleştiriliyor"
} else {
$msg.PleaseWait = "Activating Trusted Installer"
}
}

$progressFile = "$env:TEMP\TI_Progress.ps1"

    $progressScript = @"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Dpi {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
'@
[Dpi]::SetProcessDPIAware() | Out-Null

Add-Type @'
using System;
using System.Runtime.InteropServices;
public class IconLoader {
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern int ExtractIconEx(
        string file,
        int index,
        IntPtr[] large,
        IntPtr[] small,
        int icons
    );
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
}
'@

`$form = New-Object System.Windows.Forms.Form
`$form.Size = New-Object System.Drawing.Size(420,150)
`$form.StartPosition = 'CenterScreen'
`$form.FormBorderStyle = 'None'
`$form.TopMost = `$true
`$form.ShowInTaskbar = `$false
`$form.BackColor = [System.Drawing.Color]::FromArgb(32,32,32)
`$form.Opacity = 0

# DWMWA_WINDOW_CORNER_PREFERENCE (Win11+) gives anti-aliased corners;
# GraphicsPath region clipping (fallback) is hard-edged and looks jagged.
`$dwmRounded = `$false
try {
`$pref = 2 # DWMWCP_ROUND
if ([IconLoader]::DwmSetWindowAttribute(`$form.Handle, 33, [ref]`$pref, 4) -eq 0) { `$dwmRounded = `$true }
} catch {}
if (-not `$dwmRounded) {
`$radius = 14
`$path = New-Object System.Drawing.Drawing2D.GraphicsPath
`$path.AddArc(0,0,`$radius,`$radius,180,90)
`$path.AddArc(`$form.Width-`$radius,0,`$radius,`$radius,270,90)
`$path.AddArc(`$form.Width-`$radius,`$form.Height-`$radius,`$radius,`$radius,0,90)
`$path.AddArc(0,`$form.Height-`$radius,`$radius,`$radius,90,90)
`$path.CloseFigure()
`$form.Region = New-Object System.Drawing.Region(`$path)
}

`$layout = New-Object System.Windows.Forms.TableLayoutPanel
`$layout.Dock = 'Fill'
`$layout.RowCount = 2
`$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent',60)))
`$layout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent',40)))
`$form.Controls.Add(`$layout)

`$top = New-Object System.Windows.Forms.Panel
`$top.Dock = 'Fill'
`$layout.Controls.Add(`$top,0,0)

`$large = New-Object IntPtr[] 1
`$small = New-Object IntPtr[] 1
[IconLoader]::ExtractIconEx(
"`$env:SystemRoot\System32\imageres.dll",
-78,
`$large,
`$small,
1
) | Out-Null

`$iconBmp = [System.Drawing.Icon]::FromHandle(`$large[0]).ToBitmap()

`$iconBox = New-Object System.Windows.Forms.PictureBox
`$iconBox.Size = New-Object System.Drawing.Size(26,26)
`$iconBox.Location = New-Object System.Drawing.Point(24,18)
`$iconBox.SizeMode = 'Zoom'
`$iconBox.Image = `$iconBmp
`$top.Controls.Add(`$iconBox)

try { `$lang = (Get-UICulture).Name } catch { `$lang = [System.Globalization.CultureInfo]::CurrentUICulture.Name }
`$isTr = `$lang -like "tr-*"

`$labelMain = New-Object System.Windows.Forms.Label
`$labelMain.Text = `$env:TI_PROGRESS_MSG
`$labelMain.ForeColor = 'White'
`$labelMain.Font = New-Object System.Drawing.Font("Segoe UI",10)
`$labelMain.AutoSize = `$false
`$labelMain.Width = `$form.Width
`$labelMain.Height = 20
`$labelMain.TextAlign = 'MiddleCenter'
`$labelMain.Location = New-Object System.Drawing.Point(0,16)
`$top.Controls.Add(`$labelMain)
`$labelSub = New-Object System.Windows.Forms.Label
`$labelSub.Text = `$env:TI_PROGRESS_SUB
`$labelSub.ForeColor = [System.Drawing.Color]::FromArgb(220,220,220)
`$labelSub.Font = New-Object System.Drawing.Font("Segoe UI",9)
`$labelSub.AutoSize = `$false
`$labelSub.Width = `$form.Width
`$labelSub.Height = 40
`$labelSub.TextAlign = 'TopCenter'
`$labelSub.Location = New-Object System.Drawing.Point(0,42)
`$top.Controls.Add(`$labelSub)

`$progressPanel = New-Object System.Windows.Forms.Panel
`$progressPanel.Dock = 'Fill'
`$layout.Controls.Add(`$progressPanel,0,1)

`$segmentCount = 16
`$segmentWidth = 18
`$segmentHeight = 14
`$segmentGap = 6

`$totalWidth = (`$segmentCount * `$segmentWidth) + ((`$segmentCount - 1) * `$segmentGap)
`$startX = (`$form.Width - `$totalWidth) / 2
`$y = 12

`$segments = @()

for (`$i=0; `$i -lt `$segmentCount; `$i++) {
`$seg = New-Object System.Windows.Forms.Panel
`$seg.Width  = `$segmentWidth
`$seg.Height = `$segmentHeight
`$seg.Left   = `$startX + (`$i * (`$segmentWidth + `$segmentGap))
`$seg.Top    = `$y
`$seg.BackColor = [System.Drawing.Color]::FromArgb(70,70,70)
`$progressPanel.Controls.Add(`$seg)
`$segments += `$seg
}

`$credit = New-Object System.Windows.Forms.Label
`$credit.Text = "by Abdullah ERTÜRK"
`$credit.ForeColor = [System.Drawing.Color]::FromArgb(170,170,170)
`$credit.Font = New-Object System.Drawing.Font("Segoe UI",9)
`$credit.AutoSize = `$true
`$credit.Anchor = 'Top,Right'
`$progressPanel.Controls.Add(`$credit)

function Set-CreditPos {
    try {
        `$credit.Top  = `$y + `$segmentHeight + 6
        `$credit.Left = [Math]::Max(0, (`$startX + `$totalWidth) - `$credit.PreferredWidth)
    } catch {}
}
Set-CreditPos

`$progressPanel.Add_Resize({
`$totalWidth = (`$segmentCount * `$segmentWidth) + ((`$segmentCount - 1) * `$segmentGap)
`$startX = (`$progressPanel.Width - `$totalWidth) / 2
foreach (`$i in 0..(`$segments.Count-1)) {
`$segments[`$i].Left = `$startX + (`$i * (`$segmentWidth + `$segmentGap))
}
Set-CreditPos
})

`$script:index = 0
`$timer = New-Object System.Windows.Forms.Timer
`$timer.Interval = 120
`$timer.Add_Tick({
for (`$i=0; `$i -lt `$segments.Count; `$i++) {
if (`$i -le `$script:index) {
`$segments[`$i].BackColor = [System.Drawing.Color]::FromArgb(80,200,120)
} else {
`$segments[`$i].BackColor = [System.Drawing.Color]::FromArgb(70,70,70)
}
}
`$script:index++
if (`$script:index -ge `$segments.Count) { `$script:index = 0 }
})

`$fade = New-Object System.Windows.Forms.Timer
`$fade.Interval = 25
`$fade.Add_Tick({
if (`$form.Opacity -lt 0.95) {
`$form.Opacity += 0.08
} else {
`$fade.Stop()
}
})

`$form.Add_Shown({
`$fade.Start()
`$timer.Start()
})

# Fail-safe: self-close if the elevation chain never comes back to kill this window.
`$watchdog = New-Object System.Windows.Forms.Timer
`$watchdog.Interval = 90000
`$watchdog.Add_Tick({ try { `$watchdog.Stop() } catch {}; try { `$form.Close() } catch {} })
`$watchdog.Start()

`$fade.Start()
`$timer.Start()

[void]`$form.ShowDialog()
"@

$progressScript | Out-File $progressFile -Encoding UTF8 -Force

$env:TI_PROGRESS_TITLE = $msg.Title
$env:TI_PROGRESS_MSG = $msg.PleaseWait
$env:TI_PROGRESS_SUB = if ($isTurkish) { "Lütfen bekleyiniz" + $(if ($targetName) { "`n$targetName" } else { "" }) } else { "Please wait" + $(if ($targetName) { "`n$targetName" } else { "" }) }
$progressJob = Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$progressFile`"" -PassThru

$env:TI_PROGRESS_PID = $progressJob.Id
$env:TI_PROGRESS_FILE = $progressFile
$progressPidFile = "$env:TEMP\TI_Progress.pid"
try { Set-Content -LiteralPath $progressPidFile -Value ([string]$progressJob.Id) -Encoding ASCII -Force } catch {}

try {
Get-ChildItem -Path $env:TEMP -Filter "TI_Progress_*.ps1" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
} catch {}
$msgTitle = $msg.Title
$msgTitleEscaped = $msgTitle -replace '"','`"'
$scriptDir = if ($env:SCRIPT_PATH) {
Split-Path -Parent $env:SCRIPT_PATH
} else {
$PWD.Path
}
$scriptDirEscaped = $scriptDir -replace '"','`"'
    $payload = @'
try {
    $logFile = "$env:TEMP\TI_Error.log"
    $msgTitle = "MSG_TITLE_PLACEHOLDER"
    $scriptDir = "SCRIPT_DIR_PLACEHOLDER"
    "Starting payload..." | Out-File $logFile -Append

    # TrustedInstaller token via NtImpersonateThread. Launches via
    # CreateProcessWithTokenW with lpDesktop set explicitly so windows are visible.
    $tiSrc = @"
using System;
using System.Runtime.InteropServices;

public static class TIToken {
    [StructLayout(LayoutKind.Sequential)]
    public struct LUID { public uint LowPart; public int HighPart; }

    [StructLayout(LayoutKind.Sequential)]
    public struct TOKEN_PRIVILEGES { public uint PrivilegeCount; public LUID Luid; public uint Attributes; }

    [StructLayout(LayoutKind.Sequential)]
    public struct SECURITY_QUALITY_OF_SERVICE {
        public int Length;
        public int ImpersonationLevel;
        public byte ContextTrackingMode;
        public byte EffectiveOnly;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION {
        public IntPtr hProcess;
        public IntPtr hThread;
        public int dwProcessId;
        public int dwThreadId;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct STARTUPINFO {
        public int cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public int dwX;
        public int dwY;
        public int dwXSize;
        public int dwYSize;
        public int dwXCountChars;
        public int dwYCountChars;
        public int dwFillAttribute;
        public int dwFlags;
        public short wShowWindow;
        public short cbReserved2;
        public IntPtr lpReserved2;
        public IntPtr hStdInput;
        public IntPtr hStdOutput;
        public IntPtr hStdError;
    }

    public const int TOKEN_QUERY = 0x8;
    public const int TOKEN_DUPLICATE = 0x2;
    public const int TOKEN_IMPERSONATE = 0x4;
    public const int TOKEN_ASSIGN_PRIMARY = 0x1;
    public const int TOKEN_ADJUST_PRIVILEGES = 0x20;
    public const int TOKEN_ADJUST_DEFAULT = 0x80;
    public const int TOKEN_QUERY_SOURCE = 0x10;
    public const int TOKEN_ADJUST_GROUPS = 0x40;
    public const int STANDARD_RIGHTS_REQUIRED = 0xF0000;
    public const int TOKEN_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED | TOKEN_ASSIGN_PRIMARY | TOKEN_DUPLICATE | TOKEN_IMPERSONATE | TOKEN_QUERY | TOKEN_QUERY_SOURCE | TOKEN_ADJUST_PRIVILEGES | TOKEN_ADJUST_GROUPS | TOKEN_ADJUST_DEFAULT;
    public const uint MAXIMUM_ALLOWED = 0x2000000;
    public const uint SE_PRIVILEGE_ENABLED = 0x2;
    public const int THREAD_DIRECT_IMPERSONATION = 0x200;
    public const int SecurityImpersonation = 2;
    public const int TokenImpersonation = 2;
    public const int LOGON_WITH_PROFILE = 0x1;
    public const int PROCESS_DUP_HANDLE = 0x40;
    public const int PROCESS_QUERY_INFORMATION = 0x400;
    public const int TokenPrivilegesClass = 3;

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool OpenProcessToken(IntPtr ProcessHandle, int DesiredAccess, out IntPtr TokenHandle);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool GetTokenInformation(IntPtr TokenHandle, int TokenInformationClass, IntPtr TokenInformation, int TokenInformationLength, out int ReturnLength);

    [DllImport("advapi32.dll", SetLastError = true, EntryPoint = "AdjustTokenPrivileges")]
    public static extern bool AdjustTokenPrivilegesBuf(IntPtr TokenHandle, bool DisableAllPrivileges, IntPtr NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetCurrentProcess();

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetCurrentThread();

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out LUID lpLuid);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES NewState, int BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool ImpersonateLoggedOnUser(IntPtr hToken);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool RevertToSelf();

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenThread(int dwDesiredAccess, bool bInheritHandle, int dwThreadId);

    [DllImport("ntdll.dll")]
    public static extern int NtImpersonateThread(IntPtr ServerThreadHandle, IntPtr ClientThreadHandle, ref SECURITY_QUALITY_OF_SERVICE SecurityQualityOfService);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool OpenThreadToken(IntPtr ThreadHandle, int DesiredAccess, bool OpenAsSelf, out IntPtr TokenHandle);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool DuplicateTokenEx(IntPtr hExistingToken, uint dwDesiredAccess, IntPtr lpTokenAttributes, int ImpersonationLevel, int TokenType, out IntPtr phNewToken);

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CreateProcessWithTokenW(IntPtr hToken, int dwLogonFlags, IntPtr lpApplicationName, IntPtr lpCommandLine, int dwCreationFlags, IntPtr lpEnvironment, IntPtr lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);

    [DllImport("kernel32.dll")]
    public static extern uint ResumeThread(IntPtr hThread);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CreateProcess(IntPtr lpApplicationName, IntPtr lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, IntPtr lpEnvironment, IntPtr lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

    public const ulong PROC_THREAD_ATTRIBUTE_PARENT_PROCESS = 0x00020000;
    public const uint EXTENDED_STARTUPINFO_PRESENT = 0x00080000;
    public const int PROCESS_ALL_ACCESS = 0x1FFFFF;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct STARTUPINFOEX {
        public STARTUPINFO StartupInfo;
        public IntPtr lpAttributeList;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool InitializeProcThreadAttributeList(IntPtr lpAttributeList, int dwAttributeCount, int dwFlags, ref IntPtr lpSize);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool UpdateProcThreadAttribute(IntPtr lpAttributeList, uint dwFlags, IntPtr Attribute, IntPtr lpValue, IntPtr cbSize, IntPtr lpPreviousValue, IntPtr lpReturnSize);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern void DeleteProcThreadAttributeList(IntPtr lpAttributeList);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr GetEnvironmentStringsW();

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool FreeEnvironmentStringsW(IntPtr lpszEnvironmentBlock);

    [DllImport("kernel32.dll", EntryPoint = "CreateProcessW", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CreateProcessEx(IntPtr lpApplicationName, IntPtr lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, IntPtr lpEnvironment, IntPtr lpCurrentDirectory, ref STARTUPINFOEX lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);
}
"@
    Add-Type -TypeDefinition $tiSrc -ErrorAction Stop

    function Enable-TIPrivilege {
        param([string]$Name)
        $hToken = [IntPtr]::Zero
        if (-not [TIToken]::OpenProcessToken([TIToken]::GetCurrentProcess(), [TIToken]::TOKEN_ADJUST_PRIVILEGES -bor [TIToken]::TOKEN_QUERY, [ref]$hToken)) { return $false }
        try {
            $luid = New-Object TIToken+LUID
            if (-not [TIToken]::LookupPrivilegeValue($null, $Name, [ref]$luid)) { return $false }
            $tp = New-Object TIToken+TOKEN_PRIVILEGES
            $tp.PrivilegeCount = 1
            $tp.Luid = $luid
            $tp.Attributes = [TIToken]::SE_PRIVILEGE_ENABLED
            return [TIToken]::AdjustTokenPrivileges($hToken, $false, [ref]$tp, 0, [IntPtr]::Zero, [IntPtr]::Zero)
        } finally {
            [TIToken]::CloseHandle($hToken) | Out-Null
        }
    }

    function Enable-AllTokenPrivileges {
        # Several privileges are present-but-disabled by default; enable all
        # of them before handing the token to CreateProcessWithTokenW.
        param([IntPtr]$Token)
        $len = 0
        [TIToken]::GetTokenInformation($Token, [TIToken]::TokenPrivilegesClass, [IntPtr]::Zero, 0, [ref]$len) | Out-Null
        if ($len -le 0) { return }
        $buf = [Runtime.InteropServices.Marshal]::AllocHGlobal($len)
        try {
            if (-not [TIToken]::GetTokenInformation($Token, [TIToken]::TokenPrivilegesClass, $buf, $len, [ref]$len)) { return }
            $count = [Runtime.InteropServices.Marshal]::ReadInt32($buf, 0)
            for ($i = 0; $i -lt $count; $i++) {
                # TOKEN_PRIVILEGES: DWORD PrivilegeCount, then LUID_AND_ATTRIBUTES[]
                # (LUID=8 bytes + DWORD Attributes=4 bytes = 12 bytes/entry).
                $attrOffset = 4 + ($i * 12) + 8
                [Runtime.InteropServices.Marshal]::WriteInt32($buf, $attrOffset, 2) # SE_PRIVILEGE_ENABLED
            }
            [TIToken]::AdjustTokenPrivilegesBuf($Token, $false, $buf, $len, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
        } finally {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($buf)
        }
    }

    function Enter-SystemImpersonation {
        $winlogon = Get-Process -Name winlogon -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $winlogon) { throw "winlogon.exe not found" }
        $hProc = [TIToken]::OpenProcess([TIToken]::PROCESS_DUP_HANDLE -bor [TIToken]::PROCESS_QUERY_INFORMATION, $false, $winlogon.Id)
        if ($hProc -eq [IntPtr]::Zero) { throw "OpenProcess(winlogon) failed" }
        try {
            $hTok = [IntPtr]::Zero
            if (-not [TIToken]::OpenProcessToken($hProc, [TIToken]::TOKEN_QUERY -bor [TIToken]::TOKEN_DUPLICATE, [ref]$hTok)) { throw "OpenProcessToken(winlogon) failed" }
            try {
                if (-not [TIToken]::ImpersonateLoggedOnUser($hTok)) { throw "ImpersonateLoggedOnUser failed" }
            } finally { [TIToken]::CloseHandle($hTok) | Out-Null }
        } finally { [TIToken]::CloseHandle($hProc) | Out-Null }
    }

    function Get-TITokenHandle {
        $svc = Get-Service -Name TrustedInstaller
        if ($svc.Status -ne 'Running') {
            Start-Service -Name TrustedInstaller
            $deadline = (Get-Date).AddSeconds(15)
            while ((Get-Service -Name TrustedInstaller).Status -ne 'Running' -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 300 }
        }

        # Retry: the service can be mid-restart when queried.
        $lastErr = $null
        for ($attempt = 1; $attempt -le 5; $attempt++) {
            try {
                $tiPid = (Get-WmiObject Win32_Service -Filter "Name='TrustedInstaller'").ProcessId
                if (-not $tiPid) { throw "Could not resolve TrustedInstaller PID" }
                $tiThreadId = (Get-Process -Id $tiPid -ErrorAction Stop).Threads | Select-Object -First 1 -ExpandProperty Id
                if (-not $tiThreadId) { throw "Could not get a TrustedInstaller thread id" }

                $hThread = [TIToken]::OpenThread([TIToken]::THREAD_DIRECT_IMPERSONATION, $false, $tiThreadId)
                if ($hThread -eq [IntPtr]::Zero) { throw "OpenThread(TrustedInstaller) failed" }
                try {
                    $sqos = New-Object TIToken+SECURITY_QUALITY_OF_SERVICE
                    $sqos.Length = [Runtime.InteropServices.Marshal]::SizeOf([type]"TIToken+SECURITY_QUALITY_OF_SERVICE")
                    $sqos.ImpersonationLevel = [TIToken]::SecurityImpersonation
                    $status = [TIToken]::NtImpersonateThread([TIToken]::GetCurrentThread(), $hThread, [ref]$sqos)
                    if ($status -ne 0) { throw ("NtImpersonateThread failed, NTSTATUS=0x{0:X8}" -f $status) }

                    $hTiToken = [IntPtr]::Zero
                    if (-not [TIToken]::OpenThreadToken([TIToken]::GetCurrentThread(), [TIToken]::TOKEN_ALL_ACCESS, $false, [ref]$hTiToken)) {
                        throw "OpenThreadToken failed after NtImpersonateThread"
                    }
                    return $hTiToken
                } finally {
                    [TIToken]::CloseHandle($hThread) | Out-Null
                }
            } catch {
                $lastErr = $_
                Start-Sleep -Milliseconds 400
            }
        }
        throw "Get-TITokenHandle failed after 5 attempts: $($lastErr.Exception.Message)"
    }

    function Start-ProcessAsTI {
        param([Parameter(Mandatory=$true)][string]$CommandLine, [string]$CurrentDirectory = $null)

        $tiProc = Get-Process -Name TrustedInstaller -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $tiProc) { throw "TrustedInstaller process not found." }

        $hTiProc = [TIToken]::OpenProcess([TIToken]::PROCESS_ALL_ACCESS, $false, [int]$tiProc.Id)
        if ($hTiProc -eq [IntPtr]::Zero) { throw "OpenProcess failed" }

        $pCmdLine = [IntPtr]::Zero
        $pCurDir = [IntPtr]::Zero
        $attrList = [IntPtr]::Zero
        $pTiHandle = [IntPtr]::Zero

        try {
            $lpSize = [IntPtr]::Zero
            [TIToken]::InitializeProcThreadAttributeList([IntPtr]::Zero, 1, 0, [ref]$lpSize) | Out-Null
            $attrList = [Runtime.InteropServices.Marshal]::AllocHGlobal($lpSize)
            
            if (-not [TIToken]::InitializeProcThreadAttributeList($attrList, 1, 0, [ref]$lpSize)) {
                throw "InitializeProcThreadAttributeList failed"
            }

            $pTiHandle = [Runtime.InteropServices.Marshal]::AllocHGlobal([IntPtr]::Size)
            [Runtime.InteropServices.Marshal]::WriteIntPtr($pTiHandle, $hTiProc)
            
            $attrId = [IntPtr]0x00020000 # PROC_THREAD_ATTRIBUTE_PARENT_PROCESS
            if (-not [TIToken]::UpdateProcThreadAttribute($attrList, 0, $attrId, $pTiHandle, [IntPtr][IntPtr]::Size, [IntPtr]::Zero, [IntPtr]::Zero)) {
                throw "UpdateProcThreadAttribute failed"
            }

            $siEx = New-Object TIToken+STARTUPINFOEX
            $si = New-Object TIToken+STARTUPINFO
            $si.cb = [Runtime.InteropServices.Marshal]::SizeOf([type]"TIToken+STARTUPINFOEX")
            $si.lpDesktop = "WinSta0\Default"
            $siEx.StartupInfo = $si
            $siEx.lpAttributeList = $attrList
            $pi = New-Object TIToken+PROCESS_INFORMATION

            $pCmdLine = [Runtime.InteropServices.Marshal]::StringToHGlobalUni($CommandLine + (New-Object string ([char]0, 8)))
            if ($CurrentDirectory) { $pCurDir = [Runtime.InteropServices.Marshal]::StringToHGlobalUni($CurrentDirectory) }

            $envBlock = [TIToken]::GetEnvironmentStringsW()
            $createFlags = [TIToken]::EXTENDED_STARTUPINFO_PRESENT -bor 0x00000400 -bor 0x00000010 -bor 0x00000004 # CREATE_UNICODE_ENVIRONMENT | CREATE_NEW_CONSOLE | CREATE_SUSPENDED
            
            try {
                $ok = [TIToken]::CreateProcessEx([IntPtr]::Zero, $pCmdLine, [IntPtr]::Zero, [IntPtr]::Zero, $false, $createFlags, $envBlock, $pCurDir, [ref]$siEx, [ref]$pi)
                if (-not $ok) {
                    $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
                    throw "CreateProcessEx failed, Win32Error=$err"
                }

                $hTok = [IntPtr]::Zero
                if ([TIToken]::OpenProcessToken($pi.hProcess, [TIToken]::TOKEN_ADJUST_PRIVILEGES -bor [TIToken]::TOKEN_QUERY, [ref]$hTok)) {
                    Enable-AllTokenPrivileges -Token $hTok
                    [TIToken]::CloseHandle($hTok) | Out-Null
                }
                [TIToken]::ResumeThread($pi.hThread) | Out-Null
            } finally {
                if ($envBlock -ne [IntPtr]::Zero) { [TIToken]::FreeEnvironmentStringsW($envBlock) | Out-Null }
            }

            [TIToken]::CloseHandle($pi.hProcess) | Out-Null
            [TIToken]::CloseHandle($pi.hThread) | Out-Null
            return $pi.dwProcessId

        } finally {
            if ($pCmdLine -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::FreeHGlobal($pCmdLine) }
            if ($pCurDir -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::FreeHGlobal($pCurDir) }
            if ($pTiHandle -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::FreeHGlobal($pTiHandle) }
            if ($attrList -ne [IntPtr]::Zero) {
                [TIToken]::DeleteProcThreadAttributeList($attrList)
                [Runtime.InteropServices.Marshal]::FreeHGlobal($attrList)
            }
            [TIToken]::CloseHandle($hTiProc) | Out-Null
        }
    }

    function Start-ExplorerAsTI {
        param([Parameter(Mandatory=$true)][string]$Path)
        $EXP = 'HKLM:\Software\Classes\AppID\{CDCBCFCA-3CDC-436f-A4E2-0E02075250C2}'

        # Ensure SYSTEM account can run PowerShell scripts without profile errors
        try {
            if (-not (Test-Path "Registry::HKEY_USERS\S-1-5-18\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell")) {
                New-Item -Path "Registry::HKEY_USERS\S-1-5-18\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" -Force | Out-Null
            }
            Set-ItemProperty -Path "Registry::HKEY_USERS\S-1-5-18\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" -Name "ExecutionPolicy" -Value "Bypass" -Force -ErrorAction SilentlyContinue
        } catch {}

        # Ensure TrustedInstaller is running
        $svc2 = Get-Service -Name TrustedInstaller -ErrorAction SilentlyContinue
        if ($svc2 -and $svc2.Status -ne 'Running') {
            Start-Service -Name TrustedInstaller -ErrorAction SilentlyContinue
            $dl2 = (Get-Date).AddSeconds(10)
            while ((Get-Service -Name TrustedInstaller).Status -ne 'Running' -and (Get-Date) -lt $dl2) { Start-Sleep -Milliseconds 200 }
        }
        $tiProc2 = Get-Process -Name TrustedInstaller -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $tiProc2) { throw "TrustedInstaller process not found in Start-ExplorerAsTI" }

        # Step 1: Temporarily clear RunAs restriction (needs TI rights via impersonation)
        $tiThreadId2 = $tiProc2.Threads | Select-Object -First 1 -ExpandProperty Id
        if ($tiThreadId2) {
            $hTh2 = [TIToken]::OpenThread([TIToken]::THREAD_DIRECT_IMPERSONATION, $false, [int]$tiThreadId2)
            if ($hTh2 -ne [IntPtr]::Zero) {
                try {
                    $sqos2 = New-Object TIToken+SECURITY_QUALITY_OF_SERVICE
                    $sqos2.Length = [Runtime.InteropServices.Marshal]::SizeOf([type]"TIToken+SECURITY_QUALITY_OF_SERVICE")
                    $sqos2.ImpersonationLevel = [TIToken]::SecurityImpersonation
                    $sqos2.ContextTrackingMode = 1
                    $sqos2.EffectiveOnly = 0
                    $st2 = [TIToken]::NtImpersonateThread([TIToken]::GetCurrentThread(), $hTh2, [ref]$sqos2)
                    if ($st2 -eq 0) {
                        try { Set-ItemProperty $EXP RunAs '' -Force -ErrorAction SilentlyContinue } catch {}
                        [TIToken]::RevertToSelf() | Out-Null
                    }
                } finally { [TIToken]::CloseHandle($hTh2) | Out-Null }
            }
        }

        # Step 2: Open TrustedInstaller process handle (PROCESS_CREATE_PROCESS)
        # With SeDebugPrivilege we can open it with PROCESS_ALL_ACCESS
        $hTiProc = [TIToken]::OpenProcess([TIToken]::PROCESS_ALL_ACCESS, $false, [int]$tiProc2.Id)
        if ($hTiProc -eq [IntPtr]::Zero) { throw "OpenProcess(TrustedInstaller) failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())" }
        try {
            # Step 3: Build PROC_THREAD_ATTRIBUTE_LIST with PARENT_PROCESS = TrustedInstaller
            $lpSize = [IntPtr]::Zero
            [TIToken]::InitializeProcThreadAttributeList([IntPtr]::Zero, 1, 0, [ref]$lpSize) | Out-Null
            $attrList = [Runtime.InteropServices.Marshal]::AllocHGlobal($lpSize)
            try {
                if (-not [TIToken]::InitializeProcThreadAttributeList($attrList, 1, 0, [ref]$lpSize)) {
                    throw "InitializeProcThreadAttributeList failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
                }
                try {
                    # Write TI process handle into unmanaged memory so we can pass pointer to UpdateProcThreadAttribute
                    $pTiHandle = [Runtime.InteropServices.Marshal]::AllocHGlobal([IntPtr]::Size)
                    [Runtime.InteropServices.Marshal]::WriteIntPtr($pTiHandle, $hTiProc)
                    try {
                        $attrId = [IntPtr]0x00020000
                        if (-not [TIToken]::UpdateProcThreadAttribute($attrList, 0, $attrId, $pTiHandle, [IntPtr][IntPtr]::Size, [IntPtr]::Zero, [IntPtr]::Zero)) {
                            throw "UpdateProcThreadAttribute(PARENT_PROCESS) failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
                        }

                        # Step 4: CreateProcessEx with EXTENDED_STARTUPINFO_PRESENT + TI as parent -> Explorer inherits TI token
                        $siEx = New-Object TIToken+STARTUPINFOEX
                        $si = New-Object TIToken+STARTUPINFO
                        $si.cb = [Runtime.InteropServices.Marshal]::SizeOf([type]"TIToken+STARTUPINFOEX")
                        $si.lpDesktop = "WinSta0\Default"
                        $siEx.StartupInfo = $si
                        $siEx.lpAttributeList = $attrList
                        $pi2 = New-Object TIToken+PROCESS_INFORMATION

                        $explorerCmd = "`"$env:windir\explorer.exe`" `"$Path`""
                        $pCmdLine2 = [Runtime.InteropServices.Marshal]::StringToHGlobalUni($explorerCmd + (New-Object string ([char]0, 8)))
                        $envBlock = [TIToken]::GetEnvironmentStringsW()
                        try {
                            $createFlags = [TIToken]::EXTENDED_STARTUPINFO_PRESENT -bor 0x00000400 -bor 0x00000004 # CREATE_UNICODE_ENVIRONMENT | CREATE_SUSPENDED
                            $ok2 = [TIToken]::CreateProcessEx([IntPtr]::Zero, $pCmdLine2, [IntPtr]::Zero, [IntPtr]::Zero, $false, $createFlags, $envBlock, [IntPtr]::Zero, [ref]$siEx, [ref]$pi2)
                            if (-not $ok2) {
                                $err2 = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
                                "CreateProcessEx(Explorer+TI_Parent) failed: Win32Error=$err2" | Out-File $logFile -Append
                                throw "CreateProcessEx failed: $err2"
                            } else {
                                "CreateProcessEx(Explorer+TI_Parent) succeeded" | Out-File $logFile -Append
                                $hTok = [IntPtr]::Zero
                                if ([TIToken]::OpenProcessToken($pi2.hProcess, [TIToken]::TOKEN_ADJUST_PRIVILEGES -bor [TIToken]::TOKEN_QUERY, [ref]$hTok)) {
                                    Enable-AllTokenPrivileges -Token $hTok
                                    [TIToken]::CloseHandle($hTok) | Out-Null
                                }
                                [TIToken]::ResumeThread($pi2.hThread) | Out-Null
                                [TIToken]::CloseHandle($pi2.hProcess) | Out-Null
                                [TIToken]::CloseHandle($pi2.hThread) | Out-Null
                            }
                        } finally {
                            [Runtime.InteropServices.Marshal]::FreeHGlobal($pCmdLine2)
                            if ($envBlock -ne [IntPtr]::Zero) { [TIToken]::FreeEnvironmentStringsW($envBlock) | Out-Null }
                        }
                    } finally {
                        [Runtime.InteropServices.Marshal]::FreeHGlobal($pTiHandle)
                    }
                } finally {
                    [TIToken]::DeleteProcThreadAttributeList($attrList)
                }
            } finally {
                [Runtime.InteropServices.Marshal]::FreeHGlobal($attrList)
            }
        } finally {
            [TIToken]::CloseHandle($hTiProc) | Out-Null
        }

        # Step 5: Restore RunAs restriction (via impersonation again)
        Start-Sleep -Seconds 1
        $tiProc3 = Get-Process -Name TrustedInstaller -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($tiProc3) {
            $tiThreadId3 = $tiProc3.Threads | Select-Object -First 1 -ExpandProperty Id
            if ($tiThreadId3) {
                $hTh3 = [TIToken]::OpenThread([TIToken]::THREAD_DIRECT_IMPERSONATION, $false, [int]$tiThreadId3)
                if ($hTh3 -ne [IntPtr]::Zero) {
                    try {
                        $sqos3 = New-Object TIToken+SECURITY_QUALITY_OF_SERVICE
                        $sqos3.Length = [Runtime.InteropServices.Marshal]::SizeOf([type]"TIToken+SECURITY_QUALITY_OF_SERVICE")
                        $sqos3.ImpersonationLevel = [TIToken]::SecurityImpersonation
                        $sqos3.ContextTrackingMode = 1
                        $sqos3.EffectiveOnly = 0
                        $st3 = [TIToken]::NtImpersonateThread([TIToken]::GetCurrentThread(), $hTh3, [ref]$sqos3)
                        if ($st3 -eq 0) {
                            try { Set-ItemProperty $EXP RunAs 'Interactive User' -Force -ErrorAction SilentlyContinue } catch {}
                            [TIToken]::RevertToSelf() | Out-Null
                        }
                    } finally { [TIToken]::CloseHandle($hTh3) | Out-Null }
                }
            }
        }
    }

    "Acquiring TrustedInstaller token..." | Out-File $logFile -Append
    Enable-TIPrivilege -Name "SeDebugPrivilege" | Out-Null
    Enable-TIPrivilege -Name "SeImpersonatePrivilege" | Out-Null
    Enter-SystemImpersonation
    $tiToken = Get-TITokenHandle
    [TIToken]::RevertToSelf() | Out-Null
    "TrustedInstaller token acquired" | Out-File $logFile -Append

    if (!$cmd) { $cmd = 'C:\' }

    # Anchored to a bareword prefix, not a substring match - a direct .exe
    # target is always fully-quoted, so this avoids misrouting e.g. a
    # selected explorer.exe/cmd.exe itself into the folder-open/shell handling.
    $isExplorer = $cmd -match '(?i)^\s*explorer(\.exe)?(\s|$)'
    $isCMD = $cmd -match '(?i)^\s*cmd(\.exe)?(\s|$)'

    "Launching: $cmd" | Out-File $logFile -Append

    if ($isCMD) {
        $cmdArgs = $cmd -replace '^\s*cmd(\.exe)?\s*',''
        $cmdArgs = $cmdArgs.Trim()
        $scriptDirEscaped = $scriptDir -replace '"','""'
        $cdCommand = "cd /d `"$scriptDirEscaped`""
        $titleForCmd = $msgTitle -replace '"','""'
        # User's actual target shell - always visible, stays open (/k).
        if (!$cmdArgs -or $cmdArgs -eq '' -or $cmdArgs -eq '/k') {
            $argList = "/k $cdCommand && title `"$titleForCmd`""
        } else {
            $argList = "/k $cdCommand && $cmdArgs && title `"$titleForCmd`""
        }
        "CMD args: $argList" | Out-File $logFile -Append
        "CMD title: $msgTitle" | Out-File $logFile -Append
        "CMD working dir: $scriptDir" | Out-File $logFile -Append
        try {
            Start-ProcessAsTI -CommandLine "`"$env:SystemRoot\System32\cmd.exe`" $argList" | Out-Null
        } catch {
            "CMD launch (isCMD) failed: $($_.Exception.Message)" | Out-File $logFile -Append
        }
    } elseif ($isExplorer) {
        if ($cmd -match 'explorer\.exe\s+"?([^"]+)"?') {
            $explorerPath = $matches[1]
        } elseif ($cmd -match 'explorer\.exe\s+(.+)') {
            $explorerPath = $matches[1].Trim('"')
        } else {
            $explorerPath = $env:USERPROFILE
        }
        "Explorer path: $explorerPath" | Out-File $logFile -Append
        Start-ExplorerAsTI -Path $explorerPath
    } else {
        $effectiveWorkDir = $scriptDir
        "Effective working dir: $effectiveWorkDir" | Out-File $logFile -Append

        # Includes ISE: BuildPs1Command quotes it ("powershell_ise.exe" "path"),
        # which the generic cmd /c fallback below would mangle (4 quote chars
        # confuses cmd's own quote-stripping), so route it here directly.
        $isPowerShell = ($cmd -match '(?i)^\s*powershell(\.exe)?(\s|$)') -or ($cmd -like '*ise.exe*')

        if ($isPowerShell) {
            "Launching PowerShell..." | Out-File $logFile -Append
            $psExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

            if ($cmd -match '^powershell\s+-NoExit') {
                $wdEsc = $effectiveWorkDir -replace '"','""'
                $psArgs = "-NoExit -NoProfile -Command `"Set-Location '$wdEsc'; `$host.UI.RawUI.WindowTitle = '$msgTitle'`""
                Start-ProcessAsTI -CommandLine "`"$psExe`" $psArgs" -CurrentDirectory $effectiveWorkDir | Out-Null
            } elseif ($cmd -like "*powershell_ise*" -or $cmd -like "*ise.exe*") {
                $iseExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell_ise.exe"
                $iseArgs = ''

                if ($cmd -match '(?i)^\s*"?([^\"]*powershell_ise\.exe)"?\s*(.*)$') {
                    $iseExe = $matches[1]
                    $iseArgs = $matches[2].Trim()
                } elseif ($cmd -match '(?i)^\s*"?([^\"]*ise\.exe)"?\s*(.*)$') {
                    $iseExe = $matches[1]
                    $iseArgs = $matches[2].Trim()
                }

                Start-ProcessAsTI -CommandLine "`"$iseExe`" $iseArgs" -CurrentDirectory $effectiveWorkDir | Out-Null
            } else {
                $psArgs = $cmd -replace '^\s*powershell(\.exe)?\s*',''
                Start-ProcessAsTI -CommandLine "`"$psExe`" $psArgs" -CurrentDirectory $effectiveWorkDir | Out-Null
            }
        } elseif ($cmd -match '^\s*"?((?:[A-Za-z]:\\|\\\\)[^\"]+\.exe)"?\s*(.*)$') {
            $exePath = $matches[1]
            $exeArgs = $matches[2]
            "Launching EXE: $exePath" | Out-File $logFile -Append
            if ($exeArgs) { "EXE args: $exeArgs" | Out-File $logFile -Append }
            Start-ProcessAsTI -CommandLine "`"$exePath`" $exeArgs" -CurrentDirectory $effectiveWorkDir | Out-Null
        } else {
            $argString = "/c $cmd"
            "Launching via CMD: $argString" | Out-File $logFile -Append
            Start-ProcessAsTI -CommandLine "`"$env:SystemRoot\System32\cmd.exe`" $argString" -CurrentDirectory $effectiveWorkDir | Out-Null
        }
    }

    try {
        $progressPidFile = "$env:TEMP\TI_Progress.pid"
        $progressPid = $env:TI_PROGRESS_PID
        if (-not $progressPid) {
            try { $progressPid = (Get-Content -LiteralPath $progressPidFile -ErrorAction SilentlyContinue | Select-Object -First 1).Trim() } catch {}
        }
        if ($progressPid) {
            $p = Get-Process -Id ([int]$progressPid) -ErrorAction SilentlyContinue
            if ($p) { $p.Kill() }
            $env:TI_PROGRESS_PID = $null
        }

        $progressPath = $env:TI_PROGRESS_FILE
        if (-not $progressPath) { $progressPath = "$env:TEMP\TI_Progress.ps1" }
        if ($progressPath -and (Test-Path -LiteralPath $progressPath)) {
            Remove-Item $progressPath -Force -ErrorAction SilentlyContinue
            $env:TI_PROGRESS_FILE = $null
        }

        try {
            Get-WmiObject Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
                Where-Object { $_.CommandLine -like "*TI_Progress.ps1*" } |
                ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
        } catch {}
        try { if (Test-Path -LiteralPath $progressPidFile) { Remove-Item -LiteralPath $progressPidFile -Force -ErrorAction SilentlyContinue } } catch {}
    } catch {}

    "Payload completed successfully" | Out-File $logFile -Append

} catch {
    "EXCEPTION: $($_.Exception.Message)" | Out-File $logFile -Append
    "Stack: $($_.ScriptStackTrace)" | Out-File $logFile -Append
    $host.ui.WriteErrorLine("Error: $($_.Exception.Message)")
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show("Hata (Arka Plan):`n`n$($_.Exception.Message)`n`nLutfen bu hatayi bildirin.", "TI Error", 0, 16) | Out-Null
    } catch {}
    throw
}
'@
$payload = $payload -replace 'MSG_TITLE_PLACEHOLDER', $msgTitleEscaped
$payload = $payload -replace 'SCRIPT_DIR_PLACEHOLDER', $scriptDirEscaped

try {
    "Creating temp payload file..." | Out-File $logFile -Append
    $a1 = "`$id='$id';"
    $a2 = "`$cmd='$($cmd -replace "'", "''")';`$msgTitle='$($msgTitle -replace "'", "''")';"
    $a3 = "`$scriptDir='$($scriptDir -replace "'", "''")';"
    $tempFile = "$env:TEMP\$id.ps1"
    $scriptContent = "$a1`n$a2`n$a3`n$payload"
    $scriptContent | Out-File $tempFile -Encoding UTF8
    "Payload written to $tempFile" | Out-File $logFile -Append

    $arg = "try { & `'$tempFile`' } catch { ('EXEC ERROR: ' + `$_.Exception.Message) | Out-File `$env:TEMP\TI_Boot.log -Append; Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Boot Hata:' + [Environment]::NewLine + `$_.Exception.Message, 'TI Boot Error', 0, 16) } finally { Remove-Item `'$tempFile`' -Force -ErrorAction SilentlyContinue }"

    "Launching elevated PowerShell..." | Out-File $logFile -Append
    Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$arg`"" -Verb RunAs -Wait

} catch {
    "RunAsTI Exception: $($_.Exception.Message)" | Out-File $logFile -Append
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Hata oluştu!`n`nDetay: $($_.Exception.Message)`n`nLog: $logFile", "TI Launcher Error", 0, 16)
} finally {
try {
$progressPidFile = "$env:TEMP\TI_Progress.pid"
$progressPid = $env:TI_PROGRESS_PID
if (-not $progressPid) {
    try { $progressPid = (Get-Content -LiteralPath $progressPidFile -ErrorAction SilentlyContinue | Select-Object -First 1).Trim() } catch {}
}
if ($progressPid) {
    $p = Get-Process -Id ([int]$progressPid) -ErrorAction SilentlyContinue
    if ($p) { $p.Kill() }
    $env:TI_PROGRESS_PID = $null
}

$progressPath = $env:TI_PROGRESS_FILE
if (-not $progressPath) { $progressPath = "$env:TEMP\TI_Progress.ps1" }
if ($progressPath -and (Test-Path -LiteralPath $progressPath)) {
    Remove-Item $progressPath -Force -ErrorAction SilentlyContinue
    $env:TI_PROGRESS_FILE = $null
}

try {
    Get-WmiObject Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*TI_Progress.ps1*" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
} catch {}
try { if (Test-Path -LiteralPath $progressPidFile) { Remove-Item -LiteralPath $progressPidFile -Force -ErrorAction SilentlyContinue } } catch {}
} catch {}
}
}

#endregion TI_CORE_RUNASTI

if (!$param -or ($param -and $param.Trim() -eq '')) {
$argv = [Environment]::GetCommandLineArgs()
if ($argv.Length -gt 1) {
$candidate = $argv[-1]
if ($candidate -and ($candidate -ne $env:SCRIPT_PATH) -and (Test-Path -LiteralPath $candidate)) {
$param = $candidate
}
}
}

if ($param -and $param.Trim() -ne '')
{
$targetFile = $param.Trim()
if ($targetFile -match '^\s*"(.*)"\s*$') { $targetFile = $matches[1] }
Log "Drag/drop param detected: $targetFile"

# A trailing backslash before a quote gets eaten as an escaped quote across
# the bootstrap hops (C:\ -> C:", C:""), so strip quotes/whitespace and
# restore the canonical X:\ form when only a drive letter remains.
$driveProbe = ($targetFile -replace '"', '').Trim()
if ($driveProbe -match '^([A-Za-z]):\\*$') {
$targetFile = $matches[1] + ':\'
Log "Normalized drive-root param to: $targetFile"
}

# If context-menu passes a combined string like: /ps1action:ps-ti C:\Path\Script.ps1
# normalize it here so the rest of the script treats it as a real path.
try {
    if ($targetFile -match '(?i)^\s*/ps1action[:=]([^\s\"]+)\s+(.+)$') {
        $act = $matches[1]
        $maybePath = $matches[2]
        $maybePath = ($maybePath | Out-String).Trim()
        if ($maybePath -match '^\s*"(.*)"\s*$') { $maybePath = $matches[1] }

        # If $args exists (common when invoked via batch wrapper), prefer joining non-ps1action args
        try {
            if ($args -and $args.Count -ge 2) {
                $joined = (($args | Where-Object { $_ -and ($_ -notmatch '^/ps1action[:=]') }) -join ' ')
                if ($joined) { $maybePath = $joined }
            }
        } catch {}

        # Last-resort: pick trailing drive path ending with .ps1
        if ($maybePath -match '(?i)([A-Za-z]:\\.*\.ps1)\s*$') { $maybePath = $matches[1] }

        if ($maybePath -and (Test-Path -LiteralPath $maybePath)) {
            $ps1Action = $act
            $param = $maybePath
            $targetFile = $maybePath
            Log "Normalized ps1Action call: action=$ps1Action; path=$targetFile"
        } else {
            Log "ps1Action normalize failed. act=$act; maybePath=$maybePath"
        }
    }
} catch {
    try { Log "ps1Action normalize exception: $($_.Exception.Message)" } catch {}
}


if ($targetFile -match '^([A-Za-z]):\\?$') {
$driveLetter = $matches[1]
Log "Detected drive: $driveLetter"
$driveRoot = "${driveLetter}:\"
$driveCmd = "explorer.exe `"$driveRoot`""
Log "Launching with: $driveCmd"
RunAsTI $driveCmd $driveRoot $null
} elseif (Test-Path -LiteralPath $targetFile) {
try {
$fullPath = (Resolve-Path -LiteralPath $targetFile).Path
} catch {
$fullPath = $targetFile
}
Log "Resolved path: $fullPath"
$fullPathEsc = $fullPath -replace '"','""'

try {
$item = Get-Item -LiteralPath $fullPath -ErrorAction Stop
if ($item.PSIsContainer) {
Log "Detected folder; launching explorer directly"
$folderCmd = "explorer.exe `"$fullPathEsc`""
Log "Launching with: $folderCmd"
RunAsTI $folderCmd $fullPath $null
} else {
$ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
Log "Detected file; ext=$ext"

if ($ext -eq '.lnk') {
Log "Detected shortcut file, resolving target..."
try {
$scInfo = Resolve-ShortcutTarget -ShortcutPath $fullPath
$targetPath = $scInfo.TargetPath
$arguments = $scInfo.Arguments
$workingDir = $scInfo.WorkingDirectory
$resolvedTarget = $scInfo.ResolvedTargetPath
$method = $scInfo.ResolutionMethod

Log "Shortcut target: $targetPath"
Log "Shortcut arguments: $arguments"
Log "Shortcut working dir: $workingDir"
if ($resolvedTarget) {
Log "Shortcut resolved target: $resolvedTarget (method=$method)"
}

if ((-not $resolvedTarget -or $resolvedTarget.Trim() -eq '')) {
if ($arguments -and $arguments.Trim() -ne '') {
Log "Shortcut target could not be resolved; trying Arguments as command: $arguments"
RunAsTI $arguments $fullPath $workingDir
return
}
}

if ($resolvedTarget -and ([System.IO.File]::Exists($resolvedTarget) -or (Test-Path -LiteralPath $resolvedTarget -PathType Leaf -ErrorAction SilentlyContinue))) {
$resolvedTargetEsc = $resolvedTarget -replace '"','""'
if ($arguments -and $arguments.Trim() -ne '') {
$cmdToRun = "`"$resolvedTargetEsc`" $arguments"
} else {
$cmdToRun = "`"$resolvedTargetEsc`""
}

Log "Launching shortcut target with: $cmdToRun"
RunAsTI $cmdToRun $resolvedTarget $workingDir
} else {
Log "Shortcut target not found or invalid (resolvedTarget=$resolvedTarget; originalTarget=$targetPath)"

$hint = ""
if ($workingDir) { $hint += "`nWorkingDirectory: $workingDir" }
if ($targetPath) { $hint += "`nTarget: $targetPath" }
$hint += "`n`nÇözüm: EXE taşındıysa kısayolun hedefini güncelleyin veya EXE'nin bulunduğu klasörü WorkingDirectory olarak ayarlayın."

throw ("Kısayol hedefi bulunamadı: $targetPath" + $hint)
}
} catch {
Log "Error resolving shortcut: $($_.Exception.Message)"
throw "Kısayol çözümlenemedi: $($_.Exception.Message)"
}
} else {
switch ($ext) {
'.exe' { $cmdToRun = "`"$fullPathEsc`"" }
'.bat' { $cmdToRun = "`"$fullPathEsc`"" }
'.cmd' { $cmdToRun = "`"$fullPathEsc`"" }
'.reg' { $cmdToRun = "reg import `"$fullPathEsc`"" }
'.ps1' {
if ($ps1Action) {
$cmdToRun = BuildPs1Command -Action $ps1Action -FilePath $fullPath
} else {
$cmdToRun = "powershell -ExecutionPolicy Bypass -File `"$fullPathEsc`""
}
}
'.msc' { $cmdToRun = "`"$fullPathEsc`"" }
'.cpl' { $cmdToRun = "control `"$fullPathEsc`"" }
default { $cmdToRun = "`"$fullPathEsc`"" }
}
Log "Launching with: $cmdToRun"


# Always visible - these are the user's requested target, not launcher UI.
if ($ext -eq '.ps1' -and $ps1Action) {
switch ($ps1Action.ToLower()) {
'ps-run' {
Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$fullPathEsc`"") -WorkingDirectory (Split-Path -Parent $fullPath) -WindowStyle Normal
}
'ps-admin' {
Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$fullPathEsc`"") -WorkingDirectory (Split-Path -Parent $fullPath) -WindowStyle Normal -Verb RunAs
}
'ps-ti' {
RunAsTI $cmdToRun $fullPath $null
}
'ise-open' {
Start-Process -FilePath "powershell_ise.exe" -ArgumentList ("`"$fullPathEsc`"") -WorkingDirectory (Split-Path -Parent $fullPath) -WindowStyle Normal
}
'ise-admin' {
Start-Process -FilePath "powershell_ise.exe" -ArgumentList ("`"$fullPathEsc`"") -WorkingDirectory (Split-Path -Parent $fullPath) -WindowStyle Normal -Verb RunAs
}
'ise-ti' {
RunAsTI $cmdToRun $fullPath $null
}
'ise-open-x86' {
$iseX86 = "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell_ise.exe"
Start-Process -FilePath $iseX86 -ArgumentList ("`"$fullPathEsc`"") -WorkingDirectory (Split-Path -Parent $fullPath) -WindowStyle Normal
}
'ise-admin-x86' {
$iseX86 = "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell_ise.exe"
Start-Process -FilePath $iseX86 -ArgumentList ("`"$fullPathEsc`"") -WorkingDirectory (Split-Path -Parent $fullPath) -WindowStyle Normal -Verb RunAs
}
'ise-ti-x86' {
$cmdToRun = BuildPs1Command -Action $ps1Action -FilePath $fullPath
RunAsTI $cmdToRun $fullPath $null
}
'notepad-open' {
Start-Process -FilePath notepad.exe -ArgumentList @($fullPath) -WorkingDirectory (Split-Path -Parent $fullPath) -WindowStyle Normal
}
'notepad-admin' {
Start-Process -FilePath notepad.exe -ArgumentList @($fullPath) -WorkingDirectory (Split-Path -Parent $fullPath) -WindowStyle Normal -Verb RunAs
}
'notepad-ti' {
RunAsTI $cmdToRun $fullPath $null
}
default {
RunAsTI $cmdToRun $fullPath $null
}
}
} else {
RunAsTI $cmdToRun $fullPath $null
}
}
}
} catch {
Log "Error processing path: $($_.Exception.Message)"

if ($targetFile -match '^([A-Za-z]):\\?$' -and $targetFile.Length -le 3) {
$driveLetter = $matches[1]
$driveRoot = "${driveLetter}:\"
$driveCmd = "explorer.exe `"$driveRoot`""
Log "Launching drive with: $driveCmd"
RunAsTI $driveCmd $driveRoot $null
} else {
throw
}
}
} else {
Log "Param is not a path; running as command"
RunAsTI "$targetFile" $null $null
}
} else {
Log "No param; showing popup flow"
Add-Type -AssemblyName System.Windows.Forms

function Show-TopMostMessageBox {
param([string]$Message,[string]$Title,[int]$Buttons,[int]$Icon)

$mbType = $Buttons + $Icon + 0x00040000  # MB_TOPMOST

try {
            $code = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern int MessageBox(IntPtr hWnd, String text, String caption, uint type);
}
"@
try { Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue } catch {}

if ("Win32" -as [type]) {
return [Win32]::MessageBox([IntPtr]::Zero, $Message, $Title, [uint32]$mbType)
}
} catch {
}

try {
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
$btn = switch ($Buttons) {
0 { [System.Windows.Forms.MessageBoxButtons]::OK }
4 { [System.Windows.Forms.MessageBoxButtons]::YesNo }
3 { [System.Windows.Forms.MessageBoxButtons]::YesNoCancel }
default { [System.Windows.Forms.MessageBoxButtons]::OK }
}
$ico = switch ($Icon) {
16 { [System.Windows.Forms.MessageBoxIcon]::Error }
32 { [System.Windows.Forms.MessageBoxIcon]::Question }
48 { [System.Windows.Forms.MessageBoxIcon]::Warning }
64 { [System.Windows.Forms.MessageBoxIcon]::Information }
default { [System.Windows.Forms.MessageBoxIcon]::Information }
}

return [System.Windows.Forms.MessageBox]::Show($Message, $Title, $btn, $ico)
} catch {
return 0
}
}

function Show-TopMostChoiceDialog {
param(
[Parameter(Mandatory=$true)][string]$Message,
[Parameter(Mandatory=$true)][string]$Title,
[Parameter(Mandatory=$true)][string]$YesText,
[Parameter(Mandatory=$true)][string]$NoText,
[string]$CancelText = "",
[switch]$ShowCancel,
[int]$Icon = 32
)

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

        $uiCode = @"
using System;
using System.Runtime.InteropServices;
public class Win32UI {
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
    [DllImport("gdi32.dll")] public static extern IntPtr CreateRoundRectRgn(int nLeftRect, int nTopRect, int nRightRect, int nBottomRect, int nWidthEllipse, int nHeightEllipse);
    [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr hObject);
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern int ExtractIconEx(string file, int index, IntPtr[] large, IntPtr[] small, int icons);
    [DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
}
"@
try { Add-Type -TypeDefinition $uiCode -ErrorAction SilentlyContinue } catch {}

function New-GeneratedIconBitmap {
param(
[int]$Icon,
[int]$Size = 44,
[string]$Variant = ""
)

if (-not $Variant -or $Variant.Trim() -eq '') {
switch ($Icon) {
16 { $Variant = 'error' }
48 { $Variant = 'warning' }
64 { $Variant = 'check' }
default { $Variant = 'check' }
}
}

$bmp = New-Object System.Drawing.Bitmap($Size, $Size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g.Clear([System.Drawing.Color]::Transparent)

function New-RoundedRectPath {
param([int]$x,[int]$y,[int]$w,[int]$h,[int]$r)
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$d = $r * 2
$path.AddArc($x, $y, $d, $d, 180, 90) | Out-Null
$path.AddArc($x + $w - $d, $y, $d, $d, 270, 90) | Out-Null
$path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90) | Out-Null
$path.AddArc($x, $y + $h - $d, $d, $d, 90, 90) | Out-Null
$path.CloseFigure() | Out-Null
return $path
}

# Fallback icon if imageres.dll,-78 can't be extracted; splash's green.
$p1 = [System.Drawing.Color]::FromArgb(80, 200, 120)  # #50c878
$p2 = [System.Drawing.Color]::FromArgb(20, 90, 55)    # #145a37
$stroke = $p1

$pad = [Math]::Max(3, [Math]::Floor($Size * 0.08))
$rx = [Math]::Max(8, [Math]::Floor($Size * 0.24))
$rect = New-Object System.Drawing.Rectangle($pad, $pad, ($Size - ($pad*2)), ($Size - ($pad*2)))

$path = New-RoundedRectPath -x $rect.X -y $rect.Y -w $rect.Width -h $rect.Height -r $rx

foreach ($w in @(10, 7, 4)) {
$alpha = [int]([Math]::Max(20, 110 - ($w * 10)))
$glowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha, $p1), $w)
$glowPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$g.DrawPath($glowPen, $path)
$glowPen.Dispose()
}

$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $p1, $p2, 45)
$g.FillPath($brush, $path)
$brush.Dispose()

$pen = New-Object System.Drawing.Pen($stroke, 2)
$pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$g.DrawPath($pen, $path)
$pen.Dispose()

$white = [System.Drawing.Color]::White
$symbolPen = New-Object System.Drawing.Pen($white, [Math]::Max(3, [Math]::Floor($Size*0.075)))
$symbolPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$symbolPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$symbolPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

if ($Variant -eq 'check') {
$x1 = $Size * 0.30
$y1 = $Size * 0.52
$x2 = $Size * 0.42
$y2 = $Size * 0.64
$x3 = $Size * 0.70
$y3 = $Size * 0.38

$gp = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(140, $white), ($symbolPen.Width + 3))
$gp.StartCap = $symbolPen.StartCap; $gp.EndCap = $symbolPen.EndCap; $gp.LineJoin = $symbolPen.LineJoin
$g.DrawLines($gp, @(
(New-Object System.Drawing.PointF($x1,$y1)),
(New-Object System.Drawing.PointF($x2,$y2)),
(New-Object System.Drawing.PointF($x3,$y3))
))
$gp.Dispose()

$g.DrawLines($symbolPen, @(
(New-Object System.Drawing.PointF($x1,$y1)),
(New-Object System.Drawing.PointF($x2,$y2)),
(New-Object System.Drawing.PointF($x3,$y3))
))
}
elseif ($Variant -eq 'cmd') {
$text = 'C:\>'
$fontSize = [Math]::Max(11, [Math]::Floor($Size*0.30))
$font = New-Object System.Drawing.Font('Consolas', $fontSize, [System.Drawing.FontStyle]::Bold)
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = 'Center'
$sf.LineAlignment = 'Center'

$tb = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, $white))
$g.DrawString($text, $font, $tb, (New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)), $sf)
$tb.Dispose()

$b = New-Object System.Drawing.SolidBrush($white)
$g.DrawString($text, $font, $b, (New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)), $sf)
$b.Dispose(); $sf.Dispose(); $font.Dispose()
}
elseif ($Variant -eq 'ps') {
$text = 'PS>'
$fontSize = [Math]::Max(11, [Math]::Floor($Size*0.30))
$font = New-Object System.Drawing.Font('Consolas', $fontSize, [System.Drawing.FontStyle]::Bold)
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = 'Center'
$sf.LineAlignment = 'Center'

$tb = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, $white))
$g.DrawString($text, $font, $tb, (New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)), $sf)
$tb.Dispose()

$b = New-Object System.Drawing.SolidBrush($white)
$g.DrawString($text, $font, $b, (New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)), $sf)
$b.Dispose(); $sf.Dispose(); $font.Dispose()
}
elseif ($Variant -eq 'warning') {
$fontSize = [Math]::Max(16, [Math]::Floor($Size*0.56))
$font = New-Object System.Drawing.Font('Segoe UI Semibold', $fontSize)
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = 'Center'
$sf.LineAlignment = 'Center'

$tb = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, $white))
$g.DrawString('!', $font, $tb, (New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)), $sf)
$tb.Dispose()

$b = New-Object System.Drawing.SolidBrush($white)
$g.DrawString('!', $font, $b, (New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)), $sf)
$b.Dispose(); $sf.Dispose(); $font.Dispose()
}
elseif ($Variant -eq 'error') {
$m = [Math]::Floor($Size*0.30)
$gp = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, $white), ($symbolPen.Width + 3))
$gp.StartCap = $symbolPen.StartCap; $gp.EndCap = $symbolPen.EndCap; $gp.LineJoin = $symbolPen.LineJoin
$g.DrawLine($gp, $m, $m, $Size-$m, $Size-$m)
$g.DrawLine($gp, $Size-$m, $m, $m, $Size-$m)
$gp.Dispose()

$g.DrawLine($symbolPen, $m, $m, $Size-$m, $Size-$m)
$g.DrawLine($symbolPen, $Size-$m, $m, $m, $Size-$m)
}
else {
$Variant = 'check'
$x1 = $Size * 0.30
$y1 = $Size * 0.52
$x2 = $Size * 0.42
$y2 = $Size * 0.64
$x3 = $Size * 0.70
$y3 = $Size * 0.38
$g.DrawLines($symbolPen, @(
(New-Object System.Drawing.PointF($x1,$y1)),
(New-Object System.Drawing.PointF($x2,$y2)),
(New-Object System.Drawing.PointF($x3,$y3))
))
}

$symbolPen.Dispose()
$path.Dispose()
$g.Dispose()
return $bmp
}

function Get-UiIconBitmap {
param([int]$Icon,[int]$Size=44,[string]$Variant='')

$baseDir = if ($env:SCRIPT_PATH) { Split-Path -Parent $env:SCRIPT_PATH } else { $PWD.Path }
$fileName = switch ($Icon) {
16 { 'ti-error.png' }
48 { 'ti-warning.png' }
64 { 'ti-info.png' }
default { 'ti-question.png' }
}
$candidate = Join-Path $baseDir $fileName
try {
if (Test-Path $candidate) {
return [System.Drawing.Image]::FromFile($candidate)
}
} catch {}

# Same icon as splash/context-menu (imageres.dll,-78) for brand consistency.
try {
$large = New-Object IntPtr[] 1
$small = New-Object IntPtr[] 1
$n = [Win32UI]::ExtractIconEx("$env:SystemRoot\System32\imageres.dll", -78, $large, $small, 1)
if ($n -gt 0 -and $large[0] -ne [IntPtr]::Zero) {
$sysIcon = [System.Drawing.Icon]::FromHandle($large[0])
return $sysIcon.ToBitmap()
}
} catch {}

return New-GeneratedIconBitmap -Icon $Icon -Size $Size -Variant $Variant
}

# Dark theme matching the splash.
$bg = [System.Drawing.Color]::FromArgb(32, 32, 32)
$text = [System.Drawing.Color]::White
$muted = [System.Drawing.Color]::FromArgb(170, 170, 170)
$accent = [System.Drawing.Color]::FromArgb(80, 200, 120)
$accentHover = [System.Drawing.Color]::FromArgb(100, 220, 140)
$btnBg = [System.Drawing.Color]::FromArgb(45, 45, 45)
$btnBorder = [System.Drawing.Color]::FromArgb(70, 70, 70)

$btnCount = if ($ShowCancel) { 3 } else { 2 }
$formW = 480
$formH = if ($btnCount -eq 3) { 260 } else { 200 }

$form = New-Object System.Windows.Forms.Form
$form.Text = $Title
$form.StartPosition = 'CenterScreen'
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.FormBorderStyle = 'None'
$form.BackColor = $bg
$form.ClientSize = New-Object System.Drawing.Size($formW, $formH)
$form.Opacity = 0
$form.KeyPreview = $true

# DWMWA_WINDOW_CORNER_PREFERENCE (Win11+) gives properly anti-aliased
# corners; a GDI Region clip (fallback for older Windows) is hard-edged
# and looks jagged/blurry, especially once scaled by DPI.
$dwmRounded = $false
try {
$pref = 2 # DWMWCP_ROUND
if ([Win32UI]::DwmSetWindowAttribute($form.Handle, 33, [ref]$pref, 4) -eq 0) { $dwmRounded = $true }
} catch {}
if (-not $dwmRounded) {
try {
$hr = [Win32UI]::CreateRoundRectRgn(0, 0, $form.Width + 1, $form.Height + 1, 14, 14)
$form.Region = [System.Drawing.Region]::FromHrgn($hr)
[Win32UI]::DeleteObject($hr) | Out-Null
} catch {}
}

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(14, 12)
$titleLabel.Size = New-Object System.Drawing.Size(260, 16)
$titleLabel.Text = $Title
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 8.5)
$titleLabel.ForeColor = $text
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($titleLabel)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = [char]0x2715
$btnClose.Font = New-Object System.Drawing.Font('Segoe UI', 7.5)
$btnClose.FlatStyle = 'Flat'
$btnClose.FlatAppearance.BorderSize = 0
$btnClose.FlatAppearance.MouseOverBackColor = $btnBg
$btnClose.BackColor = $bg
$btnClose.ForeColor = $muted
$btnClose.Size = New-Object System.Drawing.Size(24, 20)
$btnClose.Location = New-Object System.Drawing.Point(($formW - 32), 8)
$btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnClose.Add_Click({ $form.Tag = 2; $form.Close() })
$form.Controls.Add($btnClose)

$dragHandler = {
try {
[void][Win32UI]::ReleaseCapture()
[void][Win32UI]::SendMessage($form.Handle, 0xA1, 0x2, 0)
} catch {}
}
$form.Add_MouseDown($dragHandler)
$titleLabel.Add_MouseDown($dragHandler)

$pic = New-Object System.Windows.Forms.PictureBox
$pic.Location = New-Object System.Drawing.Point(14, 38)
$pic.Size = New-Object System.Drawing.Size(30, 30)
$pic.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$pic.BackColor = [System.Drawing.Color]::Transparent
$variant = ''
if ($Title -match '(?i)cmd') { $variant = 'cmd' }
elseif ($Title -match '(?i)powershell|ise') { $variant = 'ps' }
elseif ($Title -match '(?i)install|kurulum|kuru|uninstall|kaldır') { $variant = 'check' }
elseif ($Icon -eq 48) { $variant = 'warning' }
elseif ($Icon -eq 16) { $variant = 'error' }
else { $variant = 'check' }

$pic.Image = Get-UiIconBitmap -Icon $Icon -Size 30 -Variant $variant
$form.Controls.Add($pic)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(52, 38)
$labelHeight = if ($btnCount -eq 3) { 140 } else { 100 }
$label.Size = New-Object System.Drawing.Size(($formW - 66), $labelHeight)
$label.Text = $Message
$label.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
$label.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$label.BackColor = [System.Drawing.Color]::Transparent
$label.AutoSize = $false
$form.Controls.Add($label)

$btnYes = New-Object System.Windows.Forms.Button
$btnNo = New-Object System.Windows.Forms.Button
$btnCancel = New-Object System.Windows.Forms.Button

$btnH = 28
$btnGap = 12
$sideMargin = 14
$btnW = [int](($formW - ($sideMargin*2) - ($btnGap*($btnCount-1))) / $btnCount)

foreach ($b in @($btnYes,$btnNo,$btnCancel)) {
$b.Size = New-Object System.Drawing.Size($btnW, $btnH)
$b.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$b.FlatStyle = 'Flat'
$b.FlatAppearance.BorderSize = 1
$b.FlatAppearance.BorderColor = $btnBorder
$b.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(58, 58, 58)
$b.BackColor = $btnBg
$b.ForeColor = $text
$b.Cursor = [System.Windows.Forms.Cursors]::Hand
try {
$bhr = [Win32UI]::CreateRoundRectRgn(0, 0, $b.Width + 1, $b.Height + 1, 8, 8)
$b.Region = [System.Drawing.Region]::FromHrgn($bhr)
[Win32UI]::DeleteObject($bhr) | Out-Null
} catch {}
}

$btnYes.Text = $YesText
$btnNo.Text = $NoText
$btnCancel.Text = $CancelText

$btnYes.BackColor = $accent
$btnYes.ForeColor = [System.Drawing.Color]::White
$btnYes.FlatAppearance.BorderColor = $accent
$btnYes.FlatAppearance.MouseOverBackColor = $accentHover

$btnYes.Add_Click({ $form.Tag = 6; $form.Close() })
$btnNo.Add_Click({ $form.Tag = 7; $form.Close() })
$btnCancel.Add_Click({ $form.Tag = 2; $form.Close() })

$y = $formH - $btnH - 28
$x = $sideMargin
$btnYes.Location = New-Object System.Drawing.Point($x, $y)
$x += $btnW + $btnGap
$btnNo.Location = New-Object System.Drawing.Point($x, $y)
if ($ShowCancel) {
$x += $btnW + $btnGap
$btnCancel.Location = New-Object System.Drawing.Point($x, $y)
$form.Controls.Add($btnCancel)
$form.CancelButton = $btnCancel
} else {
$form.CancelButton = $btnNo
}

$form.AcceptButton = $btnYes
$form.Controls.Add($btnYes)
$form.Controls.Add($btnNo)

$credit = New-Object System.Windows.Forms.Label
$credit.Text = "by Abdullah ERTÜRK"
$credit.ForeColor = $muted
$credit.Font = New-Object System.Drawing.Font('Segoe UI', 7)
$credit.AutoSize = $true
$credit.BackColor = [System.Drawing.Color]::Transparent
$credit.Cursor = [System.Windows.Forms.Cursors]::Hand
$credit.Add_Click({ [System.Diagnostics.Process]::Start("https://erturk-dev.netlify.app") | Out-Null; Start-Sleep -Milliseconds 100; [System.Diagnostics.Process]::Start("https://github.com/abdullah-erturk") })
$credit.Add_MouseEnter({ $credit.ForeColor = [System.Drawing.Color]::White })
$credit.Add_MouseLeave({ $credit.ForeColor = [System.Drawing.Color]::FromArgb(170,170,170) })
$form.Controls.Add($credit)
$credit.Location = New-Object System.Drawing.Point(($formW - $sideMargin - $credit.PreferredWidth), ($formH - 18))

$fadeTimer = New-Object System.Windows.Forms.Timer
$fadeTimer.Interval = 15
$fadeTimer.Add_Tick({
if ($form.Opacity -lt 1) { $form.Opacity += 0.12 } else { $fadeTimer.Stop() }
})
$form.Add_Shown({ $fadeTimer.Start() })

$form.Add_KeyDown({
if ($_.KeyCode -eq 'Escape') { $form.Tag = 2; $form.Close() }
})

try {
[void]$form.ShowDialog()
} catch {
if ($ShowCancel) {
$dr = [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
} else {
$dr = [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
}
switch ($dr) {
'Yes' { return 6 }
'No' { return 7 }
'Cancel' { return 2 }
default { return 2 }
}
}

if ($form.Tag) { return [int]$form.Tag }
return 2
}

function Show-TopMostOptionDialog {
param(
[Parameter(Mandatory=$true)][string]$Message,
[Parameter(Mandatory=$true)][string]$Title,
[Parameter(Mandatory=$true)][string[]]$Options,
[string]$RunText = ""
)

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

$uiCode = @"
using System;
using System.Runtime.InteropServices;
public class Win32UI {
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
    [DllImport("gdi32.dll")] public static extern IntPtr CreateRoundRectRgn(int nLeftRect, int nTopRect, int nRightRect, int nBottomRect, int nWidthEllipse, int nHeightEllipse);
    [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr hObject);
    [DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
}
"@
try { Add-Type -TypeDefinition $uiCode -ErrorAction SilentlyContinue } catch {}

if (-not $RunText) { $RunText = if ($isTurkish) { 'Çalıştır' } else { 'Run' } }

$bg = [System.Drawing.Color]::FromArgb(32, 32, 32)
$text = [System.Drawing.Color]::White
$muted = [System.Drawing.Color]::FromArgb(170, 170, 170)
$accent = [System.Drawing.Color]::FromArgb(80, 200, 120)
$accentHover = [System.Drawing.Color]::FromArgb(100, 220, 140)
$rowBg = [System.Drawing.Color]::FromArgb(45, 45, 45)
$rowBgSel = [System.Drawing.Color]::FromArgb(40, 62, 48)

$formW = 420
$rowH = 24
$rowGap = 5
$listTop = 66
$listHeight = ($Options.Count * ($rowH + $rowGap)) - $rowGap
$btnY = $listTop + $listHeight + 12
$formH = $btnY + 30 + 26

$form = New-Object System.Windows.Forms.Form
$form.Text = $Title
$form.StartPosition = 'CenterScreen'
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.FormBorderStyle = 'None'
$form.BackColor = $bg
$form.ClientSize = New-Object System.Drawing.Size($formW, $formH)
$form.Opacity = 0
$form.KeyPreview = $true

$dwmRounded = $false
try {
$pref = 2 # DWMWCP_ROUND
if ([Win32UI]::DwmSetWindowAttribute($form.Handle, 33, [ref]$pref, 4) -eq 0) { $dwmRounded = $true }
} catch {}
if (-not $dwmRounded) {
try {
$hr = [Win32UI]::CreateRoundRectRgn(0, 0, $form.Width + 1, $form.Height + 1, 14, 14)
$form.Region = [System.Drawing.Region]::FromHrgn($hr)
[Win32UI]::DeleteObject($hr) | Out-Null
} catch {}
}

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(12, 10)
$titleLabel.Size = New-Object System.Drawing.Size(($formW - 44), 16)
$titleLabel.Text = $Title
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 8.5)
$titleLabel.ForeColor = $text
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($titleLabel)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = [char]0x2715
$btnClose.Font = New-Object System.Drawing.Font('Segoe UI', 7.5)
$btnClose.FlatStyle = 'Flat'
$btnClose.FlatAppearance.BorderSize = 0
$btnClose.FlatAppearance.MouseOverBackColor = $rowBg
$btnClose.BackColor = $bg
$btnClose.ForeColor = $muted
$btnClose.Size = New-Object System.Drawing.Size(24, 20)
$btnClose.Location = New-Object System.Drawing.Point(($formW - 32), 8)
$btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnClose.Add_Click({ $form.Tag = -1; $form.Close() })
$form.Controls.Add($btnClose)

$dragHandler = {
try {
[void][Win32UI]::ReleaseCapture()
[void][Win32UI]::SendMessage($form.Handle, 0xA1, 0x2, 0)
} catch {}
}
$form.Add_MouseDown($dragHandler)
$titleLabel.Add_MouseDown($dragHandler)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(12, 32)
$label.Size = New-Object System.Drawing.Size(($formW - 24), 28)
$label.Text = $Message
$label.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
$label.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$label.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($label)

$radios = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $Options.Count; $i++) {
$row = New-Object System.Windows.Forms.Panel
$row.Location = New-Object System.Drawing.Point(12, ($listTop + ($i * ($rowH + $rowGap))))
$row.Size = New-Object System.Drawing.Size(($formW - 24), $rowH)
$row.BackColor = if ($i -eq 0) { $rowBgSel } else { $rowBg }
try {
$rhr = [Win32UI]::CreateRoundRectRgn(0, 0, $row.Width + 1, $row.Height + 1, 6, 6)
$row.Region = [System.Drawing.Region]::FromHrgn($rhr)
[Win32UI]::DeleteObject($rhr) | Out-Null
} catch {}

$rb = New-Object System.Windows.Forms.RadioButton
$rb.Text = $Options[$i]
$rb.Font = New-Object System.Drawing.Font('Segoe UI', 7.75)
$rb.ForeColor = $text
$rb.BackColor = [System.Drawing.Color]::Transparent
$rb.Location = New-Object System.Drawing.Point(6, 3)
$rb.Size = New-Object System.Drawing.Size(($formW - 40), 18)
$rb.Checked = ($i -eq 0)
$rb.Tag = $i
$row.Controls.Add($rb)

$rb.Add_CheckedChanged({
$r = $this.Parent
if ($r) { $r.BackColor = if ($this.Checked) { $rowBgSel } else { $rowBg } }
# RadioButtons only auto-exclude siblings sharing the same parent
# container; each option here has its own row Panel for independent
# background highlighting, so exclusivity has to be enforced by hand.
if ($this.Checked) {
foreach ($other in $radios) { if ($other -ne $this) { $other.Checked = $false } }
}
})
$row.Add_Click({ $this.Controls[0].Checked = $true })

$form.Controls.Add($row)
$radios.Add($rb)
}

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = $RunText
$btnRun.Size = New-Object System.Drawing.Size(($formW - 24), 28)
$btnRun.Location = New-Object System.Drawing.Point(12, $btnY)
$btnRun.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$btnRun.FlatStyle = 'Flat'
$btnRun.FlatAppearance.BorderSize = 1
$btnRun.FlatAppearance.BorderColor = $accent
$btnRun.FlatAppearance.MouseOverBackColor = $accentHover
$btnRun.BackColor = $accent
$btnRun.ForeColor = [System.Drawing.Color]::White
$btnRun.Cursor = [System.Windows.Forms.Cursors]::Hand
try {
$bhr = [Win32UI]::CreateRoundRectRgn(0, 0, $btnRun.Width + 1, $btnRun.Height + 1, 8, 8)
$btnRun.Region = [System.Drawing.Region]::FromHrgn($bhr)
[Win32UI]::DeleteObject($bhr) | Out-Null
} catch {}
$btnRun.Add_Click({
$form.Tag = 0
foreach ($r in $radios) { if ($r.Checked) { $form.Tag = [int]$r.Tag } }
$form.Close()
})
$form.Controls.Add($btnRun)
$form.AcceptButton = $btnRun

$credit = New-Object System.Windows.Forms.Label
$credit.Text = "by Abdullah ERTÜRK"
$credit.ForeColor = $muted
$credit.Font = New-Object System.Drawing.Font('Segoe UI', 7)
$credit.AutoSize = $true
$credit.BackColor = [System.Drawing.Color]::Transparent
$credit.Cursor = [System.Windows.Forms.Cursors]::Hand
$credit.Add_Click({ [System.Diagnostics.Process]::Start("https://erturk-dev.netlify.app") | Out-Null; Start-Sleep -Milliseconds 100; [System.Diagnostics.Process]::Start("https://github.com/abdullah-erturk") })
$credit.Add_MouseEnter({ $credit.ForeColor = [System.Drawing.Color]::White })
$credit.Add_MouseLeave({ $credit.ForeColor = [System.Drawing.Color]::FromArgb(170,170,170) })
$form.Controls.Add($credit)
$credit.Location = New-Object System.Drawing.Point(($formW - 12 - $credit.PreferredWidth), ($formH - 18))

$fadeTimer = New-Object System.Windows.Forms.Timer
$fadeTimer.Interval = 15
$fadeTimer.Add_Tick({ if ($form.Opacity -lt 1) { $form.Opacity += 0.12 } else { $fadeTimer.Stop() } })
$form.Add_Shown({ $fadeTimer.Start() })

$form.Add_KeyDown({ if ($_.KeyCode -eq 'Escape') { $form.Tag = -1; $form.Close() } })

try {
[void]$form.ShowDialog()
} catch {
return 0
}

if ($null -ne $form.Tag) { return [int]$form.Tag }
return -1
}

function Show-TopMostYesNo {
param([string]$Message,[string]$Title,[int]$Icon = 32)
$yesText = if ($isTurkish) { 'Evet' } else { 'Yes' }
$noText = if ($isTurkish) { 'Hayır' } else { 'No' }
return Show-TopMostChoiceDialog -Message $Message -Title $Title -YesText $yesText -NoText $noText -Icon $Icon
}

Log "Showing first popup"
try {
# X/Escape cover cancel, so no third button here.
$result = Show-TopMostChoiceDialog -Message $msg.PopupMsg -Title $msg.PopupTitle -YesText $msg.PopupYes -NoText $msg.PopupNo -Icon 64
} catch {
Log "TopMost popup failed, fallback: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
$result = [System.Windows.Forms.MessageBox]::Show($msg.PopupMsg, $msg.PopupTitle, 3, 64)
}
Log "First popup result: $result"

if ($result -eq 6) {
Log "Showing choice popup"
$choiceOptions = if ($isTurkish) {
@('CMD', 'PowerShell', 'PowerShell ISE', 'PowerShell ISE (x86)', 'Explorer', 'Kayıt Defteri Düzenleyicisi (Regedit)')
} else {
@('CMD', 'PowerShell', 'PowerShell ISE', 'PowerShell ISE (x86)', 'Explorer', 'Registry Editor (Regedit)')
}
$choiceMsgShort = if ($isTurkish) { 'Yükseltilmiş yetkiyle çalıştırılacak aracı seçin.' } else { 'Select the tool to run with elevated privileges.' }
try {
$choiceIdx = Show-TopMostOptionDialog -Message $choiceMsgShort -Title $msg.ChoiceTitle -Options $choiceOptions
} catch {
Log "Option dialog failed, fallback: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
$choiceIdx = 0
}
Log "User chose option index: $choiceIdx"

switch ($choiceIdx) {
0 { RunAsTI "cmd /k" $null $null }
1 { RunAsTI "powershell -NoExit" $null $null }
2 { RunAsTI "powershell_ise.exe" $null $null }
3 { RunAsTI "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell_ise.exe" $null $null }
4 {
$explorerPath = if ($env:SCRIPT_PATH) {
$scriptDir = Split-Path -Parent $env:SCRIPT_PATH
if (Test-Path $scriptDir -PathType Container) { $scriptDir } else { $env:USERPROFILE }
} else { $env:USERPROFILE }
RunAsTI "explorer.exe `"$explorerPath`"" $explorerPath $null
}
5 { RunAsTI "regedit.exe" $null $null }
default { Log "Choice dialog cancelled" }
}
#region TI_CORE_INSTALL

} elseif ($result -eq 7) {
Log "User chose install/uninstall path"
    $isInstalled = Test-Path "$env:WINDIR\ti.bat"
Log "Is installed: $isInstalled"

# Shared themed result dialog for the install/uninstall child scripts.
# Single-quoted (no $ escaping needed); spliced into both via $($tiInfoBoxFuncSrc).
$tiInfoBoxFuncSrc = @'
function Show-TIInfoBox {
param([string]$Message, [string]$Title, [bool]$IsError, [bool]$IsTr)
try {
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
$code = @"
using System;
using System.Runtime.InteropServices;
public class Win32UI2 {
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
    [DllImport("gdi32.dll")] public static extern IntPtr CreateRoundRectRgn(int nLeftRect, int nTopRect, int nRightRect, int nBottomRect, int nWidthEllipse, int nHeightEllipse);
    [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr hObject);
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern int ExtractIconEx(string file, int index, IntPtr[] large, IntPtr[] small, int icons);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
}
"@
try { Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue } catch {}
try { [Win32UI2]::SetProcessDPIAware() | Out-Null } catch {}

$accent = if ($IsError) { [System.Drawing.Color]::FromArgb(224,90,90) } else { [System.Drawing.Color]::FromArgb(80,200,120) }

$form = New-Object System.Windows.Forms.Form
$form.StartPosition = 'CenterScreen'
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.FormBorderStyle = 'None'
$form.BackColor = [System.Drawing.Color]::FromArgb(32,32,32)
$form.ClientSize = New-Object System.Drawing.Size(420,200)
$form.Opacity = 0
$form.KeyPreview = $true

$dwmRounded = $false
try {
$pref = 2 # DWMWCP_ROUND
if ([Win32UI2]::DwmSetWindowAttribute($form.Handle, 33, [ref]$pref, 4) -eq 0) { $dwmRounded = $true }
} catch {}
if (-not $dwmRounded) {
try {
$hr = [Win32UI2]::CreateRoundRectRgn(0,0,$form.Width+1,$form.Height+1,14,14)
$form.Region = [System.Drawing.Region]::FromHrgn($hr)
[Win32UI2]::DeleteObject($hr) | Out-Null
} catch {}
}

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(14,12)
$titleLabel.Size = New-Object System.Drawing.Size(250,16)
$titleLabel.Text = $Title
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI Semibold',8.5)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($titleLabel)

$dragHandler = { try { [void][Win32UI2]::ReleaseCapture(); [void][Win32UI2]::SendMessage($form.Handle,0xA1,0x2,0) } catch {} }
$form.Add_MouseDown($dragHandler)
$titleLabel.Add_MouseDown($dragHandler)

$pic = New-Object System.Windows.Forms.PictureBox
$pic.Location = New-Object System.Drawing.Point(14,40)
$pic.Size = New-Object System.Drawing.Size(28,28)
$pic.SizeMode = 'Zoom'
$pic.BackColor = [System.Drawing.Color]::Transparent
try {
$large = New-Object IntPtr[] 1
$small = New-Object IntPtr[] 1
$iconIdx = if ($IsError) { -18 } else { -78 }
$n = [Win32UI2]::ExtractIconEx("$env:SystemRoot\System32\imageres.dll", $iconIdx, $large, $small, 1)
if ($n -gt 0 -and $large[0] -ne [IntPtr]::Zero) {
$pic.Image = [System.Drawing.Icon]::FromHandle($large[0]).ToBitmap()
}
} catch {}
$form.Controls.Add($pic)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(50,40)
$label.Size = New-Object System.Drawing.Size(356,74)
$label.Text = $Message
$label.Font = New-Object System.Drawing.Font('Segoe UI',9.5)
$label.ForeColor = [System.Drawing.Color]::FromArgb(220,220,220)
$label.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($label)

$btnOk = New-Object System.Windows.Forms.Button
$btnOk.Text = if ($IsTr) { 'Tamam' } else { 'OK' }
$btnOk.Size = New-Object System.Drawing.Size(110,36)
$btnOk.Location = New-Object System.Drawing.Point((420-20-110), 146)
$btnOk.Font = New-Object System.Drawing.Font('Segoe UI',10)
$btnOk.FlatStyle = 'Flat'
$btnOk.FlatAppearance.BorderSize = 1
$btnOk.FlatAppearance.BorderColor = $accent
$btnOk.BackColor = $accent
$btnOk.ForeColor = [System.Drawing.Color]::White
$btnOk.Cursor = [System.Windows.Forms.Cursors]::Hand
try {
$bhr = [Win32UI2]::CreateRoundRectRgn(0,0,$btnOk.Width+1,$btnOk.Height+1,8,8)
$btnOk.Region = [System.Drawing.Region]::FromHrgn($bhr)
[Win32UI2]::DeleteObject($bhr) | Out-Null
} catch {}
$btnOk.Add_Click({ $form.Close() })
$form.Controls.Add($btnOk)
$form.AcceptButton = $btnOk
$form.CancelButton = $btnOk

$credit = New-Object System.Windows.Forms.Label
$credit.Text = "by Abdullah ERTÜRK"
$credit.ForeColor = [System.Drawing.Color]::FromArgb(170,170,170)
$credit.Font = New-Object System.Drawing.Font('Segoe UI',7)
$credit.AutoSize = $true
$credit.BackColor = [System.Drawing.Color]::Transparent
$credit.Cursor = [System.Windows.Forms.Cursors]::Hand
$credit.Add_Click({ [System.Diagnostics.Process]::Start("https://erturk-dev.netlify.app") | Out-Null; Start-Sleep -Milliseconds 100; [System.Diagnostics.Process]::Start("https://github.com/abdullah-erturk") })
$credit.Add_MouseEnter({ $credit.ForeColor = [System.Drawing.Color]::White })
$credit.Add_MouseLeave({ $credit.ForeColor = [System.Drawing.Color]::FromArgb(170,170,170) })
$form.Controls.Add($credit)
$credit.Location = New-Object System.Drawing.Point(24, 158)

$fadeTimer = New-Object System.Windows.Forms.Timer
$fadeTimer.Interval = 15
$fadeTimer.Add_Tick({ if ($form.Opacity -lt 1) { $form.Opacity += 0.12 } else { $fadeTimer.Stop() } })
$form.Add_Shown({ $fadeTimer.Start() })
$form.Add_KeyDown({ if ($_.KeyCode -eq 'Escape') { $form.Close() } })

[void]$form.ShowDialog()
} catch {
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
$ic = if ($IsError) { 16 } else { 64 }
[System.Windows.Forms.MessageBox]::Show($Message, $Title, 0, $ic) | Out-Null
}
}
'@

if ($isInstalled) {
    try {
        $btnK = if ($isTurkish) { 'Kaldır' } else { 'Uninstall' }
        $btnG = if ($isTurkish) { 'Güncelle' } else { 'Update' }
        $btnI = if ($isTurkish) { 'İptal' } else { 'Cancel' }
        $uninstallConfirm = Show-TopMostChoiceDialog -Message $msg.UninstallMsg -Title $msg.UninstallTitle -YesText $btnK -NoText $btnG -CancelText $btnI -ShowCancel -Icon 32
    } catch {
        Log "TopMost uninstallConfirm popup failed, fallback: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
        $uninstallConfirm = [System.Windows.Forms.MessageBox]::Show($msg.UninstallMsg, $msg.UninstallTitle, 3, 32)
    }

    if ($uninstallConfirm -ne 6 -and $uninstallConfirm -ne 7) { return }
    $doUpdate = ($uninstallConfirm -eq 7)

    Log "User confirmed uninstall (doUpdate=$doUpdate)"
    try {
$successMsgUninstall = if ($isTurkish) { "Kaldırma işlemi başarıyla tamamlandı!" } else { "Uninstallation completed successfully!" }
$errorMsgUninstall = if ($isTurkish) { "Kaldırma sırasında hata oluştu!" } else { "An error occurred during uninstallation!" }
$successTitleUninstall = $msg.SuccessTitle
$errorTitleUninstall = $msg.ErrorTitle

                $uninstallScript = @"
$tiInfoBoxFuncSrc

`$isTurkish = '$isTurkish'
`$successMsg = '$($successMsgUninstall -replace "'","''")'
`$errorMsg = '$($errorMsgUninstall -replace "'","''")'
`$successTitle = '$($successTitleUninstall -replace "'","''")'
`$errorTitle = '$($errorTitleUninstall -replace "'","''")'

try {
`$targetPath = `$scriptPath



Write-Host "Removing registry keys via REG DELETE..." -ForegroundColor Yellow

cmd /c "reg delete `"HKCR\*\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\Directory\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\Directory\Background\shell\RunAsTI`" /f 2>nul"

cmd /c "reg delete `"HKCR\SystemFileAssociations\.exe\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\SystemFileAssociations\.bat\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\SystemFileAssociations\.cmd\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\SystemFileAssociations\.reg\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\SystemFileAssociations\.msc\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\SystemFileAssociations\.cpl\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\SystemFileAssociations\.txt\shell\RunAsTI`" /f 2>nul"

cmd /c "reg delete `"HKCR\SystemFileAssociations\.lnk\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\lnkfile\shell\RunAsTI`" /f 2>nul"

cmd /c "reg delete `"HKCR\SystemFileAssociations\.ps1\shell\run_edit`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.PsRun`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.PsAdmin`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.PsTI`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.IseOpen`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.IseAdmin`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.IseTI`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.IseOpenX86`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.IseAdminX86`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.IseTIX86`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.NotepadOpen`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.NotepadAdmin`" /f 2>nul"
cmd /c "reg delete `"HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell\TI.PS1.NotepadTI`" /f 2>nul"

if (Test-Path "`$env:WINDIR\ti.bat") { Remove-Item "`$env:WINDIR\ti.bat" -Force -ErrorAction SilentlyContinue }

Write-Host "Done!"
Start-Sleep -Milliseconds 500

if ('$doUpdate' -ne 'True') {
    Show-TIInfoBox -Message `$successMsg -Title `$successTitle -IsError `$false -IsTr (`$isTurkish -eq 'True')
}

} catch {
`$errMsg = `$errorMsg + "`n`n" + `$_.Exception.Message
Show-TIInfoBox -Message `$errMsg -Title `$errorTitle -IsError `$true -IsTr (`$isTurkish -eq 'True')
}
"@
$tempPs1 = "$env:TEMP\TI_Uninstall.ps1"
$uninstallScript | Out-File $tempPs1 -Encoding UTF8
Log "Starting uninstall script"
$env:TI_PROGRESS_TITLE = $msg.Title
$env:TI_PROGRESS_MSG = if ($isTurkish) { "Sistem temizleniyor..." } else { "Uninstalling..." }
$env:TI_PROGRESS_SUB = if ($isTurkish) { "Lütfen bekleyiniz" } else { "Please wait" }
$progressFile = "$env:TEMP\TI_Progress.ps1"
$global:TI_ProgressScript | Out-File $progressFile -Encoding UTF8 -Force
$progressJob = Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$progressFile`"" -PassThru

Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempPs1`"" -Verb RunAs -Wait
if ($progressJob) { try { $progressJob.Kill() } catch {} }
Remove-Item $tempPs1 -Force -ErrorAction SilentlyContinue

} catch {
Show-TopMostMessageBox -Message ($msg.UninstallError + $_.Exception.Message) -Title $msg.ErrorTitle -Buttons 0 -Icon 16
}
if ($doUpdate) {
    $installConfirm = 6
} else {
    return
}
} else {
        $installConfirm = 6
    }

if ($installConfirm -eq 6) {
Log "Starting install flow"
try {
$currentScriptPath = $env:SCRIPT_PATH
if (!$currentScriptPath -or !(Test-Path $currentScriptPath)) { throw "Cannot find script path" }

$successMsgInstall = if ($isTurkish) { "Kurulum tamamlandı" } else { "Installation complete" }
$errorMsgInstall = if ($isTurkish) { "Kurulum hatası: " } else { "Installation error: " }
$menuTextInstall = if ($isTurkish) { "Trusted Installer Yetkisiyle Aç" } else { "Open with Trusted Installer Privileges" }
$successTitleInstall = $msg.SuccessTitle
$errorTitleInstall = $msg.ErrorTitle

                $installScript = @"
$tiInfoBoxFuncSrc

`$ErrorActionPreference = 'Stop'
`$isTurkish = '$isTurkish'
`$scriptPath = '$($currentScriptPath -replace "'","''")'
`$targetPath = `"`$env:WINDIR\ti.bat`"
`$successMsg = '$($successMsgInstall -replace "'","''")'
`$errorMsg = '$($errorMsgInstall -replace "'","''")'
`$menuText = '$($menuTextInstall -replace "'","''")'
`$successTitle = '$($successTitleInstall -replace "'","''")'
`$errorTitle = '$($errorTitleInstall -replace "'","''")'

try {
    Copy-Item -LiteralPath `$scriptPath -Destination `$targetPath -Force

    Write-Host "Adding Registry Keys via REG ADD..." -ForegroundColor Yellow

`$cmdVal = '\"' + `$targetPath + '\" \"%1\"'
`$cmdValBg = '\"' + `$targetPath + '\" \"%V\"'

cmd /c "reg delete `"HKCR\*\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\Directory\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\Directory\Background\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\SystemFileAssociations\.lnk\shell\RunAsTI`" /f 2>nul"
cmd /c "reg delete `"HKCR\lnkfile\shell\RunAsTI`" /f 2>nul"

  foreach (`$k in @("HKCR\*\shell\RunAsTI", "HKCR\Directory\shell\RunAsTI", "HKCR\Directory\Background\shell\RunAsTI")) {
  & reg.exe add `$k /ve /d "`$menuText" /f
  & reg.exe add `$k /v MUIVerb /d "`$menuText" /f
  & reg.exe add `$k /v Icon /d "imageres.dll,-78" /f
  if (`$k -match "Background") {
    & reg.exe add "`$k\command" /ve /d `$cmdValBg /f
  } else {
    & reg.exe add "`$k\command" /ve /d `$cmdVal /f
  }
  }

foreach (`$ext in @('.exe','.bat','.cmd','.reg','.msc','.cpl','.txt')) {
`$k = "HKCR\SystemFileAssociations\`$ext\shell\RunAsTI"
& reg.exe add `$k /ve /d "`$menuText" /f
& reg.exe add `$k /v MUIVerb /d "`$menuText" /f
& reg.exe add `$k /v Icon /d "imageres.dll,-78" /f
& reg.exe add "`$k\command" /ve /d `$cmdVal /f
}

`$lnkAppliesTo = 'System.Link.TargetExtension:=".exe" OR System.Link.TargetExtension:="exe" OR System.Link.TargetExtension:=".bat" OR System.Link.TargetExtension:="bat" OR System.Link.TargetExtension:=".cmd" OR System.Link.TargetExtension:="cmd" OR System.Link.TargetExtension:=".reg" OR System.Link.TargetExtension:="reg" OR System.Link.TargetExtension:=".ps1" OR System.Link.TargetExtension:="ps1" OR System.Link.TargetExtension:=".msc" OR System.Link.TargetExtension:="msc" OR System.Link.TargetExtension:=".cpl" OR System.Link.TargetExtension:="cpl" OR System.Link.TargetExtension:=".txt" OR System.Link.TargetExtension:="txt"'
foreach (`$lk in @('HKCR\SystemFileAssociations\.lnk\shell\RunAsTI','HKCR\lnkfile\shell\RunAsTI')) {
& reg.exe add `$lk /ve /d "`$menuText" /f
& reg.exe add `$lk /v MUIVerb /d "`$menuText" /f
& reg.exe add `$lk /v Icon /d "imageres.dll,-78" /f
& reg.exe add `$lk /v AppliesTo /t REG_SZ /d `$lnkAppliesTo /f
& reg.exe add "`$lk\command" /ve /d `$cmdVal /f
}

`$psRoot = "HKCR\SystemFileAssociations\.ps1\shell\run_edit"
`$cmdStore = "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"

`$cmdPsRun = '\"' + `$targetPath + '\" /ps1action:ps-run \"%1\"'
`$cmdPsAdmin = '\"' + `$targetPath + '\" /ps1action:ps-admin \"%1\"'
`$cmdPsTi = '\"' + `$targetPath + '\" /ps1action:ps-ti \"%1\"'

`$cmdIseOpen = '\"' + `$targetPath + '\" /ps1action:ise-open \"%1\"'
`$cmdIseAdmin = '\"' + `$targetPath + '\" /ps1action:ise-admin \"%1\"'
`$cmdIseTi = '\"' + `$targetPath + '\" /ps1action:ise-ti \"%1\"'

`$cmdIseOpenX86 = '\"' + `$targetPath + '\" /ps1action:ise-open-x86 \"%1\"'
`$cmdIseAdminX86 = '\"' + `$targetPath + '\" /ps1action:ise-admin-x86 \"%1\"'
`$cmdIseTiX86 = '\"' + `$targetPath + '\" /ps1action:ise-ti-x86 \"%1\"'

`$cmdNpOpen = '\"' + `$targetPath + '\" /ps1action:notepad-open \"%1\"'
`$cmdNpAdmin = '\"' + `$targetPath + '\" /ps1action:notepad-admin \"%1\"'
`$cmdNpTi = '\"' + `$targetPath + '\" /ps1action:notepad-ti \"%1\"'

& reg.exe add "`$psRoot" /v MUIVerb /d "Çalıştır veya Düzenle..." /f
& reg.exe add "`$psRoot" /v Icon /d "powershell.exe" /f

& reg.exe add "`$psRoot" /v SubCommands /d "TI.PS1.PsRun;TI.PS1.PsAdmin;TI.PS1.PsTI;TI.PS1.IseOpen;TI.PS1.IseAdmin;TI.PS1.IseTI;TI.PS1.IseOpenX86;TI.PS1.IseAdminX86;TI.PS1.IseTIX86;TI.PS1.NotepadOpen;TI.PS1.NotepadAdmin;TI.PS1.NotepadTI" /f

& reg.exe add "`$cmdStore\TI.PS1.PsRun" /v MUIVerb /d "PowerShell" /f
& reg.exe add "`$cmdStore\TI.PS1.PsRun" /v Icon /d "powershell.exe" /f
& reg.exe add "`$cmdStore\TI.PS1.PsRun\command" /ve /d `$cmdPsRun /f

& reg.exe add "`$cmdStore\TI.PS1.PsAdmin" /v MUIVerb /d "PowerShell (Admin)" /f
& reg.exe add "`$cmdStore\TI.PS1.PsAdmin" /v HasLUAShield /d "" /f
& reg.exe add "`$cmdStore\TI.PS1.PsAdmin" /v Icon /d "powershell.exe" /f
& reg.exe add "`$cmdStore\TI.PS1.PsAdmin\command" /ve /d `$cmdPsAdmin /f

& reg.exe add "`$cmdStore\TI.PS1.PsTI" /v MUIVerb /d "PowerShell (RunAsTI)" /f
& reg.exe add "`$cmdStore\TI.PS1.PsTI" /v HasLUAShield /d "" /f
& reg.exe add "`$cmdStore\TI.PS1.PsTI" /v Icon /d "imageres.dll,-78" /f
& reg.exe add "`$cmdStore\TI.PS1.PsTI\command" /ve /d `$cmdPsTi /f

& reg.exe add "`$cmdStore\TI.PS1.IseOpen" /v MUIVerb /d "PowerShell ISE" /f
& reg.exe add "`$cmdStore\TI.PS1.IseOpen" /v Icon /d "powershell_ise.exe" /f
& reg.exe add "`$cmdStore\TI.PS1.IseOpen\command" /ve /d `$cmdIseOpen /f

& reg.exe add "`$cmdStore\TI.PS1.IseAdmin" /v MUIVerb /d "PowerShell ISE (Admin)" /f
& reg.exe add "`$cmdStore\TI.PS1.IseAdmin" /v HasLUAShield /d "" /f
& reg.exe add "`$cmdStore\TI.PS1.IseAdmin" /v Icon /d "powershell_ise.exe" /f
& reg.exe add "`$cmdStore\TI.PS1.IseAdmin\command" /ve /d `$cmdIseAdmin /f

& reg.exe add "`$cmdStore\TI.PS1.IseTI" /v MUIVerb /d "PowerShell ISE (RunAsTI)" /f
& reg.exe add "`$cmdStore\TI.PS1.IseTI" /v HasLUAShield /d "" /f
& reg.exe add "`$cmdStore\TI.PS1.IseTI" /v Icon /d "imageres.dll,-78" /f
& reg.exe add "`$cmdStore\TI.PS1.IseTI\command" /ve /d `$cmdIseTi /f

& reg.exe add "`$cmdStore\TI.PS1.IseOpenX86" /v MUIVerb /d "PowerShell ISE (x86)" /f
& reg.exe add "`$cmdStore\TI.PS1.IseOpenX86" /v Icon /d "powershell_ise.exe" /f
& reg.exe add "`$cmdStore\TI.PS1.IseOpenX86\command" /ve /d `$cmdIseOpenX86 /f

& reg.exe add "`$cmdStore\TI.PS1.IseAdminX86" /v MUIVerb /d "PowerShell ISE (x86) (Admin)" /f
& reg.exe add "`$cmdStore\TI.PS1.IseAdminX86" /v HasLUAShield /d "" /f
& reg.exe add "`$cmdStore\TI.PS1.IseAdminX86" /v Icon /d "powershell_ise.exe" /f
& reg.exe add "`$cmdStore\TI.PS1.IseAdminX86\command" /ve /d `$cmdIseAdminX86 /f

& reg.exe add "`$cmdStore\TI.PS1.IseTIX86" /v MUIVerb /d "PowerShell ISE (x86) (RunAsTI)" /f
& reg.exe add "`$cmdStore\TI.PS1.IseTIX86" /v HasLUAShield /d "" /f
& reg.exe add "`$cmdStore\TI.PS1.IseTIX86" /v Icon /d "imageres.dll,-78" /f
& reg.exe add "`$cmdStore\TI.PS1.IseTIX86\command" /ve /d `$cmdIseTiX86 /f

& reg.exe add "`$cmdStore\TI.PS1.NotepadOpen" /v MUIVerb /d "Notepad" /f
& reg.exe add "`$cmdStore\TI.PS1.NotepadOpen" /v Icon /d "notepad.exe" /f
& reg.exe add "`$cmdStore\TI.PS1.NotepadOpen\command" /ve /d `$cmdNpOpen /f

& reg.exe add "`$cmdStore\TI.PS1.NotepadAdmin" /v MUIVerb /d "Notepad (Admin)" /f
& reg.exe add "`$cmdStore\TI.PS1.NotepadAdmin" /v HasLUAShield /d "" /f
& reg.exe add "`$cmdStore\TI.PS1.NotepadAdmin" /v Icon /d "notepad.exe" /f
& reg.exe add "`$cmdStore\TI.PS1.NotepadAdmin\command" /ve /d `$cmdNpAdmin /f

& reg.exe add "`$cmdStore\TI.PS1.NotepadTI" /v MUIVerb /d "Notepad (RunAsTI)" /f
& reg.exe add "`$cmdStore\TI.PS1.NotepadTI" /v HasLUAShield /d "" /f
& reg.exe add "`$cmdStore\TI.PS1.NotepadTI" /v Icon /d "imageres.dll,-78" /f
& reg.exe add "`$cmdStore\TI.PS1.NotepadTI\command" /ve /d `$cmdNpTi /f

Write-Host "Registry entries created!"
Start-Sleep -Milliseconds 500

Show-TIInfoBox -Message `$successMsg -Title `$successTitle -IsError `$false -IsTr (`$isTurkish -eq 'True')

exit 0
} catch {
`$err = `$_.Exception.Message
Write-Host "Error: `$err" -ForegroundColor Red
`$errMsg = `$errorMsg + `$err
Show-TIInfoBox -Message `$errMsg -Title `$errorTitle -IsError `$true -IsTr (`$isTurkish -eq 'True')
}
"@
$tempPs1 = "$env:TEMP\TI_Install.ps1"
$installScript | Out-File $tempPs1 -Encoding UTF8
Log "Executing install script"
$env:TI_PROGRESS_TITLE = $msg.Title
$env:TI_PROGRESS_MSG = if ($isTurkish) { "Sistem entegrasyonu kuruluyor..." } else { "Installing..." }
$env:TI_PROGRESS_SUB = if ($isTurkish) { "Lütfen bekleyiniz" } else { "Please wait" }
$progressFile = "$env:TEMP\TI_Progress.ps1"
$global:TI_ProgressScript | Out-File $progressFile -Encoding UTF8 -Force
$progressJob = Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$progressFile`"" -PassThru

$proc = Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempPs1`"" -Verb RunAs -Wait -PassThru
if ($progressJob) { try { $progressJob.Kill() } catch {} }
$exitCode = $proc.ExitCode
if ($exitCode -ne 0) {
Log "Install script exited with code $exitCode"
Show-TopMostMessageBox -Message ($msg.InstallError + " (ExitCode=" + $exitCode + ")") -Title $msg.ErrorTitle -Buttons 0 -Icon 16
} else {
Log "Install completed (exitCode=0). Success popup handled by child install script."
}

Remove-Item $tempPs1 -Force -ErrorAction SilentlyContinue

} catch {
Log "Install flow error: $($_.Exception.Message)"
Show-TopMostMessageBox -Message ($msg.InstallError + $_.Exception.Message) -Title $msg.ErrorTitle -Buttons 0 -Icon 16
		}
	}
}
#endregion TI_CORE_INSTALL
}