# Bluetooth Pigeon (Flutter)

Bluetooth Pigeon is a **Flutter-based Bluetooth Low Energy (BLE) chat application** that enables **direct, offline phone-to-phone messaging**.  
The app uses BLE scanning, advertising, and connections to allow nearby devices to discover each other and exchange messages **without internet access**.

---

## 🚀 Features
- BLE-based **offline chat** (phone ↔ phone)
- Device scanning (Central role)
- BLE advertising (Peripheral role)
- Direct connection to nearby devices
- Message exchange over BLE characteristics
- Runtime Bluetooth & permission handling
- Multi-platform Flutter project structure

---

## 🛠 Tech Stack
- **Flutter (Dart)**
- **Bluetooth Low Energy (BLE)**
- Flutter packages used:
  - `flutter_blue_plus`
  - `flutter_ble_peripheral`
  - `permission_handler`
  - `get` (state management)

---

## 📱 Supported Platforms
- Android ✅ (recommended)

---

## ⚙️ Installation & Run

1. Clone the repository
```bash
git clone https://github.com/BeratMert29/BluetoothPigeonFlutter.git
cd BluetoothPigeonFlutter
```
2. Install dependencies
```
flutter pub get
```
3. Run the app
```
flutter run
```
