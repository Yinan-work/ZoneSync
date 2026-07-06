#Requires -Version 5.0
#Requires -RunAsAdministrator

$CurrentVersion = "1.0.0"

# Function: Set Region, Time Zone, and sync time
function Set-SystemRegionAndTime {
    param (
        [string]$LocationName,
        [int]$GeoId,
        [string]$TimeZoneId
    )

    Write-Host "--------------------------------------------------"
    Write-Host "Configuring system settings for '$LocationName'..."
    Write-Host "--------------------------------------------------"

    # 1. Set Home Location
    try {
        Write-Host "1. Setting Home Location to '$LocationName' (GeoID: $GeoId)..."
        Set-WinHomeLocation -GeoId $GeoId
        $currentHomeLocation = Get-WinHomeLocation
        if ($currentHomeLocation.GeoId -eq $GeoId) {
            Write-Host "   Success: Home Location set to '$($currentHomeLocation.Description)'." -ForegroundColor Green
        }
        else {
            Write-Warning "   Warning: Verification failed. Current GeoID: $($currentHomeLocation.GeoId)"
        }
    }
    catch {
        Write-Error "   Error: Failed to set Home Location: $($_.Exception.Message)"
    }
    Write-Host ""

    # 2. Set Time Zone
    try {
        Write-Host "2. Setting Time Zone to '$TimeZoneId'..."
        Set-TimeZone -Id $TimeZoneId
        $currentTimeZone = Get-TimeZone
        if ($currentTimeZone.Id -eq $TimeZoneId) {
            Write-Host "   Success: Time Zone set to '$($currentTimeZone.DisplayName)'." -ForegroundColor Green
        }
        else {
            Write-Warning "   Warning: Verification failed. Current Time Zone ID: $($currentTimeZone.Id)"
        }
    }
    catch {
        Write-Error "   Error: Failed to set Time Zone: $($_.Exception.Message)"
    }
    Write-Host ""

    # 3. Sync System Time
    try {
        Write-Host "3. Synchronizing system time..."
        # Ensure Windows Time service is running
        $timeService = Get-Service -Name w32time -ErrorAction SilentlyContinue
        if ($timeService -and $timeService.Status -ne 'Running') {
            Write-Host "   Windows Time service (w32time) is not running. Attempting to start it..."
            Start-Service -Name w32time -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
        }

        # Force sync with time server
        w32tm /resync /force | Out-Null
        Start-Sleep -Seconds 3

        # Check sync status
        $syncStatus = w32tm /query /status /verbose
        if ($syncStatus -match "Last successful sync time: (?!never)" -and $syncStatus -notmatch "Source: Local CMOS Clock") {
            Write-Host "   Success: System time synchronized with the time server." -ForegroundColor Green
            Write-Host "   Current System Time: $(Get-Date)"
        }
        elseif ($syncStatus -match "Source: Local CMOS Clock") {
            Write-Warning "   Warning: System is using the Local CMOS Clock. Time may not be synchronized with an external server."
            Write-Host "   Current System Time: $(Get-Date)"
        }
        else {
            Write-Warning "   Warning: Time sync status unconfirmed. Please check your network connection or w32time configuration."
            Write-Host "   Current System Time: $(Get-Date)"
        }
    }
    catch {
        Write-Error "   Error: Failed to sync system time: $($_.Exception.Message)"
    }
    Write-Host "--------------------------------------------------"
    Write-Host "Configuration complete."
    Write-Host "--------------------------------------------------"
}

# -------------------------------------------------------------------------
# Helper Functions
# -------------------------------------------------------------------------

# Function: Check for updates
function Check-Update {
    try {
        Write-Host "Checking for updates..."
        $versionUrl = "https://raw.githubusercontent.com/Yinan-work/ZoneSync/main/version.txt"
        $latestVersion = (Invoke-RestMethod -Uri $versionUrl -ErrorAction Stop).Trim()
        
        if ($latestVersion -ne $CurrentVersion) {
            Write-Host "New version available: $latestVersion (Current: $CurrentVersion)" -ForegroundColor Yellow
            $updateChoice = Read-Host "Would you like to download and update now? (Y/N)"
            if ($updateChoice -match '^[Yy]$') {
                Write-Host "Downloading the latest release..."
                $scriptUrl = "https://raw.githubusercontent.com/Yinan-work/ZoneSync/main/Set-Location.ps1"
                $scriptPath = $PSCommandPath
                Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath
                Write-Host "Update complete! Please restart the script to apply the changes." -ForegroundColor Green
                Read-Host "Press Enter to exit..."
                exit
            }
        } else {
            Write-Host "You are up to date ($CurrentVersion)." -ForegroundColor Green
        }
    } catch {
        Write-Warning "Update check failed. Please check your network or repository visibility: $($_.Exception.Message)"
    }
}

