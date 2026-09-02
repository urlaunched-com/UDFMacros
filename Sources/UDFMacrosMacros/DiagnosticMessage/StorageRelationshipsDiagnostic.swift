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
    case alreadyDeclared(String)
    case malformedArgument
    case hasManyNotYetSupported

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
        case let .alreadyDeclared(name):
            return "'\(name)' is already declared manually. @StorageRelationships will not "
                + "overwrite it — remove the corresponding relationship from "
                + "@StorageRelationships if this is intentional."
        case .malformedArgument:
            return "Expected `.hasOne(Type.self)`, optionally with `name:` and/or `label:`."
        case .hasManyNotYetSupported:
            return "@StorageRelationships does not generate .hasMany relationships yet — "
                + "write this one by hand for now (deliberately deferred, not guessed at)."
        }
    }

    public var diagnosticID: MessageID {
        switch self {
        case .requiresStorage:
            return MessageID(domain: "StorageRelationshipsMacro", id: "requiresStorage")
        case .duplicateName:
            return MessageID(domain: "StorageRelationshipsMacro", id: "duplicateName")
        case .alreadyDeclared:
            return MessageID(domain: "StorageRelationshipsMacro", id: "alreadyDeclared")
        case .malformedArgument:
            return MessageID(domain: "StorageRelationshipsMacro", id: "malformedArgument")
        case .hasManyNotYetSupported:
            return MessageID(domain: "StorageRelationshipsMacro", id: "hasManyNotYetSupported")
        }
    }
}
