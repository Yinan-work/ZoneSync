#Requires -Version 5.0
#Requires -RunAsAdministrator

$CurrentVersion = "1.0.1"

# --- i18n / 多语言配置 ---
$Lang = if ((Get-UICulture).TwoLetterISOLanguageName -eq 'zh') { 'zh' } else { 'en' }
$L = @{}

if ($Lang -eq 'zh') {
    $L.HeaderConfig       = "正在为 '{0}' 配置系统设置..."
    $L.SetHomeStep        = "1. 正在设置地区为 '{0}' (GeoID: {1})..."
    $L.SetHomeSuccess     = "   成功：地区已设置为 '{0}'。"
    $L.SetHomeWarn        = "   警告：地区设置后验证失败。当前 GeoID: {0}"
    $L.SetHomeError       = "   错误：设置地区失败: {0}"
    $L.SetTimeStep        = "2. 正在设置时区为 '{0}'..."
    $L.SetTimeSuccess     = "   成功：时区已设置为 '{0}'。"
    $L.SetTimeWarn        = "   警告：时区设置后验证失败。当前时区 ID: {0}"
    $L.SetTimeError       = "   错误：设置时区失败: {0}"
    $L.SyncTimeStep       = "3. 正在同步系统时间..."
    $L.SyncTimeSvcStart   = "   Windows Time 服务 (w32time) 未运行，尝试启动..."
    $L.SyncTimeSuccess    = "   成功：系统时间已与时间服务器同步。"
    $L.SyncTimeWarnLocal  = "   警告：系统时间当前使用本地 CMOS 时钟，可能未与外部时间服务器同步。"
    $L.SyncTimeWarnUnconf = "   警告：时间同步可能未成功或无法确认。请检查网络连接和 Windows Time 服务配置。"
    $L.SyncTimeError      = "   错误：同步系统时间失败: {0}"
    $L.CurrentSystemTime  = "   当前系统时间: {0}"
    $L.ConfigComplete     = "配置完成。"
    
    $L.CheckUpdateStart   = "正在检查更新..."
    $L.CheckUpdateNew     = "发现新版本: {0} (当前版本: {1})"
    $L.CheckUpdatePrompt  = "是否立即下载并更新？(Y/N)"
    $L.CheckUpdateDL      = "正在下载最新代码..."
    $L.CheckUpdateDone    = "更新完成！请重新运行脚本以应用新版本。"
    $L.CheckUpdateExit    = "按 Enter 键退出..."
    $L.CheckUpdateLatest  = "当前已是最新版本 ({0})。"
    $L.CheckUpdateFail    = "检查更新失败，请检查网络: {0}"
    
    $L.IPLocFetching      = "正在通过 ip-api.com 获取位置信息..."
    $L.IPLocFail          = "无法获取 IP 位置信息: {0}"
    
    $L.CitySearching      = "正在搜索城市 '{0}' 的位置信息..."
    $L.CityNotFound       = "未找到该城市的位置信息，请检查拼写（中英皆可）。"
    $L.CityApiFail        = "调用外部搜索 API 失败: {0}"
    
    $L.GeoIdParseFail     = "无法解析国家代码 '{0}' 的 GeoID。"
    
    $L.MenuTitle          = "ZoneSync - Windows 地区和时间设置工具 v{0}"
    $L.MenuOpt1           = "1: 自动检测当前位置并应用"
    $L.MenuOpt2           = "2: 手动输入城市名称"
    $L.MenuOpt3           = "3: 检查脚本更新"
    $L.MenuOptQ           = "Q: 退出"
    $L.MenuPrompt         = "请输入您的选择 (1, 2, 3, 或 Q)"
    $L.MenuInvalid        = "无效的选择 '{0}'。脚本将退出。"
    $L.MenuExit           = "用户选择退出。"
    $L.MenuPressEnter     = "按 Enter 键关闭窗口..."
    
    $L.AutoDetectLoc      = "检测到位置: {0} ({1}), 城市: {2}"
    $L.AutoDetectTz       = "检测到时区: {0}"
    $L.AutoDetectGeoWarn  = "无法自动确定该地区的 GeoID。将跳过地区设置。"
    $L.AutoDetectTzWarn   = "无法找到 IANA 时区 '{0}' 对应的 Windows 时区 ID。"
    $L.AutoDetectTzPrompt = "请手动输入 Windows 时区 ID (留空跳过)"
    $L.AutoDetectFail     = "无法自动检测信息，操作已取消。"
    $L.AutoDetectName     = "自动检测 - {0}/{1}"
    
    $L.ManualPrompt       = "请输入城市名称 (中英文皆可，例如 'Tokyo' 或 '东京')"
    $L.ManualEmpty        = "城市名称不能为空。"
    $L.ManualLoc          = "解析到位置: {0} ({1}), 城市: {2}"
    $L.ManualName         = "手动设定 - {0}/{1}"
} else {
    $L.HeaderConfig       = "Configuring system settings for '{0}'..."
    $L.SetHomeStep        = "1. Setting Home Location to '{0}' (GeoID: {1})..."
    $L.SetHomeSuccess     = "   Success: Home Location set to '{0}'."
    $L.SetHomeWarn        = "   Warning: Verification failed. Current GeoID: {0}"
    $L.SetHomeError       = "   Error: Failed to set Home Location: {0}"
    $L.SetTimeStep        = "2. Setting Time Zone to '{0}'..."
    $L.SetTimeSuccess     = "   Success: Time Zone set to '{0}'."
    $L.SetTimeWarn        = "   Warning: Verification failed. Current Time Zone ID: {0}"
    $L.SetTimeError       = "   Error: Failed to set Time Zone: {0}"
    $L.SyncTimeStep       = "3. Synchronizing system time..."
    $L.SyncTimeSvcStart   = "   Windows Time service (w32time) is not running. Attempting to start it..."
    $L.SyncTimeSuccess    = "   Success: System time synchronized with the time server."
    $L.SyncTimeWarnLocal  = "   Warning: System is using the Local CMOS Clock. Time may not be synchronized with an external server."
    $L.SyncTimeWarnUnconf = "   Warning: Time sync status unconfirmed. Please check your network connection or w32time configuration."
    $L.SyncTimeError      = "   Error: Failed to sync system time: {0}"
    $L.CurrentSystemTime  = "   Current System Time: {0}"
    $L.ConfigComplete     = "Configuration complete."
    
    $L.CheckUpdateStart   = "Checking for updates..."
    $L.CheckUpdateNew     = "New version available: {0} (Current: {1})"
    $L.CheckUpdatePrompt  = "Would you like to download and update now? (Y/N)"
    $L.CheckUpdateDL      = "Downloading the latest release..."
    $L.CheckUpdateDone    = "Update complete! Please restart the script to apply the changes."
    $L.CheckUpdateExit    = "Press Enter to exit..."
    $L.CheckUpdateLatest  = "You are up to date ({0})."
    $L.CheckUpdateFail    = "Update check failed. Please check your network: {0}"
    
    $L.IPLocFetching      = "Fetching location data via ip-api.com..."
    $L.IPLocFail          = "Failed to retrieve IP location: {0}"
    
    $L.CitySearching      = "Searching for location data for '{0}'..."
    $L.CityNotFound       = "Location not found. Please check your spelling."
    $L.CityApiFail        = "External search API failed: {0}"
    
    $L.GeoIdParseFail     = "Failed to parse GeoID for country code '{0}'."
    
    $L.MenuTitle          = "ZoneSync - Windows Region & Time Zone Configuration Tool v{0}"
    $L.MenuOpt1           = "1: Auto-detect location and apply."
    $L.MenuOpt2           = "2: Manually input a city name."
    $L.MenuOpt3           = "3: Check for script updates."
    $L.MenuOptQ           = "Q: Quit."
    $L.MenuPrompt         = "Enter your choice (1, 2, 3, or Q)"
    $L.MenuInvalid        = "Invalid choice '{0}'. Exiting."
    $L.MenuExit           = "Exiting."
    $L.MenuPressEnter     = "Press Enter to close this window..."
    
    $L.AutoDetectLoc      = "Detected Location: {0} ({1}), City: {2}"
    $L.AutoDetectTz       = "Detected Time Zone: {0}"
    $L.AutoDetectGeoWarn  = "Unable to determine the GeoID for this region. Skipping Home Location setup."
    $L.AutoDetectTzWarn   = "Could not map IANA time zone '{0}' to a Windows Time Zone ID."
    $L.AutoDetectTzPrompt = "Please enter a valid Windows Time Zone ID manually (or leave blank to skip)"
    $L.AutoDetectFail     = "Auto-detection failed. Operation aborted."
    $L.AutoDetectName     = "Auto-Detect - {0}/{1}"
    
    $L.ManualPrompt       = "Enter a city name (e.g., 'Tokyo' or 'Paris')"
    $L.ManualEmpty        = "City name cannot be empty."
    $L.ManualLoc          = "Resolved Location: {0} ({1}), City: {2}"
    $L.ManualName         = "Manual Setup - {0}/{1}"
}

