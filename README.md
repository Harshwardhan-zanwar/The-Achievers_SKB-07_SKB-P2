# Pashu Rakshak AI (पशु रक्षक) 🐄
**Intelligent Livestock Healthcare & Diagnostic Ecosystem**

Pashu Rakshak AI is a comprehensive platform designed to empower farmers with instant livestock disease diagnostics, health tracking, and resource management. By integrating state-of-the-art AI inference with high-performance mobile and web interfaces, we aim to modernize animal husbandry and reduce economic losses for farmers.

---

## 🚀 Key Modules & Progress

### 1. Mobile Application (Flutter)
- **AI Scanner UI**: Real-time camera integration for livestock disease detection.
- **Diagnostic Dashboard**: Users can view health reports, history, and recommended first-aid.
- **Role Selection**: Personalized experience for Farmers, Veterinarians, and Admins.
- **Cross-Platform**: Fully configured for Android, Linux, macOS, and Windows.

### 2. Intelligent Backend (FastAPI)
- **Deep Learning Inference**: Keras-based model integration for high-accuracy disease classification.
- **Intelligence Engine v2**: 
  - Dynamic severity derivation based on disease type and bio-impact.
  - Strict validation layer for diagnostic consistency.
  - Automatic economic loss estimation.
- **AI Integration**: Powered by Google **Gemini** for advanced conversational insights and detailed treatment protocol generation.
- **Multimodal**: Integrated Speech-to-Text (STT) and Text-to-Speech (TTS) for accessibility.

### 3. Integrated Web Platform (Next.js)
- **Diagnostic Module**: 
  - Web-based scanner and diagnostic result visualization.
  - Interactive "Action Plan" and "First Aid" dashboards.
- **Fleet & Asset Management**:
  - Module for managing available assets and active rentals for equipment/livestock.
- **Admin & Analytics**:
  - Dashboard featuring national metrics and analytics controllers.
- **Secure Authentication**: Robust Login/Signup system for personalized data management.

---

## 🛠 Tech Stack
- **Frontend (Web):** Next.js (TypeScript), TailwindCSS
- **Mobile:** Flutter (Dart)
- **Backend:** FastAPI (Python), Uvicorn
- **AI/ML:** TensorFlow/Keras, Google Gemini API
- **Utilities:** OpenAI Whisper (STT), Sarvam AI (Speech), Supabase (Database)

---

## 📦 Project Structure
```bash
├── App/                # Mobile application source code (Flutter)
├── Frontend/           # Web platform source code (Next.js)
│   └── Website Dev/    # Core web diagnostic and fleet modules
├── Model/              # AI/Inference services
│   └── online/         # Fast API backend and Intelligence engine
└── requirements.txt    # Python dependencies
```

---

## ⚡ Quick Start (Backend)

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Run Server**:
   ```bash
   python Model/online/main.py
   ```

3. **Check Health**:
   Navigate to `http://localhost:8000/api/v1/health`

---

## 📋 Current Milestones
- [x] Integrate Keras Disease Detection model.
- [x] Build Intelligence Engine v2 with dynamic reasoning.
- [x] Launch Integrated Web Diagnostic & Fleet module.
- [x] Finalize Mobile Camera & Scanner logic.
- [/] STT/TTS Accessibility Polish.
- [ ] Enterprise Health heatmaps for national metrics.

---
**Developed by:** The Achievers (SKB-07)
