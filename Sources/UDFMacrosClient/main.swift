import Foundation
import UDFMacros

// Compile-time check that the macros work on public and package types.
@AutoEquatable
public struct PublicEquatableStruct {
    let id: Int
}

@AutoEquatable
public enum PublicEquatableEnum {
    case first
    case item(Int)
}

@AutoEquatable
public class PublicEquatableClass {
    let id: Int = 0
}

@AutoEquatable
package struct PackageEquatableStruct {
    let id: Int
}

@AutoHashable
public struct PublicHashableStruct {
    let id: Int
}

@AutoHashable
public enum PublicHashableEnum {
    case first
    case item(Int)
}

@AutoHashable
public class PublicHashableClass {
    let id: Int = 0
}

@AutoHashable
package struct PackageHashableStruct {
    let id: Int
}

public struct PublicScope {}

public extension PublicScope {
    @AutoEquatable
    struct EquatableNested {
        let id: Int
    }

    @AutoHashable
    struct HashableNested {
        let id: Int
    }
}

package struct PackageScope {}

package extension PackageScope {
    @AutoEquatable
    struct EquatableNested {
        let id: Int
    }

    @AutoHashable
    struct HashableNested {
        let id: Int
    }
}

@AutoHashable
enum TestEnum {
    case new(Int, String)
    case last
}

@AutoHashable
struct User {
    private let id: Int
    let name: String
    let location: UserLocation
}

@AutoHashable
@SensitiveData
class UserLocation {
    private let id: Int
    @SensitiveField
    let address: String

    init(id: Int, address: String) {
        self.id = id
        self.address = address
    }
}

@SensitiveData(option: .disabledInDebug)
struct ContactCard {
    @SensitiveField
    let id: Int
    @SensitiveField
    let firstName: String
    @SensitiveField
    let lastName: String
    let createAt: Date
}

@SensitiveData(option: .disabledInDebug)
class HealthInsurance {
    @SensitiveField
    let identifier: String
    @SensitiveField
    let expiredAt: Date

    init(identifier: String, expiredAt: Date) {
        self.identifier = identifier
        self.expiredAt = expiredAt
    }
}
