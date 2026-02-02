# Braze GTM Tag Manager - iOS Template

Complete integration template for **Firebase Analytics + Google Tag Manager + Braze** with support for:
- ✅ Custom Events
- ✅ Ecommerce Events (GA4 format → Braze format)
- ✅ Purchase Events (per-item logging)
- ✅ User Attributes (with validation)
- ✅ Subscription States (Email & Push)
- ✅ User Identity Management

---

## 📋 Features

### Events
- Custom event logging with properties
- GA4 ecommerce event mapping to Braze standards
- Per-item purchase logging with proper properties

### User Attributes
- Standard attributes: firstName, lastName, email, phone, gender, dateOfBirth, country, language, homeCity
- Format validation (E.164 phone, ISO-639-1 language, ISO 3166-1 country, YYYY-MM-DD dates)
- Custom attributes (String, Int, Double, Bool, Date)

### Subscription Management
- Email subscription states (opted_in, subscribed, unsubscribed)
- Push notification subscription states
- **Subscription Groups** - Add/remove users from specific message groups
- Supports: opted_in, subscribed, unsubscribed

---

## 🚀 Setup Instructions

### iOS (Swift)

1. **Add Dependencies** (Podfile):
```ruby
pod 'Firebase/Analytics'
pod 'GoogleTagManager'
pod 'BrazeKit'
```

2. **Add BrazeGTMTagManager.swift** to your project

3. **Register in AppDelegate**:
```swift
import GoogleTagManager

func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Initialize Firebase
    FirebaseApp.configure()
    
    // Initialize Braze
    let configuration = Braze.Configuration(apiKey: "YOUR-API-KEY", endpoint: "YOUR-ENDPOINT")
    let braze = Braze(configuration: configuration)
    AppDelegate.braze = braze
    
    // Initialize GTM
    let tagManager = TAGManager.instance()
    TAGContainerOpener.openContainer(withId: "GTM-XXXXXX",
                                     tagManager: tagManager,
                                     openType: kTAGOpenTypePreferFresh,
                                     timeout: nil) { container in
        container?.refresh()
    }
    
    return true
}
```

4. **Add AppDelegate.braze static property**:
```swift
extension AppDelegate {
    private static var _braze: Braze?
    static var braze: Braze? {
        get { _braze }
        set { _braze = newValue }
    }
}
```

---


## 📝 GTM Tag Configuration Examples

### Custom Event
```
Tag Type: Function Call
Class Name: {{Class Function Name}}  (iOS) or Function Name: BrazeGTMTagManager (Android)

Key              | Value
-----------------|-----------------
actionType       | logEvent
eventName        | {{Event Name}}
```

### User Attribute
```
Tag Type: Function Call

Key              | Value
-----------------|--------------------------
actionType       | userAttribute
attributeKey     | email
attributeValue   | {{UP - User Attribute - email}}
```

### Purchase Event
```
Tag Type: Function Call

Key              | Value
-----------------|--------------------------
actionType       | logPurchase
currency         | {{currency}}
items            | {{items}}
transaction_id   | {{transaction_id}}
```

#### 💰 logPurchase — Full Example

**How it works:** Firebase fires a `purchase` event → GTM intercepts it → `BrazeGTMTagManager` logs **one Braze purchase per item** (Braze requires individual `logPurchase` calls per product).

---

**Step 1 — Firebase fires the event **Swift :**
```swift
Analytics.logEvent(AnalyticsEventPurchase, parameters: [
    AnalyticsParameterTransactionID: "TXN-1706123456A",
    AnalyticsParameterCurrency: "IDR",
    AnalyticsParameterValue: 200000.0,
    AnalyticsParameterTax: 0.0,
    AnalyticsParameterShipping: 0.0,
    AnalyticsParameterCoupon: "SAVE10",
    AnalyticsParameterItems: [
        [
            AnalyticsParameterItemID: "sku_001",
            AnalyticsParameterItemName: "Wireless Headphones",
            AnalyticsParameterItemCategory: "Electronics",
            AnalyticsParameterItemBrand: "SonyAudio",
            AnalyticsParameterItemVariant: "Black",
            AnalyticsParameterPrice: 50000.0,
            AnalyticsParameterQuantity: 2
        ],
        [
            AnalyticsParameterItemID: "sku_002",
            AnalyticsParameterItemName: "USB-C Cable",
            AnalyticsParameterItemCategory: "Accessories",
            AnalyticsParameterItemBrand: "Anker",
            AnalyticsParameterItemVariant: "1m",
            AnalyticsParameterPrice: 100000.0,
            AnalyticsParameterQuantity: 1
        ]
    ]
])
```

