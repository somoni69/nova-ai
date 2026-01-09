# 🧠 Nova AI — The Next Gen Voice Assistant

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Bloc](https://img.shields.io/badge/Architecture-BLoC-blue?style=for-the-badge&logo=bloc&logoColor=white)

**An intelligent, hands-free assistant inspired by J.A.R.V.I.S.** *Powered by Llama 3 (Groq), Gemini Vision, and Porcupine Wake Word.*

[Features](#-key-features) • [Screenshots](#-interface-showcase) • [Installation](#-getting-started) • [Tech Stack](#-tech-stack)

</div>

---

## 🚀 Overview

**Nova AI** is not just a chatbot. It's a fully integrated multimodal assistant that can **see**, **hear**, **speak**, and **control** your device. Built with Flutter and Clean Architecture, it demonstrates the power of combining local AI processing with cloud-based LLMs.

> *"Jarvis, turn on the flashlight."* — Yes, Nova can actually do that.

## ✨ Key Features

### 🧠 Hybrid Intelligence
* **Fast Text:** Uses **Groq (Llama 3)** for lightning-fast conversational responses.
* **Computer Vision:** Uses **Google Gemini 1.5** to analyze photos, code, and objects in real-time.

### 🗣️ True Hands-Free Mode
* **Wake Word Detection:** Always listening for **"Jarvis"** using **Picovoice Porcupine** (runs offline).
* **Continuous Conversation:** Automatically listens after speaking, creating a natural dialogue loop.
* **Dynamic UI:** Beautiful glassmorphism overlay that visualizes voice activity.

### ☁️ Cloud & Memory
* **Infinite History:** All chats are synced to **Supabase (PostgreSQL)**.
* **Cross-Device:** Uninstall the app, reinstall it, log in, and your memory is restored.
* **Smart Context:** Uses a sliding context window to maintain long conversations without breaking API limits.

### 🛠️ Real World Tools
* **Hardware Control:** Can toggle the **Flashlight** on/off via voice commands.
* **App Launcher:** Can open websites and apps (e.g., "Open YouTube").

---

## 📱 Interface Showcase

| **Login & Auth** | **Smart Chat** | **Vision Mode** | **Voice Overlay** |
|:---:|:---:|:---:|:---:|
| ![Screenshot_20260109-145619](https://github.com/user-attachments/assets/2c05ec2d-8640-4889-bafa-fe26752bb92f) | ![Screenshot_20260109-145916](https://github.com/user-attachments/assets/e75e2fee-69c9-46d5-a3ce-879468cba7e6) | ![Screenshot_20260109-145929](https://github.com/user-attachments/assets/933af64f-b329-4bd7-963b-966f717a1556) | ![Screenshot_20260109-145936](https://github.com/user-attachments/assets/5aae5e94-9835-4ae5-8ca7-645a21a19970) |

---

## 📱 Демонстрация (Demo)

| ![Screen_Recording_20260109_232823](https://github.com/user-attachments/assets/957fcbd8-b0b5-40da-b21b-928a24a01666) |


---


## 🛠️ Tech Stack

This project follows **Clean Architecture** principles.

* **Core:** Flutter & Dart
* **State Management:** `flutter_bloc`
* **Navigation:** `go_router` (or standard Navigator)
* **Backend:** `supabase_flutter` (Auth + Database)
* **Local Storage:** `hive` (NoSQL cache)
* **AI & HTTP:** `http`, `flutter_image_compress`
* **Voice Stack:**
    * `porcupine_flutter` (Wake Word)
    * `speech_to_text` (STT)
    * `flutter_tts` (TTS)
* **Tools:** `torch_light`, `url_launcher`

---

## 🏗️ Project Structure

```text
lib/
├── core/                # Constants, Themes, Utilities
├── features/
│   ├── auth/            # Login & Registration (Supabase)
│   ├── chat/
│   │   ├── data/        # Repositories & API Services (Groq, Gemini)
│   │   ├── domain/      # Entities & UseCases
│   │   └── presentation/# BLoC, Pages, Widgets (Glassmorphism UI)
│   └── settings/        # App Settings & Personas
└── main.dart            # Entry point

```

---

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK** installed.
2. **Supabase** project created.
3. API Keys for **Groq**, **Google AI**, and **Picovoice**.

### Installation

1. **Clone the repository:**
```bash
git clone [https://github.com/your-username/nova-ai.git](https://github.com/your-username/nova-ai.git)
cd nova-ai

```


2. **Install dependencies:**
```bash
flutter pub get

```


3. **Configure API Keys:**
Create a file `lib/core/constants/api_keys.dart` and add your keys:
```dart
class ApiKeys {
  static const String groq = "YOUR_GROQ_KEY";
  static const String google = "YOUR_GEMINI_KEY";
  static const String picovoice = "YOUR_PICOVOICE_KEY";
  static const String supabaseUrl = "YOUR_SUPABASE_URL";
  static const String supabaseKey = "YOUR_SUPABASE_ANON_KEY";
}

```


4. **Run the app:**
```bash
flutter run

```



---

## 🔮 Future Roadmap

* [ ] **RAG Implementation:** Chat with your own PDF documents.
* [ ] **Smart Home:** Integration with Home Assistant API.
* [ ] **Multi-Language:** Full support for languages other than Russian/English.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.

<div align="center">

**Developed with ❤️ by Farzod**

</div>

```
