import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
import MacroJson
import Foundation

struct StructClassTests {
    protocol UserP {
        var name: String { get }
    }
    typealias User = UserP & Codable & Sendable

    @Jsonable
    struct UserS: User {
        @Json(name: "user_name")
        let name: String
    }

    @Jsonable
    final class UserC: User {
        @Json(name: "user_name")
        let name: String
    }

    @Test(
        arguments: [
            UserC.self as User.Type,
            UserS.self as User.Type
        ]
    ) func codec(type: any User.Type) async throws {
        do {
            let json = Data("""
            {
                "user_name" : "Peter"
            }
            """.utf8)

            let decoder = JSONDecoder()
            let sut = try decoder.decode(type, from: json)

            #expect(sut.name == "Peter")

            let encoder = JSONEncoder()
            let data = try encoder.encode(sut)
            let actual = String(data: data, encoding: .utf8)!

            #expect(actual.contains("\"user_name\":\"Peter\""))
        } catch {
            print("Error: \(error)")
        }
    }
}

struct OptionalTests {
    protocol UserP {
        var name: String { get }
        var gender: String? { get }
    }
    typealias User = UserP & Codable & Sendable

    @Jsonable
    struct UserS: User {
        @Json(name: "user_name")
        let name: String
        @Json(name: "gender")
        let gender: String?
    }

    @Jsonable
    final class UserC: User {
        @Json(name: "user_name")
        let name: String
        @Json(name: "gender")
        let gender: String?
    }

    @Test(
        arguments: [
            UserC.self as User.Type,
            UserS.self as User.Type
        ]
    ) func codec(type: any User.Type) async throws {
        do {
            let json = Data("""
            {
                "user_name" : "Peter"
            }
            """.utf8)

            let decoder = JSONDecoder()
            let sut = try decoder.decode(type, from: json)

            #expect(sut.name == "Peter")
            #expect(sut.gender == nil)

            let encoder = JSONEncoder()
            let data = try encoder.encode(sut)
            let actual = String(data: data, encoding: .utf8)!

            #expect(actual.contains("\"user_name\":\"Peter\""))
            #expect(!actual.contains("gender"))
        } catch {
            print("Error: \(error)")
        }
    }
}

struct CodingKeyTests {
    protocol UserP {
        var name: String { get }
        var gender: String? { get }
    }
    typealias User = UserP & Codable & Sendable

    @Jsonable
    struct UserS: User {
        @Json(name: "user_name")
        let name: String
        let gender: String?
    }

    @Jsonable
    final class UserC: User {
        @Json(name: "user_name")
        let name: String
        let gender: String?
    }

    @Test(
        arguments: [
            UserC.self as User.Type,
            UserS.self as User.Type
        ]
    ) func codec(type: any User.Type) async throws {
        do {
            let json = Data("""
            {
                "user_name" : "Peter",
                "gender" : "male"
            }
            """.utf8)

            let decoder = JSONDecoder()
            let sut = try decoder.decode(type, from: json)

            #expect(sut.name == "Peter")
            #expect(sut.gender == "male")

            let encoder = JSONEncoder()
            let data = try encoder.encode(sut)
            let actual = String(data: data, encoding: .utf8)!

            #expect(actual.contains("\"user_name\":\"Peter\""))
            #expect(actual.contains("\"gender\":\"male\""))
        } catch {
            print("Error: \(error)")
        }
    }
}

struct ArrayTests {
    protocol UserP {
        var name: String { get }
        var tag: [String?]? { get }
    }
    typealias User = UserP & Codable & Sendable

    @Jsonable
    struct UserS: User {
        @Json(name: "user_name")
        let name: String
        @Json(name: "tag")
        let tag: [String?]?
    }

    @Jsonable
    final class UserC: User {
        @Json(name: "user_name")
        let name: String
        @Json(name: "tag")
        let tag: [String?]?
    }

    @Test(
        arguments: [
            UserC.self as User.Type,
            UserS.self as User.Type
        ]
    ) func codec(type: any User.Type) async throws {
        do {
            let json = Data("""
            {
                "user_name" : "Peter",
                "tag" : [
                    "male",
                    "human",
                    null,
                    "admin"
                ]
            }
            """.utf8)

            let decoder = JSONDecoder()
            let sut = try decoder.decode(type, from: json)

            #expect(sut.name == "Peter")
            #expect(sut.tag!.count == 4)
            #expect(sut.tag!.contains("male"))
            #expect(sut.tag!.contains("human"))
            #expect(sut.tag!.contains(nil))
            #expect(sut.tag!.contains("admin"))

            let encoder = JSONEncoder()
            let data = try encoder.encode(sut)
            let actual = String(data: data, encoding: .utf8)!

            #expect(actual.contains("\"user_name\":\"Peter\""))
            #expect(actual.contains("\"tag\":[\"male\",\"human\",null,\"admin\"]"))
        } catch {
            print("Error: \(error)")
        }
    }
}

struct NestedStructClassTests {
    protocol UserP {
        var name: String { get }
    }
    protocol GroupP {
        associatedtype UserType: User
        var name: String { get }
        var users: [UserType?]? { get }
    }

    typealias User = UserP & Codable & Sendable
    typealias Group = GroupP & Codable & Sendable

    @Jsonable
    struct UserS: User {
        @Json(name: "user_name")
        let name: String
        @Json(name: "tag")
        let tag: [String?]?
    }

    @Jsonable
    final class UserC: User {
        @Json(name: "user_name")
        let name: String
        @Json(name: "tag")
        let tag: [String?]?
    }

    @Jsonable
    struct GroupCIS: Group {
        @Json(name: "group_name")
        let name: String
        @Json(name: "users")
        let users: [UserC?]?
    }

    @Jsonable
    struct GroupSIS: Group {
        @Json(name: "group_name")
        let name: String
        @Json(name: "users")
        let users: [UserS?]?
    }

    @Jsonable
    final class GroupCIC: Group {
        @Json(name: "group_name")
        let name: String
        @Json(name: "users")
        let users: [UserC?]?
    }

    @Jsonable
    final class GroupSIC: Group {
        @Json(name: "group_name")
        let name: String
        @Json(name: "users")
        let users: [UserS?]?
    }

    @Test(
        arguments: [
            GroupSIS.self as Group.Type,
            GroupSIC.self as Group.Type,
            GroupCIS.self as Group.Type,
            GroupCIC.self as Group.Type
        ]
    ) func codec(type: any Group.Type) {
        do {
            let json = Data("""
            {
                "group_name": "Code Deco",
                "users": [
                    { "user_name" : "Peter" },
                    null,
                    { "user_name" : "Susan" }
                ]
            }
            """.utf8)

            let decoder = JSONDecoder()
            let sut = try decoder.decode(type, from: json)

            #expect(sut.name == "Code Deco")
            #expect(sut.users!.count == 3)
            #expect(sut.users![0]!.name == "Peter")
            #expect(sut.users![1] == nil)
            #expect(sut.users![2]!.name == "Susan")

            let encoder = JSONEncoder()
            let data = try encoder.encode(sut)
            let actual = String(data: data, encoding: .utf8)!

            #expect(actual.contains("\"group_name\":\"Code Deco\""))
            #expect(actual.contains("\"users\":[{\"user_name\":\"Peter\"},null,{\"user_name\":\"Susan\"}]"))
        } catch {
            print("Error: \(error)")
        }
    }
}
