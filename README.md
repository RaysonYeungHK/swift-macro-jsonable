# Swift Macro - Json

A macro annotation to speed up implementation of Codable (Encodable / Decodable) struct / class

### Overview

Swift Codable (Encodable + Decodable), provides codec process of json data and application model.

However, implementation of data model is not concise enough and difficult to be maintained.

Here is an example

```swift
struct User : Codeable {
    let id: Int?
    let name: String?
    let weight: String?
    let email: String?

    init (id: Int?,
        name: String?,
        weight: String?,
        email: String?
    ) {
        self.id = id
        self.name = name
        self.weight = weight
        self.email = email
    }

    // If json response naming is not good enough, we need to implement coding keys
    private enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name = "user_name"
        case weight = "weight_in_kg"
        case email = "email"
    }

    // Extra init function to conform Decodable with coding keys
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int64.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.weight = try container.decodeIfPresent(Float64.self, forKey: .weight)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
    }

    // Extra encode function to conform Encodable with coding keys
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.id, forKey: .id)
        try container.encodeIfPresent(self.name, forKey: .name)
        try container.encodeIfPresent(self.weight, forKey: .weight)
        try container.encodeIfPresent(self.email, forKey: .email)
    }
}
```

In case if there is additional field `gender` need to be added to the data model, there will be **at most** 6 changes need

1. add `let gender: String?` property

2. add `gender: String?` to `init()` parameter

3. add `self.gender = gender` to `init()` implementation

4. add `case gender = "gender"` to CodingKeys enum

5. add `self.gender = try container.decodeIfPresent(String.self, forKey: .gender)` to `init(from decoder: Decoder)`

6. add `try container.encodeIfPresent(self.gender, forKey: .gender)` to `func encode(to encoder: Encoder)`



### Idea / Solution

Inspired by other libraries, such as moshi, using macro / annotation to simply model's implementation.

Here is an example

```swift
@Jsonable
struct User : Codeable {
    @Json(name: "user_id")
    let id: Int?
    @Json(name: "user_name")
    let name: String?
    @Json(name: "weight_in_kg")
    let weight: String?
    @Json(name: "email")
    let email: String?
}
```

Remaining implementation, such as default `init()`, `enum CodingKeys`, `init(from. decoder: Decoder)`, `func encode(to encoder: Encoder)` will be generated automatically.



### How to use

1. You can either clone this repository to yours or import via SPM.

2. For SPM, please checkout [Swift packages | Apple Developer Documentation](https://developer.apple.com/documentation/xcode/swift-packages)

For you code implementation, you just need to import this package and use it

Example:

```swift
import MacroJson
...

@Jsonable
struct Person : Codable {
    @Json(name: "first_name")
    let firstName: String?
    @Json(name: "last_name")
    let lastName: String?
}
```

### Supported Cases

#### Class and struct support

```swift
import MacroJson
...

@Jsonable
struct Person : Codable {
    @Json(name: "first_name")
    let firstName: String?
    @Json(name: "last_name")
    let lastName: String?
}

@Jsonable
class Person : Codable {
    @Json(name: "first_name")
    let firstName: String?
    @Json(name: "last_name")
    let lastName: String?
}
```

#### With / without coding keys

```swift
@Jsonable
struct Person : Codable {
    // With coding keys
    @Json(name: "user_id")
    let userId: String
    // Without specified coding key, means json field name is same as property name
    let email: String?
}
```

#### Optional and non-optional property

```swift
@Jsonable
struct Person : Codable {
    // Mandatory property
    @Json(name: "user_id")
    let userId: String
    // Optional property
    @Json(name: "email")
    let email: String?
}
```

#### Nested class and struct

```swift
import MacroJson
...

// Mixing struct and class also works
@Jsonable
struct Person : Codable {
    @Json(name: "first_name")
    let firstName: String?
    @Json(name: "last_name")
    let lastName: String?
}

// Mixing struct and class also works
@Jsonable
struct Group : Codable {
    @Json(name: "grp_leader")
    let leader: Person?
    @Json(name: "members")
    let members: [Person?]?
}
```

### References

[GitHub - square/moshi: A modern JSON library for Kotlin and Java.](https://github.com/square/moshi/)

[Encoding and Decoding Custom Types | Apple Developer Documentation](https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types)

[Swift packages | Apple Developer Documentation](https://developer.apple.com/documentation/xcode/swift-packages)
