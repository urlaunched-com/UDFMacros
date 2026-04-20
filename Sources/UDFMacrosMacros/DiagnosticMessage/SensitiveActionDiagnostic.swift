//
//  SensitiveActionDiagnostic.swift
//  UDFMacros
//
//  Created by Bogdan Petkanych on 16.04.2026.

import SwiftDiagnostics
import SwiftSyntax

public enum SensitiveActionDiagnostic: DiagnosticMessage {
    case unsupportedType

    public var severity: DiagnosticSeverity {
        .error
    }

    public var message: String {
        switch self {
        case .unsupportedType:
            return "This macro can only be applied to 'struct', 'class' declarations"
        }
    }

    public var diagnosticID: MessageID {
        MessageID(domain: "SensitiveActionMacro", id: "invalidType")
    }
}
