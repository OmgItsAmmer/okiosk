# Quick Fix for "No such host is known" Error

## The Problem
Your Rust server fails with DNS error 11001 due to Windows IPv6 DNS configuration issues.

## The Solution (Choose One)

### ✅ RECOMMENDED: Fix DNS Settings

1. **Open PowerShell as Administrator**
   - Right-click Start → Windows PowerShell (Admin)

2. **Run the fix script:**
   ```powershell
   cd "C:\Programming\Projects\01_ACTIVE\kks_web\kks_online_backend"
   .\fix_windows_dns.ps1
   ```

3. **Test your server:**
   ```powershell
   cargo run
   ```

### Alternative: Manual DNS Fix

```powershell
# As Administrator
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("8.8.8.8", "8.8.4.4")
ipconfig /flushdns
```

## What Changed in Your Code

1. ✅ Switched from `rustls` to `native-tls` in Cargo.toml
2. ✅ Added better error diagnostics
3. ✅ Simplified database connection code

## Next Steps

After fixing DNS:
```powershell
cargo run
```

If it works, you should see:
```
✅ Configuration loaded successfully
✅ Database connected successfully
🚀 Server starting on 0.0.0.0:3000
```

For more details, see [WINDOWS_DNS_FIX.md](./WINDOWS_DNS_FIX.md)
