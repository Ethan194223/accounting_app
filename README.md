# accounting_app 💰🐾

A Flutter app that turns everyday budgeting into a **playful pet-care game**.  
Track income & expenses, visualise analytics, and keep your e-pet healthy by saving money!

---

## ✨ Core Features

| Area | What it does |
|------|--------------|
| 🔑 **Sign-up / Login** | Firebase Auth secures your account. Cute “egg” animation welcomes new users. |
| 🏠 **Home dashboard** | Today’s balance, expense list, and your e-pet’s current mood (satiety & happiness). |
| ➕ **Add transaction** | Record income or expense in a few taps. |
| 💱 **Multi-currency** | Instantly switch currencies for travel or overseas purchases. |
| 🤖 **AI chatbot** | Ask budgeting questions via OpenAI Chat API. |
| 📊 **Analytics** | Visual summaries of spending habits and trends. |
| 👤 **Profile** | View personal data and adjust settings. |

---

## 🖼️ Screenshots

### 1 · Sign-up (egg animation)
![signup page](screenshots/signup_page.png)

### 2 · Sign-up (data filled & saved to Firebase)
![signup page](screenshots/signup_page(fill data).png)

### 3 · Home – today’s balance & pet
![home page](screenshots/home_page.png)

### 4 · Pet status (hunger & happiness)
![home page](screenshots/pet_statute.png)

### 5 · Add income / expense
![home page](screenshots/add_expense_page.png)

### 6 · Currency switcher
![home page](screenshots/currency_switch.png)

### 7 · AI Chatbot
![home page](screenshots/AIchatbot.png)

### 8 · Analytics
![home page](screenshots/analytic_page.png)

### 9 · Profile
![home page](screenshots/profile_page.png)

### 10 · Login screen
![home page](screenshots/login_page.png)

### 11 · Firebase data view
![home page](screenshots/firebase_page.png)

### 12 · Login error (animation on failure)
![home page](screenshots/login_fail.png)

---

## 🛠️ Tech Stack

- **Flutter / Dart** – cross-platform UI  
- **Firebase** – Auth & Cloud Firestore  
- **OpenAI Chat API** – budgeting assistant  
- **Provider** – state management  
- **Intl** – multi-currency formatting  

---

## 🚀 Getting Started

```bash
# Clone repo
git clone https://github.com/your-username/accounting_app.git
cd accounting_app

# Install dependencies
flutter pub get

# Run on connected device
flutter run
