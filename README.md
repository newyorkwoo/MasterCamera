# MasterCamera App 設定指南

## 已完成的功能

✅ 相機預覽畫面
✅ 拍照功能
✅ 前後鏡頭切換
✅ 閃光燈控制（關閉/開啟/自動）
✅ 照片預覽
✅ 儲存照片到相簿
✅ 分享照片
✅ 權限管理

## 需要在 Xcode 中設定的權限

為了讓 app 正常運作，你需要在 Xcode 中添加以下權限說明：

### 步驟：

1. 在 Xcode 中打開專案
2. 選擇 `MasterCamera` target
3. 切換到 `Info` 標籤
4. 添加以下兩個權限說明（Custom iOS Target Properties）：

#### 相機權限

- **Key**: Privacy - Camera Usage Description
- **Type**: String
- **Value**: 我們需要存取您的相機來拍照

#### 相簿權限

- **Key**: Privacy - Photo Library Additions Usage Description
- **Type**: String
- **Value**: 我們需要儲存照片到您的相簿

或者在 Info.plist 中添加：

```xml
<key>NSCameraUsageDescription</key>
<string>我們需要存取您的相機來拍照</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>我們需要儲存照片到您的相簿</string>
```

## 主要功能說明

### CameraService.swift

- 處理所有 AVFoundation 相關的邏輯
- 管理相機會話 (AVCaptureSession)
- 處理拍照、切換鏡頭、閃光燈控制
- 權限管理

### CameraView.swift

- 主要的使用者介面
- 相機控制按鈕（拍照、切換鏡頭、閃光燈）
- 照片預覽和儲存功能
- 相簿存取（基礎實作）

### CameraPreview.swift

- UIViewRepresentable 包裝器
- 顯示即時相機預覽

## 主要功能

### 頂部控制列

- 🔦 閃光燈按鈕（關閉/開啟/自動）
- ⚙️ 設定按鈕

### 底部控制列

- 📷 相簿按鈕 - 查看已拍攝的照片
- ⚪️ 拍照按鈕 - 按下拍攝照片
- 🔄 切換鏡頭按鈕 - 在前後鏡頭間切換

### 照片預覽

- 拍照後自動顯示預覽
- 儲存到相簿
- 分享照片
- 關閉預覽

## 執行 App

1. 在 Xcode 中打開專案
2. 選擇實體 iPhone 設備（相機功能在模擬器上無法使用）
3. 添加上述權限說明
4. 按下 Run (⌘R)
5. 第一次執行時會要求相機和相簿權限

## 注意事項

- ⚠️ 相機功能必須在實體 iPhone 上測試，模擬器不支援相機
- ⚠️ 需要 iOS 15.0 或以上版本
- ⚠️ 確保已添加必要的權限說明，否則 app 會閃退

## 未包含的功能（與原生相機 app 的差異）

- ❌ 錄影功能（依照需求移除）
- 慢動作錄影
- 縮時攝影
- 人像模式
- 夜間模式
- 全景模式
- HDR 控制
- Live Photos
- 濾鏡效果

## 可擴充功能

如果需要添加更多功能，可以考慮：

1. 縮放控制（捏合手勢）
2. 對焦和曝光控制（點擊對焦）
3. 相片庫整合（查看所有照片）
4. 編輯功能
5. 網格線
6. 水平儀
7. 計時器
8. 濾鏡效果
