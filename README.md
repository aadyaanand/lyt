# VoltLoop - Smart Battery Management App

VoltLoop is a comprehensive iOS application that helps users track battery health, reuse and recycle batteries, connect with their community for battery swaps, and monitor their environmental impact. Built with SwiftUI and Firebase, it combines sustainability, community networking, and real-time battery data into a sleek, Gotham-inspired interface.

## 🌟 Features

### Core Features
- **Battery Scan & Health Checker**: Scan QR/barcodes or manually input battery models with AI-powered health assessment
- **Battery Match + Swap Network**: Post extra batteries for donation and request batteries from the community
- **Drop-Off Point Finder**: Interactive map of verified e-waste and battery collection centers
- **Community Power Packs**: Pre-packed bundles for shelters, robotics clubs, and disaster relief
- **Emergency Mode**: Locate people needing power banks during outages

### Environmental Impact
- **Impact Dashboard**: Track batteries reused, e-waste diverted, rare metals preserved, and CO₂ avoided
- **Badges + Leaderboard**: Earn achievements and compete with the community
- **Revive Mode**: Step-by-step battery revival tips and low-voltage rescue workflows

### DIY & Builder Features
- **Open Tech Library**: Projects using repurposed batteries sorted by type, skill level, and age group
- **Teacher/Coach Portal**: Request supplies for STEM builds and track donor fulfillment

### Safety & Trust
- **Battery Safety Auto-Flag**: Blocks unsafe or recalled models
- **Verified Donor/Receiver Tags**: Email/school/org verification system

## 🎨 Design System

### Color Palette
- **Jet Black**: #050000 (Base)
- **White**: #FFFFFF (Primary text/icons)
- **Electric Blue**: #6e9ec4 (Active states, borders)
- **Burnt Orange**: #ff3700 (Alerts, emergency)
- **Soft Yellow**: #fee4a3 (Warm accent)

### Typography
- **Font**: SF Pro / Inter, sans-serif
- **Headers**: Bold, Title Case
- **Body**: Medium or Light
- **System Notes**: Extra Light grey

## 🛠 Technical Stack

### Frontend
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **Core Location**: Location services and mapping
- **AVFoundation**: Camera and barcode scanning
- **Vision**: AI-powered barcode detection

### Backend
- **Firebase Auth**: Authentication (Email, Google, Apple)
- **Firebase Firestore**: NoSQL database for real-time data
- **Firebase Cloud Messaging**: Push notifications
- **Supabase**: Alternative backend option for scalability

### APIs & Services
- **Battery API**: External battery information service
- **Google Maps SDK**: Custom monochrome map styling
- **Core ML**: Machine learning for battery health analysis

## 📱 Installation & Setup

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Apple Developer Account (for device testing)
- Firebase Project
- Google Cloud Console access

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/voltloop.git
cd voltloop
```

### 2. Install Dependencies
```bash
# Using Swift Package Manager (recommended)
# Dependencies are automatically managed through Xcode

# Or using CocoaPods (alternative)
pod install
```

### 3. Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an iOS app to your Firebase project
3. Download `GoogleService-Info.plist` and add it to your Xcode project
4. Enable Authentication methods (Email/Password, Google, Apple)
5. Create Firestore database with security rules
6. Enable Cloud Messaging for push notifications

### 4. API Configuration
1. Get API keys for external services:
   - Battery API: [Battery API Documentation](https://www.batteryapi.com/docs)
   - Google Maps: [Google Cloud Console](https://console.cloud.google.com/)
2. Update API keys in the respective service files

### 5. Build and Run
1. Open `VoltLoop.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project (⌘+R)

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the project root:
```env
FIREBASE_API_KEY=your_firebase_api_key
BATTERY_API_KEY=your_battery_api_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Firebase Security Rules
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Donations are publicly readable, but only creators can modify
    match /donations/{donationId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Requests follow similar pattern
    match /requests/{requestId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

## 🏗 Architecture

### MVVM Pattern
The app follows the Model-View-ViewModel architecture:

- **Models**: Data structures for batteries, users, donations, etc.
- **Views**: SwiftUI views for UI components
- **ViewModels**: Observable objects that manage state and business logic
- **Managers**: Service classes for authentication, location, battery management, etc.

### Key Components
```
VoltLoop/
├── VoltLoopApp.swift          # App entry point
├── ContentView.swift          # Main navigation
├── Views/                     # UI Components
│   ├── Welcome/              # Onboarding
│   ├── Authentication/       # Login/Signup
│   ├── Main/                # Tab views
│   ├── BatteryTools/        # Scanning & tools
│   ├── Community/           # Social features
│   ├── Impact/              # Environmental tracking
│   └── Maker/               # DIY projects
├── Managers/                 # Business logic
│   ├── AuthenticationManager.swift
│   ├── BatteryManager.swift
│   ├── LocationManager.swift
│   └── CommunityManager.swift
├── Services/                 # External APIs
│   ├── BatteryAPI.swift
│   └── CameraManager.swift
├── Design/                   # Design system
│   └── ColorExtensions.swift
└── Models/                   # Data structures
```

## 🧪 Testing

### Unit Tests
```bash
# Run unit tests
xcodebuild test -scheme VoltLoop -destination 'platform=iOS Simulator,name=iPhone 15'
```

### UI Tests
```bash
# Run UI tests
xcodebuild test -scheme VoltLoop -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:VoltLoopUITests
```

## 📊 Analytics & Monitoring

### Firebase Analytics
Track user engagement and app performance:
- Battery scan events
- Community interactions
- Environmental impact metrics
- User retention and conversion

### Crash Reporting
Automatic crash reporting through Firebase Crashlytics for stability monitoring.

## 🔒 Security

### Data Protection
- All sensitive data is encrypted at rest and in transit
- User authentication through Firebase Auth
- Secure API key management
- Privacy-compliant data collection

### Privacy
- Minimal data collection
- User consent for location and camera access
- GDPR and CCPA compliant
- Transparent data usage policies

## 🚀 Deployment

### App Store Preparation
1. Update version and build numbers
2. Create app store screenshots
3. Write app store description
4. Configure app store connect
5. Submit for review

### CI/CD Pipeline
```yaml
# GitHub Actions example
name: Build and Test
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and Test
        run: |
          xcodebuild test -scheme VoltLoop -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 🤝 Contributing

### Development Guidelines
1. Follow Swift style guidelines
2. Write unit tests for new features
3. Update documentation
4. Create feature branches
5. Submit pull requests

### Code Style
- Use SwiftLint for code formatting
- Follow MVVM architecture
- Write self-documenting code
- Add comments for complex logic

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Firebase team for the excellent backend services
- Apple for SwiftUI and iOS development tools
- The open-source community for various libraries and tools
- Environmental organizations for battery recycling guidelines

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Email: support@voltloop.app
- Documentation: [docs.voltloop.app](https://docs.voltloop.app)

## 🔄 Changelog

### Version 1.0.0
- Initial release
- Core battery scanning and health assessment
- Community features and battery swaps
- Environmental impact tracking
- Emergency mode and location services
- Teacher portal and maker projects

---

**VoltLoop** - Powering a sustainable future, one battery at a time. 🔋♻️ 