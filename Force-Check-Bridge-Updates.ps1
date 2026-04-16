# Script to force Philips Hue Bridge to check for updates, and install it if available
# Author: ThioJoe
# Source Repo: https://github.com/ThioJoe/Philips-Hue-Tools

# ---- INSTRUCTIONS ----
# - By default windows restricts running powershell scripts for security. The command below will temporarily allow scripts and run it.
# - You'll need a API key for your local bridge. This site has a good quick tutorial on how to generate one:
#		https://www.sitebase.be/generate-phillips-hue-api-token/
#
# To Run the Script:
# 	1. Open Windows Powershell to the folder containing the script.
#		 Tip: You can just type "powershell" into the Windows File Explorer address bar to open it to the current directory
#
# 	2. Run this command in the Windows PowerShell window:
# 		Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force; .\Force-Check-Bridge-Updates.ps1
#
#	3. When prompted, enter your bridges local IP address (For example "192.168.1.99". You can find yours in the official Hue app)
#
#	4. Then enter your API key when prompted.
#
#	The script will tell the bridge to check for updates. If one is found, you will have the choice to install it now. Otherwise, the bridge will likely auto-install it within a day or so.

Write-Host "-------- Bridge Update Checker Tool for Philips Hue --------"
Write-Host "Forces the bridge to check for new available updates, and then tells it to install if found."

# Prompt the user for the Bridge IP and API Key
$BridgeIP = Read-Host "`nEnter your Hue Bridge Local IP"

Write-Host "`nNext enter your Hue API Key for your bridge. You can look up tutorials on how to generate this."
$ApiKey = Read-Host "Hue API Key"

$baseUrl = "https://$BridgeIP/api/$ApiKey/config"

# --- Handle the Hue Bridge's invalid self-signed certificate ---
# Create a splatting hash table for our Invoke-RestMethod parameters
$irmParams = @{
    Uri     = $baseUrl
    Headers = @{ "Content-Type" = "application/json" }
}

# Use the modern approach for PowerShell 6+, or the .NET fallback for Windows PowerShell 5.1
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $irmParams.Add("SkipCertificateCheck", $true)
} else {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}
# ----------------------------------------------------------------

Write-Host "`n[1/3] Triggering bridge to check for available updates..." -ForegroundColor Cyan
$bodyCheck = '{"swupdate2":{"checkforupdate":true}}'
$null = Invoke-RestMethod @irmParams -Method Put -Body $bodyCheck

Write-Host "[2/3] Waiting for the bridge to finish checking with Philips servers..." -ForegroundColor Cyan
do {
    Start-Sleep -Seconds 3
    # Fetch the config
    $config = Invoke-RestMethod @irmParams -Method Get
    $isChecking = $config.swupdate2.checkforupdate
    
    if ($isChecking) {
        Write-Host "      Still checking..." -ForegroundColor DarkGray
    }
} while ($isChecking -eq $true)

# Extract the current state
$updateState = $config.swupdate2.state
Write-Host "      Check complete. Current update state: $updateState" -ForegroundColor Green

