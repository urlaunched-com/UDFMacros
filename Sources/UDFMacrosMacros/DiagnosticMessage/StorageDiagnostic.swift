//
//  StorageDiagnostic.swift
//  UDFMacros
//
//  Created by Oleksandr Bodnar on 28.07.2026.
//

import SwiftDiagnostics
import SwiftSyntax

public enum StorageDiagnostic: DiagnosticMessage {
    case unsupportedType
    case invalidArgument
    case handWrittenReduce

    public var severity: DiagnosticSeverity {
        switch self {
        case .unsupportedType, .invalidArgument:
            return .error
        case .handWrittenReduce:
            return .warning
        }
    }

    public var message: String {
        switch self {
        case .unsupportedType:
            return "@Storage can only be applied to a 'struct' declaration"
        case .invalidArgument:
            return "@Storage requires 'TypeName.self' as the first argument, optionally followed by 'hasEmpty: Bool'"
        case .handWrittenReduce:
            return "This struct declares 'reduce(_:)' by hand, so @Storage won't generate the standard DidLoadItems/DidLoadItem/DidUpdateItem/DeleteItem handling. Consider moving custom logic into 'reduceCustom(_:)' instead, so the standard cases are generated automatically."
        }
    }

    public var diagnosticID: MessageID {
        switch self {
        case .unsupportedType:
            return MessageID(domain: "StorageMacro", id: "unsupportedType")
        case .invalidArgument:
            return MessageID(domain: "StorageMacro", id: "invalidArgument")
        case .handWrittenReduce:
            return MessageID(domain: "StorageMacro", id: "handWrittenReduce")
        }
    }
}