---

**Step 2 — GTM Tag configuration:**
```
Tag Name:    Braze - Log Purchase
Tag Type:    Function Call
Function:    BrazeGTMTagManager

Key                | Value
-------------------|----------------------------------------
actionType         | logPurchase
currency           | {{Event Value - currency}}
transaction_id     | {{Event Value - transaction_id}}
items              | {{Event Value - items}}

Trigger:    Purchase (built-in GA4 purchase event)
```

---

**Step 3 — BrazeGTMTagManager processes each item individually:**
```
Input (2 items):
  items[0] → sku_001 | Wireless Headphones | IDR 50,000 x 2
  items[1] → sku_002 | USB-C Cable         | IDR 100,000 x 1

Output (2 separate Braze logPurchase calls):
  ├── logPurchase("Wireless Headphones", "IDR", 50000.0, qty=2, properties)
  └── logPurchase("USB-C Cable",         "IDR", 100000.0, qty=1, properties)

Properties attached to each item:
  product_id     → sku_001 / sku_002
  price          → 50000.0 / 100000.0
  transaction_id → TXN-1706123456A
  category       → Electronics / Accessories
  brand          → SonyAudio / Anker
  variant        → Black / 1m
  value          → 200000.0 (total order value)
```

---

**Step 4 — Verify in Braze Dashboard:**
- Go to **Settings** → **User Search** → search external user ID
- Click **Custom Events** tab → look for purchase events
- Each item appears as a **separate purchase entry** with its own properties
- All entries share the same `transaction_id` so you can group them

---

**⚠️ Key things to know about logPurchase:**
- Braze requires **one `logPurchase` call per product** — you cannot batch multiple items in a single call
- The first argument is always the **product name** (not ID) — Braze uses this as the purchase identifier in the dashboard
- `product_id` (SKU) is passed inside properties for reference
- `quantity` handles multiples of the same item (e.g. buying 2 headphones = qty 2, not 2 separate calls)
- `value` in properties is the **total order value**, not the per-item value

### Email Subscription
```
Tag Type: Function Call

Key                 | Value
--------------------|--------------------------
actionType          | setEmailSubscription
subscriptionState   | opted_in
```

### Push Subscription
```
Tag Type: Function Call

Key                 | Value
--------------------|--------------------------
actionType          | setPushSubscription
subscriptionState   | subscribed
```

### Add to Subscription Group
```
Tag Type: Function Call

Key                    | Value
-----------------------|----------------------------------
actionType             | addToSubscriptionGroup
subscriptionGroupId    | your-group-id-from-braze-dashboard
```

### Remove from Subscription Group
```
Tag Type: Function Call

Key                    | Value
-----------------------|----------------------------------
actionType             | removeFromSubscriptionGroup
subscriptionGroupId    | your-group-id-from-braze-dashboard
```

---

## 🎯 Usage Examples

### Firebase Analytics (Both Platforms)

**Swift:**
```swift
// Log custom event
Analytics.logEvent("button_clicked", parameters: ["button_name": "signup"])

// Set user attributes
Analytics.setUserProperty("test@example.com", forName: "email")
Analytics.setUserProperty("John", forName: "first_name")

// Log purchase
Analytics.logEvent(AnalyticsEventPurchase, parameters: [
    AnalyticsParameterCurrency: "USD",
    AnalyticsParameterValue: 29.99,
    AnalyticsParameterTransactionID: "TXN123",
    AnalyticsParameterItems: [[
        AnalyticsParameterItemID: "SKU001",
        AnalyticsParameterItemName: "Premium Plan",
        AnalyticsParameterPrice: 29.99,
        AnalyticsParameterQuantity: 1
    ]]
])
```

