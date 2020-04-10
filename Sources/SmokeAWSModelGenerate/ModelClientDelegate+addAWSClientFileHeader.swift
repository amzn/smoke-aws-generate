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

extension ModelClientDelegate {
    func addAWSClientFileHeader(codeGenerator: ServiceModelCodeGenerator,
                                fileBuilder: FileBuilder, baseName: String,
                                isGenerator: Bool) {
        fileBuilder.appendLine("""
            import SmokeAWSHttp
            import NIO
            import NIOHTTP1
            import AsyncHTTPClient
            import Logging
            """)
        
        if !isGenerator {
            fileBuilder.appendLine("""
                
                public enum \(baseName)ClientError: Swift.Error {
                    case invalidEndpoint(String)
                    case unsupportedPayload
                    case unknownError(String?)
                }
                """)
        
            addTypedErrorRetriableExtension(codeGenerator: codeGenerator, fileBuilder: fileBuilder, baseName: baseName)
        }
        addErrorRetriableExtension(codeGenerator: codeGenerator, fileBuilder: fileBuilder, baseName: baseName)
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
            switch httpClientConfiguration.knownErrorsDefaultRetryBehavior {
            case .retry:
                fileBuilder.appendLine("""
                    default:
                        return true
                    """)
            case .fail:
                fileBuilder.appendLine("""
                    default:
                        return false
                    """)
            }
        }
        
        fileBuilder.appendLine("""
                }
                """)
        fileBuilder.decIndent()
        fileBuilder.decIndent()
    }
    
    public func addTypedErrorRetriableExtension(codeGenerator: ServiceModelCodeGenerator,
                                                fileBuilder: FileBuilder, baseName: String) {
        let errorType = "\(baseName)Error"
        let httpClientConfiguration = codeGenerator.customizations.httpClientConfiguration
        
        var retriableErrors: [String] = []
        var unretriableErrors: [String] = []
        var defaultBehaviorErrorsCount: Int = 0
        
        let sortedErrors = codeGenerator.getSortedErrors(allErrorTypes: codeGenerator.model.errorTypes)
        
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
        
        fileBuilder.appendLine("""
            
            internal extension \(errorType) {
                func isRetriable() -> Bool {
            """)
        
        if retriableErrors.isEmpty && unretriableErrors.isEmpty {
            switch httpClientConfiguration.knownErrorsDefaultRetryBehavior {
            case .retry:
                fileBuilder.appendLine("""
                        return true
                """)
            case .fail:
                fileBuilder.appendLine("""
                        return false
                """)
            }
        } else {
            addRetriableSwitchStatement(fileBuilder: fileBuilder, retriableErrors: retriableErrors,
                                        unretriableErrors: unretriableErrors,
                                        defaultBehaviorErrorsCount: defaultBehaviorErrorsCount,
                                        httpClientConfiguration: httpClientConfiguration)
        }
        
        fileBuilder.appendLine("""
            }
        }
        """)
    }
    
    public func addErrorRetriableExtension(codeGenerator: ServiceModelCodeGenerator,
                                           fileBuilder: FileBuilder, baseName: String) {
        let errorType = "\(baseName)Error"
        let httpClientConfiguration = codeGenerator.customizations.httpClientConfiguration
        
        let unknownErrorIsRetriable = httpClientConfiguration.retryOnUnknownError.description
        
        fileBuilder.appendLine("""
            
            private extension Swift.Error {
                func isRetriable() -> Bool {
                    if let typedError = self as? \(errorType) {
                        return typedError.isRetriable()
                    } else {
                        return \(unknownErrorIsRetriable)
                    }
                }
            }
            """)
    }
}
