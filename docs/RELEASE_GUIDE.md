# 构建与发布指南

本文档说明如何为榄雕云艺项目生成 Android 安装包、Windows 桌面包与 Windows 安装器，以及如何通过 GitHub Releases 对外提供下载。

## 当前发布现状

仓库已经配置：

- GitHub 仓库
- 公开 Release 页面
- GitHub Actions 自动构建工作流

当前最新 Release：

[https://github.com/EmoSakura/olive_carving/releases/tag/v1.3.1](https://github.com/EmoSakura/olive_carving/releases/tag/v1.3.1)

当前推荐对外分发的资产包括：

- Android：`app-release.apk`
- Windows 安装器：`olive_carving_setup_v1.3.1.exe`
- Windows 便携包：`olive_carving-windows-portable-v1.3.1.zip`

## 本地构建 APK

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 构建 Release APK

```bash
flutter build apk --release
```

### 3. 查看输出文件

输出文件位于：

`build/app/outputs/flutter-apk/app-release.apk`

## 本地构建 Windows 桌面版

### 1. 构建 Windows Release

```bash
flutter build windows --release
```

### 2. 查看输出文件

输出目录位于：

`build/windows/x64/runner/Release/`

这是一个可直接运行的桌面分发目录，包含 `olive_carving.exe`、依赖 DLL 与 `data/` 资源目录。

### 3. 生成 Windows 安装器

仓库已经补充 Inno Setup 脚本：

`/windows/installer/olive_carving.iss`

如果本机已安装 Inno Setup，可执行：

```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows/installer/olive_carving.iss
```

默认输出目录：

`build/windows/installer/`

## GitHub Actions 自动构建

仓库中已经包含工作流文件：

`/.github/workflows/android-release.yml`
`/.github/workflows/windows-release.yml`

Android 工作流会执行以下步骤：

1. 拉取仓库代码
2. 配置 Java 17
3. 安装 Flutter
4. 执行 `flutter pub get`
5. 执行 `flutter build apk --release`
6. 上传 APK 作为 Actions Artifact
7. 如果当前是标签构建，则自动把 APK 上传到 GitHub Release

Windows 工作流会执行以下步骤：

1. 拉取仓库代码
2. 安装 Flutter
3. 安装 Inno Setup
4. 执行 `flutter pub get`
5. 执行 `flutter build windows --release`
6. 打包 Windows 便携版 ZIP
7. 编译 Windows 安装器 `Setup.exe`
8. 上传 ZIP 和安装器作为 Artifact
9. 如果当前是标签构建，则自动把 ZIP 和安装器上传到 GitHub Release

## 两种发布方式

### 方式一：手动运行工作流

适合测试构建是否成功。

步骤：

1. 打开 GitHub 仓库的 `Actions`
2. 选择 `Android Release`
3. 点击 `Run workflow`
4. 构建完成后，在 workflow 页面下载 Artifact

### 方式二：通过版本标签发布

适合正式发一个新版本。

示例：

```bash
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin v1.0.1
```

标签推送成功后，GitHub Actions 会自动构建并把以下资产附加到对应 Release：

- Android APK
- Windows 安装器
- Windows 便携包

## 建议版本规范

建议继续使用以下形式：

- `v1.0.0`
- `v1.0.1`
- `v1.1.0`

同时保持 `pubspec.yaml` 中的版本号同步更新，例如：

```yaml
version: 1.0.1+2
```

其中：

- `1.0.1` 是展示给用户的版本号
- `2` 是 Android 内部版本号

## 当前签名说明

目前 `android/app/build.gradle.kts` 已经支持：

- 如果存在 `android/key.properties`，则使用正式 keystore 签名
- 如果不存在 `android/key.properties`，则回退为 debug signing，方便继续演示构建

你可以先复制模板文件：

```bash
cp android/key.properties.example android/key.properties
```

这意味着：

- 项目默认仍能正常生成 release APK
- 在未配置正式 keystore 前，输出包依然只适合演示和测试
- 想要正式商店发布，必须补齐自己的 keystore 与密码配置

## 如果后续要接入正式签名

建议流程：

1. 生成自己的 keystore
2. 复制 `android/key.properties.example` 为 `android/key.properties`
3. 在本地填写真实密钥信息，不要上传到仓库
4. 重新生成 APK 或 AAB

## 什么时候用 APK，什么时候用 AAB

- `APK`：适合老师、同学、客户直接下载安装测试
- `AAB`：适合未来上架 Google Play

如果你后面准备正式分发给更多人，建议继续保留 APK 下载方式；如果准备上架商店，再额外增加 AAB 构建流程。

## 发布前检查清单

每次正式发布前建议确认：

1. `pubspec.yaml` 版本号已更新
2. 文案与资源内容已确认
3. 本地运行正常
4. `flutter build apk --release` 能成功
5. Release 页面说明已经更新
6. Windows 安装器或便携包已成功生成

## 常见问题

### 1. GitHub Actions 构建失败

优先检查：

- `pubspec.yaml` 是否有语法错误
- `content.json` 是否是合法 JSON
- 图片路径是否写错
- workflow 文件是否被误改

### 2. Release 页面没有安装包

请确认：

- 是否是通过 `v*` 标签触发的构建
- GitHub Actions 是否执行成功
- Release 页面是否存在同名版本但附件未上传
- Windows 工作流是否成功执行了 Inno Setup 打包

### 3. 安装时提示签名问题

通常是因为本机已安装了使用不同签名的同包名应用。可以先卸载旧版本，再安装新 APK。
