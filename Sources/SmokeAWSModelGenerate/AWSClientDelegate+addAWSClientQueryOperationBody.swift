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
        
        fileBuilder.appendLine("""
            let handlerDelegate = AWSClientChannelInboundHandlerDelegate(
                        credentialsProvider: credentialsProvider,
                        awsRegion: awsRegion,
                        service: service,
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

        fileBuilder.appendLine("""
            
            let httpClientInvocationReporting = SmokeAWSHTTPClientInvocationReporting(smokeAWSInvocationReporting: reporting,
                                                                                      smokeAWSOperationReporting: \(function.name)OperationReporting)
            let invocationContext = HTTPClientInvocationContext(reporting: httpClientInvocationReporting, handlerDelegate: handlerDelegate)
            let wrappedInput = \(wrappedTypeDeclaration)
            
            let requestInput = QueryWrapperHTTPRequestInput(
                wrappedInput: wrappedInput,
                action: \(baseName)ModelOperations.\(function.name).rawValue,
                version: apiVersion)
            """)

        fileBuilder.appendEmptyLine()
        
        let httpClientName = getHttpClientForOperation(name: name,
                                                       httpClientConfiguration: codeGenerator.customizations.httpClientConfiguration)
        
        let returnStatement = getQueryOperationReturnStatement(
            functionOutputType: function.outputType,
            invokeType: invokeType,
            httpClientName: httpClientName,
            http: http)
        fileBuilder.appendLine(returnStatement)
        
        fileBuilder.appendLine("}", preDec: true)
    }
    
    private func getQueryOperationNoOutputReturnStatement(
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
                invocationContext: invocationContext,
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
                invocationContext: invocationContext,
                retryConfiguration: retryConfiguration,
                retryOnError: retryOnErrorProvider)
            """
        }
    }
    
    private func getQueryOperationWithOutputReturnStatement(
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
                invocationContext: invocationContext,
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
                invocationContext: invocationContext,
                retryConfiguration: retryConfiguration,
                retryOnError: retryOnErrorProvider)
            """
        }
    }
    
    private func getQueryOperationReturnStatement(
            functionOutputType: String?, invokeType: InvokeType,
            httpClientName: String, http: (verb: String, url: String)) -> String {
        if functionOutputType != nil {
            return getQueryOperationNoOutputReturnStatement(
                invokeType: invokeType,
                httpClientName: httpClientName,
                http: http)
        } else {
            return getQueryOperationWithOutputReturnStatement(
                invokeType: invokeType,
                httpClientName: httpClientName,
                http: http)
        }
    }
}