Write-Host "`n[3/3] Evaluating update state..." -ForegroundColor Cyan
if ($updateState -in @("anyreadytoinstall", "allreadytoinstall")) {
    Write-Host "      Updates are ready!" -ForegroundColor Yellow
    
    # Prompt the user for installation
    $installPrompt = Read-Host "      Do you want to install the update now? (y/n)"
    
    if ($installPrompt -match "^[yY]") {
        Write-Host "      Forcing installation now..." -ForegroundColor Yellow
        
        $bodyInstall = '{"swupdate2":{"install":true}}'
        $installResponse = Invoke-RestMethod @irmParams -Method Put -Body $bodyInstall
        
        # Check if the command was accepted (Hue API usually returns an array with a "success" object)
        if ($installResponse.success -or $installResponse[0].success) {
            Write-Host "      Success: Update installation triggered. The bridge may reboot shortly." -ForegroundColor Green
        } else {
            Write-Host "      Command sent, but check the bridge. Response: $($installResponse | ConvertTo-Json -Compress)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "      Installation skipped by user." -ForegroundColor DarkGray
    }
} else {
    Write-Host "      No updates available to install at this time." -ForegroundColor Green
}

Write-Host ""
Read-Host "Press Enter to exit"

# SIG # Begin signature block
# MII9NAYJKoZIhvcNAQcCoII9JTCCPSECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA5y5cFwNJYY/US
# nAxpvel5/IZ4N0ORzP8PXkjkCOIgOqCCIfowggXMMIIDtKADAgECAhBUmNLR1FsZ
# lUgTecgRwIeZMA0GCSqGSIb3DQEBDAUAMHcxCzAJBgNVBAYTAlVTMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jvc29mdCBJZGVu
# dGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAy
# MDAeFw0yMDA0MTYxODM2MTZaFw00NTA0MTYxODQ0NDBaMHcxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jv
# c29mdCBJZGVudGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkgMjAyMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALORKgeD
# Bmf9np3gx8C3pOZCBH8Ppttf+9Va10Wg+3cL8IDzpm1aTXlT2KCGhFdFIMeiVPvH
# or+Kx24186IVxC9O40qFlkkN/76Z2BT2vCcH7kKbK/ULkgbk/WkTZaiRcvKYhOuD
# PQ7k13ESSCHLDe32R0m3m/nJxxe2hE//uKya13NnSYXjhr03QNAlhtTetcJtYmrV
# qXi8LW9J+eVsFBT9FMfTZRY33stuvF4pjf1imxUs1gXmuYkyM6Nix9fWUmcIxC70
# ViueC4fM7Ke0pqrrBc0ZV6U6CwQnHJFnni1iLS8evtrAIMsEGcoz+4m+mOJyoHI1
# vnnhnINv5G0Xb5DzPQCGdTiO0OBJmrvb0/gwytVXiGhNctO/bX9x2P29Da6SZEi3
# W295JrXNm5UhhNHvDzI9e1eM80UHTHzgXhgONXaLbZ7LNnSrBfjgc10yVpRnlyUK
# xjU9lJfnwUSLgP3B+PR0GeUw9gb7IVc+BhyLaxWGJ0l7gpPKWeh1R+g/OPTHU3mg
# trTiXFHvvV84wRPmeAyVWi7FQFkozA8kwOy6CXcjmTimthzax7ogttc32H83rwjj
# O3HbbnMbfZlysOSGM1l0tRYAe1BtxoYT2v3EOYI9JACaYNq6lMAFUSw0rFCZE4e7
# swWAsk0wAly4JoNdtGNz764jlU9gKL431VulAgMBAAGjVDBSMA4GA1UdDwEB/wQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTIftJqhSobyhmYBAcnz1AQ
# T2ioojAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0BAQwFAAOCAgEAr2rd5hnn
# LZRDGU7L6VCVZKUDkQKL4jaAOxWiUsIWGbZqWl10QzD0m/9gdAmxIR6QFm3FJI9c
# Zohj9E/MffISTEAQiwGf2qnIrvKVG8+dBetJPnSgaFvlVixlHIJ+U9pW2UYXeZJF
# xBA2CFIpF8svpvJ+1Gkkih6PsHMNzBxKq7Kq7aeRYwFkIqgyuH4yKLNncy2RtNwx
# AQv3Rwqm8ddK7VZgxCwIo3tAsLx0J1KH1r6I3TeKiW5niB31yV2g/rarOoDXGpc8
# FzYiQR6sTdWD5jw4vU8w6VSp07YEwzJ2YbuwGMUrGLPAgNW3lbBeUU0i/OxYqujY
# lLSlLu2S3ucYfCFX3VVj979tzR/SpncocMfiWzpbCNJbTsgAlrPhgzavhgplXHT2
# 6ux6anSg8Evu75SjrFDyh+3XOjCDyft9V77l4/hByuVkrrOj7FjshZrM77nq81YY
# uVxzmq/FdxeDWds3GhhyVKVB0rYjdaNDmuV3fJZ5t0GNv+zcgKCf0Xd1WF81E+Al
# GmcLfc4l+gcK5GEh2NQc5QfGNpn0ltDGFf5Ozdeui53bFv0ExpK91IjmqaOqu/dk
# ODtfzAzQNb50GQOmxapMomE2gj4d8yu8l13bS3g7LfU772Aj6PXsCyM2la+YZr9T
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggaqMIIEkqADAgECAhMzAAAodT7W
# uOOeQTtXAAAAACh1MA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDQwHhcNMjYwNDE2MTg1OTIwWhcNMjYwNDE5
# MTg1OTIwWjBsMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHV3lvbWluZzERMA8GA1UE
# BxMIU2hlcmlkYW4xGzAZBgNVBAoTElRoaW8gU29mdHdhcmUsIExMQzEbMBkGA1UE
# AxMSVGhpbyBTb2Z0d2FyZSwgTExDMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIB
# igKCAYEAjyw1wfWAJE0exTHoqrd7TfR9cZ3oA8cdP+FZAtO0wtBl/3bh7mqx2R5O
# vk/3C8LI3tupN0jjp5vBWugUQrIAErQ0jDLrW9pI8aHaZ69WOFhAe1aEm6/wdi16
# vR+8nwwwsSYBisDKIUD+AcwFyZVOur/WjmojGE5y7QEZ9m93/1y/chtPP5w/5By0
# 4f+UVsGhiSAQSA+QyUmYWgkEuqNox4sPLljdXxgac/aMf5v/1R+abbb7gCTtTfF0
# NB38KsTVTeWPjw7RcpgZw2cFaBa92MsfENV0saXaIqtFIxJD69+7uq/+Cx3clx0+
# pf3bCQ3i4Pa5aHueRx9tveCOznfdWVMNrM8XL32wkSQPyvNt26l6A/scuxEbCf2I
# hAG4O3Y5cE5hkJlYXN4iJfK+P1S7x0YK+odYL+QZxEA2H4G1KC4fbF540LQDIucG
# uRT0mslYEGqD3jNBjvDtDjV551Pzau4KbDQvPKcndx8SOIDjaBhnu71cY47hw7v4
# imII+qRFAgMBAAGjggHVMIIB0TAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIH
# gDA8BgNVHSUENTAzBgorBgEEAYI3YQEABggrBgEFBQcDAwYbKwYBBAGCN2GCyITf
# TKbD3mqByam9GIO77qlmMB0GA1UdDgQWBBRBVL2QxNRemyPR6upnVeqcY6jWrDAf
# BgNVHSMEGDAWgBRrJUHe+2t8/RiACi1/j3ZdqnM9uDBnBgNVHR8EYDBeMFygWqBY
# hlZodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQl
# MjBJRCUyMFZlcmlmaWVkJTIwQ1MlMjBBT0MlMjBDQSUyMDA0LmNybDB0BggrBgEF
# BQcBAQRoMGYwZAYIKwYBBQUHMAKGWGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmllZCUyMENTJTIwQU9D
# JTIwQ0ElMjAwNC5jcnQwVAYDVR0gBE0wSzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEW
# M2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5
# Lmh0bTANBgkqhkiG9w0BAQwFAAOCAgEAaRszIhvIt+wgTlJsbZ2vLbi+cYnN+EsQ
# D96YhXPAK56txTtOLMt1/IfCv8OPsVflyMjpa6yn/XenlfN4W1Oht7Ix35rNgcJQ
# /woYk8QA/Ujk6jJ/3nQvOsC5zcMtkzTdsB0cVoMtMFFMeeH4fSVEL654RR7coNV+
# Xe6aFSPv3qx36opOLy7CsXAjfqCclu67hmurCeDbty7lKOXTMm4KSGKShPq9ZaeU
# flRFBTzELIt7Q8aEUv+VyH1Xl5GQ+ruoaglYJJk7BdIRiZDaB1JnCIMo0AZTMxWf
# VL838ms7h3MZooSjtLfJtctrXOETX4fyEu0ZNaOwIPmRWGvhD5pRrQtwy9pz2eOA
# 6oyDITZmfo2e2MieUeMwazCnOBdVLMy09V/tn+1RSIxLas27yKKVHXKXD/MbVDqE
# F+n6yp3XXpwcxXqcPGgaFT2oY75r+DEcLc7vzc7aEc/Ar3anNi4D7R7TnYBgQZ01
# zMq8LyT5cMPksq+D87y7G83abq87i5coCHFds0jgG5LVHULpGzPc/kohLx8y5J6F
# vnPnEDNrW/nX5batvkteWxnVevEmrdCV1IjkweLsIWTOwmHkmeM+xjxIcAkmZhuv
# l+tBeAGkVqffjUMO9bCyJUO1ax/MSGE3OrhZSbcQSJmZ66+GVGZorpbPNW5a7ubr
# pzoHnEgzaaIwggaqMIIEkqADAgECAhMzAAAodT7WuOOeQTtXAAAAACh1MA0GCSqG
# SIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBBT0Mg
# Q0EgMDQwHhcNMjYwNDE2MTg1OTIwWhcNMjYwNDE5MTg1OTIwWjBsMQswCQYDVQQG
# EwJVUzEQMA4GA1UECBMHV3lvbWluZzERMA8GA1UEBxMIU2hlcmlkYW4xGzAZBgNV
# BAoTElRoaW8gU29mdHdhcmUsIExMQzEbMBkGA1UEAxMSVGhpbyBTb2Z0d2FyZSwg
# TExDMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAjyw1wfWAJE0exTHo
# qrd7TfR9cZ3oA8cdP+FZAtO0wtBl/3bh7mqx2R5Ovk/3C8LI3tupN0jjp5vBWugU
# QrIAErQ0jDLrW9pI8aHaZ69WOFhAe1aEm6/wdi16vR+8nwwwsSYBisDKIUD+AcwF
# yZVOur/WjmojGE5y7QEZ9m93/1y/chtPP5w/5By04f+UVsGhiSAQSA+QyUmYWgkE
# uqNox4sPLljdXxgac/aMf5v/1R+abbb7gCTtTfF0NB38KsTVTeWPjw7RcpgZw2cF
# aBa92MsfENV0saXaIqtFIxJD69+7uq/+Cx3clx0+pf3bCQ3i4Pa5aHueRx9tveCO
# znfdWVMNrM8XL32wkSQPyvNt26l6A/scuxEbCf2IhAG4O3Y5cE5hkJlYXN4iJfK+
# P1S7x0YK+odYL+QZxEA2H4G1KC4fbF540LQDIucGuRT0mslYEGqD3jNBjvDtDjV5
# 51Pzau4KbDQvPKcndx8SOIDjaBhnu71cY47hw7v4imII+qRFAgMBAAGjggHVMIIB
# 0TAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA8BgNVHSUENTAzBgorBgEE
# AYI3YQEABggrBgEFBQcDAwYbKwYBBAGCN2GCyITfTKbD3mqByam9GIO77qlmMB0G
# A1UdDgQWBBRBVL2QxNRemyPR6upnVeqcY6jWrDAfBgNVHSMEGDAWgBRrJUHe+2t8
# /RiACi1/j3ZdqnM9uDBnBgNVHR8EYDBeMFygWqBYhlZodHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIw
# Q1MlMjBBT0MlMjBDQSUyMDA0LmNybDB0BggrBgEFBQcBAQRoMGYwZAYIKwYBBQUH
# MAKGWGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9z
# b2Z0JTIwSUQlMjBWZXJpZmllZCUyMENTJTIwQU9DJTIwQ0ElMjAwNC5jcnQwVAYD
# VR0gBE0wSzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTANBgkqhkiG9w0BAQwF
# AAOCAgEAaRszIhvIt+wgTlJsbZ2vLbi+cYnN+EsQD96YhXPAK56txTtOLMt1/IfC
# v8OPsVflyMjpa6yn/XenlfN4W1Oht7Ix35rNgcJQ/woYk8QA/Ujk6jJ/3nQvOsC5
# zcMtkzTdsB0cVoMtMFFMeeH4fSVEL654RR7coNV+Xe6aFSPv3qx36opOLy7CsXAj
# fqCclu67hmurCeDbty7lKOXTMm4KSGKShPq9ZaeUflRFBTzELIt7Q8aEUv+VyH1X
# l5GQ+ruoaglYJJk7BdIRiZDaB1JnCIMo0AZTMxWfVL838ms7h3MZooSjtLfJtctr
# XOETX4fyEu0ZNaOwIPmRWGvhD5pRrQtwy9pz2eOA6oyDITZmfo2e2MieUeMwazCn
# OBdVLMy09V/tn+1RSIxLas27yKKVHXKXD/MbVDqEF+n6yp3XXpwcxXqcPGgaFT2o
# Y75r+DEcLc7vzc7aEc/Ar3anNi4D7R7TnYBgQZ01zMq8LyT5cMPksq+D87y7G83a
# bq87i5coCHFds0jgG5LVHULpGzPc/kohLx8y5J6FvnPnEDNrW/nX5batvkteWxnV
# evEmrdCV1IjkweLsIWTOwmHkmeM+xjxIcAkmZhuvl+tBeAGkVqffjUMO9bCyJUO1
# ax/MSGE3OrhZSbcQSJmZ66+GVGZorpbPNW5a7ubrpzoHnEgzaaIwggcoMIIFEKAD
# AgECAhMzAAAAFjGSjZICZXuaAAAAAAAWMA0GCSqGSIb3DQEBDAUAMGMxCzAJBgNV
# BAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xNDAyBgNVBAMT
# K01pY3Jvc29mdCBJRCBWZXJpZmllZCBDb2RlIFNpZ25pbmcgUENBIDIwMjEwHhcN
# MjYwMzI2MTgxMTI5WhcNMzEwMzI2MTgxMTI5WjBaMQswCQYDVQQGEwJVUzEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSswKQYDVQQDEyJNaWNyb3NvZnQg
# SUQgVmVyaWZpZWQgQ1MgQU9DIENBIDA0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAylX6yNvoCTDP9G0OTlSjXbzgEsy21FDL17n/lZe2BrqHz2mR1aN4
# DBxeYp0/hjEqSHHyGfarV1NVBuvK8vLzW0LTi+DZt9In16aiNfgcogFiztWE9Fp8
# xu1zzrqE3nlrDWb+RZo8QrEXgWb8s8swsl2W7tREHycVkx+Hm1MLQIlva6jH/Xg4
# /8GIYhHzbXiVd2RXomw9s7Qh6/SYRXXfe125wh4EKEyKnNNl+cZUSrVBgWvvjrRw
# QY4if7sAZ805KruBY6WY0Hiba5nWvrq9Qk9o35ViAf8qZ+7u1fbb1vcCWyWLfx9h
# LSdBjjVsSWe0xLvI1j4p3Tjt5czz+1Lc0v5lQ1feB7nFmpbZrK2us0hvAaBCfOyD
# PEEm+735vzuNRYWJFL/PViI+REtjuJMcojEn3veQjIrwrmK0T9oSr8e3oDzK1oAw
# wZMTC4KymTvYUTVDJvL5N8OW/UqIBzsiVYcchZvGhV3yMYKgxeEtIOG4W4Z85Y5k
# pQi5bpjGXFxRg46RdrTaALt1RhRmLR7U0jVSr2aYAd2+Mp2qA5Gz3/loOOdt47eF
# Z3mrAYGYQtbK2SNjQpwgQX4Iy6tOKahCgFhKIcltitvSkpJB77eVWhNWnN2LfqMo
# jszEue7V8EAySxry4PzlxTtFTb3Mw53XyH12BMQf2m9j7jEsHeVSATsCAwEAAaOC
# AdwwggHYMA4GA1UdDwEB/wQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4E
# FgQUayVB3vtrfP0YgAotf492XapzPbgwVAYDVR0gBE0wSzBJBgRVHSAAMEEwPwYI
# KwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9S
# ZXBvc2l0b3J5Lmh0bTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTASBgNVHRMB
# Af8ECDAGAQH/AgEAMB8GA1UdIwQYMBaAFNlBKbAPD2Ns72nX9c0pnqRIajDmMHAG
# A1UdHwRpMGcwZaBjoGGGX2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# Y3JsL01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDb2RlJTIwU2lnbmluZyUy
# MFBDQSUyMDIwMjEuY3JsMH0GCCsGAQUFBwEBBHEwbzBtBggrBgEFBQcwAoZhaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJ
# RCUyMFZlcmlmaWVkJTIwQ29kZSUyMFNpZ25pbmclMjBQQ0ElMjAyMDIxLmNydDAN
# BgkqhkiG9w0BAQwFAAOCAgEABtVQXlR01UQZY5XGQ9yIjMcD8jI0MizWhJ1buZjg
# 5toUQSXx/BrASwE5qxwHPBeO45pOQp6VD4iILgm8OmfylY+A7KIqttvDUizC3sBX
# xjK4u7sDRiyEguXHKfL1HQAwxCLEtnRPkCPTsJA6b917lA+3foQIHC1XDDpdQLHx
# GbbGXp4Rr0mFK5vxbi6tAahBi/RlzOXPh6PavKPlZ/0vhlkDdsvoJETtebNJCNOZ
# 1Kav3Tg+K4va4FbOrYqRHdGGahoA/gmTYmmVqw0zkGzT53HdhfajrFGttJomK7qE
# +T8CQGiPkEIkxNmSXjCTpDqc4U1IKlTGcGYnRFGSgqrnWnkANPFsJ5EDHysh82lP
# I+PFC3FOIVMLzLL+30rqznvRgHUUAj7xfFnEiuaAx3vFVSTOLb+iigpvdR6i8fSW
# pgYESOkdkn2N57tuhBs57tKwoP++vc/MVpuD1XAtmWi+lZSlahadTbDfGKjMn+bf
# m2xlW9PZ6BSnCRv1MMhpcUZkAZX3gVEMef8rZc2c7BJ4ayRfX0wH43vI9znV+ZRJ
# 3j0xUC0Zb82RQalF5yHkCr93x0IwvZtn6P2dNQyCP6qd3fC4RlVFtAQhtOH0cByT
# R/Iqqghv6qHzL/pMptgMQQ5x8zYEYy+tCThYgYIrq7y4WEDYQfeSlqIxQOrIUJ4I
# JDEwggeeMIIFhqADAgECAhMzAAAAB4ejNKN7pY4cAAAAAAAHMA0GCSqGSIb3DQEB
# DAUAMHcxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xSDBGBgNVBAMTP01pY3Jvc29mdCBJZGVudGl0eSBWZXJpZmljYXRpb24gUm9v
# dCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAyMDAeFw0yMTA0MDEyMDA1MjBaFw0z
# NjA0MDEyMDE1MjBaMGMxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xNDAyBgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBDb2Rl
# IFNpZ25pbmcgUENBIDIwMjEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQCy8MCvGYgo4t1UekxJbGkIVQm0Uv96SvjB6yUo92cXdylN65Xy96q2YpWCiTas
# 7QPTkGnK9QMKDXB2ygS27EAIQZyAd+M8X+dmw6SDtzSZXyGkxP8a8Hi6EO9Zcwh5
# A+wOALNQbNO+iLvpgOnEM7GGB/wm5dYnMEOguua1OFfTUITVMIK8faxkP/4fPdEP
# CXYyy8NJ1fmskNhW5HduNqPZB/NkWbB9xxMqowAeWvPgHtpzyD3PLGVOmRO4ka0W
# csEZqyg6efk3JiV/TEX39uNVGjgbODZhzspHvKFNU2K5MYfmHh4H1qObU4JKEjKG
# sqqA6RziybPqhvE74fEp4n1tiY9/ootdU0vPxRp4BGjQFq28nzawuvaCqUUF2PWx
# h+o5/TRCb/cHhcYU8Mr8fTiS15kRmwFFzdVPZ3+JV3s5MulIf3II5FXeghlAH9Cv
# icPhhP+VaSFW3Da/azROdEm5sv+EUwhBrzqtxoYyE2wmuHKws00x4GGIx7NTWznO
# m6x/niqVi7a/mxnnMvQq8EMse0vwX2CfqM7Le/smbRtsEeOtbnJBbtLfoAsC3TdA
# OnBbUkbUfG78VRclsE7YDDBUbgWt75lDk53yi7C3n0WkHFU4EZ83i83abd9nHWCq
# fnYa9qIHPqjOiuAgSOf4+FRcguEBXlD9mAInS7b6V0UaNwIDAQABo4ICNTCCAjEw
# DgYDVR0PAQH/BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBTZQSmw
# Dw9jbO9p1/XNKZ6kSGow5jBUBgNVHSAETTBLMEkGBFUdIAAwQTA/BggrBgEFBQcC
# ARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRv
# cnkuaHRtMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMA8GA1UdEwEB/wQFMAMB
# Af8wHwYDVR0jBBgwFoAUyH7SaoUqG8oZmAQHJ89QEE9oqKIwgYQGA1UdHwR9MHsw
# eaB3oHWGc2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jv
# c29mdCUyMElkZW50aXR5JTIwVmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmlj
# YXRlJTIwQXV0aG9yaXR5JTIwMjAyMC5jcmwwgcMGCCsGAQUFBwEBBIG2MIGzMIGB
# BggrBgEFBQcwAoZ1aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0
# cy9NaWNyb3NvZnQlMjBJZGVudGl0eSUyMFZlcmlmaWNhdGlvbiUyMFJvb3QlMjBD
# ZXJ0aWZpY2F0ZSUyMEF1dGhvcml0eSUyMDIwMjAuY3J0MC0GCCsGAQUFBzABhiFo
# dHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29jc3AwDQYJKoZIhvcNAQEMBQAD
# ggIBAH8lKp7+1Kvq3WYK21cjTLpebJDjW4ZbOX3HD5ZiG84vjsFXT0OB+eb+1TiJ
# 55ns0BHluC6itMI2vnwc5wDW1ywdCq3TAmx0KWy7xulAP179qX6VSBNQkRXzReFy
# jvF2BGt6FvKFR/imR4CEESMAG8hSkPYso+GjlngM8JPn/ROUrTaeU/BRu/1RFESF
# VgK2wMz7fU4VTd8NXwGZBe/mFPZG6tWwkdmA/jLbp0kNUX7elxu2+HtHo0QO5gdi
# KF+YTYd1BGrmNG8sTURvn09jAhIUJfYNotn7OlThtfQjXqe0qrimgY4Vpoq2MgDW
# 9ESUi1o4pzC1zTgIGtdJ/IvY6nqa80jFOTg5qzAiRNdsUvzVkoYP7bi4wLCj+ks2
# GftUct+fGUxXMdBUv5sdr0qFPLPB0b8vq516slCfRwaktAxK1S40MCvFbbAXXpAZ
# nU20FaAoDwqq/jwzwd8Wo2J83r7O3onQbDO9TyDStgaBNlHzMMQgl95nHBYMelLE
# HkUnVVVTUsgC0Huj09duNfMaJ9ogxhPNThgq3i8w3DAGZ61AMeF0C1M+mU5eucj1
# Ijod5O2MMPeJQ3/vKBtqGZg4eTtUHt/BPjN74SsJsyHqAdXVS5c+ItyKWg3Eforh
# ox9k3WgtWTpgV4gkSiS4+A09roSdOI4vrRw+p+fL4WrxSK5nMYIakDCCGowCAQEw
# cTBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgQU9DIENBIDA0AhMz
# AAAodT7WuOOeQTtXAAAAACh1MA0GCWCGSAFlAwQCAQUAoF4wEAYKKwYBBAGCNwIB
# DDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwLwYJKoZIhvcNAQkEMSIE
# IHSv/DLhW/4OLYHi80SEnMqJf860TcWMsN2bdPOoB3f2MA0GCSqGSIb3DQEBAQUA
# BIIBgIK6sI5oc7TtKykzLsN/vL3owNoibX0dGTBUjQQRfmRApQmKszwn6MeS2/6p
# nAmtXdA3Cy8qGxtllhBqdASJcy+sEhrfMqtdlnt6Ld5nulWVZdYWp25NpTJ7MMmT
# /wsRfnFfCvEtFD1tm43Uq1I952ObF8nnTIsC6WcA5Uy0HOjtxZ8qWR/GS0gil6SC
# SFVss4DhymacD2Pi/CrtJt2SdkVKhWOjfjPZwR9RuL7OMqxusEWrub+9SsUqwHdJ
# hWBf9xGsAC1B8svRDARam7xV6qbESEnNn9zxeGm91++BDm28Tii9rrgy5Cs/ryCU
# Qj4DbznhbIjVmEGqrbb3hkyKGHaYsUf8Bybpe+Mxwo0btmWFCvlv0gw4Oip9XOLJ
# EgqAmtnwflz0P889mdrCxoFByaWfdzuXBMkj5cZ4LF0GAmUXSznt6u/UtgnWFHp+
# x6q/eGf+5q9K7gJmRo0LVrrLQydsxJ3jZQ0+r+lsyATzQI1/++AhEov1tO/JfPNX
# KYJQaaGCGBAwghgMBgorBgEEAYI3AwMBMYIX/DCCF/gGCSqGSIb3DQEHAqCCF+kw
# ghflAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFhBgsqhkiG9w0BCRABBKCCAVAEggFM
# MIIBSAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFlAwQCAQUABCAzmG2A54gdPAdU
# ZY1VF2uEIDjy2fb8byVN+stjSsESFgIGadQGkh+GGBIyMDI2MDQxNjIwMjE0Mi43
# OVowBIACAfSggeGkgd4wgdsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJzAl
# BgNVBAsTHm5TaGllbGQgVFNTIEVTTjo3ODAwLTA1RTAtRDk0NzE1MDMGA1UEAxMs
# TWljcm9zb2Z0IFB1YmxpYyBSU0EgVGltZSBTdGFtcGluZyBBdXRob3JpdHmggg8h
# MIIHgjCCBWqgAwIBAgITMwAAAAXlzw//Zi7JhwAAAAAABTANBgkqhkiG9w0BAQwF
# ADB3MQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MUgwRgYDVQQDEz9NaWNyb3NvZnQgSWRlbnRpdHkgVmVyaWZpY2F0aW9uIFJvb3Qg
# Q2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMjAwHhcNMjAxMTE5MjAzMjMxWhcNMzUx
# MTE5MjA0MjMxWjBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3Rh
# bXBpbmcgQ0EgMjAyMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJ58
# 51Jj/eDFnwV9Y7UGIqMcHtfnlzPREwW9ZUZHd5HBXXBvf7KrQ5cMSqFSHGqg2/qJ
# hYqOQxwuEQXG8kB41wsDJP5d0zmLYKAY8Zxv3lYkuLDsfMuIEqvGYOPURAH+Ybl4
# SJEESnt0MbPEoKdNihwM5xGv0rGofJ1qOYSTNcc55EbBT7uq3wx3mXhtVmtcCEr5
# ZKTkKKE1CxZvNPWdGWJUPC6e4uRfWHIhZcgCsJ+sozf5EeH5KrlFnxpjKKTavwfF
# P6XaGZGWUG8TZaiTogRoAlqcevbiqioUz1Yt4FRK53P6ovnUfANjIgM9JDdJ4e0q
# iDRm5sOTiEQtBLGd9Vhd1MadxoGcHrRCsS5rO9yhv2fjJHrmlQ0EIXmp4DhDBieK
# UGR+eZ4CNE3ctW4uvSDQVeSp9h1SaPV8UWEfyTxgGjOsRpeexIveR1MPTVf7gt8h
# Y64XNPO6iyUGsEgt8c2PxF87E+CO7A28TpjNq5eLiiunhKbq0XbjkNoU5JhtYUrl
# mAbpxRjb9tSreDdtACpm3rkpxp7AQndnI0Shu/fk1/rE3oWsDqMX3jjv40e8KN5Y
# sJBnczyWB4JyeeFMW3JBfdeAKhzohFe8U5w9WuvcP1E8cIxLoKSDzCCBOu0hWdjz
# KNu8Y5SwB1lt5dQhABYyzR3dxEO/T1K/BVF3rV69AgMBAAGjggIbMIICFzAOBgNV
# HQ8BAf8EBAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFGtpKDo1L0hj
# QM972K9J6T7ZPdshMFQGA1UdIARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNo
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5o
# dG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBD
# AEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTIftJqhSobyhmYBAcnz1AQ
# T2ioojCBhAYDVR0fBH0wezB5oHegdYZzaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSWRlbnRpdHklMjBWZXJpZmljYXRpb24l
# MjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHklMjAyMDIwLmNybDCBlAYI
# KwYBBQUHAQEEgYcwgYQwgYEGCCsGAQUFBzAChnVodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElkZW50aXR5JTIwVmVyaWZp
# Y2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5JTIwMjAyMC5j
# cnQwDQYJKoZIhvcNAQEMBQADggIBAF+Idsd+bbVaFXXnTHho+k7h2ESZJRWluLE0
# Oa/pO+4ge/XEizXvhs0Y7+KVYyb4nHlugBesnFqBGEdC2IWmtKMyS1OWIviwpnK3
# aL5JedwzbeBF7POyg6IGG/XhhJ3UqWeWTO+Czb1c2NP5zyEh89F72u9UIw+IfvM9
# lzDmc2O2END7MPnrcjWdQnrLn1Ntday7JSyrDvBdmgbNnCKNZPmhzoa8PccOiQlj
# jTW6GePe5sGFuRHzdFt8y+bN2neF7Zu8hTO1I64XNGqst8S+w+RUdie8fXC1jKu3
# m9KGIqF4aldrYBamyh3g4nJPj/LR2CBaLyD+2BuGZCVmoNR/dSpRCxlot0i79dKO
# ChmoONqbMI8m04uLaEHAv4qwKHQ1vBzbV/nG89LDKbRSSvijmwJwxRxLLpMQ/u4x
# XxFfR4f/gksSkbJp7oqLwliDm/h+w0aJ/U5ccnYhYb7vPKNMN+SZDWycU5ODIRfy
# oGl59BsXR/HpRGtiJquOYGmvA/pk5vC1lcnbeMrcWD/26ozePQ/TWfNXKBOmkFpv
# PE8CH+EeGGWzqTCjdAsno2jzTeNSxlx3glDGJgcdz5D/AAxw9Sdgq/+rY7jjgs7X
# 6fqPTXPmaCAJKVHAP19oEjJIBwD1LyHbaEgBxFCogYSOiUIr0Xqcr1nJfiWG2GwY
# e6ZoAF1bMIIHlzCCBX+gAwIBAgITMwAAAFck05XgounJMQAAAAAAVzANBgkqhkiG
# 9w0BAQwFADBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3RhbXBp
# bmcgQ0EgMjAyMDAeFw0yNTEwMjMyMDQ2NTNaFw0yNjEwMjIyMDQ2NTNaMIHbMQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNy
# b3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBF
# U046NzgwMC0wNUUwLUQ5NDcxNTAzBgNVBAMTLE1pY3Jvc29mdCBQdWJsaWMgUlNB
# IFRpbWUgU3RhbXBpbmcgQXV0aG9yaXR5MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAsWylCpMIfbizJLY1kPXO2cmX2HRWvRbAmeKSZ5ex7/jCymdV7Eap
# +Ic2iqRtWDkKKe5gL6JV80wtn5C2qHJLPxUYFKNG3UkHkAI21MoCN+YWnhT8K/Yu
# Pib6+6970jdbeFKIiZMWwd5hnpX9J3jeteuEdXbp/DfFBK15JuD3JOzWuF2suQCP
# gqYjQPk/gpq+3KCKtXJRbXSCSJ9YtITU2IHwmfdE7l2PfZ154w041po+fDeTj0gJ
# OzcV/Jv56Q0M+w19jAKo/I5PEzrLV1IPQnmP4or1X4RbJXk8ONXyOOfXOxK2VLpN
# xgklK1yAezbFP2uzqihaXkW1h9GQLGENKESnezwgdRaLNNaYtm8AT/pZHYJ35mZV
# qkZdMIckpQHJk/F1fSLyDKeKtH4TC4cc3ESKUMgItq07ZZm74JCsfhmrQ1ijVNDi
# 1Sln+QBamgC7WviZbkQnceQRq9DY+6hANwOrasAZUiVr2kPuj1jHDOXzUG4O9QTK
# 70P/oXSqZAN1oTv3UfF8JTGmAxg+l1ZPOz50MY96HBDw/3bI/wBGNvLk6fLVnrxG
# N5B5unF/lYvjjWbIUdyBPVQnPOKXu08SRHbY19M1HoWX6PNZv+vzSeqVeWWHKdKj
# C3GjVjbbGpi+JLbiyaKRSwEqo49tJLvu69cQ7dWsbksai4TURnVj2mMCAwEAAaOC
# AcswggHHMB0GA1UdDgQWBBSOg8leLTUOAglIZ+bjXpiD7RKSpzAfBgNVHSMEGDAW
# gBRraSg6NS9IY0DPe9ivSek+2T3bITBsBgNVHR8EZTBjMGGgX6BdhltodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBQdWJsaWMl
# MjBSU0ElMjBUaW1lc3RhbXBpbmclMjBDQSUyMDIwMjAuY3JsMHkGCCsGAQUFBwEB
# BG0wazBpBggrBgEFBQcwAoZdaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9jZXJ0cy9NaWNyb3NvZnQlMjBQdWJsaWMlMjBSU0ElMjBUaW1lc3RhbXBpbmcl
# MjBDQSUyMDIwMjAuY3J0MAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYB
# BQUHAwgwDgYDVR0PAQH/BAQDAgeAMGYGA1UdIARfMF0wUQYMKwYBBAGCN0yDfQEB
# MEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMv
# RG9jcy9SZXBvc2l0b3J5Lmh0bTAIBgZngQwBBAIwDQYJKoZIhvcNAQEMBQADggIB
# AHJ1wHY86Zk5SUBDPY25d/u9YJVaaNa71uxjX4cyO/XJ4uPENCSOwkRTnNogPLxT
# D0Fg3z4TFf/2T/0IFSxdtWVtTjhzrn+WLInzeRawUhTCFVrPBJKEWVshm+Ig7/nB
# 7JbJN88+ltImBbL5kT1StBLfG6UksAcDbNSQww90CUXhGueBxlnSvjkAX1ohiN16
# y1bB2s0rvQx8Csepl2CuBefTfDrMGzW/tzNx5YaK2D8OWweqTWZcGlJO4YjZNI83
# cTrQghfHl/8AXOHj8cWL3wEFltQQs2xeRYAb3Kdnl7oIWKKXWaBYJY5P3QPsiC+D
# TMp7ejdYKTrb396f3gr+wL/Ms5/Z3vIWZPJJv18qNw40fUNveRnwzMQnx8dM2bGu
# XXQZ5y7P8aXT4HJMo349qZtn4XQwiUE/DDp++MUL0kgjvd/Deo7Xr371PFPPYb4T
# boZhjV1x9+wCHDoOpNCBt+VuXU78ytJdKzQ1Jv2cEP1F9H9/wSLsMDUvWME7u9mG
# ElOPDZPMVr8AuBEuLdbTSEdaLwsZBplzxLBcgxhZ/Cs30yBhuE3QhqT1YDZ2pa56
# RexPA2SasPcToT6gJgJ6E06BmZ2zQTNvWOjs5XQqHbYuXcoeDcwe2UaC7EDOGD8G
# mLE9LiqtQsuQCM7v7I2xR+sPZT2Ax/85HjIkM+3MzTK1MYIHQzCCBz8CAQEweDBh
# MQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIw
# MAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3RhbXBpbmcgQ0EgMjAy
# MAITMwAAAFck05XgounJMQAAAAAAVzANBglghkgBZQMEAgEFAKCCBJwwEQYLKoZI
# hvcNAQkQAg8xAgUAMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAcBgkqhkiG
# 9w0BCQUxDxcNMjYwNDE2MjAyMTQyWjAvBgkqhkiG9w0BCQQxIgQgrHW3EtNvESab
# NHZVCHRQth0b0Otzle6kv3wHu6zPAPcwgbkGCyqGSIb3DQEJEAIvMYGpMIGmMIGj
# MIGgBCD1PJ9ktQVuTGWIbKLO4f1VUOlUU29ARCEpDZmFTHjbUjB8MGWkYzBhMQsw
# CQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYD
# VQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3RhbXBpbmcgQ0EgMjAyMAIT
# MwAAAFck05XgounJMQAAAAAAVzCCA14GCyqGSIb3DQEJEAISMYIDTTCCA0mhggNF
# MIIDQTCCAikCAQEwggEJoYHhpIHeMIHbMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRp
# b25zMScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046NzgwMC0wNUUwLUQ5NDcxNTAz
# BgNVBAMTLE1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWUgU3RhbXBpbmcgQXV0aG9y
# aXR5oiMKAQEwBwYFKw4DAhoDFQD9LzE5nEJRAUE2Ss3xaKKPXHnLw6BnMGWkYzBh
# MQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIw
# MAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBUaW1lc3RhbXBpbmcgQ0EgMjAy
# MDANBgkqhkiG9w0BAQsFAAIFAO2Ls/wwIhgPMjAyNjA0MTYxOTE2MTJaGA8yMDI2
# MDQxNzE5MTYxMlowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA7Yuz/AIBADAHAgEA
# AgIYDTAHAgEAAgISwDAKAgUA7Y0FfAIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgor
# BgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBCwUA
# A4IBAQCes5dFwalzGQQvgcXLgj4pP3Lry1JgKXT39BDCdYTqenqJ/hpjCm4m6lZa
# 0b4Q1Jh6AH0ahQ/0R8eU7e4ZKx3fINB24un5NiS4yR+uyeEEhAAIvQaHvO7dcAKF
# Z3jP4ycm1aAqUgLJnFCH5m8FZLczbDhYlPbVTGpyfNR+DFgGZh/fBvC2ZxxiFSUk
# RSUNk9dOi9b7IzsT4atGz5shAZ3Tf93c8ylt2xNLgjhw/KmhSqsCIp1Iq0bW6rmM
# IkkBKPxW5Lp4zG1hg65q4JKdSnP4uhWCtmMbzNGdIXuX1YD0adR26/BrB4d1Crpz
# eQTyuqxORgXayrlicoOaaEx2G5h3MA0GCSqGSIb3DQEBAQUABIICAH/RcbkYXfbD
# Xg5bxu2O5YVCS0ZR0iupJoUFszuH7UBaejp3gShgv2DV3zEyGwPYmYvRoMw11DFP
# SM5tCafFRjz9ZOehJ3xrXKFDM5xsGZPrMV6RNE2DZXCGOWqFAvRZC9mLwjV6Avwl
# 18kR8J2dhLbhUkiClQepWwMCgATz7z6AcEmrhKJ2/V6YKoblOZXWFPNFlIo6ywLJ
# zi5DhPCt2f53jcYmmLQQI4wYphWQHCk09xDBC3GV0g+QS0lTw8MT5nizsErFpFa3
# 0o89PZcYzQU5hDvOqz5lDuPUO9PR69ex47V32ETqUo053sMWn1whTlmd6BbtBUYv
# 0kdO4k6Lkp39aWXqy2fi4/CUvpoh9XEiKR8HbWe8RsmeUUEi4DL6jxncfJ1NGNB4
# MQY9dtopg0OqXWA6RYO+BVF1CU5LnsdENroC54mLp3xLrdclNjwOn98AxyKOG+Ds
# 1GxtQJVQzNHIvp5xFNUfXeQvme7gxUrDG0alxK4RzoMc4xlY8lgvpyI3JL8gGgu9
# dJ8dg8LexzjA15FqfMazS9inj/YZt3JNNmwIvosVvafIVXM/Bm7rRWCjtubt4Fwc
# nQtd9q1/JYzpr2VFzBpYE6z38QnRrbc8BwZRTqpHp/6O2c7gv5lTwi2bjaw/gaBO
# K1a2rnrU6JDP6+XQmQgSUmFz23bT0xQF
# SIG # End signature block
