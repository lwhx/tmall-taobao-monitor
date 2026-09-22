# 淘宝/天猫商品监控系统

基于 Flask、SQLite 和 Chart.js 的商品价格监控看板。项目通过 Chrome DevTools Protocol (CDP) 复用用户在本机 Chrome 中的淘宝/天猫登录态，并定期同步 Cookie 用于商品价格抓取。

## 功能

- 手动监控与每 30 分钟自动监控商品
- 提取 SKU 最低价，并在缺少 SKU 信息时回退到商品展示价
- 与上一次记录对比价格变化，保存历史数据
- 查询、筛选、导出 CSV，并展示最近 7 天最低价趋势
- 首次登录后自动同步 Chrome Cookie，后续启动可复用登录态
- 看板显示 CDP 连接、Cookie 数量、最近同步时间与同步错误
- 支持在看板中手动同步 Cookie

## 环境要求

- Python 3.10 或更高版本
- Google Chrome
- Windows PowerShell 5.1 或 PowerShell 7（使用一键启动脚本时）

## 快速开始

在项目根目录安装依赖：

```powershell
& "D:\python\python.exe" -m pip install -r .\tmall_taobao_monitor\requirements.txt
```

推荐使用一键启动脚本：

```powershell
.\start_cdp_chrome.ps1
```

首次运行时，脚本会：

1. 创建并启动项目专属的 Chrome 调试 Profile。
2. 打开淘宝登录页；请在该 Chrome 窗口完成手动登录。
3. 回到终端按 Enter，脚本将从 CDP 同步淘宝/天猫 Cookie。
4. 启动监控服务并在同一个调试 Chrome 中打开 `http://127.0.0.1:5000/`。

后续运行会复用已成功同步的登录态，直接启动服务、同步 Cookie 并打开面板。登录失效时，可强制重新进入登录流程：

```powershell
.\start_cdp_chrome.ps1 -Login
```

也可以手动启动服务。此方式需要先在看板的 Cookie 设置中粘贴 Cookie，或先启动 CDP Chrome 再通过看板同步：

```powershell
Set-Location .\tmall_taobao_monitor
& "D:\python\python.exe" .\app.py
```

访问 `http://127.0.0.1:5000/`。

## CDP 与 Cookie

脚本使用 `127.0.0.1:9222` 作为本机 CDP 调试端口，并只读取浏览器中已有的淘宝/天猫 Cookie；不会自动输入账号密码、处理验证码或绕过登录验证。

看板顶部的“CDP 与 Cookie”状态条显示：

- Chrome CDP 是否连接
- 调试端点
- 最近同步的 Cookie 数量和时间
- 最近一次同步的错误信息

点击“立即同步 Cookie”可在不重启服务的情况下手动拉取当前浏览器登录态。

下列本地文件包含会话或监控数据，已通过 `.gitignore` 排除，不会推送到 GitHub：

- `cookies.txt`
- `monitor.db`
- `chrome_profile/`
- `.cdp_cookie_ready`

## 截图
<img width="1349" height="778" alt="image" src="https://github.com/user-attachments/assets/93aee6ad-92bd-4412-b6ba-acedf4beb2cd" />
<img width="1337" height="336" alt="image" src="https://github.com/user-attachments/assets/b95c1bcf-4e10-4604-bbad-e00c81f64756" />


## 技术栈
- 后端：Flask、APScheduler、requests、websocket-client
- 前端：Chart.js, 原生 JS
- 数据库：SQLite

## License
MIT
