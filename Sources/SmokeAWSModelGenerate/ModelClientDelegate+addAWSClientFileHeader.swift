// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
// ModelClientDelegate+addAWSClientFileHeader.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import ServiceModelGenerate
import CoralToJSONServiceModel

private typealias SpecificErrorBehaviour = (retriableErrors: [String], unretriableErrors: [String], defaultBehaviorErrorsCount: Int)

extension ModelClientDelegate {
    func addAWSClientFileHeader(codeGenerator: ServiceModelCodeGenerator,
                                fileBuilder: FileBuilder, baseName: String,
                                isGenerator: Bool, defaultInvocationTraceContext: InvocationTraceContextDeclaration) {
        fileBuilder.appendLine("""
            import SmokeAWSHttp
            import NIO
            import NIOHTTP1
            import AsyncHTTPClient
            import Logging
            """)
        
        let specificErrorBehaviour = getSpecificErrors(codeGenerator: codeGenerator, baseName: baseName)
        
        if isGenerator {
            if let importPackage = defaultInvocationTraceContext.importPackage {
                fileBuilder.appendLine("""
                    import \(importPackage)
                    """)
            }
        } else {
            fileBuilder.appendLine("""
                
                public enum \(baseName)ClientError: Swift.Error {
                    case invalidEndpoint(String)
                    case unsupportedPayload
                    case unknownError(String?)
                }
                """)
        
            addTypedErrorRetriableExtension(codeGenerator: codeGenerator, fileBuilder: fileBuilder,
                                            baseName: baseName, specificErrorBehaviour: specificErrorBehaviour)
        }
        
        if !(specificErrorBehaviour.retriableErrors.isEmpty && specificErrorBehaviour.unretriableErrors.isEmpty) {
            addErrorRetriableExtension(codeGenerator: codeGenerator, fileBuilder: fileBuilder, baseName: baseName)
        }
    }
    
    private func addRetriableSwitchStatement(fileBuilder: FileBuilder, retriableErrors: [String],
                                             unretriableErrors: [String], defaultBehaviorErrorsCount: Int,
                                             httpClientConfiguration: HttpClientConfiguration) {
        fileBuilder.incIndent()
        fileBuilder.incIndent()
        fileBuilder.appendLine("""
                switch self {
                """)
        
        if !retriableErrors.isEmpty {
            let joinedCases = retriableErrors.sorted(by: <)
                .joined(separator: ", ")
            
            fileBuilder.appendLine("""
                case \(joinedCases):
                    return true
                """)
        }
        
        if !unretriableErrors.isEmpty {
            let joinedCases = unretriableErrors.sorted(by: <)
                .joined(separator: ", ")
            
            fileBuilder.appendLine("""
                case \(joinedCases):
                    return false
                """)
        }
        
        if defaultBehaviorErrorsCount != 0 {
            fileBuilder.appendLine("""
                default:
                    return nil
                """)
        }
        
        fileBuilder.appendLine("""
                }
                """)
        fileBuilder.decIndent()
        fileBuilder.decIndent()
    }
    
    private func getSpecificErrors(codeGenerator: ServiceModelCodeGenerator, baseName: String) -> SpecificErrorBehaviour {
        let sortedErrors = codeGenerator.getSortedErrors(allErrorTypes: codeGenerator.model.errorTypes)
        
        var retriableErrors: [String] = []
        var unretriableErrors: [String] = []
        var defaultBehaviorErrorsCount: Int = 0
        
        let httpClientConfiguration = codeGenerator.customizations.httpClientConfiguration
        
        sortedErrors.forEach { errorType in
            let errorIdentity = errorType.identity
            let enumName = codeGenerator.getNormalizedEnumCaseName(
                modelTypeName: errorType.normalizedName,
                inStructure: "\(baseName)Error",
                usingUpperCamelCase: true)
            
            if case .fail = httpClientConfiguration.knownErrorsDefaultRetryBehavior,
                httpClientConfiguration.retriableUnknownErrors.contains(errorIdentity) {
                retriableErrors.append( ".\(enumName)")
            } else if case .retry = httpClientConfiguration.knownErrorsDefaultRetryBehavior,
                httpClientConfiguration.unretriableUnknownErrors.contains(errorIdentity) {
                unretriableErrors.append( ".\(enumName)")
            } else {
                defaultBehaviorErrorsCount += 1
            }
        }
        
        return (retriableErrors, unretriableErrors, defaultBehaviorErrorsCount)
    }
    
    private func addTypedErrorRetriableExtension(codeGenerator: ServiceModelCodeGenerator,
                                                fileBuilder: FileBuilder, baseName: String,
                                                specificErrorBehaviour: SpecificErrorBehaviour) {
        let errorType = "\(baseName)Error"
        let httpClientConfiguration = codeGenerator.customizations.httpClientConfiguration
        
        let retriableErrors = specificErrorBehaviour.retriableErrors
        let unretriableErrors = specificErrorBehaviour.unretriableErrors
        let defaultBehaviorErrorsCount = specificErrorBehaviour.defaultBehaviorErrorsCount
        
        fileBuilder.appendLine("""
            
             extension \(errorType): ConvertableError {
                public static func asUnrecognizedError(error: Swift.Error) -> \(errorType) {
                    return error.asUnrecognized\(baseName)Error()
                }
            """)
        
        if !(retriableErrors.isEmpty && unretriableErrors.isEmpty) {
            fileBuilder.appendLine("""
                
                    func isRetriable() -> Bool? {
                """)
            
            addRetriableSwitchStatement(fileBuilder: fileBuilder, retriableErrors: retriableErrors,
                                        unretriableErrors: unretriableErrors,
                                        defaultBehaviorErrorsCount: defaultBehaviorErrorsCount,
                                        httpClientConfiguration: httpClientConfiguration)
            
            fileBuilder.appendLine("""
                }
            """)
        }
        
        fileBuilder.appendLine("""
        }
        """)
    }
    
    public func addErrorRetriableExtension(codeGenerator: ServiceModelCodeGenerator,
                                           fileBuilder: FileBuilder, baseName: String) {
        let errorType = "\(baseName)Error"
                
        fileBuilder.appendLine("""
            
            private extension SmokeHTTPClient.HTTPClientError {
                func isRetriable() -> Bool {
                    if let typedError = self.cause as? \(errorType), let isRetriable = typedError.isRetriable() {
                        return isRetriable
                    } else {
                        return self.isRetriableAccordingToCategory
                    }
                }
            }
            """)
    }
}
