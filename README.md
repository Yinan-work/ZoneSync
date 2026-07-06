# ZoneSync

[English](#english) | [中文](#中文)

---

<h2 id="english">🌐 ZoneSync - Windows Region & Time Zone Configuration Tool</h2>

**ZoneSync** is a lightweight, interactive PowerShell utility designed to quickly configure your Windows system's Region (GeoID), Time Zone, and synchronize the system clock. It's perfect for remote workers, digital nomads, or anyone who frequently needs to switch their system's location seamlessly.

### ✨ Features
- **Auto-Detect (IP-based)**: Automatically detects your current location and time zone based on your network IP.
- **Manual City Search**: Type in any city name (in English or Chinese, e.g., "New York" or "东京") to instantly look up and apply its respective time zone and region settings.
- **Time Synchronization**: Automatically forces the Windows Time Service (`w32time`) to resync with the server.
- **Built-in Updater**: Check for script updates directly from the menu and auto-download the latest release from GitHub.

### 🚀 Getting Started

#### Prerequisites
- Windows 10 or Windows 11
- PowerShell 5.0 or later
- Administrator privileges (handled automatically via the provided batch script)

#### Installation & Usage
1. Clone the repository or download `Set-Location.ps1` and `RunAsAdmin.bat`.
2. Double-click **`RunAsAdmin.bat`**. (This ensures the PowerShell script runs with the required Admin privileges).
3. Follow the on-screen menu:
   - `0`: Auto-detect location and apply.
   - `1`: Manually input a city name.
   - `2`: Check for script updates.
   - `Q`: Quit.

### 🛠 Under the Hood
- **IP Location**: Powered by [ip-api.com](http://ip-api.com/).
- **City Geocoding**: Powered by the free [Open-Meteo Geocoding API](https://open-meteo.com/).

---

<h2 id="中文">🌐 ZoneSync - Windows 地区与时区自动配置工具</h2>

**ZoneSync** 是一款轻量级的交互式 PowerShell 实用工具，旨在帮助用户快速配置 Windows 系统的地区（GeoID）、时区，并自动同步系统时间。非常适合远程办公人员、差旅人士以及需要频繁切换系统位置的用户。

### ✨ 主要功能
- **智能自动检测**：基于当前的网络 IP 地址，自动识别并配置对应的国家/地区和时区。
- **手动城市搜索**：支持中英双语输入任意城市名称（如“北京”或“London”），脚本会动态解析并应用该城市的时区和地区设置。
- **强制时间同步**：自动调用 Windows 时间服务（`w32time`），强制系统与外部服务器重新校准时间。
- **内建更新机制**：自带“检查更新”功能，可一键对比并从 GitHub 拉取最新版本的代码覆盖本地。

### 🚀 使用指南

#### 环境要求
- Windows 10 或 Windows 11
- PowerShell 5.0 及以上版本
- 需具备管理员权限（附带的 `.bat` 文件会自动处理提权操作）

#### 安装与运行
1. 克隆此仓库，或者直接下载压缩包并解压 `Set-Location.ps1` 和 `RunAsAdmin.bat` 文件。
2. 双击运行 **`RunAsAdmin.bat`**。（这会安全地以管理员身份唤起 PowerShell 脚本）。
3. 根据命令行菜单提示进行选择：
   - `0`：自动检测并应用当前位置。
   - `1`：手动输入想要切换的城市名称。
   - `2`：检查工具更新。
   - `Q`：退出。

### 🛠 技术支持
- **IP 定位**：通过 [ip-api.com](http://ip-api.com/) 获取。
- **城市地理解析**：通过免费的 [Open-Meteo Geocoding API](https://open-meteo.com/) 实现动态搜素。
