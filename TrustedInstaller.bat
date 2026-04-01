
<# : hybrid batch + powershell script
@echo off
title Trusted Installer Launcher ^| made by Abdullah ERTURK
mode con: cols=70 lines=4
echo.
echo			   Trusted Installer Launcher
set "SCRIPT_PATH=%~f0"
@powershell -noprofile -ExecutionPolicy Bypass -c "$param='%*';$env:SCRIPT_PATH='%~f0';iex([System.IO.File]::ReadAllText('%~f0'))"
if errorlevel 1 pause
exit/b
#>

<#
	TrustedInstaller Sürükle-Bırak Başlatıcı
	
	https://github.com/abdullah-erturk/)
		
	https://erturk.netlify.app
#>

if ($env:SCRIPT_PATH) {
    try {
        $scriptItem = Get-Item $env:SCRIPT_PATH -ErrorAction SilentlyContinue
        if ($scriptItem) {
            $scriptItem.IsReadOnly = $true
        }
    } catch {
    }
}

# --- AYARLAR ---
$ErrorActionPreference = 'Stop'
$global:TI_MainLog = "$env:TEMP\TI_Main.log"

function Log($m) {
    try { "[{0:u}] {1}" -f (Get-Date), $m | Out-File $global:TI_MainLog -Append } catch {}
}
Log "=== Script start ==="

try {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Dpi {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
'@
    [Dpi]::SetProcessDPIAware() | Out-Null
} catch {}

# --- HATA YAKALAMA (TRAP) ---
trap {
    Log "ERROR: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show("Hata: $($_.Exception.Message)`nLog: $global:TI_MainLog", "TI Launcher Error", 0, 16) | Out-Null
    } catch {}
    exit 1
}

# --- DİL AYARI ---
try {
    $systemLang = (Get-UICulture).Name
} catch {
    $systemLang = [System.Globalization.CultureInfo]::CurrentUICulture.Name
}
$isTurkish = $systemLang -like "tr-*"
Log "Lang: $systemLang (TR=$isTurkish)"

# --- ARAYÜZ METİNLERİ ---
if ($isTurkish) {
    $msg = @{
        Title = "Trusted Installer / Süper Yönetici / made by Abdullah ERTÜRK"
        PopupTitle = "Trusted Installer Launcher | made by Abdullah ERTÜRK | TNCTR.com"
        PopupMsg = @"
Bu script'i kullanmak için herhangi bir dosyayı veya klasörü üzerine sürükleyip bırakın.

Desteklenen dosyalar:
• EXE, BAT, CMD, REG, PS1
• MSC (MMC snap-in'ler)
• CPL (Kontrol Paneli)
• Ve daha fazlası...

Örnek: explorer.exe dosyasını bu script üzerine sürükleyin.

======================================
EVET   	-> CMD veya Explorer'ı TI yetkisiyle aç
HAYIR  	-> Sisteme Kur (Sağ tık menüsü entegrasyonu)
İPTAL  	-> Çıkış
"@
        ChoiceTitle = "Seçim"
        ChoiceMsg = "Hangisini açmak istersiniz?`n`nEVET 	= CMD`nHAYIR 	= Explorer"
        InstallTitle = "Kurulum Onayı"
        InstallMsg = @"
Trusted Installer bilgisayarınıza kurulacaktır.

Kurulum içeriği:
• ti.bat dosyası Windows klasörüne kopyalanacak.
• Tüm dosya ve klasörler için sağ tık menüsüne ekleme yapılacak.

Onay veriyor musunuz?

EVET   	-> Kurulumu başlat
HAYIR  	-> İptal et
"@
        ReinstallTitle = "Yeniden Kurulum"
        ReinstallMsg = @"
Trusted Installer zaten kurulu!
C:\Windows\ti.bat dosyası mevcut.

EVET   	-> Yeniden kur (mevcut kurulum güncellenecek)
HAYIR  	-> Kaldır (tüm dosya ve kayıtları sil)
İPTAL  	-> Hiçbir şey yapma
"@
        InstallSuccess = "Kurulum başarıyla tamamlandı!`n`nArtık herhangi bir dosya veya klasöre sağ tıklayıp 'Trusted Installer ile Aç' seçeneğini kullanabilirsiniz."
        InstallError = "Kurulum sırasında hata oluştu!`n`nDetay: "
        UninstallTitle = "Kaldırma Onayı"
        UninstallMsg = "Trusted Installer sistem entegrasyonu kaldırılacaktır.`n`nOnay veriyor musunuz?"
        UninstallSuccess = "Kaldırma işlemi başarıyla tamamlandı!"
        UninstallError = "Kaldırma sırasında hata oluştu!`n`nDetay: "
        SuccessTitle = "Başarılı"
        ErrorTitle = "Hata"
        MenuText = "Trusted Installer ile Aç"
        PleaseWait = "Trusted Installer etkinleştiriliyor, lütfen bekleyin...`n`nBu ekran otomatik kapanacaktır."
    }
} else {
    $msg = @{
        Title = "Trusted Installer / Super Administrator / made by Abdullah ERTÜRK"
        PopupTitle = "Trusted Installer Launcher | made by Abdullah ERTÜRK | TNCTR.com"
        PopupMsg = @"
Drag and drop any file or folder onto this script to run it.

Supported files:
• EXE, BAT, CMD, REG, PS1
• MSC (MMC snap-ins)
• CPL (Control Panel)
• And more...

Example: Drag explorer.exe onto this script.

======================================
YES	-> Open CMD or Explorer with TI privileges
NO	-> Install to System (Context menu integration)
CANCEL	-> Exit
"@
        ChoiceTitle = "Choice"
        ChoiceMsg = "Which one would you like to open?`n`nYES = CMD`nNO = Explorer"
        InstallTitle = "Installation Confirmation"
        InstallMsg = @"
Trusted Installer will be installed to your computer.

Installation includes:
• ti.bat file will be copied to Windows folder.
• Context menu integration.

Do you confirm?

YES	-> Start installation
NO	-> Cancel
"@
        ReinstallTitle = "Reinstallation"
        ReinstallMsg = @"
Trusted Installer is already installed!
C:\Windows\ti.bat file exists.

YES	-> Reinstall (update existing installation)
NO	-> Uninstall (remove all files and registry entries)
CANCEL	-> Do nothing
"@
        InstallSuccess = "Installation completed successfully!`n`nYou can now right-click any file or folder and select 'Open with Trusted Installer'."
        InstallError = "An error occurred during installation!`n`nDetails: "
        UninstallTitle = "Uninstall Confirmation"
        UninstallMsg = "Trusted Installer system integration will be removed.`n`nDo you confirm?"
        UninstallSuccess = "Uninstallation completed successfully!"
        UninstallError = "An error occurred during uninstallation!`n`nDetails: "
        SuccessTitle = "Success"
        ErrorTitle = "Error"
        MenuText = "Open with Trusted Installer"
        PleaseWait = "Trusted Installer is being activated, please wait....`n`nThis window will close automatically."
    }
}

