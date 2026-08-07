# mpv for Android（yt-dlp 增强版）

一个基于 [libmpv](https://github.com/mpv-player/mpv) 的 Android 视频播放器，本分支在原版 mpv-android 基础上**内置了 yt-dlp 网页链接解析**，可以直接播放 Bilibili、YouTube 等网站的页面链接，无需在手机上安装 yt-dlp。

## ✨ 特性

**本分支新增（yt-dlp 集成）：**
* 🎬 **网页链接直接播放**：把 Bilibili / YouTube / 其他支持站点的链接发给 mpv（分享菜单 / 打开 URL），自动通过内置 yt-dlp 解析出直链播放
* 🍪 **Cookies 支持**：设置 → 常规 → 网络播放 → 选择 Cookies 文件，可绕过 B 站 412 反爬校验、播放私密/会员视频
* 🎵 **DASH 双流自动处理**：B 站等站点只提供分离的视频/音频流，解析后自动合并播放（视频主轨 + 音频附轨）
* 🖥️ **全新主界面**：Material 卡片化 UI，实时显示 yt-dlp 状态
* 播放失败自动回退原链接，并有 Toast 提示

**原版 mpv-android 特性：**
* 硬件 / 软件解码
* 手势控制（进度、音量、亮度）
* libass 样式字幕、双语字幕
* 高级渲染（scalers、debanding、插帧……）
* 后台播放、画中画、键盘输入
* 网络串流（"打开 URL"）

## 📥 下载

从 [Releases](https://github.com/FuturePioneer-3/mpv-android/releases) 下载最新版 APK：

* `app-default-arm64-v8a-release.apk`（推荐，arm64 专用，已签名）
* `app-default-universal-release.apk`（全 ABI 通用，已签名）

> 注意：`*-unsigned.apk` 为未签名构建，请优先使用已签名版本。

## 📝 B 站使用提示

1. 打开 [B 站播放页](https://www.bilibili.com)，按 `F12` → Network 找到任意请求的 Cookie（或使用浏览器扩展导出 **Netscape 格式** cookies.txt）
2. 在 mpv 设置 → 常规 → **网络播放** → 选择 Cookies 文件 导入
3. 将 B 站分享链接（`b23.tv/xxx` 或 `bilibili.com/video/BVxxx`）通过分享菜单发送给 mpv 即可播放

不带 Cookies 时，B 站会返回 412 反爬错误；解析需要访问目标站点网络环境（YouTube 等海外站点需要科学上网）。

## 🛠 构建

需要：Android NDK r29、SDK 35+、JDK 17+，国内用户可参考 `buildscripts` 中的镜像配置。

```sh
cd buildscripts
cores=4 ./buildall.sh --arch arm64
```

## 📚 更多

* 原版项目：[mpv-android/mpv-android](https://github.com/mpv-android/mpv-android)
* 构建脚本说明：[buildscripts/README.md](buildscripts/README.md)
