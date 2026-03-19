# Flutter 原型作品二维码说明

当前公网访问地址：

`https://highlights-relying-peripheral-multi.trycloudflare.com`

二维码文件：

`prototype_qr.svg`

当前本机原型入口：

`http://127.0.0.1:54185`

使用方法：

1. 老师或其他人直接扫描 `prototype_qr.svg`。
2. 扫码后会在手机浏览器中打开你的 Flutter Web 原型。
3. 你的电脑需要保持开机，且本地 Flutter Web 与 Cloudflare Tunnel 进程保持运行。

注意事项：

- 这个二维码现在已经是公网二维码，不需要和你的电脑处于同一局域网。
- 当前公网地址已经验证可访问。
- 这是 Cloudflare Quick Tunnel 的临时地址，不适合长期托管，也没有稳定性保证。
- 如果你关闭电脑、关闭 Flutter 运行进程，或关闭 `cloudflared.exe`，公网地址会失效。
- 如果你想要一个更长期、可重复使用的作品链接，下一步建议部署到正式静态托管。