# -------------------------------------------------------------------------

# Function: Set Region, Time Zone, and sync time
function Set-SystemRegionAndTime {
    param (
        [string]$LocationName,
        [int]$GeoId,
        [string]$TimeZoneId
    )

    Write-Host "--------------------------------------------------"
    Write-Host ($L.HeaderConfig -f $LocationName)
    Write-Host "--------------------------------------------------"

    # 1. Set Home Location
    try {
        Write-Host ($L.SetHomeStep -f $LocationName, $GeoId)
        Set-WinHomeLocation -GeoId $GeoId
        $currentHomeLocation = Get-WinHomeLocation
        if ($currentHomeLocation.GeoId -eq $GeoId) {
            Write-Host ($L.SetHomeSuccess -f $currentHomeLocation.Description) -ForegroundColor Green
        }
        else {
            Write-Warning ($L.SetHomeWarn -f $currentHomeLocation.GeoId)
        }
    }
    catch {
        Write-Error ($L.SetHomeError -f $_.Exception.Message)
    }
    Write-Host ""

    # 2. Set Time Zone
    try {
        Write-Host ($L.SetTimeStep -f $TimeZoneId)
        Set-TimeZone -Id $TimeZoneId
        $currentTimeZone = Get-TimeZone
        if ($currentTimeZone.Id -eq $TimeZoneId) {
            Write-Host ($L.SetTimeSuccess -f $currentTimeZone.DisplayName) -ForegroundColor Green
        }
        else {
            Write-Warning ($L.SetTimeWarn -f $currentTimeZone.Id)
        }
    }
    catch {
        Write-Error ($L.SetTimeError -f $_.Exception.Message)
    }
    Write-Host ""

    # 3. Sync System Time
    try {
        Write-Host $L.SyncTimeStep
        $timeService = Get-Service -Name w32time -ErrorAction SilentlyContinue
        if ($timeService -and $timeService.Status -ne 'Running') {
            Write-Host $L.SyncTimeSvcStart
            Start-Service -Name w32time -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
        }

        w32tm /resync /force | Out-Null
        Start-Sleep -Seconds 3

        $syncStatus = w32tm /query /status /verbose
        if ($syncStatus -match "Last successful sync time: (?!never)" -and $syncStatus -notmatch "Source: Local CMOS Clock") {
            Write-Host $L.SyncTimeSuccess -ForegroundColor Green
            Write-Host ($L.CurrentSystemTime -f (Get-Date))
        }
        elseif ($syncStatus -match "Source: Local CMOS Clock") {
            Write-Warning $L.SyncTimeWarnLocal
            Write-Host ($L.CurrentSystemTime -f (Get-Date))
        }
        else {
            Write-Warning $L.SyncTimeWarnUnconf
            Write-Host ($L.CurrentSystemTime -f (Get-Date))
        }
    }
    catch {
        Write-Error ($L.SyncTimeError -f $_.Exception.Message)
    }
    Write-Host "--------------------------------------------------"
    Write-Host $L.ConfigComplete
    Write-Host "--------------------------------------------------"
}

