# Clipline

Hang screenshots from a clothesline at the top of your Mac screen. Screenshots copied with Feishu/Lark are received automatically. Press **Option + Q** to show or hide the line, including in native macOS full screen spaces.

An open source enhancement of [Tendedero](https://github.com/alejandrobujan/tendedero), with its own name, icon and settings. Requires macOS 14 or later. The downloadable app supports both Apple silicon and Intel Macs.

[Download the latest release](https://github.com/JaysinSU/clipline/releases/latest) · [简体中文](../README.md)

## Install and use

1. Download `Clipline-1.1.2.zip` from Releases, unzip it and move `Clipline.app` to Applications.
2. Quit the original Tendedero if it is running, then open Clipline. A clothes icon appears in the menu bar.
3. Clipboard image receiving is enabled by default. Complete a Feishu/Lark screenshot with Copy/Done so that the image is written to the system clipboard.
4. Press **Option + Q**, or choose Show line from the menu, to show or hide your images. Hovering over the menu bar also shows the line on the normal desktop.

This release is ad hoc signed and has not been notarized by Apple. If macOS blocks the first launch, verify that you downloaded it from this repository and follow [Apple's instructions](https://support.apple.com/en-us/102445) to approve it in System Settings → Privacy & Security.

Click an image to copy it, hold to open Markup, double click to preview, drag to an app to share a copy, or drag to a folder to save it and take it off the line. The image's close button moves app-managed images to the Trash.

In full screen spaces, new screenshots and pointer hovering do not automatically reveal the line. Use the shortcut or menu to show it manually. Images remain stored while the line is hidden.

## Clipboard and storage

Clipline receives new PNG, TIFF, JPEG, HEIC and WebP images on the system clipboard, including images copied from other apps. Feishu must write the image to the clipboard; a screenshot sent only inside the chat cannot be received. No private Feishu API is used.

Text, file-only clipboard content, images already present at launch, and content marked concealed or transient are ignored. Images are deduplicated by pixels, and copying an image from Clipline does not add it again. The clipboard is checked every 0.2 seconds and remains unchanged when receiving an image.

Full resolution PNGs are saved in `~/Library/Application Support/Clipline/Clipboard` and restored after restart. Clipline has no networking code and does not upload screenshots. Disable clipboard receiving in the menu if you do not want copied images to be saved locally.

Handle screenshots is a separate opt-in for macOS screenshot files. It saves and changes the system screenshot location and floating thumbnail settings, then restores them when switched off or the app exits normally.

## Build and test

Install Xcode Command Line Tools. There are no third-party package dependencies.

```bash
git clone https://github.com/JaysinSU/clipline.git
cd clipline
bash scripts/build-app.sh
open build/Clipline.app
bash scripts/test-clipboard.sh
bash scripts/test-fullscreen.sh
swift scripts/check-strings.swift
bash scripts/package-release.sh
```

The build script makes a universal app and signs ad hoc by default. Set `SIGN_IDENTITY` to use a Developer ID; notarization is a separate step. Release archives are written to `build/releases`. Clipboard tests use a private named pasteboard. The full screen smoke test briefly opens and closes a blank native full screen window.

The release includes the app zip, complete source zip, an all-in-one zip and SHA-256 checksums. The app was built with Swift 6.2.4 and the macOS 26.2 SDK. Clipboard tests passed 15/15, native full screen tests passed 9/9, all 28 interface strings have English, Spanish and Simplified Chinese translations, and universal binary signing checks passed.

## Credits and license

The original interaction, drawing and foundation code are by Alejandro Buján in [Tendedero](https://github.com/alejandrobujan/tendedero), baseline `ed0618a67cc59e0a8621b97bb5e32ab9af3b0b69`. Original copyright and the full MIT license are retained in [LICENSE](../LICENSE) and in the app bundle.

Tendedero's name and icon are outside its MIT license. Clipline uses a different name and an original clipboard icon, and does not distribute the original documentation artwork. It is not endorsed by the original author or Feishu/Lark.

Report problems and suggestions through [Issues](https://github.com/JaysinSU/clipline/issues), including app version, macOS version and steps to reproduce. Remove private information from attachments. Pull requests and translation contributions are welcome.
