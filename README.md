# Bluetooth Pigeon (Flutter)

Bluetooth Pigeon is a Flutter application created to experiment with **Bluetooth Low Energy (BLE)** communication between mobile devices.  
The project focuses on **phone-to-phone BLE scanning, advertising, and connecting**, making it suitable for short-range communication and indoor positioning experiments.

---

## 🚀 Features
- BLE device scanning (Central role)
- BLE advertising / peripheral mode
- Connect to nearby BLE devices
- Runtime Bluetooth & permission handling
- Multi-platform Flutter project structure

---

## 🛠 Tech Stack
- **Flutter (Dart)**
- **Bluetooth Low Energy (BLE)**
- Flutter packages commonly used in this project:
  - `flutter_blue_plus`
  - `flutter_ble_peripheral`
  - `permission_handler`
  - `get` (state management)

---

## 📱 Supported Platforms
- Android ✅ (recommended)
- iOS ⚠️ (with platform limitations)
- Desktop / Web ❌ (BLE not fully supported)

> BLE functionality works best on **real devices**, not emulators.

---

## ⚙️ Installation & Run

### 1️⃣ Clone the repository
```bash
git clone https://github.com/BeratMert29/BluetoothPigeonFlutter.git
cd BluetoothPigeonFlutter

### 2️⃣ Install dependencies
flutter pub get

### 3️⃣ Run the app
flutter run
