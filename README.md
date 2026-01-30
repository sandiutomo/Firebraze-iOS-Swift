Firebraze

Firebraze is an iOS template that enables sending GA4-structured analytics events to Braze via Google Tag Manager (GTM).
It acts as a translation layer between GA4’s event & ecommerce data model and Braze’s event, purchase, and user attribute APIs.

This project is designed for teams who want consistent analytics instrumentation, scalable event governance, and clean separation between app code and marketing SDK logic.

🚀 Key Features
GA4 → Braze Event Mapping

- Log Braze custom events and purchase events

- Supports GA4 ecommerce schema, including full items[] array parsing

- Works for both standard GA4 ecommerce events and custom events


Braze User Attribute Management

- Log custom user attributes with automatic type parsing:

    - String

    - Int

    - Float / Double

     - Boolean

- Set default Braze user attributes

- Change Braze user ID dynamically

- Update user subscription state (email / push)


GTM-First Architecture

- Centralized event logic via Google Tag Manager

- Minimal coupling between app code and the Braze SDK

- Easy to extend for additional destinations or schemas


🧱 Tech Stack

- Language: Swift

- Platform: iOS


SDKs & Tools

- Firebase SDK

- Google Tag Manager SDK

- Braze iOS SDK


📦 Installation

Prerequisites

- Xcode 16.4+

- iOS deployment target compatible with Braze & Firebase SDKs

Dependency manager:

- CocoaPods or Swift Package Manager


Setup (High Level)

1. Clone the repository

2. Install dependencies

3. Configure:

    - Firebase

    - Google Tag Manager container

    - Braze SDK credentials

    - Map GA4 event parameters to Braze via GTM tags. Detailed setup instructions can be added in a dedicated docs/ section if needed.





👤 Author:
- Sandi Utomo, CXM Solution Architect
- LinkedIn: https://www.linkedin.com/in/sandiutomo/
- Email: hi.sandiutomo@gmail.com
