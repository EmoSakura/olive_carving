# Olive Carving

榄雕云艺交互体验产品，一个以 Flutter 构建的非遗数字化展示原型。项目围绕增城榄雕的视觉审美、作品浏览、工艺学习与指尖模拟互动展开，适合课程展示、作品答辩、原型演示和移动端体验。

仓库地址：
[https://github.com/EmoSakura/olive_carving](https://github.com/EmoSakura/olive_carving)

APK 下载：
[https://github.com/EmoSakura/olive_carving/releases/tag/v1.0.0](https://github.com/EmoSakura/olive_carving/releases/tag/v1.0.0)

## 项目概览

本项目当前包含 3 个核心体验模块：

1. 数字展馆：浏览榄雕作品，支持分类筛选、关键词搜索、收藏与最近浏览。
2. 工艺解构：用分步骤卡片和弹层说明展示榄雕从选核到抛光的制作流程。
3. 指尖互动：通过手势拖动模拟雕刻过程，包含模式切换、难度切换、进度统计、历史记录与成就系统。

项目打开后会先展示启动页和引导页，再进入底部导航主界面。整体设计风格偏新中式极简，强调深色背景、金色点缀、留白和轻量动画。

## 功能说明

### 1. 启动与引导

- 启动时先读取 `assets/data/content.json` 中的本地内容。
- 如果资源正常，会先显示品牌启动页，再进入 3 页引导介绍。
- 引导页点击“进入榄雕云艺”后进入主界面。

### 2. 数字展馆

- 展示榄雕作品列表和作品封面。
- 支持按分类筛选，如人物、山水、龙凤、花鸟。
- 支持按标题、作者、题材、工艺关键词搜索。
- 支持收藏作品。
- 支持记录最近浏览作品，方便快速回看。

### 3. 工艺解构

- 展示榄雕制作流程的步骤卡片。
- 点击步骤会弹出详细说明。
- 阅读后会记录学习进度。
- 页面顶部会显示整体学习完成百分比。

### 4. 指尖互动

- 支持 3 种雕刻模式：
  - `粗雕`
  - `精雕`
  - `镂空雕`
- 支持 3 种难度：
  - `简单`
  - `中等`
  - `困难`
- 用户在榄核区域拖动手指或鼠标时，会生成雕刻笔触和木屑粒子效果。
- 当进度达到 100% 后，可以保存当前作品到历史记录。
- 系统内置成就解锁逻辑，例如首次体验、完成多次雕刻、体验全部模式等。

## 技术栈

- Flutter
- Dart
- Material 3
- 本地 JSON 资源加载
- 自定义 `CustomPainter` 绘制背景、雕刻轨迹和粒子效果
- GitHub Actions 自动构建 Android Release APK

## 运行环境

建议环境：

- Flutter `3.41.x` 或更高稳定版
- Dart `3.11.x` 或兼容版本
- Java `17`
- Android SDK 已正确安装

本项目已经在以下目标上完成过运行或构建验证：

- Android
- Chrome Web
- Windows Desktop

## 快速开始

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 本地运行

在 Windows 桌面运行：

```bash
flutter run -d windows
```

在 Chrome 中运行 Web 版本：

```bash
flutter run -d chrome
```

在已连接的 Android 设备或模拟器上运行：

```bash
flutter run -d android
```

如果你想让同一局域网中的手机访问 Web 原型，可以直接执行：

```powershell
.\run_web_prototype.ps1
```

该脚本会：

- 自动选择本机 IPv4 地址
- 固定使用 `54185` 端口
- 启动 Flutter Web
- 输出手机可访问的局域网地址

## 构建与发布

### 本地生成 Android APK

```bash
flutter build apk --release
```

构建产物默认位于：

`build/app/outputs/flutter-apk/app-release.apk`

### GitHub Release 下载

当前公开 Release 页面：

[https://github.com/EmoSakura/olive_carving/releases/tag/v1.0.0](https://github.com/EmoSakura/olive_carving/releases/tag/v1.0.0)

当前 APK 直链：

[https://github.com/EmoSakura/olive_carving/releases/download/v1.0.0/app-release.apk](https://github.com/EmoSakura/olive_carving/releases/download/v1.0.0/app-release.apk)

### GitHub Actions 自动构建

仓库已配置自动构建工作流：

[`android-release.yml`](.github/workflows/android-release.yml)

支持两种方式：

1. 在 GitHub Actions 页面手动运行 `Android Release` 工作流。
2. 推送形如 `v1.0.0` 的标签，自动构建 APK 并挂到 GitHub Release。

更详细的发布说明可查看：

[`docs/RELEASE_GUIDE.md`](docs/RELEASE_GUIDE.md)

## 内容维护

项目的主要展示内容来自：

- `assets/data/content.json`
- `assets/images/`

如果你要修改作品标题、作者、工艺说明、引导页文案或工艺步骤，优先编辑 `content.json` 即可。

如果你要替换图片：

1. 把图片放进 `assets/images/`
2. 在 `assets/data/content.json` 中更新对应 `image` 路径
3. 重新运行 `flutter pub get`
4. 重新启动项目验证显示效果

更详细的内容维护说明可查看：

[`docs/CONTENT_GUIDE.md`](docs/CONTENT_GUIDE.md)

## 项目结构

```text
olive_carving/
|- assets/
|  |- data/content.json        # 引导页、展品、工艺步骤等内容数据
|  |- images/                  # 展品图片与占位图
|- lib/
|  |- main.dart                # 应用入口、引导页、数字展馆、工艺解构
|  |- interaction_screen.dart  # 指尖互动模块
|- android/                    # Android 构建配置
|- web/                        # Web 端静态入口
|- windows/                    # Windows 桌面端配置
|- .github/workflows/          # GitHub Actions 工作流
|- run_web_prototype.ps1       # 局域网 Web 原型启动脚本
|- prototype_access.md         # 临时公网访问说明
```

## 测试

运行基础测试：

```bash
flutter test
```

当前仓库包含一个基础 Widget 测试，用于验证应用能够正常启动并进入品牌启动界面。

## 已知限制

- Android Release 当前仍使用默认 `debug` 签名配置，适合演示和下载，不适合正式商店分发。
- 收藏、最近浏览、雕刻历史和成就目前只保存在运行时内存中，关闭应用后不会持久化。
- `prototype_access.md` 中的公网地址基于 Cloudflare Quick Tunnel，属于临时地址，失效后需要重新生成。

## 常见问题

### 1. 应用启动后提示本地内容加载失败

请检查：

- `assets/data/content.json` 是否为合法 JSON
- `pubspec.yaml` 中是否仍然声明了 `assets/images/` 和 `assets/data/`
- 图片路径是否写错

### 2. 图片不显示

请检查 `content.json` 中的 `image` 字段路径是否与 `assets/images/` 下文件名一致。

### 3. 手机无法打开 Web 原型

请确认：

- 启动 Web 原型的电脑和手机在同一局域网
- `run_web_prototype.ps1` 对应的终端窗口没有关闭
- 防火墙没有拦截对应端口

### 4. 为什么已经是 Release APK，却仍然提示是调试签名

因为当前项目的 Android Release 构建还没有接入正式 keystore，仅仅是以 Release 模式编译并使用默认调试签名输出。后续如果要长期分发，建议补上正式签名。

## 后续建议

如果你后面继续完善这个项目，优先推荐以下方向：

1. 接入正式 Android 签名。
2. 增加本地持久化，让收藏和历史记录可保留。
3. 增加更多展品数据和更高清的作品图片。
4. 为 Web 版本接入正式静态托管地址，替代临时 tunnel。