# --- TRUSTED INSTALLER MOTORU (ORİJİNAL KODDAN KORUNAN KISIM) ---
function RunAsTI {
    param(
        $cmd,
        $targetName  # İşlem yapılan dosya/klasör yolu veya adı (isteğe bağlı)
    )
    $id = $msg.Title
    $sid = ((whoami /user) -split ' ')[-1]
    if (!$cmd -or ($cmd -and $cmd.Trim() -eq '')) { $cmd = 'cmd.exe' }
    
    # Kendi script çağrısını kontrol et
    if ($cmd -match '\$param=.*SCRIPT_PATH') { $cmd = 'cmd.exe' }
    
    # Debug log
    $logFile = "$env:TEMP\TI_Error.log"
    "=== Debug Log ===" | Out-File $logFile
    "Command: $cmd" | Out-File $logFile -Append
    "SID: $sid" | Out-File $logFile -Append
    "Time: $(Get-Date)" | Out-File $logFile -Append
    
    # Hedef adı için dinamik bekleme mesajı hazırla
    $targetDisplay = $null
    if ($targetName) {
        try {
            if (Test-Path $targetName) {
                $targetDisplay = Split-Path $targetName -Leaf
                if (-not $targetDisplay -or $targetDisplay -eq '\') {
                    $targetDisplay = $targetName
                }
            } else {
                $targetDisplay = $targetName
            }
        } catch {
            $targetDisplay = $targetName
        }
    }
    if ($targetDisplay) {
        if ($isTurkish) {
            $msg.PleaseWait = "$targetDisplay için Trusted Installer etkinleştiriliyor, lütfen bekleyin...`n`nBu ekran otomatik kapanacaktır."
        } else {
            $msg.PleaseWait = "Trusted Installer is being activated for $targetDisplay, please wait...`n`nThis window will close automatically."
        }
    }

    # Modern Progress Bar (from TrustedInstaller.bat)
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

`$radius = 14
`$path = New-Object System.Drawing.Drawing2D.GraphicsPath
`$path.AddArc(0,0,`$radius,`$radius,180,90)
`$path.AddArc(`$form.Width-`$radius,0,`$radius,`$radius,270,90)
`$path.AddArc(`$form.Width-`$radius,`$form.Height-`$radius,`$radius,`$radius,0,90)
`$path.AddArc(0,`$form.Height-`$radius,`$radius,`$radius,90,90)
`$path.CloseFigure()
`$form.Region = New-Object System.Drawing.Region(`$path)

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

`$targetName = "$($targetDisplay -replace '"','\"')"

`$labelMain = New-Object System.Windows.Forms.Label
`$labelMain.Text = `$(if (`$isTr) { "Trusted Installer etkinleştiriliyor..." } else { "Activating Trusted Installer..." })
`$labelMain.ForeColor = 'White'
`$labelMain.Font = New-Object System.Drawing.Font("Segoe UI",10)
`$labelMain.AutoSize = `$false
`$labelMain.Width = `$form.Width
`$labelMain.Height = 20
`$labelMain.TextAlign = 'MiddleCenter'
`$labelMain.Location = New-Object System.Drawing.Point(0,16)
`$top.Controls.Add(`$labelMain)

`$labelSub = New-Object System.Windows.Forms.Label
`$labelSub.Text = `$(if (`$isTr) { "Lütfen bekleyin...`n$targetName" } else { "Please wait...`n$targetName" })
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

`$fade.Start()
`$timer.Start()

[void]`$form.ShowDialog()
"@

    $progressScript | Out-File $progressFile -Encoding UTF8 -Force
    
    $progressJob = Start-Process powershell -ArgumentList "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$progressFile`"" -PassThru
    
    $env:TI_PROGRESS_PID = $progressJob.Id
    $env:TI_PROGRESS_FILE = $progressFile
    $progressPidFile = "$env:TEMP\TI_Progress.pid"
    try { Set-Content -LiteralPath $progressPidFile -Value ([string]$progressJob.Id) -Encoding ASCII -Force } catch {}
    
    # --- ORİJİNAL PAYLOAD (P/INVOKE DEFINITIONS) ---
    $msgTitle = $msg.Title
    $msgTitleEscaped = $msgTitle -replace '"','`"'
    # Script dizinini al
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

    $ti = $false
    try {
        $ti = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups | Where-Object { $_.Value -eq "S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464" }
    } catch {}
    "TI Check Result: $(if ($ti) {$true} else {$false})" | Out-File $logFile -Append -Encoding UTF8

    # Dynamic Assembly & Module Definition
    $DM = [AppDomain]::CurrentDomain."DefineDynamicAssembly"(1,1)."DefineDynamicModule"(1)
    "DM created" | Out-File $logFile -Append

    $D = @()
    0..5 | ForEach-Object { $D += $DM."DefineType"("M$_", 1179913, [ValueType]) }
    "Types defined" | Out-File $logFile -Append

    $I = [int32]
    $P = $I.module.gettype("System.IntPtr")
    $U = [uintptr]
    $D += $U
    4..6 | ForEach-Object { $D += $D[$_]."MakeByRefType"() }
    $M = $I.module.gettype("System.Runtime.InteropServices.Marshal")
    $Z = [uintptr]::size
    $S = [string]
    
    # P/Invoke Signatures
    $F = "kernel", "advapi", "advapi", ($S,$S,$I,$I,$I,$I,$I,$S,$D[7],$D[8]), ($U,$S,$I,$I,$D[9]), ($U,$S,$I,$I,[byte[]],$I)
    0..2 | ForEach-Object { $9 = $D[0]."DefinePInvokeMethod"(("CreateProcess","RegOpenKeyEx","RegSetValueEx")[$_], $F[$_]+'32', 8214, 1, $S, $F[$_+3], 1, 4) }
    "P/Invoke defined" | Out-File $logFile -Append

    # Struct Fields Definition
    $DF = 0, ($P,$I,$P), ($I,$I,$I,$I,$P,$D[1]), ($I,$S,$S,$S,$I,$I,$I,$I,$I,$I,$I,$I,[int16],[int16],$P,$P,$P,$P), ($D[3],$P), ($P,$P,$I,$I)
    1..5 | ForEach-Object {
        $k = $_
        $n = 1
        $DF[$_] | ForEach-Object { $9 = $D[$k]."DefineField"('f'+$n++, $_, 6) }
    }
    "Fields defined" | Out-File $logFile -Append

    $T = @()
    0..5 | ForEach-Object { $T += $D[$_]."CreateType"() }
    0..5 | ForEach-Object { New-Variable -Name "A$_" -Value ([Activator]::CreateInstance($T[$_])) -Force }
    "Types created" | Out-File $logFile -Append

    function F ($1,$2) { $T[0]."GetMethod"($1).invoke(0,$2) }

    if ($ti) {
        "Already TI - running command" | Out-File $logFile -Append
        
        $env:A = ''
        $PRIV = [uri].module.gettype("System.Diagnostics.Process")."GetMethods"(42) | Where-Object { $_.Name -eq "SetPrivilege" }
        "SeAssignPrimaryTokenPrivilege","SeLockMemoryPrivilege","SeIncreaseQuotaPrivilege","SeTcbPrivilege","SeSecurityPrivilege","SeTakeOwnershipPrivilege","SeLoadDriverPrivilege","SeSystemProfilePrivilege","SeSystemtimePrivilege","SeProfileSingleProcessPrivilege","SeIncreaseBasePriorityPrivilege","SeCreatePagefilePrivilege","SeCreatePermanentPrivilege","SeBackupPrivilege","SeRestorePrivilege","SeShutdownPrivilege","SeDebugPrivilege","SeAuditPrivilege","SeSystemEnvironmentPrivilege","SeChangeNotifyPrivilege","SeUndockPrivilege","SeManageVolumePrivilege","SeImpersonatePrivilege","SeCreateGlobalPrivilege","SeIncreaseWorkingSetPrivilege","SeTimeZonePrivilege","SeCreateSymbolicLinkPrivilege","SeDelegateSessionUserImpersonatePrivilege" | ForEach-Object { try { $PRIV.Invoke(0, @("$_", 2)) } catch {} }
        
        $HKU = [uintptr][uint32]2147483651
        $LNK = $HKU
        $reg = @($HKU, "S-1-5-18", 8, 2, ($LNK -as $D[9]))
        F "RegOpenKeyEx" $reg
        $LNK = $reg[4]
        
        function SYM($1,$2) {
            $b = [Text.Encoding]::Unicode.GetBytes("\Registry\User\$1")
            @($2, "SymbolicLinkValue", 0, 6, [byte[]]$b, $b.Length)
        }
        
        F "RegSetValueEx" (SYM $(($key -split '\\')[1]) $LNK)
        $EXP = "HKLM:\Software\Classes\AppID\{CDCBCFCA-3CDC-436f-A4E2-0E02075250C2}"
        
        if (!$cmd) { $cmd = 'C:\' }
        
        # Explorer için özel kontrol
        $isExplorer = $cmd -like "*explorer*"
        $isCMD = ($cmd -like "*cmd*" -or $cmd -match '\.(bat|cmd)"?\s*$')
        
        "DEBUG: cmd='$cmd'" | Out-File $logFile -Append -Encoding UTF8
        "DEBUG: isCMD=$isCMD" | Out-File $logFile -Append -Encoding UTF8
        "DEBUG: isExplorer=$isExplorer" | Out-File $logFile -Append -Encoding UTF8

        Set-ItemProperty $EXP RunAs '' -Force
        "Launching: $cmd" | Out-File $logFile -Append -Encoding UTF8
        
        # Direkt process başlat
        if ($isCMD) {
            $cmdArgs = $cmd -replace '^\s*cmd(\.exe)?\s*',''
            $cmdArgs = $cmdArgs.Trim()
            # Script dizinine geçiş komutu
            $scriptDirEscaped = $scriptDir -replace '"','""'
            $cdCommand = "cd /d `"$scriptDirEscaped`""
            # Eğer boş veya sadece /k ise title ekle
            if (!$cmdArgs -or $cmdArgs -eq '' -or $cmdArgs -eq '/k') {
                # Title'ı ekle - Tırnak içinde olduğu için sadece tırnak karakterini escape et
                $titleForCmd = $msgTitle -replace '"','""'
                $argList = "/k $cdCommand && title `"$titleForCmd`""
            } else {
                # Mevcut argümanlara title ekle
                $titleForCmd = $msgTitle -replace '"','""'
                $argList = "/k $cdCommand && $cmdArgs && title `"$titleForCmd`""
            }
            "CMD args: $argList" | Out-File $logFile -Append -Encoding UTF8
            "CMD title: $msgTitle" | Out-File $logFile -Append -Encoding UTF8
            "CMD working dir: $scriptDir" | Out-File $logFile -Append -Encoding UTF8
            try {
                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = "$env:SystemRoot\System32\cmd.exe"
                $psi.Arguments = $argList
                $psi.UseShellExecute = $true
                $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
                [System.Diagnostics.Process]::Start($psi)
            } catch {
                 Add-Type -AssemblyName System.Windows.Forms
                 [System.Windows.Forms.MessageBox]::Show("CMD Launch Error (isCMD): $($_.Exception.Message)", "TI Error", 0, 16)
            }
        } elseif ($isExplorer) {
            # Explorer komutunu parse et
            if ($cmd -match 'explorer\.exe\s+"?([^"]+)"?') {
                $explorerPath = $matches[1]
            } elseif ($cmd -match 'explorer\.exe\s+(.+)') {
                $explorerPath = $matches[1].Trim('"')
            } else {
                $explorerPath = $env:USERPROFILE
            }
            "Explorer path: $explorerPath" | Out-File $logFile -Append
            Start-Process explorer.exe -ArgumentList "`"$explorerPath`"" -WindowStyle Normal
        } else {
            # Sadece saf EXE yollarını direkt başlat, aksi halde cmd üzerinden çalıştır
            if ($cmd -match '^\s*"?([A-Za-z]:\\[^"]+\.exe)"?\s*$') {
                $exePath = $matches[1]
                "Launching EXE directly: $exePath" | Out-File $logFile -Append
                $exeDir = Split-Path -Parent $exePath
                if (-not $exeDir) { $exeDir = $scriptDir }
                Start-Process -FilePath $exePath -WorkingDirectory $exeDir
            } else {
                $argString = "/c title $id"
                if ($cmd -and $cmd.Trim() -ne '') { $argString += " && `"$cmd`"" }
                try {
                    "Launching via CMD: $argString" | Out-File $logFile -Append
                    # PS 2.0 workaround for -UseShellExecute $false
                    $psi = New-Object System.Diagnostics.ProcessStartInfo
                    $psi.FileName = "$env:SystemRoot\System32\cmd.exe"
                    $psi.Arguments = $argString
                    $psi.UseShellExecute = $false
                    $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
                    [System.Diagnostics.Process]::Start($psi)
                } catch {
                    Add-Type -AssemblyName System.Windows.Forms
                    [System.Windows.Forms.MessageBox]::Show("CMD Launch Error: $($_.Exception.Message)", "TI Error", 0, 16)
                }
            }
        }
        
        # TI ortamı stabil olsun diye kısa bir bekleme; süreleri kısaltıldı
        if ($isExplorer) {
            Start-Sleep -Seconds 1
        } else {
            Start-Sleep -Seconds 1
        }
        
        F "RegSetValueEx" (SYM ".Default" $LNK)
        Set-ItemProperty $EXP RunAs "Interactive User" -Force

        # TI ile hedef program başlatıldıktan sonra bekleme popup'ını hemen kapat
        try {
            # Modern Progress Bar Cleanup
            try {
                $progressPidFile = "$env:TEMP\TI_Progress.pid"
                if (Test-Path $progressPidFile) {
                    $pidVal = Get-Content $progressPidFile -ErrorAction SilentlyContinue
                    if ($pidVal) { Stop-Process -Id $pidVal -Force -ErrorAction SilentlyContinue }
                    Remove-Item $progressPidFile -Force -ErrorAction SilentlyContinue
                }
                $progressFile = "$env:TEMP\TI_Progress.ps1"
                if (Test-Path $progressFile) { Remove-Item $progressFile -Force -ErrorAction SilentlyContinue }
            } catch {}
        } catch {}
    }
    else {
        "Not TI yet - elevating..." | Out-File $logFile -Append
        $g = 0
        "TrustedInstaller", "lsass" | ForEach-Object {
            if (!$g) {
                "Trying to start: $_" | Out-File $logFile -Append
                Start-Process net -ArgumentList "start $_" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                $g = @(Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object { $_ })[0]
                if ($g) {
                    "Got process: $_ (PID: $($g.Id))" | Out-File $logFile -Append
                }
            }
        }
        
        if (!$g) {
            "ERROR: Could not get TI process!" | Out-File $logFile -Append
            throw "Could not get TrustedInstaller process"
        }
        
        function M($1,$2,$3) { $M."GetMethod"($1, [type[]]$2).invoke(0,$3) }
        
        $H = @()
        $Z, (4*$Z+16) | ForEach-Object { $H += M "AllocHGlobal" $I $_ }
        M "WriteIntPtr" ($P,$P) ($H[0], $g.Handle)
        $A1.f1 = 131072
        $A1.f2 = $Z
        $A1.f3 = $H[0]
        $A2.f1 = $A2.f2 = $A2.f3 = $A2.f4 = 1
        $A2.f6 = $A1
        $A3.f1 = 10*$Z+32
        $A4.f1 = $A3
        $A4.f2 = $H[1]
        M "StructureToPtr" ($D[2],$P,[boolean]) (($A2 -as $D[2]), $A4.f2, $false)
        $w = 0x0E080600
        "Creating TI process..." | Out-File $logFile -Append
        
        $arg4 = $A4 -as $D[4]
        $arg5 = $A5 -as $D[5]
        $out = @($null, "powershell -WindowStyle Hidden -nop -c iex `$env:A", 0, 0, 0, $w, 0, $null, $arg4, $arg5)
        F "CreateProcess" $out
        "TI process created!" | Out-File $logFile -Append
    }

    "Payload completed successfully" | Out-File $logFile -Append

} catch {
    "EXCEPTION: $($_.Exception.Message)" | Out-File $logFile -Append
    "Stack: $($_.ScriptStackTrace)" | Out-File $logFile -Append
    $host.ui.WriteErrorLine("Error: $($_.Exception.Message)")
    Read-Host "Press Enter to continue"
    throw
}
'@
    # Placeholder'ı gerçek değerle değiştir
    $payload = $payload -replace 'MSG_TITLE_PLACEHOLDER', $msgTitleEscaped
    $payload = $payload -replace 'SCRIPT_DIR_PLACEHOLDER', $scriptDirEscaped
    
    try {
        "Creating registry key..." | Out-File $logFile -Append
        $key = "Registry::HKEY_USERS\$sid\Volatile Environment"
        $a1 = "`$id='$id';`$key='$key';"
        $a2 = "`$cmd='$($cmd -replace "'", "''")';"
        $a3 = "`$msgTitle='$($msgTitle -replace "'", "''")';"
        $a4 = "`$scriptDir='$($scriptDir -replace "'", "''")';"
        
        if (!(Test-Path $key)) {
            "Creating Volatile Environment key..." | Out-File $logFile -Append
            New-Item -Path "Registry::HKEY_USERS\$sid" -Name "Volatile Environment" -Force | Out-Null
        }
        
        Set-ItemProperty $key $id $($a1, $a2, $a3, $a4, $payload) -Type 7 -Force
        "Registry set successfully" | Out-File $logFile -Append
        
        $arg = "$a1 $a4 `$env:A = (Get-ItemProperty '$key').'$id' -join ''; Remove-ItemProperty '$key' '$id' -Force; iex `$env:A"
        
        "Launching elevated PowerShell..." | Out-File $logFile -Append
        Start-Process powershell -ArgumentList "-WindowStyle Hidden -NoProfile -Command `"$arg`"" -Verb RunAs -Wait
        
        # Cleanup Progress Bar (Success via Wait)
        try {
            $progressPidFile = "$env:TEMP\TI_Progress.pid"
            if (Test-Path $progressPidFile) {
                $pidVal = Get-Content $progressPidFile -ErrorAction SilentlyContinue
                if ($pidVal) { Stop-Process -Id $pidVal -Force -ErrorAction SilentlyContinue }
                Remove-Item $progressPidFile -Force -ErrorAction SilentlyContinue
            }
            $progressFile = "$env:TEMP\TI_Progress.ps1"
            if (Test-Path $progressFile) { Remove-Item $progressFile -Force -ErrorAction SilentlyContinue }
        } catch {}
        
    } catch {
        # Cleanup Progress Bar (Error)
        try {
            $progressPidFile = "$env:TEMP\TI_Progress.pid"
            if (Test-Path $progressPidFile) {
                $pidVal = Get-Content $progressPidFile -ErrorAction SilentlyContinue
                if ($pidVal) { Stop-Process -Id $pidVal -Force -ErrorAction SilentlyContinue }
                Remove-Item $progressPidFile -Force -ErrorAction SilentlyContinue
            }
            $progressFile = "$env:TEMP\TI_Progress.ps1"
            if (Test-Path $progressFile) { Remove-Item $progressFile -Force -ErrorAction SilentlyContinue }
        } catch {}

        "RunAsTI Exception: $($_.Exception.Message)" | Out-File $logFile -Append
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("Hata oluştu!`n`nDetay: $($_.Exception.Message)`n`nLog: $logFile", "TI Launcher Error", 0, 16)
    }
}

# --- PARAMETRE VE MOD KONTROLÜ ---
if (!$param -or ($param -and $param.Trim() -eq '')) {
    $argv = [Environment]::GetCommandLineArgs()
    if ($argv.Length -gt 1) {
        $candidate = $argv[-1]
        if ($candidate -and ($candidate -ne $env:SCRIPT_PATH) -and (Test-Path $candidate)) {
            $param = $candidate
        }
    }
}

if ($param -and $param.Trim() -ne '') 
{
    # >>> SÜRÜKLE BIRAK MODU (TI OLARAK ÇALIŞTIR) <<<
    $targetFile = $param.Trim()
    if ($targetFile -match '^\s*"(.*)"\s*$') { $targetFile = $matches[1] }
    Log "Drag/drop param detected: $targetFile"
    
    # Sürücü kontrolü (C:\ gibi)
    if ($targetFile -match '^([A-Za-z]):\\?$') {
        $driveLetter = $matches[1]
        Log "Detected drive: $driveLetter"
        $driveCmd = "explorer.exe `"$driveLetter`:\`""
        Log "Launching with: $driveCmd"
        RunAsTI $driveCmd "$driveLetter`:\"
    } elseif (Test-Path $targetFile) {
        try {
            $fullPath = (Resolve-Path $targetFile).Path
        } catch {
            # Resolve-Path başarısız olursa (sürücü gibi), direkt kullan
            $fullPath = $targetFile
        }
        Log "Resolved path: $fullPath"
        
        try {
            $item = Get-Item $fullPath -ErrorAction Stop
            if ($item.PSIsContainer) {
                # Klasörler için Explorer
                Log "Detected folder; launching explorer directly"
                $folderCmd = 'explorer.exe "' + $fullPath + '"'
                Log "Launching with: $folderCmd"
                RunAsTI $folderCmd $fullPath
            } else {
            # Dosyalar
            $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
            Log "Detected file; ext=$ext"
            
            switch ($ext) {
                '.exe' { $cmdToRun = "`"$fullPath`"" }
                '.bat' { $cmdToRun = "`"$fullPath`"" }
                '.cmd' { $cmdToRun = "`"$fullPath`"" }
                '.reg' { $cmdToRun = "reg import `"`"$fullPath`"`"" }
                '.ps1' { $cmdToRun = "powershell -ExecutionPolicy Bypass -File `"`"$fullPath`"`"" }
                '.msc' { $cmdToRun = "`"$fullPath`"" }
                '.cpl' { $cmdToRun = "control `"`"$fullPath`"`"" }
                default { $cmdToRun = "`"$fullPath`"" }
            }
            Log "Launching with: $cmdToRun"
            RunAsTI $cmdToRun $fullPath
            }
        } catch {
            # Hata durumunda sürücü olarak dene
            Log "Error processing path, trying as drive: $($_.Exception.Message)"
            if ($targetFile -match '^([A-Za-z]):') {
                $driveLetter = $matches[1]
                $driveCmd = "explorer.exe `"$driveLetter`:\`""
                Log "Launching drive with: $driveCmd"
                RunAsTI $driveCmd "$driveLetter`:\"
            } else {
                throw
            }
        }
    } else {
        # Dosya yolu değilse komut olarak algıla
        Log "Param is not a path; running as command"
        RunAsTI "$targetFile"
    }
} else {
    # >>> ARAYÜZ MODU (KURULUM/KALDIRMA/SEÇİM) <<<
    Log "No param; showing popup flow"
    Add-Type -AssemblyName System.Windows.Forms
    
    # Windows 7 uyumlu TopMost MessageBox
    function Show-TopMostMessageBox {
        param([string]$Message,[string]$Title,[int]$Buttons,[int]$Icon)
        $code = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern int MessageBox(IntPtr hWnd, String text, String caption, uint type);
}
"@
        try { Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue } catch {}
        $mbType = $Buttons + $Icon + 0x00040000
        return [Win32]::MessageBox([IntPtr]::Zero, $Message, $Title, $mbType)
    }
    
    Log "Showing first popup"
    try {
        $result = Show-TopMostMessageBox -Message $msg.PopupMsg -Title $msg.PopupTitle -Buttons 3 -Icon 64
    } catch {
        Log "TopMost popup failed, fallback"
        $result = [System.Windows.Forms.MessageBox]::Show($msg.PopupMsg, $msg.PopupTitle, 3, 64)
    }
    Log "First popup result: $result"
    
    # YES (6) = Manuel Çalıştır, NO (7) = Kurulum/Kaldırma
    if ($result -eq 6) {
        # Manuel Seçim
        Log "Showing choice popup"
        try {
            $choice = Show-TopMostMessageBox -Message $msg.ChoiceMsg -Title $msg.ChoiceTitle -Buttons 4 -Icon 32
        } catch {
            $choice = [System.Windows.Forms.MessageBox]::Show($msg.ChoiceMsg, $msg.ChoiceTitle, 4, 32)
        }
        
        if ($choice -eq 6) { 
            RunAsTI "cmd /k" 
        } else { 
            # Explorer'ı script'in bulunduğu dizinde aç
            $explorerPath = if ($env:SCRIPT_PATH) { 
                $scriptDir = Split-Path -Parent $env:SCRIPT_PATH
                if (Test-Path $scriptDir -PathType Container) {
                    $scriptDir
                } else {
                    $env:USERPROFILE
                }
            } else {
                $env:USERPROFILE
            }
            RunAsTI "explorer.exe `"$explorerPath`"" $explorerPath
        }
        
    } elseif ($result -eq 7) {
        # Kurulum Yönetimi
        Log "User chose install/uninstall path"
        $targetPath = "$env:SystemRoot\ti.bat"
        $isInstalled = Test-Path $targetPath
        Log "Is installed: $isInstalled"
        
        if ($isInstalled) {
            # Zaten kurulu -> Onar/Kaldır
            try {
                $reinstallChoice = Show-TopMostMessageBox -Message $msg.ReinstallMsg -Title $msg.ReinstallTitle -Buttons 3 -Icon 32
            } catch {
                $reinstallChoice = [System.Windows.Forms.MessageBox]::Show($msg.ReinstallMsg, $msg.ReinstallTitle, 3, 32)
            }
            
            if ($reinstallChoice -eq 6) { $installConfirm = 6 } # Reinstall
            elseif ($reinstallChoice -eq 7) {
                # --- KALDIRMA (REG DELETE) ---
                Log "User chose uninstall"
                try {
                    $successMsgUninstall = if ($isTurkish) { "Kaldırma işlemi başarıyla tamamlandı!" } else { "Uninstallation completed successfully!" }
                    $errorMsgUninstall = if ($isTurkish) { "Kaldırma sırasında hata oluştu!" } else { "An error occurred during uninstallation!" }
                    $successTitleUninstall = $msg.SuccessTitle
                    $errorTitleUninstall = $msg.ErrorTitle
                    
                    $uninstallScript = @"
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern int MessageBox(IntPtr hWnd, String text, String caption, uint type);
}
'@ -ErrorAction SilentlyContinue

`$isTurkish = '$isTurkish'
`$successMsg = '$($successMsgUninstall -replace "'","''")'
`$errorMsg = '$($errorMsgUninstall -replace "'","''")'
`$successTitle = '$($successTitleUninstall -replace "'","''")'
`$errorTitle = '$($errorTitleUninstall -replace "'","''")'

try {
    `$targetPath = "`$env:SystemRoot\ti.bat"
    Write-Host "Deleting file..." -ForegroundColor Yellow
    if (Test-Path `$targetPath) { Remove-Item `$targetPath -Force }
    
    Write-Host "Removing registry keys via REG DELETE..." -ForegroundColor Yellow
    
    cmd /c "reg delete `"HKCR\*\shell\RunAsTI`" /f 2>nul"
    cmd /c "reg delete `"HKCR\Directory\shell\RunAsTI`" /f 2>nul"
    cmd /c "reg delete `"HKCR\Directory\Background\shell\RunAsTI`" /f 2>nul"
    
    Write-Host "Done!" -ForegroundColor Green
    Start-Sleep -Seconds 1
    
    `$mbType = 0 + 64 + 0x00040000
    [Win32]::MessageBox([IntPtr]::Zero, `$successMsg, `$successTitle, `$mbType) | Out-Null
} catch {
    `$errMsg = `$errorMsg + "`n`n" + `$_.Exception.Message
    `$mbType = 0 + 16 + 0x00040000
    [Win32]::MessageBox([IntPtr]::Zero, `$errMsg, `$errorTitle, `$mbType) | Out-Null
}
"@
                    $tempPs1 = "$env:TEMP\TI_Uninstall.ps1"
                    $uninstallScript | Out-File $tempPs1 -Encoding UTF8
                    Log "Starting uninstall script"
                    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempPs1`"" -Verb RunAs -Wait
                    Remove-Item $tempPs1 -Force -ErrorAction SilentlyContinue
                } catch {
                    Show-TopMostMessageBox -Message ($msg.UninstallError + $_.Exception.Message) -Title $msg.ErrorTitle -Buttons 0 -Icon 16
                }
                return
            } else { return } # Cancel
        } else {
            # Kurulu değil -> Kur
            try {
                $installConfirm = Show-TopMostMessageBox -Message $msg.InstallMsg -Title $msg.InstallTitle -Buttons 4 -Icon 32
            } catch {
                $installConfirm = [System.Windows.Forms.MessageBox]::Show($msg.InstallMsg, $msg.InstallTitle, 4, 32)
            }
        }
        
        if ($installConfirm -eq 6) {
            # --- KURULUM (REG ADD) ---
            Log "Starting install flow"
            try {
                $currentScriptPath = $env:SCRIPT_PATH
                if (!$currentScriptPath -or !(Test-Path $currentScriptPath)) { throw "Cannot find script path" }
                
                $successMsgInstall = if ($isTurkish) { "Kurulum başarıyla tamamlandı!" } else { "Installation completed successfully!" }
                $errorMsgInstall = if ($isTurkish) { "Kurulum hatası: " } else { "Installation error: " }
                $menuTextInstall = if ($isTurkish) { "Trusted Installer Yetkisiyle Aç" } else { "Open with Trusted Installer Privileges." }
                $successTitleInstall = $msg.SuccessTitle
                $errorTitleInstall = $msg.ErrorTitle
                
                $installScript = @"
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern int MessageBox(IntPtr hWnd, String text, String caption, uint type);
}
'@ -ErrorAction SilentlyContinue

`$ErrorActionPreference = 'Stop'
`$scriptPath = '$($currentScriptPath -replace "'","''")'
`$targetPath = "`$env:SystemRoot\ti.bat"
`$successMsg = '$($successMsgInstall -replace "'","''")'
`$errorMsg = '$($errorMsgInstall -replace "'","''")'
`$menuText = '$($menuTextInstall -replace "'","''")'
`$successTitle = '$($successTitleInstall -replace "'","''")'
`$errorTitle = '$($errorTitleInstall -replace "'","''")'

try {
    Copy-Item `$scriptPath `$targetPath -Force
    Write-Host "File copied to: `$targetPath" -ForegroundColor Green
    
    Write-Host "Adding Registry Keys via REG ADD..." -ForegroundColor Yellow
    
    `$cmdVal = '\"C:\Windows\ti.bat\" \"%1\"'
    `$cmdValBg = '\"C:\Windows\ti.bat\" \"%V\"'
    
    # 1. DOSYALAR (*)
    & reg.exe add "HKCR\*\shell\RunAsTI" /ve /d "`$menuText" /f
    & reg.exe add "HKCR\*\shell\RunAsTI" /v MUIVerb /d "`$menuText" /f
    & reg.exe add "HKCR\*\shell\RunAsTI" /v Icon /d "imageres.dll,-78" /f
    & reg.exe add "HKCR\*\shell\RunAsTI\command" /ve /d `$cmdVal /f
    
    # 2. KLASÖRLER (Directory)
    & reg.exe add "HKCR\Directory\shell\RunAsTI" /ve /d "`$menuText" /f
    & reg.exe add "HKCR\Directory\shell\RunAsTI" /v MUIVerb /d "`$menuText" /f
    & reg.exe add "HKCR\Directory\shell\RunAsTI" /v Icon /d "imageres.dll,-78" /f
    & reg.exe add "HKCR\Directory\shell\RunAsTI\command" /ve /d `$cmdVal /f

    # 3. KLASÖR ARKAPLANI (Background - %V)
    & reg.exe add "HKCR\Directory\Background\shell\RunAsTI" /ve /d "`$menuText" /f
    & reg.exe add "HKCR\Directory\Background\shell\RunAsTI" /v MUIVerb /d "`$menuText" /f
    & reg.exe add "HKCR\Directory\Background\shell\RunAsTI" /v Icon /d "imageres.dll,-78" /f
    & reg.exe add "HKCR\Directory\Background\shell\RunAsTI\command" /ve /d `$cmdValBg /f
    
    Write-Host "Registry entries created!" -ForegroundColor Green
    Start-Sleep -Seconds 1
    
    `$mbType = 0 + 64 + 0x00040000
    [Win32]::MessageBox([IntPtr]::Zero, `$successMsg, `$successTitle, `$mbType) | Out-Null
} catch {
    `$err = `$_.Exception.Message
    Write-Host "Error: `$err" -ForegroundColor Red
    `$errMsg = `$errorMsg + `$err
    `$mbType = 0 + 16 + 0x00040000
    [Win32]::MessageBox([IntPtr]::Zero, `$errMsg, `$errorTitle, `$mbType) | Out-Null
}
"@
                $tempPs1 = "$env:TEMP\TI_Install.ps1"
                $installScript | Out-File $tempPs1 -Encoding UTF8
                Log "Executing install script"
                $proc = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempPs1`"" -Verb RunAs -WindowStyle Normal -Wait -PassThru
                if ($proc.ExitCode -ne 0) {
                    Log "Install script exited with code $($proc.ExitCode)"
                }
                Remove-Item $tempPs1 -Force -ErrorAction SilentlyContinue
                
            } catch {
                Log "Install flow error: $($_.Exception.Message)"
                Show-TopMostMessageBox -Message ($msg.InstallError + $_.Exception.Message) -Title $msg.ErrorTitle -Buttons 0 -Icon 16
            }
        }
    }
}