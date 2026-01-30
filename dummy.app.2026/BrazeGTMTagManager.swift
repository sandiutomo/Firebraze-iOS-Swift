import SwiftUI
import FirebaseCore
import Firebase
import FirebaseAnalytics
import GoogleTagManager
import BrazeKit

let ActionTypeKey: String = "actionType"
// Custom Events
let LogEventAction: String = "logEvent"
let LogEventName: String = "eventName"
// Purchase Events
let LogPurchaseAction: String = "logPurchase"
let PurchaseProductIdKey: String = "product_id"
let PurchaseCurrencyKey: String = "currency"
let PurchasePriceKey: String = "price"
let PurchasePropertiesKey: String = "properties"
// Change User
let ChangeUserAction: String = "changeUser"
let ChangeUserExternalUserId: String = "externalUserId"
// Attributes
let CustomAttributeAction: String = "customAttribute"
let CustomAttributeKey: String = "customAttributeKey"
let CustomAttributeValueKey: String = "customAttributeValue"
let UserAttributeAction: String = "userAttribute"
let AttributeKey: String = "attributeKey"
let AttributeValueKey: String = "attributeValue"
// Subscription States
let SubscriptionStateKey: String = "subscriptionState"
let SetEmailSubscriptionAction: String = "setEmailSubscription"
let SetPushSubscriptionAction: String = "setPushSubscription"
// Subscription Groups
let AddToSubscriptionGroupAction: String = "addToSubscriptionGroup"
let RemoveFromSubscriptionGroupAction: String = "removeFromSubscriptionGroup"
let SubscriptionGroupIdKey: String = "subscriptionGroupId"

