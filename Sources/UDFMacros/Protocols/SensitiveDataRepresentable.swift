//
//  SensitiveDataRepresentable.swift
//  UDFMacros
//
//  Created by Bogdan Petkanych on 16.04.2026.
//

public protocol SensitiveDataRepresentable {
    var maskedDescription: String { get }
    var plainDescription: String { get }
}
