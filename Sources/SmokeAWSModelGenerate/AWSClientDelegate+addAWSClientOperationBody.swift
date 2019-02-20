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
// AWSClientDelegate+addAWSClientOperationBody.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

internal extension AWSClientDelegate {
    internal func addAWSClientOperationBody(
            name: String,
            fileBuilder: FileBuilder,
            codeGenerator: ServiceModelCodeGenerator,
            function: AWSClientFunction,
            http: (verb: String, url: String), invokeType: InvokeType,
            signAllHeaders: Bool) {
        fileBuilder.incIndent()
        
        let typeName = function.name.getNormalizedTypeName(forModel: codeGenerator.model)
        
        fileBuilder.appendLine("""
            let handlerDelegate = AWSClientChannelInboundHandlerDelegate(
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
            http: (verb: String, url: String)) -> String {
        switch invokeType {
        case .sync:
            return """
            return try \(httpClientName).executeSyncRetriableWithOutput(
                endpointPath: "\(http.url)",
                httpMethod: .\(http.verb),
                input: requestInput,
                handlerDelegate: handlerDelegate,
                retryConfiguration: retryConfiguration,
                retryOnError: retryOnErrorProvider)
            """
        case .async:
            return """
            _ = try \(httpClientName).executeAsyncRetriableWithOutput(
                endpointPath: "\(http.url)",
                httpMethod: .\(http.verb),
                input: requestInput,
                completion: completion,
                handlerDelegate: handlerDelegate,
                retryConfiguration: retryConfiguration,
                retryOnError: retryOnErrorProvider)
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
            try \(httpClientName).executeSyncRetriableWithoutOutput(
                endpointPath: "\(http.url)",
                httpMethod: .\(http.verb),
                input: requestInput,
                handlerDelegate: handlerDelegate,
                retryConfiguration: retryConfiguration,
                retryOnError: retryOnErrorProvider)
            """
        case .async:
            return """
            _ = try \(httpClientName).executeAsyncRetriableWithoutOutput(
                endpointPath: "\(http.url)",
                httpMethod: .\(http.verb),
                input: requestInput,
                completion: completion,
                handlerDelegate: handlerDelegate,
                retryConfiguration: retryConfiguration,
                retryOnError: retryOnErrorProvider)
            """
        }
    }
    
    private func getOperationReturnStatement(
            function: AWSClientDelegate.AWSClientFunction,
            invokeType: InvokeType,
            httpClientName: String,
            http: (verb: String, url: String)) -> String {
        if function.outputType != nil {
            return getOperationNoOutputReturnStatement(
                invokeType: invokeType,
                httpClientName: httpClientName,
                http: http)
        } else {
            return getOperationWithOutputReturnStatement(
                invokeType: invokeType,
                httpClientName: httpClientName,
                http: http)
        }
    }
}
