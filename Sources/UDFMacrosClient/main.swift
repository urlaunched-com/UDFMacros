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
class UserLocation {
    private let id: Int
    let address: String
    
    init(id: Int, address: String) {
        self.id = id
        self.address = address
    }
}
