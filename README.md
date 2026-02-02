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

## 📝 GTM Tag Configuration Examples

### Custom Event
```
Tag Type: Function Call
Class Name: BrazeGTMTagManager

Key                       | Value
--------------------------|--------------------------------
actionType                | logEvent
eventName                 | {{Event Name}}
YOUR_CUSTOM_PARAM_KEY     | {{YOUR_CUSTOM_PARAM_VALUE}}
```

### User Attribute
```
Tag Type: Function Call
Class Name: BrazeGTMTagManager

Key              | Value
-----------------|--------------------------
actionType       | userAttribute
attributeKey     | email (or firstName, lastName, phone, gender, dateOfBirth, country, language, homeCity)
attributeValue   | {{UP - USER_ATTRIBUTE_VALUE}}
```

### Purchase Event

> **⚠️ DEPRECATION NOTICE:**  
> The `logPurchase` action type is **soon to be deprecated** in favor of using standard custom events for ecommerce tracking. This implementation now routes purchase events to **both** `logPurchase` (for backward compatibility) **and** the custom event "ecommerce.order_placed" via `logEvent` to future-proof your analytics.

---

**Step 1 — Firebase fires the event:**
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
```
```
Tag Name:    Braze - Log Ecommerce Order Placed
Tag Type:    Function Call
Function:    BrazeGTMTagManager

Key                | Value
-------------------|----------------------------------------
actionType         | logEvent
eventName          | {{Event Name}}
currency           | {{Event Value - currency}}
value              | {{Event Value - value}}
items              | {{Event Value - items}}
```

---

**Step 3 — BrazeGTMTagManager processes each item individually:**
```
Input (2 items):
  items[0] → sku_001 | Wireless Headphones | IDR 50,000 x 2
  items[1] → sku_002 | USB-C Cable         | IDR 100,000 x 1

Output (2 separate Braze logPurchase calls + 1 custom event):
  ├── logPurchase("Wireless Headphones", "IDR", 50000.0, qty=2, properties)
  ├── logPurchase("USB-C Cable",         "IDR", 100000.0, qty=1, properties)
  └── logCustomEvent("ecommerce.order_placed"), with full order details: ("Wireless Headphones", "IDR", 50000.0, qty=2, properties)
  └── logCustomEvent("ecommerce.order_placed"), with full order details: ("USB-C Cable",         "IDR", 100000.0, qty=1, properties)
```

---

**⚠️ Key things to know about logPurchase:**
- Braze requires **one `logPurchase` call per product** — you cannot batch multiple items in a single call
- The first argument is always the **product name** (not ID) — Braze uses this as the purchase identifier in the dashboard
- `product_id` (SKU) is passed inside properties for reference
- `quantity` handles multiples of the same item (e.g. buying 2 headphones = qty 2, not 2 separate calls)
- `value` in properties is the **total order value**, not the per-item value
- **Future-proofing:** This implementation automatically creates `ecommerce.order_placed` custom events alongside `logPurchase` calls to ensure continuity when Braze deprecates the purchase API

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

### Firebase Analytics

**Swift:**
```swift
// Log custom event
Analytics.logEvent("button_clicked", parameters: ["button_name": "signup"])

// Set user attributes
Analytics.setUserProperty("test@example.com", forName: "email")
Analytics.setUserProperty("John", forName: "first_name")

// Log purchase (automatically routes to both logPurchase and ecommerce.order_placed)
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

## 🔐 Security Best Practices

### Never Commit Secrets to Git

1. **Always use `.gitignore`** to exclude sensitive files:
```bash
# .gitignore
dummy.app.2026/secrets/
*.plist
*Secrets*
```

2. **Use environment-specific configuration files:**
   - Development: `BrazeSecrets-Dev.plist`
   - Staging: `BrazeSecrets-Staging.plist`
   - Production: `BrazeSecrets-Prod.plist`

3. **Rotate API keys immediately** if accidentally exposed:
   - Braze: Generate new API key in Braze Dashboard → Settings → API Keys
   - GTM: Create new container or regenerate credentials
   - Firebase: Regenerate GoogleService-Info.plist

4. **Use CI/CD secrets management** for production builds:
   - GitHub Actions Secrets
   - Xcode Cloud environment variables
   - Fastlane environment variables

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

- [ ] Add dependencies (CocoaPods)
- [ ] Copy BrazeGTMTagManager file to project
- [ ] Create `secrets/` folder and add configuration files
- [ ] Add `secrets/` to `.gitignore`
- [ ] Configure Firebase (GoogleService-Info.plist)
- [ ] Initialize Braze with secrets loaded from plist
- [ ] Set up GTM container with secrets
- [ ] Create GTM tags for events
- [ ] Create GTM triggers
- [ ] Test with debug builds
- [ ] Verify both `logPurchase` and `ecommerce.order_placed` events in Braze dashboard
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

---

## 🔄 Migration Path for logPurchase Deprecation

When Braze officially deprecates `logPurchase`, your implementation is already prepared:

1. **Current State (Now):**
   - Purchase events trigger both `logPurchase()` and `ecommerce.order_placed`
   - Both appear in Braze dashboard
   - No data loss

2. **Transition Period:**
   - Continue monitoring both event types
   - Validate that `ecommerce.order_placed` contains all necessary data
   - Update any dashboards/reports to reference the new event

3. **Post-Deprecation:**
   - Simply remove the `logPurchase` routing from BrazeGTMTagManager.swift
   - All purchase data will flow exclusively through `ecommerce.order_placed`
   - Zero downtime, zero data loss

**No action required from you** — the dual-logging system ensures continuity automatically.
