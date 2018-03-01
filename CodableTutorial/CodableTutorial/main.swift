import Foundation

let jsonData = """
{
    "userInfo": {
        "id": "109",
        "name": "Jerry Wang",
        "email": "jeerywa@gmail.com",
        "imageURLs": [
            "http://url1",
            "http://url2",
            "http://url3"
        ],
        "bodyShape": {
            "weight": "100",
            "height": "1000"
        },
        "friends": [
            {
                "id": "2",
                "name": "John",
                "bodyShape": {
                    "weight": "100",
                    "height": "1000"
                }
            },
            {
                "id": "3",
                "name": "Merry",
                "email": "Merry1234@gmail.com"
            }
        ]
    }
}
""".data(using: .utf8)!

let decoder = JSONDecoder()
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

// MARK: - 基本格式
struct User: Codable {
    
    let userInfo : UserInfo
    
    struct UserInfo: Codable {
        let id : String
        let name : String
        let email : String
        let imageURLs : [String]
        let bodyShape: BodyShape
        let friends : [Friend]
    }
    
    struct Friend: Codable {
        let id: String
        let name: String
        let email: String?
        let bodyShape: BodyShape?
    }
    
    struct BodyShape: Codable {
        let weight: String
        let height: String
    }
}

let user = try decoder.decode(User.self, from: jsonData)
print(user.userInfo.email)
let encodedUserData = try? encoder.encode(user)
let userDict = try? JSONSerialization.jsonObject(with: encodedUserData!, options: .mutableContainers) as! NSDictionary
print(userDict)

// MARK: - data model property structure與getJSON架構不同
struct FormedUser {
    
    let id: String
    let name: String
    let imageURLs: [String]
    let weight: String
    let height: String
    let friends: [Friend]?
    
    struct BodyShape: Codable {
        let weight: String
        let height: String
    }
    
    struct Friend: Codable {
        let id: String
        let name: String
        let email: String?
        let bodyShape: BodyShape?
    }
    
    enum RootKeys: String, CodingKey {
        case userInfo
    }
    
    enum UserKeys: String, CodingKey {
        case id, name, email, imageURLs, bodyShape, friends
    }
    
    enum BodyShapeKeys: String, CodingKey {
        case weight, height
    }
    
    enum FriendsKey: String, CodingKey {
        case id, name, email, bodyShape
    }
    
    enum EncodedKeys: String, CodingKey {
        case id, name, imageURLs, weight, height, friends
    }
}

extension FormedUser: Decodable {
    init(from decoder: Decoder) throws {
        //id, name
        let container = try decoder.container(keyedBy: RootKeys.self)
        print(container.allKeys) //key為userInfo
        let userInfoContainer = try container.nestedContainer(keyedBy: UserKeys.self, forKey: .userInfo)
        print(userInfoContainer.allKeys) //key為imageURLs, name, friends, email, id, bodyShape
        id = try userInfoContainer.decode(String.self, forKey: .id)
        name = try userInfoContainer.decode(String.self, forKey: .name)
        
        //imageURLs
        var imageURLsUnKeyContainer = try userInfoContainer.nestedUnkeyedContainer(forKey: .imageURLs)
        var imageURLsArray = [String]()
        while !imageURLsUnKeyContainer.isAtEnd {
            //可以對array內的每個element做客製化的改變
            imageURLsArray.append(try imageURLsUnKeyContainer.decode(String.self))
        }
        imageURLs = imageURLsArray
        
        //width,height
        let bodyShapeContainer = try userInfoContainer.nestedContainer(keyedBy: BodyShapeKeys.self, forKey: .bodyShape)
        weight = try bodyShapeContainer.decode(String.self, forKey: .weight)
        height = try bodyShapeContainer.decode(String.self, forKey: .height)
        //friends
        friends = try userInfoContainer.decodeIfPresent([Friend].self, forKey: .friends)
        //若要進一步修改Friend內的資料，或只取出Friend內的部分變數，可以用nestedUnkeyedContainer
        /*
         var friendsUnkeyContainer = try userInfoContainer.nestedUnkeyedContainer(forKey: .friends)
         var friendsArray = [Friend]()
         while !friendsUnkeyContainer.isAtEnd {
         //可以對array內的每個element做客製化的改變
         friendsArray.append(try friendsUnkeyContainer.decode(Friend.self))
         }
         friends = friendsArray
         */
    }
}

extension FormedUser: Encodable {
    func encode(to encoder: Encoder) throws {
        //id, name
        var container = try encoder.container(keyedBy: EncodedKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        //imageURLs
        try container.encode(imageURLs, forKey: .imageURLs)
        
        //weight, height
        try container.encode(weight, forKey: .weight)
        try container.encode(height, forKey: .height)
        
        //friends
        try container.encodeIfPresent(friends, forKey: .friends)
        //若要進一步產生客製化的json格式，可以用nestedUnkeyedContainer
        /*
        var firendsUnkeyContainer = try container.nestedUnkeyedContainer(forKey: .friends)
        try friends?.forEach({ (friend) in
            var friendsContainer = firendsUnkeyContainer.nestedContainer(keyedBy: FriendsKey.self)
            try friendsContainer.encode(friend.id, forKey: .id)
            try friendsContainer.encode(friend.name, forKey: .name)
            try friendsContainer.encodeIfPresent(friend.email, forKey: .email)
            try friendsContainer.encodeIfPresent(friend.bodyShape, forKey: .bodyShape)
        })
        */
    }
}

let formedUser = try decoder.decode(FormedUser.self, from: jsonData)
print(formedUser.friends)
let encodedFormedUserData = try? encoder.encode(formedUser)
let formedUserDict = try? JSONSerialization.jsonObject(with: encodedFormedUserData!, options: .mutableContainers) as! NSDictionary
print(formedUserDict)


// MARK: - key非固定
let jsonData2 = """
{
    "Banana": {
        "points": 200,
        "description": "A banana grown in Ecuador."
    },
    "Orange": {
        "points": 100
    }
}
""".data(using: .utf8)!

struct GroceryStore {
    
    var products: [Product]
    
    struct Product {
        let name: String
        let points: Int
        let description: String?
    }
    
    struct ProductKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }
        
        static let points = ProductKey(stringValue: "points")!
        static let description = ProductKey(stringValue: "description")!
    }
}

extension GroceryStore: Decodable {
    
    public init(from decoder: Decoder) throws {
        products = [Product]()
        let container = try decoder.container(keyedBy: ProductKey.self)
        for key in container.allKeys {
            print(key)
            let productContainer = try container.nestedContainer(keyedBy: ProductKey.self, forKey: key)
            let points = try productContainer.decode(Int.self, forKey: .points)
            let description = try productContainer.decodeIfPresent(String.self, forKey: .description)
            
            let product = Product(name: key.stringValue, points: points, description: description)
            products.append(product)
        }
    }
}

extension GroceryStore: Encodable {
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ProductKey.self)
        
        for product in products {
            let nameKey = ProductKey(stringValue: product.name)!
            var productContainer = container.nestedContainer(keyedBy: ProductKey.self, forKey: nameKey)
            try productContainer.encode(product.points, forKey: .points)
            try productContainer.encodeIfPresent(product.description, forKey: .description)
        }
    }
}

let store = try decoder.decode(GroceryStore.self, from: jsonData2)
print(store.products)
let encodedStoreData = try? encoder.encode(store)
let storeDict = try? JSONSerialization.jsonObject(with: encodedStoreData!, options: .mutableContainers) as! NSDictionary
print(storeDict)


