//
//  SensitiveActionDiagnostic.swift
//  UDFMacros
//
//  Created by Bogdan Petkanych on 16.04.2026.

import SwiftDiagnostics
import SwiftSyntax

public enum SensitiveActionDiagnostic: DiagnosticMessage {
    case onlyStructsSupported
    case mustConformToAction

    public var severity: DiagnosticSeverity { .error }
    
    public var message: String {
        switch self {
        case .onlyStructsSupported:
            return "@SensitiveAction can only be applied to a struct."
        case .mustConformToAction:
            return "The type must conform to 'Action' to use this macro."
        }
    }
    
    public var diagnosticID: MessageID {
        MessageID(domain: "SensitiveActionMacro", id: "invalidType")
    }
}
