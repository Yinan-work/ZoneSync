#Requires -Version 5.0
#Requires -RunAsAdministrator

$CurrentVersion = "1.0.0"

# 函数：设置地区、时区和同步时间
function Set-SystemRegionAndTime {
    param (
        [string]$LocationName,
        [int]$GeoId,
        [string]$TimeZoneId
    )

    Write-Host "--------------------------------------------------"
    Write-Host "正在为 '$LocationName' 配置系统设置..."
    Write-Host "--------------------------------------------------"

    # 1. 设置地区 (Home Location)
    try {
        Write-Host "1. 正在设置地区为 '$LocationName' (GeoID: $GeoId)..."
        Set-WinHomeLocation -GeoId $GeoId
        $currentHomeLocation = Get-WinHomeLocation
        if ($currentHomeLocation.GeoId -eq $GeoId) {
            Write-Host "   成功：地区已设置为 '$($currentHomeLocation.Description)'." -ForegroundColor Green
        }
        else {
            Write-Warning "   警告：地区设置后验证失败。当前 GeoID: $($currentHomeLocation.GeoId)"
        }
    }
    catch {
        Write-Error "   错误：设置地区失败: $($_.Exception.Message)"
    }
    Write-Host ""

    # 2. 设置时区
    try {
        Write-Host "2. 正在设置时区为 '$TimeZoneId'..."
        Set-TimeZone -Id $TimeZoneId
        $currentTimeZone = Get-TimeZone
        if ($currentTimeZone.Id -eq $TimeZoneId) {
            Write-Host "   成功：时区已设置为 '$($currentTimeZone.DisplayName)'." -ForegroundColor Green
        }
        else {
            Write-Warning "   警告：时区设置后验证失败。当前时区 ID: $($currentTimeZone.Id)"
        }
    }
    catch {
        Write-Error "   错误：设置时区失败: $($_.Exception.Message)"
    }
    Write-Host ""

    # 3. 同步系统时间
    try {
        Write-Host "3. 正在同步系统时间..."
        # 确保 Windows Time 服务正在运行
        $timeService = Get-Service -Name w32time -ErrorAction SilentlyContinue
        if ($timeService -and $timeService.Status -ne 'Running') {
            Write-Host "   Windows Time 服务 (w32time) 未运行，尝试启动..."
            Start-Service -Name w32time -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3 # 等待服务启动
        }

        # 强制与时间服务器同步
        w32tm /resync /force | Out-Null
        Start-Sleep -Seconds 3 # 给点时间同步

        # 检查同步状态 (可选，但推荐)
        $syncStatus = w32tm /query /status /verbose
        if ($syncStatus -match "Last successful sync time: (?!never)" -and $syncStatus -notmatch "Source: Local CMOS Clock") {
            Write-Host "   成功：系统时间已与时间服务器同步。" -ForegroundColor Green
            Write-Host "   当前系统时间: $(Get-Date)"
        }
        elseif ($syncStatus -match "Source: Local CMOS Clock") {
            Write-Warning "   警告：系统时间当前使用本地CMOS时钟，可能未与外部时间服务器同步。"
            Write-Host "   当前系统时间: $(Get-Date)"
        }
        else {
            Write-Warning "   警告：时间同步可能未成功或无法确认。请检查网络连接和 Windows Time 服务配置。"
            Write-Host "   当前系统时间: $(Get-Date)"
        }
    }
    catch {
        Write-Error "   错误：同步系统时间失败: $($_.Exception.Message)"
    }
    Write-Host "--------------------------------------------------"
    Write-Host "配置完成。"
    Write-Host "--------------------------------------------------"
}

# -------------------------------------------------------------------------
# 新增辅助函数
# -------------------------------------------------------------------------

# 函数：检查更新
function Check-Update {
    try {
        Write-Host "正在检查更新..."
        $versionUrl = "https://raw.githubusercontent.com/Yinan-work/ZoneSync/main/version.txt"
        $latestVersion = (Invoke-RestMethod -Uri $versionUrl -ErrorAction Stop).Trim()
        
        if ($latestVersion -ne $CurrentVersion) {
            Write-Host "发现新版本: $latestVersion (当前版本: $CurrentVersion)" -ForegroundColor Yellow
            $updateChoice = Read-Host "是否立即下载并更新？(Y/N)"
            if ($updateChoice -match '^[Yy]$') {
                Write-Host "正在下载最新代码..."
                $scriptUrl = "https://raw.githubusercontent.com/Yinan-work/ZoneSync/main/Set-Location.ps1"
                $scriptPath = $PSCommandPath
                Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath
                Write-Host "更新完成！请重新运行脚本以应用新版本。" -ForegroundColor Green
                Read-Host "按 Enter 键退出..."
                exit
            }
        } else {
            Write-Host "当前已是最新版本 ($CurrentVersion)。" -ForegroundColor Green
        }
    } catch {
        Write-Warning "检查更新失败，请检查网络或仓库是否已公开: $($_.Exception.Message)"
    }
}

# 函数：获取 IP 地址和地理位置信息
function Get-IPLocation {
    try {
        Write-Host "正在通过 ip-api.com 获取位置信息..."
        $response = Invoke-RestMethod -Uri "http://ip-api.com/json" -ErrorAction Stop
        if ($response.status -eq 'fail') {
            throw "API 返回失败: $($response.message)"
        }
        return $response
    }
    catch {
        Write-Error "无法获取 IP 位置信息: $($_.Exception.Message)"
        return $null
    }
}

