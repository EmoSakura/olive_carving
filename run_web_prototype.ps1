$flutter = 'C:\Users\AORUS\development\flutter\bin\flutter.bat'
$port = 54185

$lanIp = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Where-Object {
    $_.IPAddress -notlike '127.*' -and
    $_.IPAddress -notlike '169.254.*' -and
    $_.PrefixOrigin -ne 'WellKnown'
  } |
  Select-Object -First 1 -ExpandProperty IPAddress

if (-not $lanIp) {
  $lanIp = '127.0.0.1'
}

Write-Host "Flutter Web 原型即将启动..." -ForegroundColor Yellow
Write-Host "手机扫码访问地址: http://$lanIp`:$port" -ForegroundColor Green
Write-Host "请保持此窗口开启，否则手机将无法访问。" -ForegroundColor Yellow

& $flutter run -d chrome --web-hostname 0.0.0.0 --web-port $port
