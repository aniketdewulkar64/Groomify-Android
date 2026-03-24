# Groomify - Quick Setup Guide

## Prerequisites

1. **Flutter SDK** (version 3.0.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **IDE** (Optional but recommended)
   - Visual Studio Code with Flutter extension
   - OR Android Studio with Flutter plugin

3. **Camera Access**
   - Ensure your device has a working camera
   - Grant camera permissions when prompted

## Installation Steps

### Step 1: Clone/Navigate to Project
```bash
cd GROOMIFYYY
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

This will install all required packages:
- `google_fonts` - Typography
- `flutter_animate` - Animations
- `camera` - Camera access
- `google_mlkit_face_detection` - Face detection
- `sqflite` - Database
- `path_provider` - File system access
- And other dependencies...

### Step 3: Run the Application

**For Windows:**
```bash
flutter run -d windows
```

**For macOS:**
```bash
flutter run -d macos
```

**For Linux:**
```bash
flutter run -d linux
```

### Step 4: Test the Application

1. **Welcome Screen**: Should show animated welcome screen with three options
2. **Sign Up**: Create a test account
   - Email: test@example.com
   - Password: test123
3. **Login**: Use the credentials you just created
4. **Face Detection**: 
   - Click "Face Shape Detector"
   - Allow camera permissions
   - Position face in frame
   - Click "Detect Face Shape"
5. **View Recommendations**: See hairstyle and beard suggestions
6. **Save Result**: Click "Save Result" (only for logged-in users)
7. **Gallery**: View saved results in "My Gallery"

## Troubleshooting

### Issue: Camera not working
**Solution**: 
- Check camera permissions in system settings
- Ensure no other app is using the camera
- Try restarting the application

### Issue: Face detection not working
**Solution**:
- Ensure good lighting
- Face should be clearly visible
- Try different angles
- Check if ML Kit is properly initialized

### Issue: Database errors
**Solution**:
- Delete the app and reinstall
- Database will be recreated automatically
- Check file permissions

### Issue: Dependencies not installing
**Solution**:
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

## Project Structure Overview

```
GROOMIFYYY/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── models/                      # Data models
│   ├── services/                    # Business logic
│   └── screens/                     # UI screens
├── pubspec.yaml                     # Dependencies
├── README.md                        # Main documentation
├── PROJECT_EXPLANATION.md          # Detailed explanation
└── SETUP_GUIDE.md                  # This file
```

## Key Files to Review

1. **lib/main.dart** - Application entry point
2. **lib/services/face_detection_service.dart** - AI face detection logic
3. **lib/services/recommendation_service.dart** - Style recommendation logic
4. **lib/screens/dashboard_screen.dart** - Main navigation
5. **lib/screens/face_detection_screen.dart** - Camera and detection UI

## Testing Checklist

- [ ] App launches successfully
- [ ] Welcome screen displays correctly
- [ ] Sign up creates new user
- [ ] Login works with created credentials
- [ ] Guest mode works without login
- [ ] Camera opens and displays preview
- [ ] Face detection captures image
- [ ] Face shape is detected correctly
- [ ] Recommendations are displayed
- [ ] Save functionality works (logged-in users)
- [ ] Gallery displays saved results
- [ ] Guest users cannot save (shows message)

## Performance Notes

- First face detection may take 2-3 seconds (ML Kit initialization)
- Subsequent detections are faster
- Image saving is asynchronous (won't block UI)
- Database queries are optimized with indexing

## Development Tips

1. **Hot Reload**: Press `r` in terminal to hot reload
2. **Hot Restart**: Press `R` in terminal to hot restart
3. **Debug Mode**: Use `flutter run` for debugging
4. **Release Mode**: Use `flutter build` for production

## Next Steps for Enhancement

1. Add unit tests for services
2. Add widget tests for UI components
3. Implement error logging
4. Add user profile management
5. Implement recommendation history search
6. Add export functionality for recommendations

## Support

For issues or questions:
1. Check Flutter documentation: https://flutter.dev/docs
2. Check package documentation in pubspec.yaml
3. Review code comments in source files

---

**Happy Coding! 🚀**