# Function: Get IP-based location
function Get-IPLocation {
    try {
        Write-Host "Fetching location data via ip-api.com..."
        $response = Invoke-RestMethod -Uri "http://ip-api.com/json" -ErrorAction Stop
        if ($response.status -eq 'fail') {
            throw "API request failed: $($response.message)"
        }
        return $response
    }
    catch {
        Write-Error "Failed to retrieve IP location: $($_.Exception.Message)"
        return $null
    }
}

# Function: Get city location via Open-Meteo
function Get-CityLocation {
    param([string]$CityName)
    try {
        Write-Host "Searching for location data for '$CityName'..."
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
            Write-Warning "Location not found. Please check your spelling."
            return $null
        }
    } catch {
        Write-Error "External search API failed: $($_.Exception.Message)"
        return $null
    }
}

# Function: Get Windows GeoID from Country Code
function Get-GeoIdFromCountryCode {
    param ([string]$CountryCode)
    try {
        if ([string]::IsNullOrWhiteSpace($CountryCode)) { return $null }
        $region = [System.Globalization.RegionInfo]::new($CountryCode)
        return $region.GeoId
    }
    catch {
        Write-Warning "Failed to parse GeoID for country code '$CountryCode'."
        return $null
    }
}

# Function: Convert IANA Time Zone to Windows Time Zone ID
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

Clear-Host
Write-Host "ZoneSync - Windows Region & Time Zone Configuration Tool v$CurrentVersion"
Write-Host "================================================================"
Write-Host ""
Write-Host "Please select an option:"
Write-Host "0. Auto-Detect (IP-based)"
Write-Host "1. Manual City Search (e.g., 'New York', 'London', 'Tokyo')"
Write-Host "2. Check for Updates"
Write-Host "Q. Quit"
Write-Host ""

$choice = Read-Host "Enter your choice (0, 1, 2, or Q)"

switch ($choice) {
    "0" {
        $ipInfo = Get-IPLocation
        if ($ipInfo) {
            Write-Host "Detected Location: $($ipInfo.country) ($($ipInfo.countryCode)), City: $($ipInfo.city)"
            Write-Host "Detected Time Zone: $($ipInfo.timezone)"
            
            $geoId = Get-GeoIdFromCountryCode -CountryCode $ipInfo.countryCode
            if (-not $geoId) {
                Write-Warning "Unable to determine the GeoID for this region. Skipping Home Location setup."
            }

            $winTimeZoneId = Get-WindowsTimeZoneId -IanaTimeZone $ipInfo.timezone
            if (-not $winTimeZoneId) {
                Write-Warning "Could not map IANA time zone '$($ipInfo.timezone)' to a Windows Time Zone ID."
                $winTimeZoneId = Read-Host "Please enter a valid Windows Time Zone ID manually (or leave blank to skip)"
            }

            if ($geoId -or $winTimeZoneId) {
                $locationName = "Auto-Detect - $($ipInfo.country)/$($ipInfo.city)"
                Set-SystemRegionAndTime -LocationName $locationName -GeoId $geoId -TimeZoneId $winTimeZoneId
            }
        } else {
            Write-Error "Auto-detection failed. Operation aborted."
        }
    }
    "1" {
        $inputCity = Read-Host "Enter a city name (e.g., 'Tokyo' or 'Paris')"
        if (-not [string]::IsNullOrWhiteSpace($inputCity)) {
            $cityInfo = Get-CityLocation -CityName $inputCity
            if ($cityInfo) {
                Write-Host "Resolved Location: $($cityInfo.Country) ($($cityInfo.CountryCode)), City: $($cityInfo.City)"
                Write-Host "Resolved Time Zone: $($cityInfo.TimeZone)"
                
                $geoId = Get-GeoIdFromCountryCode -CountryCode $cityInfo.CountryCode
                if (-not $geoId) {
                    Write-Warning "Unable to determine the GeoID for this region. Skipping Home Location setup."
                }

                $winTimeZoneId = Get-WindowsTimeZoneId -IanaTimeZone $cityInfo.TimeZone
                if (-not $winTimeZoneId) {
                    Write-Warning "Could not map IANA time zone '$($cityInfo.TimeZone)' to a Windows Time Zone ID."
                    $winTimeZoneId = Read-Host "Please enter a valid Windows Time Zone ID manually (or leave blank to skip)"
                }

                if ($geoId -or $winTimeZoneId) {
                    $locationName = "Manual Setup - $($cityInfo.Country)/$($cityInfo.City)"
                    Set-SystemRegionAndTime -LocationName $locationName -GeoId $geoId -TimeZoneId $winTimeZoneId
                }
            }
        } else {
            Write-Warning "City name cannot be empty."
        }
    }
    "2" {
        Check-Update
    }
    "Q" {
        Write-Host "Exiting."
    }
    default {
        Write-Warning "Invalid choice '$choice'. Exiting."
    }
}

Write-Host ""
Read-Host "Press Enter to close this window..."