# 函数：根据城市名搜索地理位置和时区
function Get-CityLocation {
    param([string]$CityName)
    try {
        Write-Host "正在搜索城市 '$CityName' 的位置信息..."
        # 使用 open-meteo 免费 API
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
            Write-Warning "未找到该城市的位置信息，请检查拼写（中英皆可）。"
            return $null
        }
    } catch {
        Write-Error "调用外部搜索 API 失败: $($_.Exception.Message)"
        return $null
    }
}

# 函数：根据国家代码获取 Windows GeoID
function Get-GeoIdFromCountryCode {
    param ([string]$CountryCode)
    try {
        if ([string]::IsNullOrWhiteSpace($CountryCode)) { return $null }
        # 使用 .NET RegionInfo 类
        $region = [System.Globalization.RegionInfo]::new($CountryCode)
        return $region.GeoId
    }
    catch {
        Write-Warning "无法解析国家代码 '$CountryCode' 的 GeoID。"
        return $null
    }
}

# 函数：将 IANA 时区 (如 Asia/Shanghai) 转换为 Windows 时区 ID
function Get-WindowsTimeZoneId {
    param ([string]$IanaTimeZone)

    # 常见时区映射表 (根据需要添加更多)
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
    
    # 尝试直接匹配 (有些系统可能已经支持或名字本身很像)
    try {
        $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($IanaTimeZone)
        return $tz.Id
    } catch {
        return $null
    }
}

# -------------------------------------------------------------------------
# 主程序逻辑
# -------------------------------------------------------------------------

Clear-Host
Write-Host "Windows 地区和时间设置工具 v$CurrentVersion"
Write-Host "============================="
Write-Host ""
Write-Host "请选择要应用的功能："
Write-Host "0. 自动检测 (基于当前网络 IP)"
Write-Host "1. 手动输入城市 (例如: Beijing, New York, 巴黎)"
Write-Host "2. 检查更新"
Write-Host "Q. 退出 (Quit)"
Write-Host ""

$choice = Read-Host "请输入您的选择 (0, 1, 2, 或 Q)"

switch ($choice) {
    "0" {
        # 自动检测
        $ipInfo = Get-IPLocation
        if ($ipInfo) {
            Write-Host "检测到位置: $($ipInfo.country) ($($ipInfo.countryCode)), 城市: $($ipInfo.city)"
            Write-Host "检测到时区: $($ipInfo.timezone)"
            
            # 解析 GeoID
            $geoId = Get-GeoIdFromCountryCode -CountryCode $ipInfo.countryCode
            if (-not $geoId) {
                Write-Warning "无法自动确定因为地区的 GeoID。将跳过地区设置。"
            }

            # 解析 TimeZone
            $winTimeZoneId = Get-WindowsTimeZoneId -IanaTimeZone $ipInfo.timezone
            if (-not $winTimeZoneId) {
                Write-Warning "无法找到 IANA 时区 '$($ipInfo.timezone)' 对应的 Windows 时区 ID。"
                $winTimeZoneId = Read-Host "请手动输入 Windows 时区 ID (留空跳过)"
            }

            if ($geoId -or $winTimeZoneId) {
                $locationName = "自动检测 - $($ipInfo.country)/$($ipInfo.city)"
                Set-SystemRegionAndTime -LocationName $locationName -GeoId $geoId -TimeZoneId $winTimeZoneId
            }
        } else {
            Write-Error "无法自动检测信息，操作已取消。"
        }
    }
    "1" {
        # 手动输入城市
        $inputCity = Read-Host "请输入城市名称 (中英文皆可，例如 'Tokyo' 或 '东京')"
        if (-not [string]::IsNullOrWhiteSpace($inputCity)) {
            $cityInfo = Get-CityLocation -CityName $inputCity
            if ($cityInfo) {
                Write-Host "解析到位置: $($cityInfo.Country) ($($cityInfo.CountryCode)), 城市: $($cityInfo.City)"
                Write-Host "解析到时区: $($cityInfo.TimeZone)"
                
                # 解析 GeoID
                $geoId = Get-GeoIdFromCountryCode -CountryCode $cityInfo.CountryCode
                if (-not $geoId) {
                    Write-Warning "无法确定该地区的 GeoID。将跳过地区设置。"
                }

                # 解析 TimeZone
                $winTimeZoneId = Get-WindowsTimeZoneId -IanaTimeZone $cityInfo.TimeZone
                if (-not $winTimeZoneId) {
                    Write-Warning "无法找到 IANA 时区 '$($cityInfo.TimeZone)' 对应的 Windows 时区 ID。"
                    $winTimeZoneId = Read-Host "请手动输入 Windows 时区 ID (留空跳过)"
                }

                if ($geoId -or $winTimeZoneId) {
                    $locationName = "手动设定 - $($cityInfo.Country)/$($cityInfo.City)"
                    Set-SystemRegionAndTime -LocationName $locationName -GeoId $geoId -TimeZoneId $winTimeZoneId
                }
            }
        } else {
            Write-Warning "城市名称不能为空。"
        }
    }
    "2" {
        # 检查更新
        Check-Update
    }
    "Q" {
        Write-Host "用户选择退出。"
    }
    default {
        Write-Warning "无效的选择 '$choice'。脚本将退出。"
    }
}

Write-Host ""
Read-Host "按 Enter 键关闭窗口..."