# -------------------------------------------------------------------------
# Helper Functions
# -------------------------------------------------------------------------

function Check-Update {
    try {
        Write-Host $L.CheckUpdateStart
        $versionUrl = "https://raw.githubusercontent.com/Yinan-work/ZoneSync/main/version.txt"
        $latestVersion = (Invoke-RestMethod -Uri $versionUrl -ErrorAction Stop).Trim()
        
        if ($latestVersion -ne $CurrentVersion) {
            Write-Host ($L.CheckUpdateNew -f $latestVersion, $CurrentVersion) -ForegroundColor Yellow
            $updateChoice = Read-Host $L.CheckUpdatePrompt
            if ($updateChoice -match '^[Yy]$') {
                Write-Host $L.CheckUpdateDL
                $scriptUrl = "https://raw.githubusercontent.com/Yinan-work/ZoneSync/main/Set-Location.ps1"
                $scriptPath = $PSCommandPath
                Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath
                Write-Host $L.CheckUpdateDone -ForegroundColor Green
                Read-Host $L.CheckUpdateExit
                exit
            }
        } else {
            Write-Host ($L.CheckUpdateLatest -f $CurrentVersion) -ForegroundColor Green
        }
    } catch {
        Write-Warning ($L.CheckUpdateFail -f $_.Exception.Message)
    }
}