@objc(BrazeGTMTagManager)
final class BrazeGTMTagManager : NSObject, TAGCustomFunction {
    @objc func execute(withParameters parameters: [AnyHashable : Any]!) -> NSObject! {
        print("# 🔍 ===== BrazeGTMTagManager EXECUTE ===== 🔍")
        
        guard parameters != nil else {
            print("# ❌ Parameters are nil! ❌")
            return nil
        }
        print("# 👉🔍 Raw parameters available:", parameters!)
        
        var parameters: [String : Any] = parameters as! [String : Any]
        print("# 👉 Print parameters respectively for debugging")
        print("#    🔍 All parameters:")
        for (key, value) in parameters {
            print("#        📍   '\(key)' = '\(value)' (type: \(type(of: value)))")
        }
        
        var actionType: String?
        if let explicitActionType = parameters[ActionTypeKey] as? String {
            actionType = explicitActionType
            parameters.removeValue(forKey: ActionTypeKey)
        } else if parameters["ga4_purchase"] != nil {
            actionType = "logPurchase"
            parameters.removeValue(forKey: "ga4_purchase")
        } else if parameters["eventName"] != nil {
            actionType = "logEvent"
        }
        
        guard let actionType = actionType else {
            print("# ❌ Cannot determine action type from parameters ❌")
            print("# ❌ Available keys:", parameters.keys)
            return nil
        }
        print("# ✅ 1. Action Type determined:", actionType)
        
        // MARK: - List of actionType to be used in Google Tag Manager
        if actionType == LogEventAction {
            print("#    🔷 Routing to logEvent 🔷")
            logEvent(parameters: parameters)
        } else if actionType == LogPurchaseAction {
            print("#    🔷 Routing to logPurchase 🔷")
            logPurchase(parameters: parameters)
        } else if actionType == CustomAttributeAction || actionType == UserAttributeAction {
            print("#    🔷 Routing to logCustomAttribute (action: \(actionType)) 🔷")
            logCustomAttribute(parameters: parameters)
        } else if actionType == ChangeUserAction {
            print("#    🔷 Routing to changeUser 🔷")
            changeUser(parameters: parameters)
        } else if actionType == SetEmailSubscriptionAction {
            print("#    🔷 Routing to setEmailSubscription 🔷")
            setEmailSubscription(parameters: parameters)
        } else if actionType == SetPushSubscriptionAction {
            print("#    🔷 Routing to setPushSubscription 🔷")
            setPushSubscription(parameters: parameters)
        } else if actionType == AddToSubscriptionGroupAction {
            print("#    🔷 Routing to addToSubscriptionGroup 🔷")
            addToSubscriptionGroup(parameters: parameters)
        } else if actionType == RemoveFromSubscriptionGroupAction {
            print("#    🔷 Routing to removeFromSubscriptionGroup 🔷")
            removeFromSubscriptionGroup(parameters: parameters)
        } else {
            print("#    ❌❌ Unknown action type:", actionType)
        }
        print("# ✅ 2. GTM Braze tag execution completed")
        return nil
    }
    // MARK: - Log Custom Event & Ecommerce (Non Purchase) Event
    func logEvent(parameters: [String : Any]) {
        var parameters: [String : Any] = parameters
        guard let eventName: String = parameters[LogEventName] as? String else {
            return
        }
        parameters.removeValue(forKey: LogEventName)
        
        let isEcommerceEvent = eventName.contains("view_item") || eventName.contains("add_to_cart") || eventName.contains("begin_checkout") || eventName.contains("remove_from_cart") || eventName.contains("view_cart") || eventName.contains("select_item") || eventName.contains("purchase") || eventName.contains("order_placed") || eventName.contains("refund")
        
        // Routing for custom event or ecommerce event
        if isEcommerceEvent {
            print("#    🛒 Detected GA4 ecommerce event:", eventName)
            handleEcommerceEvent(eventName: eventName, parameters: parameters)
            AppDelegate.braze?.requestImmediateDataFlush()
        } else {
            AppDelegate.braze?.logCustomEvent(name: eventName, properties: parameters)
            AppDelegate.braze?.requestImmediateDataFlush()
            print("#    ⏩ Braze custom event logged:", eventName)
        }
    }
    // MARK: - Helper: Ecommerce Parser
    func handleEcommerceEvent(eventName: String, parameters: [String: Any]) {
        print("#    🔍 Processing ecommerce event parameters...")
        // Mapping GA4 ecommerce event name to equivalent Braze ecommerce event name
        let brazeEventName: String
        switch eventName {
        case "select_item":
            brazeEventName = "ecommerce.product_clicked"
        case "view_item":
            brazeEventName = "ecommerce.product_viewed"
        case "add_to_cart":
            brazeEventName = "ecommerce.product_added_to_cart"
        case "remove_from_cart":
            brazeEventName = "ecommerce.product_removed_from_cart"
        case "view_cart":
            brazeEventName = "ecommerce.cart_viewed"
        case "begin_checkout":
            brazeEventName = "ecommerce.checkout_started"
        case "add_payment_info", "add_shipping_info":
            brazeEventName = "ecommerce.order_placed"
            /*      case "purchase":
             brazeEventName = "ecommerce.xxxxxx" */ // preparation for new purchase event to be released in 2026
        case "refund":
            brazeEventName = "ecommerce.purchase_refunded"
        default:
            brazeEventName = eventName
        }
        
        var items: [[String: Any]]?
        if let directItems = parameters["items"] as? [[String: Any]] {
            items = directItems
        }
        
        if let itemsArray = items, !itemsArray.isEmpty {
            print("#    📦 Found \(itemsArray.count) items in event")
            
            for (index, item) in itemsArray.enumerated() {
                let itemNum = index + 1
                
                var brazeProperties: [String: Any] = [:]
                
                // Map GA4 item_id → product_id
                if let itemId = item["item_id"] as? String {
                    brazeProperties["product_id"] = itemId
                }
                // Map GA4 item_name → product_name
                if let itemName = item["item_name"] as? String {
                    brazeProperties["product_name"] = itemName
                }
                // Map GA4 item_brand → brand
                if let itemBrand = item["item_brand"] as? String {
                    brazeProperties["brand"] = itemBrand
                }
                // Map GA4 item_category → category
                if let itemCategory = item["item_category"] as? String {
                    brazeProperties["category"] = itemCategory
                }
                // Map GA4 item_variant → variant
                if let itemVariant = item["item_variant"] as? String {
                    brazeProperties["variant"] = itemVariant
                }
                // Map GA4 price → price
                if let price = item["price"] {
                    brazeProperties["price"] = price
                }
                // Map GA4 quantity → quantity
                if let quantity = item["quantity"] {
                    brazeProperties["quantity"] = quantity
                }
                if let currency = parameters["currency"] as? String {
                    brazeProperties["currency"] = currency
                }
                if let value = parameters["value"] {
                    brazeProperties["value"] = value
                }
                // For order_placed/purchase events, add transaction details
                if eventName == "purchase" || eventName == "order_placed" {
                    if let transactionId = parameters["transaction_id"] as? String {
                        brazeProperties["transaction_id"] = transactionId
                    }
                    if let affiliation = parameters["affiliation"] as? String {
                        brazeProperties["affiliation"] = affiliation
                    }
                    if let tax = parameters["tax"] {
                        brazeProperties["tax"] = tax
                    }
                    if let shipping = parameters["shipping"] {
                        brazeProperties["shipping"] = shipping
                    }
                    if let coupon = parameters["coupon"] as? String {
                        brazeProperties["coupon"] = coupon
                    }
                }
                // For refunds, add refund-specific data
                if eventName == "refund" {
                    if let transactionId = parameters["transaction_id"] as? String {
                        brazeProperties["transaction_id"] = transactionId
                    }
                }
                // Build metadata object for additional fields
                var metadata: [String: Any] = [:]
                for (key, value) in item {
                    if !["item_id", "item_name", "price", "quantity", "item_brand", "item_category", "item_variant"].contains(key) {
                        metadata[key] = value
                    }
                }
                if !metadata.isEmpty {
                    brazeProperties["metadata"] = metadata
                }
                print("#    🔷 Item \(itemNum):", item["item_name"] ?? "Unknown")
                print("#    🔷 Braze properties:", brazeProperties)
                
                AppDelegate.braze?.logCustomEvent(name: brazeEventName, properties: brazeProperties)
                AppDelegate.braze?.requestImmediateDataFlush()
                print("#        ⏩ Braze event logged:", brazeEventName)
            }
        } else {
            print("#        ℹ️ No items found, logging event with raw parameters")
            AppDelegate.braze?.logCustomEvent(name: brazeEventName, properties: parameters)
            AppDelegate.braze?.requestImmediateDataFlush()
            print("#        ⏩ Braze event logged:", brazeEventName)
        }
    }
    // MARK: - Log Purchase Event
    func logPurchase(parameters: [String: Any]) {
        print("# 👉🔍 logPurchase called with parameters:", parameters)
        print("# 👉 Print parameters respectively for debugging")
        print("# 🔍 Purchase parameters:")
        for (key, value) in parameters {
            print("#    💰  '\(key)' = '\(value)' (type: \(type(of: value)))")
        }
        
        guard let currency = parameters[PurchaseCurrencyKey] as? String else {
            print("#    ❌❌ logPurchase - Missing currency")
            return
        }
        
        let transactionId = (parameters["transaction_id"] as? String) ?? (parameters[PurchaseProductIdKey] as? String) ?? "UNKNOWN_TRANSACTION"
        print("#    💰  'transaction_id':, \(transactionId) (type: \(type(of: transactionId)))")
        print("#    💰  'currency':, \(currency) (type: \(type(of: currency)))")
        
        var items: [[String: Any]]?
        if let directItems = parameters["items"] as? [[String: Any]] {
            items = directItems
        } else if let props = parameters[PurchasePropertiesKey] as? [String: Any],
                  let propsItems = props["items"] as? [[String: Any]] {
            items = propsItems
        }
        
        guard let itemsArray = items, !itemsArray.isEmpty else {
            print("# ❌ logPurchase - No items found in parameters")
            return
        }
        
        print("# 🔍 Found \(itemsArray.count) items - logging one purchase per item")
        for (index, item) in itemsArray.enumerated() {
            let itemNum = index + 1
            
            let itemId = item["item_id"] as? String ?? "unknown_sku"
            let itemName = item["item_name"] as? String ?? "Unknown Product"
            
            let itemPrice: Double
            if let price = item["price"] as? Double {
                itemPrice = price
            } else if let price = item["price"] as? Int {
                itemPrice = Double(price)
            } else {
                itemPrice = 0.0
            }
            
            let itemQuantity: Int
            if let quantity = item["quantity"] as? Int {
                itemQuantity = quantity
            } else if let quantity = item["quantity"] as? Double {
                itemQuantity = Int(quantity)
            } else {
                itemQuantity = 1
            }
            
            var itemProperties: [String: Any] = [
                "product_id": itemId,
                "price": itemPrice,
                "transaction_id": transactionId
            ]
            
            if let value = parameters["value"] {
                itemProperties["value"] = value
            }
            // Map GA4 item_category → category
            if let itemCategory = item["item_category"] as? String {
                itemProperties["category"] = itemCategory
            }
            // Map GA4 item_brand → brand
            if let itemBrand = item["item_brand"] as? String {
                itemProperties["brand"] = itemBrand
            }
            // Map GA4 item_variant → variant
            if let itemVariant = item["item_variant"] as? String {
                itemProperties["variant"] = itemVariant
            }
            print("#    🛍 Item \(itemNum): \(itemName) (SKU: \(itemId), Price: \(itemPrice), Qty: \(itemQuantity))")
            print("#    🛍 Item \(itemNum) Properties:", itemProperties)
            
            AppDelegate.braze?.logPurchase(
                productId: itemName,
                currency: currency,
                price: itemPrice,
                quantity: itemQuantity,
                properties: itemProperties
            )
            print("#        ⏩ Braze purchase logged - Product Name: \(itemName), SKU: \(itemId)")
        }
        AppDelegate.braze?.requestImmediateDataFlush()
        print("#    🧾 All purchases logged - Total items: \(itemsArray.count), Transaction: \(transactionId) 🧾")
    }
    // MARK: - Log User & Custom Attributes
    func logCustomAttribute(parameters: [String: Any]) {
        let attributeKey = (parameters[CustomAttributeKey] as? String) ?? (parameters[AttributeKey] as? String)
        let attributeValue = parameters[CustomAttributeValueKey] ?? parameters[AttributeValueKey]
        
        guard let customAttributeKey = attributeKey else {
            print("# ❌ logCustomAttribute - Missing attribute key")
            return
        }
        print("#    🔍 Processing attribute: '\(customAttributeKey)' = '\(attributeValue ?? "nil")'")
        
        // Gender Attribute (Braze Enum: Male, Female, Other, Unknown, Not Applicable, Prefer Not to Say)
        if customAttributeKey == "gender" {
            if let genderString = attributeValue as? String {
                let genderLower = genderString.lowercased()
                if genderLower == "male" || genderLower == "m" || genderLower == "pria" || genderLower == "laki-laki" {
                    AppDelegate.braze?.user.set(gender: .male)
                    print("#        ⏩ Braze gender set to: .male")
                } else if genderLower == "female" || genderLower == "f" || genderLower == "perempuan" {
                    AppDelegate.braze?.user.set(gender: .female)
                    print("#        ⏩ Braze gender set to: .female")
                } else if genderLower == "other" || genderLower == "o" {
                    AppDelegate.braze?.user.set(gender: .other)
                    print("#        ⏩ Braze gender set to: .other")
                } else if genderLower == "unknown" || genderLower == "not_applicable" {
                    AppDelegate.braze?.user.set(gender: .unknown)
                    print("#        ⏩ Braze gender set to: .unknown")
                } else if genderLower == "prefer_not_to_say" || genderLower == "prefernottosay" {
                    AppDelegate.braze?.user.set(gender: .preferNotToSay)
                    print("#        ⏩ Braze gender set to: .preferNotToSay")
                } else {
                    print("#        ⚠️ Unknown gender value '\(genderString)', defaulting to .preferNotToSay")
                    AppDelegate.braze?.user.set(gender: .preferNotToSay)
                }
                return
            }
        }
        
        // First Name Attribute (String)
        if customAttributeKey == "firstName" || customAttributeKey == "first_name" {
            if let firstName = attributeValue as? String, !firstName.isEmpty {
                AppDelegate.braze?.user.set(firstName: firstName)
                print("#        ⏩ Braze firstName set to:", firstName)
                return
            } else {
                print("#        ⚠️ firstName is empty or invalid")
                return
            }
        }
        
        // Last Name Attribute (String)
        if customAttributeKey == "lastName" || customAttributeKey == "last_name" {
            if let lastName = attributeValue as? String, !lastName.isEmpty {
                AppDelegate.braze?.user.set(lastName: lastName)
                print("#        ⏩ Braze lastName set to:", lastName)
                return
            } else {
                print("#        ⚠️ lastName is empty or invalid")
                return
            }
        }
        
        // Language Attribute (String - ISO-639-1 standard)
        if customAttributeKey == "language" {
            if let language = attributeValue as? String {
                // Validate ISO-639-1 format (2 lowercase letters)
                let iso639Pattern = "^[a-z]{2}$"
                let iso639Regex = try? NSRegularExpression(pattern: iso639Pattern)
                let languageRange = NSRange(location: 0, length: language.utf16.count)
                let lowercaseLanguage = language.lowercased()
                
                if iso639Regex?.firstMatch(in: lowercaseLanguage, range: languageRange) == nil {
                    print("#        ⚠️ Language should be ISO-639-1 (2-letter code), got:", language)
                    print("#        ℹ️ Examples: en, es, fr, de, ja, id, pt, ru, etc.")
                    print("#        ℹ️ Auto-converting to lowercase:", lowercaseLanguage)
                }
                AppDelegate.braze?.user.set(language: lowercaseLanguage)
                print("#        ⏩ Braze language set to:", lowercaseLanguage)
                return
            }
        }
        
        // Email Attribute (String - valid email format)
        if customAttributeKey == "email" {
            if let email = attributeValue as? String {
                // Basic email validation
                let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
                
                if emailPredicate.evaluate(with: email) {
                    AppDelegate.braze?.user.set(email: email)
                    print("#        ⏩ Braze email set to:", email)
                } else {
                    print("#        ⚠️ Invalid email format:", email)
                }
                return
            }
        }
        
        // Date of Birth Attribute (String in "YYYY-MM-DD" format - ISO 8601)
        if customAttributeKey == "dateOfBirth"
            || customAttributeKey == "date_of_birth"
            || customAttributeKey == "dob" {
            
            if let dobString = attributeValue as? String {
                let dobPattern = "^\\d{4}-\\d{2}-\\d{2}$"
                let dobRegex = try? NSRegularExpression(pattern: dobPattern)
                let dobRange = NSRange(location: 0, length: dobString.utf16.count)
                
                if dobRegex?.firstMatch(in: dobString, range: dobRange) == nil {
                    print("#        ❌ DOB format invalid - must be YYYY-MM-DD (ISO 8601), got:", dobString)
                    print("#        ℹ️ Example: 2012-12-12")
                    return
                }
                
                let f = DateFormatter()
                f.locale = Locale(identifier: "en_US_POSIX")
                f.dateFormat = "yyyy-MM-dd"
                
                if let dob = f.date(from: dobString) {
                    AppDelegate.braze?.user.set(dateOfBirth: dob)
                    print("#        ⏩ Braze dateOfBirth set:", dob, "(from:", dobString, ")")
                } else {
                    print("#        ❌ DOB parse failed:", dobString)
                }
                return
            }
        }
        
        // Country Attribute (String - ISO 3166-1 alpha-2 standard)
        if customAttributeKey == "country" {
            if let country = attributeValue as? String {
                // Validate ISO 3166-1 alpha-2 (2 uppercase letters)
                let countryPattern = "^[A-Z]{2}$"
                let countryRegex = try? NSRegularExpression(pattern: countryPattern)
                let countryRange = NSRange(location: 0, length: country.utf16.count)
                
                let uppercaseCountry = country.uppercased()
                
                if countryRegex?.firstMatch(in: uppercaseCountry, range: countryRange) == nil {
                    print("#        ⚠️ Country should be ISO 3166-1 alpha-2 (2-letter code), got:", country)
                    print("#        ℹ️ Examples: US, GB, ID, AU, JP, FR, DE, etc.")
                    print("#        ℹ️ Auto-converting to uppercase:", uppercaseCountry)
                }
                AppDelegate.braze?.user.set(country: uppercaseCountry)
                print("#        ⏩ Braze country set to:", uppercaseCountry)
                return
            }
        }
        
        // Home City Attribute (String)
        if customAttributeKey == "homeCity" || customAttributeKey == "home_city" || customAttributeKey == "city" {
            if let city = attributeValue as? String, !city.isEmpty {
                AppDelegate.braze?.user.set(homeCity: city)
                print("#        ⏩ Braze homeCity set to:", city)
                return
            } else {
                print("#        ⚠️ homeCity is empty or invalid")
                return
            }
        }
        
        // Phone Number Attribute (String - E.164 format)
        if customAttributeKey == "phoneNumber" || customAttributeKey == "phone_number" || customAttributeKey == "phone" {
            if let phone = attributeValue as? String {
                // Validate E.164 format: +[country code][number]
                let e164Pattern = "^\\+[1-9]\\d{1,14}$"
                let e164Regex = try? NSRegularExpression(pattern: e164Pattern)
                let phoneRange = NSRange(location: 0, length: phone.utf16.count)
                
                if e164Regex?.firstMatch(in: phone, range: phoneRange) == nil {
                    print("#        ⚠️ Phone should be E.164 format (+[country code][number]), got:", phone)
                    print("#        ℹ️ Examples:")
                    print("#        ℹ️   US: +14155552671")
                    print("#        ℹ️   ID: +628123456789")
                    print("#        ℹ️   UK: +442071234567")
                    print("#        ℹ️ Setting anyway, but SMS/WhatsApp may not work correctly")
                }
                AppDelegate.braze?.user.set(phoneNumber: phone)
                print("#        ⏩ Braze phoneNumber set to:", phone)
                return
            }
            
            // Generic Custom Attributes
            if let stringValue = attributeValue as? String {
                AppDelegate.braze?.user.setCustomAttribute(key: customAttributeKey, value: stringValue)
                print("#        ⏩ Braze custom attribute (String):", customAttributeKey, "=", stringValue)
            } else if let intValue = attributeValue as? Int {
                AppDelegate.braze?.user.setCustomAttribute(key: customAttributeKey, value: intValue)
                print("#        ⏩ Braze custom attribute (Int):", customAttributeKey, "=", intValue)
            } else if let doubleValue = attributeValue as? Double {
                AppDelegate.braze?.user.setCustomAttribute(key: customAttributeKey, value: doubleValue)
                print("#        ⏩ Braze custom attribute (Double):", customAttributeKey, "=", doubleValue)
            } else if let boolValue = attributeValue as? Bool {
                AppDelegate.braze?.user.setCustomAttribute(key: customAttributeKey, value: boolValue)
                print("#        ⏩ Braze custom attribute (Bool):", customAttributeKey, "=", boolValue)
            } else if let dateValue = attributeValue as? Date {
                AppDelegate.braze?.user.setCustomAttribute(key: customAttributeKey, value: dateValue)
                print("#        ⏩ Braze custom attribute (Date):", customAttributeKey, "=", dateValue)
            }
        }
    }
    // MARK: - Log Change User
    func changeUser(parameters: [String: Any]) {
        guard let userId = parameters[ChangeUserExternalUserId] as? String,
              !userId.isEmpty,
              userId != "undefined",
              userId != "null" else {
            print("#    ❌ changeUser - Invalid externalUserId:", parameters[ChangeUserExternalUserId] ?? "nil")
            return
        }
        AppDelegate.braze?.changeUser(userId: userId)
        AppDelegate.braze?.requestImmediateDataFlush()
        print("#    ⏩ Braze user changed to:", userId)
    }
    // MARK: - Log Email Subscription State
    func setEmailSubscription(parameters: [String: Any]) {
        guard let stateString = parameters[SubscriptionStateKey] as? String else {
            print("#        ❌ setEmailSubscription - Missing subscriptionState")
            return
        }
        let state = parseSubscriptionState(stateString)
        AppDelegate.braze?.user.set(emailSubscriptionState: state)
        AppDelegate.braze?.requestImmediateDataFlush()
        print("#        ⏩ Braze email subscription state set to:", state)
    }
    // MARK: - Log Push Subscription State
    func setPushSubscription(parameters: [String: Any]) {
        guard let stateString = parameters[SubscriptionStateKey] as? String else {
            print("#        ❌ setPushSubscription - Missing subscriptionState")
            return
        }

        // check whether apps has asked for push permission
        let state = parseSubscriptionState(stateString)
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status: UNAuthorizationStatus = settings.authorizationStatus
            
          /*  switch status {
            case .authorized:
                print("#        🔐 Push permission status: authorized")
            case .denied:
                print("#        🔐 Push permission status: denied")
            case .notDetermined:
                print("#        🔐 Push permission status: notDetermined")
            case .provisional:
                print("#        🔐 Push permission status: provisional")
            case .ephemeral:
                print("#        🔐 Push permission status: ephemeral")
            @unknown default:
                print("#        🔐 Push permission status: unknown")
            } */
            
            guard status == .authorized || status == .provisional else {
                print("#        ❌ Push permission not granted — skipping Braze update")
                return
            }
            print("# ✅ Push permission is valid — Braze update allowed")
            AppDelegate.braze?.user.set(pushNotificationSubscriptionState: state)
            AppDelegate.braze?.requestImmediateDataFlush()
            print("#    ⏩ Braze push subscription state set to:", state)
        }
    }
    // MARK: - Helper: Parse Subscription State
    private func parseSubscriptionState(_ stateString: String) -> Braze.User.SubscriptionState {
        let stateLower = stateString.lowercased()
        
        switch stateLower {
        case "opted_in", "optedin":
            return .optedIn
        case "subscribed", "opted_out", "optedout":
            return .subscribed
        case "unsubscribed":
            return .unsubscribed
        default:
            print("#        ⚠️ Unknown subscription state '\(stateString)', defaulting to .unsubscribed")
            return .unsubscribed
        }
    }
    // MARK: - Add to Subscription Group
    func addToSubscriptionGroup(parameters: [String: Any]) {
        guard let groupId = parameters[SubscriptionGroupIdKey] as? String,
              !groupId.isEmpty else {
            print("#        ❌ addToSubscriptionGroup - Missing or invalid subscriptionGroupId")
            return
        }
        
        AppDelegate.braze?.user.addToSubscriptionGroup(id: groupId)
        AppDelegate.braze?.requestImmediateDataFlush()
        print("#            ⏩ Braze added user to subscription group:", groupId)
    }
    // MARK: - Remove from Subscription Group
    func removeFromSubscriptionGroup(parameters: [String: Any]) {
        guard let groupId = parameters[SubscriptionGroupIdKey] as? String,
              !groupId.isEmpty else {
            print("#        ❌ removeFromSubscriptionGroup - Missing or invalid subscriptionGroupId")
            return
        }
    }
}
