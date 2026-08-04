//
//  StorageRelationshipsDiagnostic.swift
//  UDFMacros
//
//  Created by Oleksandr Bodnar on 29.07.2026.
//

import SwiftDiagnostics
import SwiftSyntax

public enum StorageRelationshipsDiagnostic: DiagnosticMessage {
    case requiresStorage
    case duplicateName(String)
    case duplicateParentType(String)
    case alreadyDeclared(String)
    case malformedArgument

    public var severity: DiagnosticSeverity {
        .error
    }

    public var message: String {
        switch self {
        case .requiresStorage:
            return "@StorageRelationships requires @Storage(_:) on the same declaration — "
                + "without it, the generated _reduceRelationships(_:) is never called."
        case let .duplicateName(name):
            return "Relationship name '\(name)' is used more than once. Pass an explicit "
                + "`name:` to disambiguate two relationships to the same parent type."
        case let .duplicateParentType(typeName):
            return "'\(typeName)' is already used as a relationship parent type on this "
                + "declaration. Two relationships to the same parent type — regardless of "
                + "whether they're `.hasOne` or `.hasMany` — would generate a duplicate "
                + "`Actions.DidLoadNestedItem<\(typeName).ID, _>` case in _reduceRelationships(_:), "
                + "even if their storage property names differ via `name:`."
        case let .alreadyDeclared(name):
            return "'\(name)' is already declared manually. @StorageRelationships will not "
                + "overwrite it — remove the corresponding relationship from "
                + "@StorageRelationships if this is intentional."
        case .malformedArgument:
            return "Expected `.hasOne(Type.self)` or `.hasMany(Type.self)`, optionally with "
                + "`name:` and/or `label:`."
        }
    }

    public var diagnosticID: MessageID {
        switch self {
        case .requiresStorage:
            return MessageID(domain: "StorageRelationshipsMacro", id: "requiresStorage")
        case .duplicateName:
            return MessageID(domain: "StorageRelationshipsMacro", id: "duplicateName")
        case .duplicateParentType:
            return MessageID(domain: "StorageRelationshipsMacro", id: "duplicateParentType")
        case .alreadyDeclared:
            return MessageID(domain: "StorageRelationshipsMacro", id: "alreadyDeclared")
        case .malformedArgument:
            return MessageID(domain: "StorageRelationshipsMacro", id: "malformedArgument")
        }
    }
}
