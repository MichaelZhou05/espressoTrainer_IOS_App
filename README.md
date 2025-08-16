# Espresso Trainer

A SwiftUI app for home baristas to track and analyze their espresso shots.

## Features

### Core Features
- **Bean Management**: Add, store, and manage your coffee beans with detailed information
- **Guided Shot Recording**: Step-by-step flow through 6 pages to capture shot details
- **Built-in Timer**: Real-time shot timing with start/stop functionality
- **Auto-calculation**: Automatic extraction ratio calculation (yield ÷ dose)
- **Local Storage**: All data is stored locally using UserDefaults
- **Shot History**: View and browse past shots with detailed information

### Bean Management System
- **Paginated Bean Creation**: Step-by-step guided flow for adding new beans
  - **Page 1 - Origin**: Enter where the coffee is from (country/region)
  - **Page 2 - Roast Level**: Select Light/Medium/Dark with visual color indicators
  - **Page 3 - Roast Date**: Pick roast date with live freshness calculation
  - **Page 4 - Bean Name**: Name your bean with preview of all entered info
- **Bean Selection**: Choose from your saved beans when recording shots
- **Freshness Tracking**: Automatic calculation of days since roast with freshness indicators
- **Bean Details**: Each bean stores roast level, origin, and roast date information
- **Swipe-to-Delete**: Remove beans with a simple left swipe gesture (iOS-style)
- **Visual Indicators**: Color-coded roast levels and freshness status
- **Smart Input**: Each step focuses on one piece of information for better UX

### 6-Page Shot Flow
1. **Page 1 - Choose Bean**: Select from your saved beans or add new ones
2. **Page 2 - Grind Setting**: Adjust grind setting from 1-10 with slider  
3. **Page 3 - Dose**: Enter coffee input weight in grams
4. **Page 4 - Shot Timer**: Built-in timer for timing your espresso shot
5. **Page 5 - Yield**: Enter output weight with side-by-side extraction ratio display and ideal ratio guidance
6. **Page 6 - Flavor Compass**: Interactive circular interface to pinpoint espresso taste profile
   - Drag needle across color-coded wheel to describe flavor
   - Horizontal axis: Sour (left) → Bitter (right)
   - Vertical axis: Light (top) → Dark (bottom)
   - Real-time flavor description updates

### Navigation & UX
- **Progress Indicator**: Visual progress bar showing current step (both shot and bean flows)
- **Step Validation**: Next button disabled until required fields are complete
- **Back/Forward Navigation**: Easy navigation between steps in both flows
- **Form Persistence**: State maintained throughout shot and bean creation flows
- **Full-Screen Experience**: Immersive shot recording and bean creation experience
- **Dedicated Flows**: Separate optimized flows for shot recording and bean management
- **Cancel Support**: Easy exit from multi-page flows with top-right X button

### Data Display
- **Home Screen**: Clean landing page with recent shots preview
- **Shot History**: Complete browsable history with bean information and freshness
- **Bean Information**: Each shot displays bean name, origin, roast level, and age
- **Extraction Ratio**: Prominently displayed with automatic calculation
- **Date & Time**: Each shot timestamped for tracking trends
- **Freshness Indicators**: Visual cues showing bean freshness over time

### UI Features
- **Modern Design**: Clean, step-focused interface with excellent typography
- **Color-coded Elements**: Visual indicators for roast levels and timer states
- **Responsive Layout**: Optimized for iPhone with proper spacing
- **Touch-Friendly**: Large buttons and easy-to-use controls

## Technical Details

- **Framework**: SwiftUI
- **Data Storage**: UserDefaults with JSON encoding
- **Minimum iOS Version**: 18.5
- **Architecture**: MVVM with @State properties

## Future Enhancements

- Charts and analytics for shot trends
- Export functionality
- Multiple coffee bean profiles
- Shot rating system
- Brew method selection
- Temperature tracking
- Pressure profiling (for advanced machines)

## Getting Started

1. Open the project in Xcode
2. Select your target device or simulator
3. Build and run the app
4. Start recording your espresso shots!

The app is designed to be simple and focused, helping home baristas develop their skills through consistent tracking and analysis of their shots. # espresso_trainer_IOS
