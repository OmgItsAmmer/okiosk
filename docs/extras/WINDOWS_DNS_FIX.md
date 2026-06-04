# Windows DNS Resolution Fix for Rust Applications

## Problem

You're encountering this error when running the Rust backend on Windows:

```
Error: Io(Os { code: 11001, kind: Uncategorized, message: "No such host is known." })
```

This is **Windows error code 11001** which means "No such host is known" - a DNS resolution failure.

## Root Cause

Based on [this issue](https://github.com/ogham/dog/issues/9) and [the fix](https://github.com/ogham/dog/commit/8238e217c74485e84b204b3819445bc8b44da732), the problem occurs when:

1. Windows is configured with an **IPv6 DNS server as the primary DNS** (common with mobile hotspots)
2. That IPv6 DNS server is a **link-local address** (e.g., `fe80::387f:8bff:fe87:5764%13`)
3. Rust applications using `native-tls` try to resolve hostnames but fail with this IPv6-first configuration

Your `ipconfig /all` showed:
```
DNS Servers . . . . . . . . . . . : fe80::387f:8bff:fe87:5764%13  <-- IPv6 link-local (problematic)
                                    172.20.10.1                    <-- IPv4 (works)
```

## What Was Fixed in the Code

1. **Changed from `rustls-tls` to `native-tls`** in `Cargo.toml`:
   - `sqlx` now uses `runtime-tokio-native-tls` instead of `runtime-tokio-rustls`
   - `reqwest` now uses `native-tls` instead of `rustls-tls`
   - This uses Windows' native TLS and DNS resolution

2. **Added better error messages** to help diagnose the issue

## Solutions

### Option 1: Fix Windows DNS Settings (Recommended)

Run the provided PowerShell script to configure Google's public DNS servers:

```powershell
# Right-click PowerShell and select "Run as Administrator"
.\fix_windows_dns.ps1
```

This script will:
- ✅ Add Google's DNS servers (8.8.8.8, 8.8.4.4) to your Wi-Fi adapter
- ✅ Flush the DNS cache
- ✅ Show you how to revert if needed

**Manual Method:**

If you prefer to do it manually:

```powershell
# Run as Administrator
# Find your adapter index
Get-NetAdapter | Where-Object {$_.Status -eq "Up"}

# Set DNS (replace X with your adapter index)
Set-DnsClientServerAddress -InterfaceIndex X -ServerAddresses ("8.8.8.8", "8.8.4.4")

# Flush DNS cache
ipconfig /flushdns
```

**To revert to automatic DNS:**

```powershell
Set-DnsClientServerAddress -InterfaceIndex X -ResetServerAddresses
```

### Option 2: Use IP Address Instead of Hostname

If you can't change DNS settings, modify your `.env` file to use an IP address instead of a hostname in the `DATABASE_URL`.

For Supabase, you can resolve the hostname first:

```powershell
nslookup db.your-project.supabase.co
```

Then use the returned IP address in your connection string. **Note:** This is less reliable as IPs can change.

### Option 3: Use a Different Network

If you're on a mobile hotspot or problematic network, try:
- Switching to a different Wi-Fi network
- Using Ethernet connection
- Using your phone's hotspot with different settings

## Verification

After applying the fix, test that DNS is working:

```powershell
# Test DNS resolution
nslookup google.com

# Run your backend
cargo run
```

You should see:
```
✅ Configuration loaded successfully
🔍 Attempting to connect to database...
✅ Database connected successfully
```

## References

- [GitHub Issue: dog DNS tool with same error](https://github.com/ogham/dog/issues/9)
- [GitHub Commit: Fix for Windows DNS resolution](https://github.com/ogham/dog/commit/8238e217c74485e84b204b3819445bc8b44da732)
- [Windows Error Codes](https://learn.microsoft.com/en-us/windows/win32/winsock/windows-sockets-error-codes-2)

## Technical Details

The issue occurs because:
1. Windows prioritizes IPv6 DNS servers over IPv4
2. Link-local IPv6 addresses (`fe80::/10`) have limited reachability
3. Rust's DNS resolution (even with native-tls) may not properly fallback to IPv4 DNS
4. The solution is to use reliable IPv4 DNS servers (like Google's 8.8.8.8)

The dog tool fixed this by [iterating through all network adapters to find the first IPv4 DNS server](https://github.com/ogham/dog/commit/8238e217c74485e84b204b3819445bc8b44da732) instead of just using the first adapter's first DNS server.