---

## 📊 Data Format Requirements

### Date of Birth
- **Format:** `YYYY-MM-DD` (ISO 8601)
- **Example:** `2012-12-12`

### Language
- **Format:** ISO-639-1 (2-letter lowercase)
- **Example:** `en`, `es`, `fr`, `id`

### Country
- **Format:** ISO 3166-1 alpha-2 (2-letter uppercase)
- **Example:** `US`, `GB`, `ID`, `AU`

### Phone Number
- **Format:** E.164 (+[country][number])
- **Example:** `+14155552671`, `+628123456789`

### Gender
- **Values:** `male`, `female`, `other`, `unknown`, `prefer_not_to_say`

### Subscription States
- **Values:** `opted_in`, `subscribed`, `unsubscribed`

---

## 🔍 Debugging

### Enable Detailed Logging

**iOS:**
```swift
// Add to your scheme's Run arguments
-FIRDebugEnabled
-FIRAnalyticsDebugEnabled
```


### Check Logs

**iOS (Xcode Console):**
```
🔍 ===== BrazeGTMTagManager EXECUTE =====
📍 'actionType' = 'logEvent'
✅ Action Type determined: logEvent
⏩ Braze custom event logged: button_clicked
```

---

## 🤝 Contributing

This is a template for integrating Firebase Analytics + GTM + Braze. Feel free to:
- Customize action types and parameters
- Add additional validation
- Extend with more Braze features
- Adapt to your specific use case

---

## 📄 License

This template is provided as-is for educational and integration purposes.

---

## 🆘 Support

For issues:
- **Braze SDK:** https://www.braze.com/docs/developer_guide/
- **Firebase Analytics:** https://firebase.google.com/docs/analytics
- **Google Tag Manager:** https://developers.google.com/tag-manager

---

## ✅ Checklist for Implementation

- [ ] Add dependencies (CocoaPods/Gradle)
- [ ] Copy BrazeGTMTagManager file to project
- [ ] Configure Firebase (GoogleService-Info.plist / google-services.json)
- [ ] Initialize Braze with API key and endpoint
- [ ] Set up GTM container
- [ ] Create GTM tags for events
- [ ] Create GTM triggers
- [ ] Test with debug builds
- [ ] Verify data in Braze dashboard
- [ ] Deploy to production

---

**Made with ❤️ for seamless analytics integration**

## 📬 Subscription Groups Explained

### What are Subscription Groups?

Subscription Groups allow you to organize your messaging into specific categories that users can opt in/out of independently.

**Examples:**
- Marketing Emails
- Transactional Emails  
- Newsletter
- Product Updates
- Promotional SMS
- Order Status Notifications

### How to Use

1. **Create Subscription Groups in Braze Dashboard:**
   - Go to **Engagement** → **Subscriptions** → **Subscription Groups**
   - Click **+ Create Subscription Group**
   - Note the Group ID (e.g., `subscription_group_id_abc123`)

2. **Add User to Group via GTM:**
```
Tag Type: Function Call

Key                    | Value
-----------------------|----------------------------------
actionType             | addToSubscriptionGroup
subscriptionGroupId    | subscription_group_id_abc123
```

3. **Example in Firebase Analytics:**

**Swift:**
```swift
// User opts into marketing emails
Analytics.logEvent("subscription_preference_changed", parameters: [
    "group_type": "marketing_emails",
    "action": "add"
])

// GTM tag will call: addToSubscriptionGroup with the group ID
```


### Best Practices

- Use subscription groups for **granular control** over message types
- Use subscription states for **global** opt-in/out preferences
- Always respect user preferences immediately
- Sync subscription preferences across platforms

### Subscription Groups vs Subscription States

| Feature | Subscription States | Subscription Groups |
|---------|-------------------|-------------------|
| Scope | Global (email/push) | Specific message types |
| Values | opted_in, subscribed, unsubscribed | Member/Not Member |
| Use Case | GDPR compliance, global preferences | Message categorization |
| Example | "Unsubscribe from all emails" | "Unsubscribe from marketing only" |
