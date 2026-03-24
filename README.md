# Groomify - AI-Powered Personal Grooming Desktop Application

## 📋 Project Overview

Groomify is an AI-powered personal grooming and style-suggestion desktop application built with Flutter. It allows users to detect their face shape using computer vision, receive personalized hairstyle and beard recommendations, and save their results for future reference.

## ✨ Key Features

### 1. **User Access Flow**
- **Login**: Email/username + password authentication
- **Signup**: Create new account with full name, email, and password
- **Guest Login**: Explore app without authentication (save feature disabled)

### 2. **Face Shape Detection Module**
- Real-time camera feed integration
- Face landmark detection using Google ML Kit
- Measurement extraction:
  - Forehead width
  - Jawline width
  - Cheekbone width
  - Face length
- Face shape classification:
  - 🔵 Oval
  - 🔵 Round
  - 🔵 Square
  - 🔵 Triangle
  - 🔵 Heart
  - 🔵 Diamond
- Confidence score (80-95%)
- Rating system (1-10) based on symmetry and proportions

### 3. **Hairstyle Suggestion Module**
Personalized recommendations based on detected face shape:
- **Oval**: Almost all styles, fade, quiff, slick back
- **Round**: Volume top + short sides, angular fringe
- **Square**: Side part, textured crop
- **Diamond**: Layered top, medium-length hair
- **Heart**: Long swept fringe, side-swept
- **Triangle**: Thick sides, low fade

### 4. **Beard Suggestion Module**
Jawline geometry-based recommendations:
- **Oval**: Stubble, goatee, full beard
- **Round**: Extended goatee, anchor beard
- **Square**: Circle beard, chin curtain
- **Diamond**: Full beard with weight
- **Triangle**: Heavy stubble with soft edges
- **Heart**: Light beard, minimalist goatee

### 5. **Save Functionality**
- **Logged-in Users**: Save results to local gallery
  - Images saved to `GroomifyGallery/FaceShapeResults/YYYY-MM-DD/`
  - Stores face shape, ratings, and recommendations
- **Guest Users**: Save feature disabled with informative message

### 6. **Gallery View**
- View all saved recommendations
- Browse by date
- View detailed results with images

## 🛠️ Technologies Used

### Frontend
- **Flutter**: Cross-platform UI framework
- **Google Fonts (Poppins)**: Typography
- **Flutter Animate**: Smooth animations and transitions

### Backend & AI
- **Google ML Kit**: Face detection and landmark analysis
- **Camera Plugin**: Live camera feed
- **Image Processing**: Image manipulation and encoding

### Data Storage
- **SQLite (sqflite)**: Local database for users and recommendations
- **Path Provider**: File system access for image storage
- **Crypto**: Password hashing (SHA-256)

### Utilities
- **Intl**: Date formatting
- **Path**: File path manipulation

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/                        # Data models
│   ├── user.dart                  # User model with authentication
│   ├── face_shape.dart            # Face shape enum and result model
│   └── recommendation.dart        # Saved recommendation model
├── services/                      # Business logic
│   ├── database_service.dart      # SQLite database operations
│   ├── face_detection_service.dart # Face detection using ML Kit
│   └── recommendation_service.dart # Style recommendation logic
└── screens/                       # UI screens
    ├── welcome_screen.dart        # Welcome screen with animated intro
    ├── login_screen.dart          # User login
    ├── signup_screen.dart         # User registration
    ├── dashboard_screen.dart      # Main dashboard with feature cards
    ├── face_detection_screen.dart # Camera and face detection
    ├── suggestion_screen.dart     # Display recommendations
    └── gallery_screen.dart        # Saved results gallery
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Camera access permissions

### Installation

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the application:**
   ```bash
   # For Windows
   flutter run -d windows
   
   # For macOS
   flutter run -d macos
   
   # For Linux
   flutter run -d linux
   ```

## 📱 User Experience Flow

1. **App Launch** → Animated welcome screen
2. **User Selection**:
   - Login (existing users)
   - Sign Up (new users)
   - Continue as Guest (no authentication)
3. **Dashboard** → Access to all features:
   - Face Shape Detector
   - Hairstyle Suggestor
   - Beard Suggestor
   - My Gallery (logged-in users only)
4. **Face Detection**:
   - Camera opens with face guide overlay
   - Real-time face detection
   - Capture photo and analyze
5. **Recommendations**:
   - Display detected face shape
   - Show confidence and rating
   - List personalized hairstyle suggestions
   - List personalized beard suggestions
6. **Save Results** (if logged in):
   - Save to local gallery
   - View in My Gallery section

## 🎯 Face Shape Detection Algorithm

The app uses facial landmark detection to calculate:
1. **Measurements**: Forehead width, cheekbone width, jawline width, face length
2. **Ratios**: Length-to-width ratio, jaw sharpness, cheekbone prominence
3. **Classification**: Determines face shape based on calculated ratios
4. **Confidence**: Based on landmark detection quality
5. **Rating**: Calculated from symmetry, jawline, and overall balance

## 💾 Data Management

### Logged-in Users
- User credentials (hashed passwords)
- Face shape detection history
- Saved recommendations with timestamps
- Image storage in organized folders

### Guest Users
- No data persistence
- Runtime-only suggestions
- No save functionality

## 🎨 UI/UX Features

- **Modern Design**: Gradient backgrounds, glassmorphism effects
- **Smooth Animations**: Fade-in, slide, and scale transitions
- **Responsive Layout**: Adapts to different screen sizes
- **Intuitive Navigation**: Clear button labels and icons
- **Visual Feedback**: Loading states, success/error messages

## 📊 Database Schema

### Users Table
- `id`: Primary key
- `name`: Full name
- `email`: Unique email address
- `passwordHash`: SHA-256 hashed password
- `createdAt`: Registration timestamp

### Recommendations Table
- `id`: Primary key
- `userId`: Foreign key to users
- `faceShape`: Detected face shape
- `hairstyles`: Comma-separated list
- `beardStyles`: Comma-separated list
- `rating`: Face rating (1-10)
- `imagePath`: Path to saved image
- `createdAt`: Detection timestamp

## 🔒 Security Features

- Password hashing using SHA-256
- Email uniqueness validation
- Secure local database storage
- Guest mode isolation

## 📝 Future Enhancements (Optional)

- Snapchat Lens integration for live filters
- Hair color simulation
- Beard overlay using AR
- Skin tone analysis
- Makeup filters (for extended user base)

## 🎓 Educational Purpose

This project demonstrates:
- Flutter desktop application development
- Computer vision integration
- Local database management
- User authentication systems
- Image processing and storage
- Modern UI/UX design patterns

## 📄 License

This project is created for educational purposes.

## 👨‍💻 Development Notes

- Built with Flutter for easy cross-platform deployment (Desktop, Android, iOS)
- Uses Google ML Kit for reliable face detection
- Implements clean architecture with separation of concerns
- Follows Material Design 3 guidelines
- Fully responsive design for phones, tablets, and desktop
- Optimized for all platforms (Windows, macOS, Linux, Android, iOS)

