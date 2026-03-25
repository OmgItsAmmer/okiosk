# Fix Windows DNS for Rust applications
# This script adds Google's public DNS servers to your Wi-Fi adapter
# Run this script as Administrator

Write-Host "🔧 Windows DNS Fix for Rust Applications" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

# Get the active Wi-Fi adapter
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceDescription -like "*Wi-Fi*"}

if ($null -eq $adapter) {
    Write-Host "❌ No active Wi-Fi adapter found!" -ForegroundColor Red
    Write-Host "   This script is designed for Wi-Fi connections." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "✅ Found active adapter: $($adapter.Name)" -ForegroundColor Green
Write-Host "   Interface: $($adapter.InterfaceDescription)" -ForegroundColor Gray
Write-Host ""

# Backup current DNS settings
Write-Host "📋 Current DNS Settings:" -ForegroundColor Yellow
$currentDNS = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
Write-Host "   $($currentDNS.ServerAddresses -join ', ')" -ForegroundColor Gray
Write-Host ""

# Ask for confirmation
Write-Host "⚠️  This will add Google's public DNS servers (8.8.8.8, 8.8.4.4) to your adapter" -ForegroundColor Yellow
$confirm = Read-Host "Do you want to continue? (Y/N)"

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "❌ Operation cancelled" -ForegroundColor Red
    pause
    exit 0
}

Write-Host ""
Write-Host "🔧 Setting DNS servers..." -ForegroundColor Cyan

try {
    # Set DNS servers to Google's public DNS
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("8.8.8.8", "8.8.4.4")
    
    Write-Host "✅ DNS servers updated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 New DNS Settings:" -ForegroundColor Yellow
    $newDNS = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
    Write-Host "   $($newDNS.ServerAddresses -join ', ')" -ForegroundColor Gray
    Write-Host ""
    
    # Flush DNS cache
    Write-Host "🔄 Flushing DNS cache..." -ForegroundColor Cyan
    ipconfig /flushdns | Out-Null
    Write-Host "✅ DNS cache flushed!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "✅ All done! Your Rust backend should now be able to resolve hostnames." -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 To revert to automatic DNS, run:" -ForegroundColor Yellow
    Write-Host "   Set-DnsClientServerAddress -InterfaceIndex $($adapter.ifIndex) -ResetServerAddresses" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Try running this command manually:" -ForegroundColor Yellow
    Write-Host "   Set-DnsClientServerAddress -InterfaceIndex $($adapter.ifIndex) -ServerAddresses ('8.8.8.8', '8.8.4.4')" -ForegroundColor Gray
}

Write-Host ""
pause