function Get-IPLocation {
    try {
        Write-Host $L.IPLocFetching
        $response = Invoke-RestMethod -Uri "http://ip-api.com/json" -ErrorAction Stop
        if ($response.status -eq 'fail') {
            throw "API request failed: $($response.message)"
        }
        return $response
    }
    catch {
        Write-Error ($L.IPLocFail -f $_.Exception.Message)
        return $null
    }
}

function Get-CityLocation {
    param([string]$CityName)
    try {
        Write-Host ($L.CitySearching -f $CityName)
        $uri = "https://geocoding-api.open-meteo.com/v1/search?name=$([uri]::EscapeDataString($CityName))&count=1&language=en&format=json"
        $response = Invoke-RestMethod -Uri $uri -ErrorAction Stop
        
        if ($response.results -and $response.results.Count -gt 0) {
            $result = $response.results[0]
            return @{
                Country = $result.country
                CountryCode = $result.country_code
                City = $result.name
                TimeZone = $result.timezone
            }
        } else {
            Write-Warning $L.CityNotFound
            return $null
        }
    } catch {
        Write-Error ($L.CityApiFail -f $_.Exception.Message)
        return $null
    }
}

function Get-GeoIdFromCountryCode {
    param ([string]$CountryCode)
    try {
        if ([string]::IsNullOrWhiteSpace($CountryCode)) { return $null }
        $region = [System.Globalization.RegionInfo]::new($CountryCode)
        return $region.GeoId
    }
    catch {
        Write-Warning ($L.GeoIdParseFail -f $CountryCode)
        return $null
    }
}

function Get-WindowsTimeZoneId {
    param ([string]$IanaTimeZone)

    $ianaToWindows = @{
        "Asia/Shanghai"       = "China Standard Time"
        "Asia/Chongqing"      = "China Standard Time"
        "Asia/Hong_Kong"      = "China Standard Time"
        "Asia/Urumqi"         = "China Standard Time"
        "Asia/Singapore"      = "Singapore Standard Time"
        "Asia/Tokyo"          = "Tokyo Standard Time"
        "Asia/Seoul"          = "Korea Standard Time"
        "Asia/Taipei"         = "Taipei Standard Time"
        
        "America/New_York"    = "Eastern Standard Time"
        "America/Detroit"     = "Eastern Standard Time"
        "America/Toronto"     = "Eastern Standard Time"
        "America/Chicago"     = "Central Standard Time"
        "America/Los_Angeles" = "Pacific Standard Time"
        "America/Vancouver"   = "Pacific Standard Time"
        "America/Phoenix"     = "US Mountain Standard Time"
        "America/Denver"      = "Mountain Standard Time"
        "Pacific/Honolulu"    = "Hawaiian Standard Time"
        "America/Anchorage"   = "Alaskan Standard Time"

        "Europe/London"       = "GMT Standard Time"
        "Europe/Paris"        = "Romance Standard Time"
        "Europe/Berlin"       = "W. Europe Standard Time"
        "Europe/Moscow"       = "Russian Standard Time"
        
        "Australia/Sydney"    = "AUS Eastern Standard Time"
        "Australia/Perth"     = "W. Australia Standard Time"
    }

    if ($ianaToWindows.ContainsKey($IanaTimeZone)) {
        return $ianaToWindows[$IanaTimeZone]
    }
    
    try {
        $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($IanaTimeZone)
        return $tz.Id
    } catch {
        return $null
    }
}

