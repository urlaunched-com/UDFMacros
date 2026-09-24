import Testing
import UDF
import UDFMacros

private struct Item: StorageItem {
    let id: Int

    static let empty = Self(id: -1)
}

private struct ParentItem: StorageItem {
    let id: Int

    static let empty = Self(id: -1)
}

private struct GroupItem: StorageItem {
    let id: Int

    static let empty = Self(id: -1)
}

@Storage(Item.self)
@StorageRelationships(
    .hasOne(ParentItem.self),
    .hasMany(GroupItem.self)
)
private struct AllItems {}

/// Compilation of this fixture validates the public macro declarations and
/// their generated code against the real UDF APIs. Reducer behavior is covered
/// by UDF itself and intentionally not duplicated here.
@Test
func storageMacrosCompileAgainstUDF() {
    _ = AllItems()
}
