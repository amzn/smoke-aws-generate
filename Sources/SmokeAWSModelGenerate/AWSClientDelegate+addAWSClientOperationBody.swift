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
// AWSClientDelegate+addAWSClientOperationBody.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

internal extension AWSClientDelegate {
    func addAWSClientOperationBody(
            name: String,
            fileBuilder: FileBuilder,
            codeGenerator: ServiceModelCodeGenerator,
            function: AWSClientFunction,
            http: (verb: String, url: String), invokeType: InvokeType,
            signAllHeaders: Bool) {
        fileBuilder.incIndent()
        
        let typeName = function.name.getNormalizedTypeName(forModel: codeGenerator.model)
        
        fileBuilder.appendLine("""
            let handlerDelegate = AWSClientInvocationDelegate(
                        credentialsProvider: credentialsProvider,
                        awsRegion: awsRegion,
                        service: service,
                        operation: \(baseName)ModelOperations.\(function.name).rawValue,
            """)
        
        if signAllHeaders {
            fileBuilder.appendLine("""
                            target: target,
                            signAllHeaders: true)
                """)
        } else {
            fileBuilder.appendLine("""
                            target: target)
                """)
        }
        
        fileBuilder.appendEmptyLine()
        
        fileBuilder.appendLine("""
            let invocationContext = HTTPClientInvocationContext(reporting: self.invocationsReporting.\(function.name),
                                                                handlerDelegate: handlerDelegate)
            """)
        
        if function.inputType != nil {
            fileBuilder.appendLine("""
                let requestInput = \(typeName)OperationHTTPRequestInput(encodable: input)
                """)
        } else {
            fileBuilder.appendLine("""
                let requestInput = NoHTTPRequestInput()
                """)
        }
        
        fileBuilder.appendEmptyLine()
        
        let httpClientName = getHttpClientForOperation(name: name,
                                                       httpClientConfiguration: codeGenerator.customizations.httpClientConfiguration)
        
        let returnStatement = getOperationReturnStatement(
            function: function,
            invokeType: invokeType,
            httpClientName: httpClientName,
            http: http)
        fileBuilder.appendLine(returnStatement)
        
        fileBuilder.appendLine("}", preDec: true)
    }
    
    private func getOperationNoOutputReturnStatement(
            invokeType: InvokeType,
            httpClientName: String,
            outputType: String,
            http: (verb: String, url: String)) -> String {
        switch invokeType {
        case .sync:
            return """
            do {
                return try \(httpClientName).executeSyncRetriableWithOutput(
                    endpointPath: "\(http.url)",
                    httpMethod: .\(http.verb),
                    input: requestInput,
                    invocationContext: invocationContext,
                    retryConfiguration: retryConfiguration,
                    retryOnError: retryOnErrorProvider)
            } catch {
                let typedError: \(baseName)Error = error.asTypedError()
                throw typedError
            }
            """
        case .async:
            return """
            _ = try \(httpClientName).executeOperationAsyncRetriableWithOutput(
                endpointPath: "\(http.url)",
                httpMethod: .\(http.verb),
                input: requestInput,
                completion: completion,
                invocationContext: invocationContext,
                retryConfiguration: retryConfiguration,
                retryOnError: retryOnErrorProvider)
            """
        case .asyncFunction:
            return """
            do {
                return try await \(httpClientName).executeRetriableWithOutput(
                    endpointPath: "\(http.url)",
                    httpMethod: .\(http.verb),
                    input: requestInput,
                    invocationContext: invocationContext,
                    retryConfiguration: retryConfiguration,
                    retryOnError: retryOnErrorProvider)
            } catch {
                let typedError: \(baseName)Error = error.asTypedError()
                throw typedError
            }
            """
        }
    }
    
    private func getOperationWithOutputReturnStatement(
            invokeType: InvokeType,
            httpClientName: String,
            http: (verb: String, url: String)) -> String {
        switch invokeType {
        case .sync:
            return """
            do {
                try \(httpClientName).executeSyncRetriableWithoutOutput(
                    endpointPath: "\(http.url)",
                    httpMethod: .\(http.verb),
                    input: requestInput,
                    invocationContext: invocationContext,
                    retryConfiguration: retryConfiguration,
                    retryOnError: retryOnErrorProvider)
            } catch {
                let typedError: \(baseName)Error = error.asTypedError()
                throw typedError
            }
            """
        case .async:
            return """
            _ = try \(httpClientName).executeOperationAsyncRetriableWithoutOutput(
                endpointPath: "\(http.url)",
                httpMethod: .\(http.verb),
                input: requestInput,
                completion: completion,
                invocationContext: invocationContext,
                retryConfiguration: retryConfiguration,
                retryOnError: retryOnErrorProvider)
            """
        case .asyncFunction:
            return """
            do {
                try await \(httpClientName).executeRetriableWithoutOutput(
                    endpointPath: "\(http.url)",
                    httpMethod: .\(http.verb),
                    input: requestInput,
                    invocationContext: invocationContext,
                    retryConfiguration: retryConfiguration,
                    retryOnError: retryOnErrorProvider)
            } catch {
                let typedError: \(baseName)Error = error.asTypedError()
                throw typedError
            }
            """
        }
    }
    
    private func getOperationReturnStatement(
            function: AWSClientDelegate.AWSClientFunction,
            invokeType: InvokeType,
            httpClientName: String,
            http: (verb: String, url: String)) -> String {
        if let outputType = function.outputType {
            return getOperationNoOutputReturnStatement(
                invokeType: invokeType,
                httpClientName: httpClientName, outputType: outputType,
                http: http)
        } else {
            return getOperationWithOutputReturnStatement(
                invokeType: invokeType,
                httpClientName: httpClientName,
                http: http)
        }
    }
}
