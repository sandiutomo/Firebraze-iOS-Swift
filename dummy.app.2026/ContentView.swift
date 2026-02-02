import SwiftUI
import FirebaseCore
import Firebase
import FirebaseAnalytics
import GoogleTagManager
import BrazeKit

struct ContentView: View {
    var body: some View {
        VStack {
            // MARK: -
            Button(action: {
                Analytics.setUserID(userIdValue)
                
                Analytics.logEvent(AnalyticsEventLogin,
                                   parameters: [ "method": "Email"
                                               ])
                print("~ logged event: Login!")
            }) {
                Text("Login")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }.frame(width: 200, height: 60, alignment: .center)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(15)
                .shadow(radius: 4)
            // MARK: -
            Button(action: {
                Analytics.logEvent("test_custom_event", parameters: [
                    // String
                    "custom1_param1": "custom param 1 value test",
                    "custom1_param2": "custom param 2 value test",
                    
                    // Int
                    "param_int": 42,
                    
                    // Double
                    "param_double": 3.14159,
                    
                    // Bool
                    "param_bool": true,
                    
                    // Array
                    "param_test_array": ["test", "array", "string", "value"],
                    
                    // Timestamp (Int)
                    "timestamp": timestampMs
                ])
                print("~ logged event: Custom Event!")
            }) {
                Text("Custom Event 1")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }.frame(width: 200, height: 60, alignment: .center)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(15)
                .shadow(radius: 4)
            // MARK: -
            Button(action: {
                Analytics.setUserProperty(deviceId, forName: "gtm_test_device_id")
                Analytics.setUserProperty(osNameValue, forName: "gtm_test_os_name")
                Analytics.setUserProperty(osVersionValue, forName: "gtm_test_os_version")
                
                Analytics.logEvent("test_custom_event_attr", parameters: nil)
                print("~ logged event: Custom Event + Attr!")
            }) {
                Text("Custom Event + Attr")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }.frame(width: 200, height: 60, alignment: .center)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(15)
                .shadow(radius: 4)
            // MARK: -
            Button(action: {
                AppDelegate.braze?.logCustomEvent(name: "braze_hardcode_event")
                print("~ logged event: Braze Hardcode!")
            }) {
                Text("Braze Hardcode Event")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }.frame(width: 200, height: 60, alignment: .center)
                .foregroundColor(.white)
                .background(Color.purple)
                .cornerRadius(15)
                .shadow(radius: 4)
            // MARK: -
            Button(action: {
                let items = threeItemsHardcode
                let totalValue = calculateTotalValue(items: items)
                
                // Log ONE purchase per product
                for (index, item) in items.enumerated() {
                    let itemNum = index + 1
                    
                    var purchaseProperties: [String: Any] = [
                        "transaction_id": transactionIdValue,
                        "item_id": item["item_id"] ?? "unknown",
                        "item_price": (item["price"] as? Int).map(Double.init) ?? 0.0,
                        "value": totalValue
                    ]
                    
                    // Add optional item attributes to properties
                    if let category = item["item_category"] as? String {
                        purchaseProperties["item_category"] = category
                    }
                    if let brand = item["item_brand"] as? String {
                        purchaseProperties["item_brand"] = brand
                    }
                    if let variant = item["item_variant"] as? String {
                        purchaseProperties["item_variant"] = variant
                    }
                    
                    let itemName = item["item_name"] as? String ?? "Unknown Product"
                    let itemId = item["item_id"] as? String ?? "unknown"
                    let itemPrice = (item["price"] as? Int).map(Double.init) ?? 0.0
                    let itemQuantity = item["quantity"] as? Int ?? 1
                    
                    print("~        🔷 Item \(itemNum): \(itemName) (SKU: \(itemId), Price: \(itemPrice), Qty: \(itemQuantity))")
                    print("~        🔷 Item \(itemNum) Properties:", purchaseProperties)
                    
                    AppDelegate.braze?.logPurchase(
                        productId: itemName,
                        currency: "IDR",
                        price: itemPrice,
                        quantity: itemQuantity,
                        properties: purchaseProperties
                    )
                    print("~            ⏩ Braze purchase logged - Product Name: \(itemName), SKU: \(itemId)")
                }
                AppDelegate.braze?.requestImmediateDataFlush()
                print("~        ⏩ Braze Purchase hardcode logged with \(items.count) items!")
            }) {
                Text("Braze Hardcode Purchase")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }.frame(width: 200, height: 60, alignment: .center)
                .foregroundColor(.white)
                .background(Color.purple)
                .cornerRadius(15)
                .shadow(radius: 4)
            // MARK: -
            Button(action: {
                Analytics.logEvent(AnalyticsEventViewItem, parameters: [
                    AnalyticsParameterCurrency: "IDR",
                    AnalyticsParameterValue: 50000,
                    AnalyticsParameterItems: singleItemGA4
                ])
                print("~ logged event: Product Viewed!")
            }) {
                Text("Product Viewed")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }.frame(width: 200, height: 60, alignment: .center)
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(15)
                .shadow(radius: 4)
            // MARK: -
            Button(action: {
                // Modify quantity to 2 for this event
                var items = singleItemGA4
                items[0][AnalyticsParameterQuantity] = 2
                
                Analytics.logEvent(AnalyticsEventAddToCart, parameters: [
                    AnalyticsParameterCurrency: "IDR",
                    AnalyticsParameterValue: 100000, // 50000 * 2
                    AnalyticsParameterItems: items
                ])
                print("~ logged event: Add Cart!")
            }) {
                Text("Add Cart")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }.frame(width: 200, height: 60, alignment: .center)
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(15)
                .shadow(radius: 4)
            // MARK: -
            Button(action: {
                Analytics.logEvent(AnalyticsEventBeginCheckout, parameters: [
                    AnalyticsParameterCurrency: "IDR",
                    AnalyticsParameterValue: 100000, // 50000 + 50000
                    AnalyticsParameterItems: singleItemGA4
                ])
                print("~ logged event: Checkout Started!")
            }) {
                Text("Checkout")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }.frame(width: 200, height: 60, alignment: .center)
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(15)
                .shadow(radius: 4)
            // MARK: -
            Button(action: {
                let purchaseParams: [String: Any] = [
                    AnalyticsParameterTransactionID: transactionIdValue,
                    AnalyticsParameterAffiliation: "test affiliation",
                    AnalyticsParameterCurrency: "IDR",
                    AnalyticsParameterValue: 200000,
                    AnalyticsParameterTax: 0,
                    AnalyticsParameterShipping: 0,
                    AnalyticsParameterCoupon: "test coupon",
                    AnalyticsParameterItems: threeItemsGA4
                ]
                
                Analytics.logEvent(AnalyticsEventPurchase, parameters: purchaseParams)
                print("~ logged event: Purchase!")
            }) {
                Text("Purchase")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }.frame(width: 200, height: 60, alignment: .center)
                .foregroundColor(.white)
                .background(Color.green)
                .cornerRadius(15)
                .shadow(radius: 4)
            // MARK: -
            Button(action: {
                Analytics.logEvent("subscription_status", parameters: [
                    "email_subscription": "opted_in", // use interchangeably opted_in, opted_out, subscribed, unsubscribed
                    "push_subscription": "opted_out", // use interchangeably opted_in, opted_out, subscribed, unsubscribed
                    "whatsapp_subscription": "36bba8fd-c772-4ca2-8a83-81bbc411501d" // use interchangeably 36bba8fd-c772-4ca2-8a83-81bbc411501d, ba5e1b75-1fc4-4ea4-bfff-5e9edf32c1d2
                ])
                print("~ logged event: Subscription Status!")
            }) {
                Text("Subscribe Push & Email")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }.frame(width: 200, height: 60, alignment: .center)
                .foregroundColor(.white)
                .background(Color.red)
                .cornerRadius(15)
                .shadow(radius: 4)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

// MARK: -
var timestampMs = Int(Date().timeIntervalSince1970 * 1000)
var osVersionValue = UIDevice.current.systemVersion
var osNameValue = UIDevice.current.systemName
var deviceId = UIDevice.current.identifierForVendor?.uuidString
var userIdValue = "testuserid1"
// MARK: - Ecommerce Variables
var transactionIdValue = "T\(Int(Date().timeIntervalSince1970) / 100)\(["A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","W","X","Y","Z"].randomElement()!)"
// Single item
var singleItemGA4: [[String: Any]] {
    [
        [
            AnalyticsParameterItemID: "sku_001G",
            AnalyticsParameterItemName: "Product A GTM",
            AnalyticsParameterItemCategory: "Category A GTM",
            AnalyticsParameterItemBrand: "Brand A GTM",
            AnalyticsParameterItemVariant: "Red",
            AnalyticsParameterPrice: 50000,
            AnalyticsParameterQuantity: 1
        ]
    ]
}
// Two items
var twoItemsGA4: [[String: Any]] {
    [
        [
            AnalyticsParameterItemID: "sku_001G",
            AnalyticsParameterItemName: "Product A GTM",
            AnalyticsParameterItemCategory: "Category A GTM",
            AnalyticsParameterItemBrand: "Brand A GTM",
            AnalyticsParameterItemVariant: "Red",
            AnalyticsParameterPrice: 50000,
            AnalyticsParameterQuantity: 1
        ],
        [
            AnalyticsParameterItemID: "sku_002G",
            AnalyticsParameterItemName: "Product B GTM",
            AnalyticsParameterItemCategory: "Category B GTM",
            AnalyticsParameterItemBrand: "Brand B GTM",
            AnalyticsParameterItemVariant: "Blue",
            AnalyticsParameterPrice: 50000,
            AnalyticsParameterQuantity: 1
        ]
    ]
}
// Three items for Purchase
var threeItemsGA4: [[String: Any]] {
    [
        [
            AnalyticsParameterItemID: "sku_001G",
            AnalyticsParameterItemName: "Product A GTM",
            AnalyticsParameterItemCategory: "Category A GTM",
            AnalyticsParameterItemBrand: "Brand A GTM",
            AnalyticsParameterItemVariant: "Red",
            AnalyticsParameterPrice: 50000,
            AnalyticsParameterQuantity: 1
        ],
        [
            AnalyticsParameterItemID: "sku_002G",
            AnalyticsParameterItemName: "Product B GTM",
            AnalyticsParameterItemCategory: "Category B GTM",
            AnalyticsParameterItemBrand: "Brand B GTM",
            AnalyticsParameterItemVariant: "Large",
            AnalyticsParameterPrice: 50000,
            AnalyticsParameterQuantity: 1
        ],
        [
            AnalyticsParameterItemID: "sku_003G",
            AnalyticsParameterItemName: "Product C GTM",
            AnalyticsParameterItemCategory: "Category C GTM",
            AnalyticsParameterItemBrand: "Brand C GTM",
            AnalyticsParameterItemVariant: "Small",
            AnalyticsParameterPrice: 100000,
            AnalyticsParameterQuantity: 1
        ]
    ]
}
// Three items
var threeItemsHardcode: [[String: Any]] {
    [
        [
            "item_id": "sku_001H",
            "item_name": "Product A Hardcode",
            "item_category": "Category A Hardcode",
            "item_brand": "Brand A Hardcode",
            "item_variant": "Red",
            "price": 50000,
            "quantity": 1
        ],
        [
            "item_id": "sku_002H",
            "item_name": "Product B Hardcode",
            "item_category": "Category B Hardcode",
            "item_brand": "Brand B Hardcode",
            "item_variant": "Blue",
            "price": 50000,
            "quantity": 1
        ],
        [
            "item_id": "sku_003H",
            "item_name": "Product C Hardcode",
            "item_category": "Category C Hardcode",
            "item_brand": "Brand C Hardcode",
            "item_variant": "Large",
            "price": 100000,
            "quantity": 1
        ]
    ]
}
// MARK: - Helper Functions
func calculateTotalValue(items: [[String: Any]]) -> Double {
    items.reduce(0.0) { sum, item in
        let price = (item["price"] as? Int).map(Double.init) ?? 0.0
        let quantity = (item["quantity"] as? Int).map(Double.init) ?? 1.0
        return sum + (price * quantity)
    }
}
