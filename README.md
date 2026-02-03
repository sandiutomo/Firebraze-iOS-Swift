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
- Logged-in users (user id String)

### Subscription Management
- Email subscription states (opted_in, subscribed, unsubscribed)
- Push notification subscription states
- **Subscription Groups** - Add/remove users from specific message groups
- Supports: opted_in, subscribed, unsubscribed

---

## 📝 GTM Tag Configuration Examples

### Custom Attribute
```
Tag Type: Function Call
Class Name: BrazeGTMTagManager

Key                    | Value
-----------------------|--------------------------
actionType             | customAttribute
customAttributeKey     | your-custom-attributekey-value
customAttributeValue   | your-custom-attribute-value
```

### User Attribute
```
Tag Type: Function Call
Class Name: BrazeGTMTagManager

Key              | Value
-----------------|--------------------------
actionType       | userAttribute
attributeKey     | email (or firstName, lastName, phone, gender, dateOfBirth, country, language, homeCity)
attributeValue   | your-user-attribute-value
```

### Change User
```
Tag Type: Function Call
Class Name: BrazeGTMTagManager

Key              | Value
-----------------|--------------------------
actionType       | changeUser
externalUserId   | your_user_id_value
```

### Custom Event
```
Tag Type: Function Call
Class Name: BrazeGTMTagManager

Key                       | Value
--------------------------|--------------------------------
actionType                | logEvent
eventName                 | {{Event Name}}
your-custom-param-key     | your-custom-param-value
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
currency           | {{ecommerce.currency}}
transaction_id     | {{ecommerce.transaction_id}}
items              | {{ecommerce.items}}
```

```
Tag Name:    Braze - Ecommerce Order Placed
Tag Type:    Function Call
Function:    BrazeGTMTagManager

Key                | Value
-------------------|----------------------------------------
actionType         | logEvent
eventName          | {{Event Name}}
currency           | {{ecommerce.currency}}
value              | {{ecommerce.value}}
items              | {{ecommerce.items}}
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
subscriptionState   | your-email-subscrption-state-value
```

### Push Subscription
```
Tag Type: Function Call

Key                 | Value
--------------------|--------------------------
actionType          | setPushSubscription
subscriptionState   | your-push-subscrption-state-value
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

**Made with ❤️ for seamless analytics integration**

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
