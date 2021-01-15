// Copyright 2019-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//
// APIGatewayClientModelErrorsDelegate.swift
// APIGatewayClientModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

struct APIGatewayClientModelErrorsDelegate: ModelErrorsDelegate {
    let optionSetGeneration: ErrorOptionSetGeneration = .noGeneration
    let generateEncodableConformance: Bool = false
    let generateCustomStringConvertibleConformance: Bool = false
    let canExpectValidationError: Bool = false
    
    func errorTypeAdditionalImportsGenerator(fileBuilder: FileBuilder,
                                             errorTypes: [ErrorType]) {
        // nothing to do
    }
    
    func errorTypeAdditionalErrorIdentitiesGenerator(fileBuilder: FileBuilder,
                                                     errorTypes: [ErrorType]) {
        // nothing to do
    }
    
    func errorTypeWillAddAdditionalCases(fileBuilder: FileBuilder,
                                         errorTypes: [ErrorType]) -> Int {
        return 2
    }
    
    func errorTypeAdditionalErrorCasesGenerator(fileBuilder: FileBuilder,
                                                errorTypes: [ErrorType]) {
        fileBuilder.appendLine("""
        case validationError(reason: String)
        case unrecognizedError(String, String?)
        """)
    }
    
    func errorTypeCodingKeysGenerator(fileBuilder: FileBuilder,
                                      errorTypes: [ErrorType]) {
        fileBuilder.appendLine("""
        enum CodingKeys: String, CodingKey {
            case type = "__type"
            case message = "message"
        }
        """)
    }
    
    func errorTypeIdentityGenerator(fileBuilder: FileBuilder,
                                    codingErrorUnknownError: String) -> String {
        fileBuilder.appendLine("""
            let values = try decoder.container(keyedBy: CodingKeys.self)
            var errorReason = try values.decode(String.self, forKey: .type)
            let errorMessage = try values.decodeIfPresent(String.self, forKey: .message)

            if let index = errorReason.firstIndex(of: "#") {
                errorReason = String(errorReason[errorReason.index(index, offsetBy: 1)...])
            }
            """)
        
            return "errorReason"
    }
    
    func errorTypeAdditionalErrorDecodeStatementsGenerator(fileBuilder: FileBuilder,
                                                           errorTypes: [ErrorType]) {
        // nothing to do
    }
    
    func errorTypeAdditionalErrorEncodeStatementsGenerator(fileBuilder: FileBuilder,
                                                           errorTypes: [ErrorType]) {
        // nothing to do
    }
    
    func errorTypeAdditionalDescriptionCases(fileBuilder: FileBuilder,
                                             errorTypes: [ErrorType]) {
        // nothing to do
    }
}