# -------------------------------------------------------------------------
# Main Logic
# -------------------------------------------------------------------------

do {
    Clear-Host
    Write-Host "================================================================"
    Write-Host ($L.MenuTitle -f $CurrentVersion)
    Write-Host "================================================================"
    Write-Host ""
    Write-Host $L.MenuOpt1
    Write-Host $L.MenuOpt2
    Write-Host $L.MenuOpt3
    Write-Host $L.MenuOptQ
    Write-Host ""

    $choice = Read-Host $L.MenuPrompt

    switch ($choice) {
    "1" {
        $ipInfo = Get-IPLocation
        if ($ipInfo) {
            Write-Host ($L.AutoDetectLoc -f $ipInfo.country, $ipInfo.countryCode, $ipInfo.city)
            Write-Host ($L.AutoDetectTz -f $ipInfo.timezone)
            
            $geoId = Get-GeoIdFromCountryCode -CountryCode $ipInfo.countryCode
            if (-not $geoId) {
                Write-Warning $L.AutoDetectGeoWarn
            }

            $winTimeZoneId = Get-WindowsTimeZoneId -IanaTimeZone $ipInfo.timezone
            if (-not $winTimeZoneId) {
                Write-Warning ($L.AutoDetectTzWarn -f $ipInfo.timezone)
                $winTimeZoneId = Read-Host $L.AutoDetectTzPrompt
            }

            if ($geoId -or $winTimeZoneId) {
                $locationName = ($L.AutoDetectName -f $ipInfo.country, $ipInfo.city)
                Set-SystemRegionAndTime -LocationName $locationName -GeoId $geoId -TimeZoneId $winTimeZoneId
            }
        } else {
            Write-Error $L.AutoDetectFail
        }
    }
    "2" {
        $inputCity = Read-Host $L.ManualPrompt
        if (-not [string]::IsNullOrWhiteSpace($inputCity)) {
            $cityInfo = Get-CityLocation -CityName $inputCity
            if ($cityInfo) {
                Write-Host ($L.ManualLoc -f $cityInfo.Country, $cityInfo.CountryCode, $cityInfo.City)
                Write-Host ($L.AutoDetectTz -f $cityInfo.TimeZone)
                
                $geoId = Get-GeoIdFromCountryCode -CountryCode $cityInfo.CountryCode
                if (-not $geoId) {
                    Write-Warning $L.AutoDetectGeoWarn
                }

                $winTimeZoneId = Get-WindowsTimeZoneId -IanaTimeZone $cityInfo.TimeZone
                if (-not $winTimeZoneId) {
                    Write-Warning ($L.AutoDetectTzWarn -f $cityInfo.TimeZone)
                    $winTimeZoneId = Read-Host $L.AutoDetectTzPrompt
                }

                if ($geoId -or $winTimeZoneId) {
                    $locationName = ($L.ManualName -f $cityInfo.Country, $cityInfo.City)
                    Set-SystemRegionAndTime -LocationName $locationName -GeoId $geoId -TimeZoneId $winTimeZoneId
                }
            }
        } else {
            Write-Warning $L.ManualEmpty
        }
    }
    "3" {
        Check-Update
    }
    "Q" {
        Write-Host $L.MenuExit
        exit
    }
    default {
        Write-Warning ($L.MenuInvalid -f $choice)
    }
}

if ($choice -ne "Q" -and $choice -ne "q") {
    Write-Host ""
    Read-Host $L.MenuPressEnter
}
} while ($true)
