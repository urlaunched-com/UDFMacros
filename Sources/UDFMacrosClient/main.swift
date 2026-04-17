import Foundation
import UDFMacros

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
