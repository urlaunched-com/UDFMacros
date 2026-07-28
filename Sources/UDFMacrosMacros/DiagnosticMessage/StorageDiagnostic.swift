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

    public var severity: DiagnosticSeverity {
        .error
    }

    public var message: String {
        switch self {
        case .unsupportedType:
            return "@Storage can only be applied to a 'struct' declaration"
        case .invalidArgument:
            return "@Storage requires a single argument in the form 'TypeName.self'"
        }
    }

    public var diagnosticID: MessageID {
        switch self {
        case .unsupportedType:
            return MessageID(domain: "StorageMacro", id: "unsupportedType")
        case .invalidArgument:
            return MessageID(domain: "StorageMacro", id: "invalidArgument")
        }
    }
}
