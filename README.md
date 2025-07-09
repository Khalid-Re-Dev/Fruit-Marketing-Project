Fruit-Marketing-Project
A modern, cross-platform fruit marketing and delivery application built with Flutter. This project aims to connect fruit sellers and buyers, providing a seamless experience for browsing, purchasing, and managing fruit orders.

Table of Contents
Project Description
Key Features
Technologies Used
Getting Started / Local Setup
Project Structure
Contributing
License
Contact
Screenshots
Project Description
Fruit-Marketing-Project is a full-featured fruit marketing and delivery platform. It allows users to browse a variety of fruit products, add them to a cart, place orders, and manage their profiles. The app leverages Firebase for authentication, data storage, and payment processing, ensuring a secure and scalable backend.

Purpose:
To simplify the process of buying and selling fruits by providing a user-friendly, digital marketplace.

Problems Solved:

Streamlines fruit ordering for consumers.
Empowers sellers to reach a wider audience.
Provides real-time order management and secure payments.
Core Functionalities:

Product browsing and search
Shopping cart and order management
User authentication and profile management
Payment integration (Stripe)
Favorites and order history
Responsive UI for mobile and web
Key Features
Product Browse & Search: View and search a catalog of fruit items with images, descriptions, and prices.
Product Detail Pages: Detailed view for each fruit item.
Shopping Cart: Add, remove, and update items in the cart.
Order Management: Place orders, view order history, and track status.
User Authentication: Register, login, and manage user profiles (Firebase Auth).
Favorites: Mark and manage favorite products.
Payment Integration: Secure payments via Stripe and Firebase Cloud Functions.
Responsive UI: Optimized for Android, iOS, and Web.
Offline Support: Local data fallback for food items and cart.
Firebase Integration: Firestore for data, Storage for images, Auth for users.
Network Connectivity Checks: Handles offline/online states gracefully.
Technologies Used
Flutter (UI framework)
Dart (Programming language)
Firebase:
firebase_core
firebase_auth (Authentication)
cloud_firestore (Database)
firebase_storage (Image storage)
cloud_functions (Serverless backend for payments)
Stripe (flutter_stripe for payment processing)
State Management: provider
Networking: dio
Local Storage: shared_preferences
UI Enhancements: lottie, google_fonts, animated_text_kit, cached_network_image, flutter_svg
Utilities: uuid, intl, logger, logging, connectivity_plus, image_picker, path
Getting Started / Local Setup
Prerequisites
Flutter SDK
Dart SDK
Android Studio, VS Code, or Xcode (for iOS)
A Firebase project (for backend services)
Stripe account (for payment integration)
Setup Instructions
Clone the repository:
https://github.com/Khalid-Re-Dev/Fruit-Marketing-Project/
cd Fruit-Marketing-Project
Install dependencies:
flutter pub get
Firebase Configuration:

Add your google-services.json (Android) and GoogleService-Info.plist (iOS) to the respective platform folders.
Ensure firebase_options.dart is generated (use flutterfire configure if needed).
Environment Variables:

Set your Stripe publishable key in main.dart.
Configure any other required environment variables.
Run the application:
flutter run
Project Structure :
lib/
  firebase_options.dart         # Firebase config
  main.dart                    # App entry point
  models/                      # Data models (User, FoodItem, Order, etc.)
  screens/                     # UI screens (Home, Cart, Auth, Checkout, etc.)
    auth/                      # Login & Registration screens
    checkout/                  # Delivery & Payment screens
  services/                    # Business logic & API/Firebase services
  themes/                      # App themes (light/dark)
  utils/                       # Utility helpers (e.g., Firebase storage)
  widgets/                     # Reusable UI components
assets/
  images/                      # App images (e.g., empty cart, error, etc.)
  animations/                  # Lottie animation files
  json/                        # Local JSON data (e.g., food_items.json)
test/
  widget_test.dart             # Widget tests
Contributing
Contributions are welcome!
Feel free to open issues or submit pull requests to improve the project. Please follow standard GitHub contribution guidelines.

License
This project is currently unlicensed. You may suggest or add a license (e.g., MIT) as appropriate.

Contact
For questions, suggestions, or support, please contact the project maintainer:

GitHub: Khalid-Re-Dev
Email: kh99.wa.bd@gmail.com
Screenshots :-


Thank you for checking out Fruit-Marketing-Project!# Flutter_Project
