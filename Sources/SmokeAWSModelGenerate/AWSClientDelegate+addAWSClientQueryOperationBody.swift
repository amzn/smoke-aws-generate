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
// AWSClientDelegate+addAWSClientQueryOperationBody.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

internal extension AWSClientDelegate {
    func addAWSClientQueryOperationBody(
            name: String,
            fileBuilder: FileBuilder,
            codeGenerator: ServiceModelCodeGenerator,
            function: AWSClientFunction,
            http: (verb: String, url: String),
            invokeType: InvokeType,
            signAllHeaders: Bool) {
        fileBuilder.incIndent()
        
        let typeName = function.name.getNormalizedTypeName(forModel: codeGenerator.model)
        
        let wrappedTypeDeclaration: String
        if function.inputType != nil {
            wrappedTypeDeclaration = "\(typeName)OperationHTTPRequestInput(encodable: input)"
        } else {
            wrappedTypeDeclaration = "NoHTTPRequestInput(encodable: input)"
        }
        
        let httpClientName = getHttpClientForOperation(name: name,
                                                       httpClientConfiguration: codeGenerator.customizations.httpClientConfiguration)
        
        if function.outputType != nil {
            fileBuilder.appendLine("""
                return executeWithOutput(httpClient: \(httpClientName),
                                         wrappedInput: \(wrappedTypeDeclaration),
                                         action: \(baseName)ModelOperations.\(function.name).rawValue,
                                         reporting: self.invocationsReporting.\(function.name),
                                         errorType: \(baseName)Error.self)
                """)
        } else {
            fileBuilder.appendLine("""
                return executeWithoutOutput(httpClient: \(httpClientName),
                                            wrappedInput: \(wrappedTypeDeclaration),
                                            action: \(baseName)ModelOperations.\(function.name).rawValue,
                                            reporting: self.invocationsReporting.\(function.name),
                                            errorType: \(baseName)Error.self)
                """)
        }
        
        fileBuilder.appendLine("}", preDec: true)
    }
}
