# Olive Carving

榄雕云艺交互体验产品，一个以 Flutter 构建的非遗数字化展示应用。项目当前已经从单纯答辩原型升级为带有真实账号注册登录、产品首页、管理员后台入口与 Supabase 接入能力的产品化雏形，适合课程展示、作品答辩、客户演示和后续继续迭代。

仓库地址：
[https://github.com/EmoSakura/olive_carving](https://github.com/EmoSakura/olive_carving)

APK 下载：
[https://github.com/EmoSakura/olive_carving/releases/tag/v1.2.0](https://github.com/EmoSakura/olive_carving/releases/tag/v1.2.0)

## 项目概览

本项目当前包含 5 个面向用户的核心体验层，以及 1 个管理员后台层：

1. 登录与注册：支持本地演示模式与 Supabase 真实后端模式，提供邮箱密码登录、注册与会话恢复。
2. 产品首页：提供欢迎入口、内容概览、首页精选、最近浏览与快速入口，更接近正式产品首页。
3. 数字展馆：浏览榄雕作品，支持分类筛选、关键词搜索、收藏与最近浏览。
4. 工艺解构：用分步骤卡片和弹层说明展示榄雕从选核到抛光的制作流程，并记录学习进度。
5. 指尖互动：通过手势拖动模拟雕刻过程，包含模式切换、难度切换、作品归档、历史档案与成就系统。
6. 管理员后台：管理员登录后可控制展品发布状态、首页精选与后台标记。

项目启动后会先展示启动页和引导页，再进入登录界面；登录成功后进入产品主界面。整体设计风格偏新中式极简，强调深色背景、金色点缀、留白和轻量动画。

## 功能说明

### 1. 启动、引导与登录

- 启动时先读取 `assets/data/content.json` 中的本地内容。
- 如果资源正常，会先显示品牌启动页，再进入 3 页引导介绍。
- 引导页点击“登录并进入产品”后进入认证页。
- 认证页支持：
  - `登录`
  - `注册`
  - 演示账号快速填充
  - Supabase 真实后端 / 本地演示模式状态提示

### 2. 产品首页

- 展示当前用户欢迎信息。
- 展示首页核心指标，如可见馆藏、我的收藏、已归档作品。
- 提供“进入展馆”“继续学习”“开始创作”等快速入口。
- 支持首页精选内容展示与最近浏览回看。

### 3. 数字展馆

- 展示榄雕作品列表和作品封面。
- 支持按分类筛选，如人物、山水、龙凤、花鸟。
- 支持按标题、作者、题材、工艺关键词搜索。
- 支持收藏作品。
- 支持记录最近浏览作品，方便快速回看。
- 当管理员在后台关闭某件展品的发布状态时，该展品不会出现在前台展馆中。

### 4. 工艺解构

- 展示榄雕制作流程的步骤卡片。
- 点击步骤会弹出详细说明。
- 阅读后会记录学习进度。
- 页面顶部会显示整体学习完成百分比。

### 5. 指尖互动

- 支持 3 种雕刻模式：
  - `粗雕`
  - `精雕`
  - `镂空雕`
- 支持 3 种难度：
  - `简单`
  - `中等`
  - `困难`
- 用户在榄核区域拖动手指或鼠标时，会生成雕刻笔触和木屑粒子效果。
- 当进度达到 100% 后，可以为作品命名并归档到本地档案。
- 系统内置成就解锁逻辑，例如首次体验、完成多次雕刻、体验全部模式等。

### 6. 管理员后台

- 仅管理员登录后显示后台页。
- 支持查看已发布展品数量、首页精选数量与内容总量。
- 支持切换展品 `发布 / 下线` 状态。
- 支持切换展品 `首页精选` 状态。
- 支持设置后台标记，例如“首页精选”“推荐上新”“教学重点”。

## 技术栈

- Flutter
- Dart
- Material 3
- 本地 JSON 内容资源加载
- Shared Preferences 本地持久化
- Supabase Flutter
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

### 3. 后端模式

项目当前支持两种后端模式：

1. 本地演示模式：未配置 Supabase 时自动启用。
2. Supabase 真实模式：配置后支持真实注册登录、会话恢复与后台内容状态读写。

配置方式可查看：

[`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md)

如果你想让同一局域网中的手机访问 Web 原型，可以直接执行：

```powershell
.\run_web_prototype.ps1
```

## 构建与发布

### 本地生成 Android APK

```bash
flutter build apk --release
```

构建产物默认位于：

`build/app/outputs/flutter-apk/app-release.apk`

### GitHub Actions 自动构建

仓库已配置自动构建工作流：

[`android-release.yml`](.github/workflows/android-release.yml)

更详细的发布说明可查看：

[`docs/RELEASE_GUIDE.md`](docs/RELEASE_GUIDE.md)

## 文档索引

- 商用推进建议：
  [`docs/COMMERCIALIZATION_GUIDE.md`](docs/COMMERCIALIZATION_GUIDE.md)
- Supabase 配置与建表说明：
  [`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md)
- 内容维护说明：
  [`docs/CONTENT_GUIDE.md`](docs/CONTENT_GUIDE.md)

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

## 项目结构

```text
olive_carving/
|- assets/
|  |- data/content.json          # 引导页、展品、工艺步骤等内容数据
|  |- config/supabase_config.json # Supabase 本地配置
|  |- images/                    # 展品图片与占位图
|- lib/
|  |- main.dart                  # 应用入口、导航与主流程
|  |- auth_screen.dart           # 登录 / 注册页
|  |- home_screen.dart           # 产品首页
|  |- admin_screen.dart          # 管理员后台页
|  |- backend_gateway.dart       # 本地 / Supabase 双模后端网关
|  |- product_models.dart        # 会话与后台状态模型
|  |- interaction_screen.dart    # 指尖互动模块
|  |- app_models.dart            # 内容模型与用户状态模型
|  |- app_theme.dart             # 主题色与颜色扩展
|  |- content_repository.dart    # 本地内容仓库
|  |- user_state_repository.dart # 本地用户状态持久化
|- docs/                         # 项目文档
|- android/                      # Android 构建配置
|- web/                          # Web 端静态入口
|- windows/                      # Windows 桌面端配置
```

## 测试

运行基础测试：

```bash
flutter test
```

当前仓库包含一个基础 Widget 测试，用于验证应用能够正常启动并进入品牌启动界面。

## 已知限制

- 收藏、学习进度、互动作品归档目前仍主要保存在本地，没有全部同步上云。
- 管理后台当前只覆盖展品发布状态、首页精选和后台标记，尚未支持正文与图片的在线编辑。
- Android Release 当前支持“正式 keystore 存在时走正式签名，否则回退 debug signing”的构建策略，正式上架前仍需你配置自己的 keystore。

## 后续建议

如果你后面继续完善这个项目，优先推荐以下方向：

1. 把收藏、学习进度和互动归档同步到 Supabase。
2. 把内容表从本地 JSON 迁移到数据库或 CMS。
3. 扩展管理员后台，让它支持正文、图片和标签编辑。
4. 补齐隐私政策、用户协议和正式商用发布材料。
