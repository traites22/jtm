param(
  [Parameter(Mandatory = $false)][string]$ServerKey = $env:FCM_SERVER_KEY,
  [Parameter(Mandatory = $false)][string]$Token = $env:FCM_TARGET_TOKEN
)

if (-not $ServerKey -or -not $Token) {
  Write-Host "Usage: .\send_fcm_test.ps1 -ServerKey '<SERVER_KEY>' -Token '<DEVICE_TOKEN>'" -ForegroundColor Yellow
  Write-Host "Or set env vars FCM_SERVER_KEY and FCM_TARGET_TOKEN" -ForegroundColor Yellow
  exit 1
}

$body = @{ to = $Token; data = @{ title = 'Test JTM'; body = 'Message de test envoyé depuis script'; test = '1' } } | ConvertTo-Json

try {
  $resp = Invoke-RestMethod -Uri 'https://fcm.googleapis.com/fcm/send' -Method Post -Headers @{ 'Authorization' = "key=$ServerKey"; 'Content-Type' = 'application/json' } -Body $body
  Write-Host "FCM response:" -ForegroundColor Green
  $resp | ConvertTo-Json -Depth 5
  exit 0
}
catch {
  Write-Host "Error sending FCM message: $_" -ForegroundColor Red
  exit 2
}