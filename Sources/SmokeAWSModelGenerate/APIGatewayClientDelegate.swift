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
// APIGatewayClientDelegate.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

/**
 A ModelClientDelegate that can be used to generate an
 API Gateway Client from a Service Model.
 */
public struct APIGatewayClientDelegate: ModelClientDelegate {
    public let clientType: ClientType
    public let asyncResultType: AsyncResultType?
    public let baseName: String
    public let contentType: String
    public let signAllHeaders: Bool
    public let defaultInvocationTraceContext: InvocationTraceContextDeclaration
    
    private struct APIGatewayClientFunction {
        let name: String
        let outputType: String?
        let inputType: String?
    }
    
    /**
     Initializer.
 
     - Parameters:
        - baseName: The base name of the Service.
        - asyncResultType: The name of the result type to use for async functions.
     */
    public init(baseName: String,
                asyncResultType: AsyncResultType? = nil,
                contentType: String,
                signAllHeaders: Bool,
                defaultInvocationTraceContext: InvocationTraceContextDeclaration = InvocationTraceContextDeclaration(name: "AWSClientInvocationTraceContext")) {
        self.baseName = baseName
        self.asyncResultType = asyncResultType
        let genericParameters: [(String, String?)] = [("InvocationReportingType", "HTTPClientCoreInvocationReporting")]
        self.clientType = .struct(name: "APIGateway\(baseName)Client", genericParameters: genericParameters,
                                  conformingProtocolName: "\(baseName)ClientProtocol")
        self.contentType = contentType
        self.signAllHeaders = signAllHeaders
        self.defaultInvocationTraceContext = defaultInvocationTraceContext
    }
    
    public func getFileDescription(isGenerator: Bool) -> String {
        if isGenerator {
            return "API Gateway Client Generator for the \(baseName) service."
        } else {
            return "API Gateway Client for the \(baseName) service."
        }
    }
    
    public func addCustomFileHeader(codeGenerator: ServiceModelCodeGenerator,
                                    delegate: ModelClientDelegate,
                                    fileBuilder: FileBuilder,
                                    isGenerator: Bool) {
        addAWSClientFileHeader(codeGenerator: codeGenerator, fileBuilder: fileBuilder, baseName: baseName, isGenerator: isGenerator,
                               defaultInvocationTraceContext: self.defaultInvocationTraceContext)
    }
    
    public func addCommonFunctions(codeGenerator: ServiceModelCodeGenerator,
                                   delegate: ModelClientDelegate,
                                   fileBuilder: FileBuilder,
                                   sortedOperations: [(String, OperationDescription)],
                                   isGenerator: Bool) {
        // An API Gateway client is essentially an AWS service client calling execute-api
        let clientAttributes = AWSClientAttributes(apiVersion: "2017-07-25",
                                                   service: "execute-api",
                                                   target: nil,
                                                   contentType: contentType,
                                                   globalEndpoint: nil,
                                                   defaultInvocationTraceContext: self.defaultInvocationTraceContext)
    
        addAWSClientCommonFunctions(fileBuilder: fileBuilder, baseName: baseName,
                                    clientAttributes: clientAttributes,
                                    codeGenerator: codeGenerator,
                                    targetsAPIGateway: true,
                                    contentType: contentType,
                                    sortedOperations: sortedOperations, isGenerator: isGenerator)
    }
    
    public func addOperationBody(codeGenerator: ServiceModelCodeGenerator,
                                 delegate: ModelClientDelegate,
                                 fileBuilder: FileBuilder, invokeType: InvokeType,
                                 operationName: String,
                                 operationDescription: OperationDescription,
                                 functionInputType: String?,
                                 functionOutputType: String?,
                                 isGenerator: Bool) {
        guard let httpVerb = operationDescription.httpVerb else {
            fatalError("Unable to create an APIGateway operation that doesn't have a HTTP verb")
        }
        
        let functionName = operationName.upperToLowerCamelCase
        
        let function = APIGatewayClientFunction(name: functionName,
                                                outputType: functionOutputType, inputType: functionInputType)
    
        addAPIGatewayClientOperationBody(
            operationName: operationName,
            codeGenerator: codeGenerator,
            fileBuilder: fileBuilder,
            function: function, httpVerb: httpVerb,
            invokeType: invokeType,
            signAllHeaders: signAllHeaders)
    }
        
    private func getOperationReturnStatement(
            functionOutputType: String?,
            invokeType: InvokeType,
            httpClientName: String,
            functionName: String,
            httpVerb: String) -> String {
        if functionOutputType != nil {
            switch invokeType {
            case .sync:
                return """
                    do {
                        return try \(httpClientName).executeSyncRetriableWithOutput(
                            endpointPath: "/\\(stage)" + \(baseName)ModelOperations.\(functionName).operationPath,
                            httpMethod: .\(httpVerb),
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
                        endpointPath: "/\\(stage)" + \(baseName)ModelOperations.\(functionName).operationPath,
                        httpMethod: .\(httpVerb),
                        input: requestInput,
                        completion: completion,
                        invocationContext: invocationContext,
                        retryConfiguration: retryConfiguration,
                        retryOnError: retryOnErrorProvider)
                    """
            }
        } else {
            switch invokeType {
            case .sync:
                return """
                    do {
                        try \(httpClientName).executeSyncRetriableWithoutOutput(
                            endpointPath: "/\\(stage)" + \(baseName)ModelOperations.\(functionName).operationPath,
                            httpMethod: .\(httpVerb),
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
                        endpointPath: "/\\(stage)" + \(baseName)ModelOperations.\(functionName).operationPath,
                        httpMethod: .\(httpVerb),
                        input: requestInput,
                        completion: completion,
                        invocationContext: invocationContext,
                        retryConfiguration: retryConfiguration,
                        retryOnError: retryOnErrorProvider)
                    """
            }
        }
    }
    
    private func addAPIGatewayClientOperationBody(
            operationName: String,
            codeGenerator: ServiceModelCodeGenerator,
            fileBuilder: FileBuilder,
            function: APIGatewayClientFunction,
            httpVerb: String,
            invokeType: InvokeType,
            signAllHeaders: Bool) {
        fileBuilder.incIndent()
        
        let typeName = function.name.getNormalizedTypeName(forModel: codeGenerator.model)
        let httpClientConfiguration = codeGenerator.customizations.httpClientConfiguration
        
        let input = function.inputType != nil ? "input" : "Data()"
        
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

        fileBuilder.appendLine("""
            
            let invocationContext = HTTPClientInvocationContext(reporting: self.invocationsReporting.\(function.name),
                                                                handlerDelegate: handlerDelegate)
            let requestInput = \(typeName)OperationHTTPRequestInput(encodable: \(input))
            """)
        
        fileBuilder.appendEmptyLine()
        
        let httpClientName = getHttpClientForOperation(name: operationName,
                                                       httpClientConfiguration: httpClientConfiguration)
        
        let returnStatement = getOperationReturnStatement(functionOutputType: function.outputType,
                                                          invokeType: invokeType,
                                                          httpClientName: httpClientName,
                                                          functionName: function.name,
                                                          httpVerb: httpVerb)
        fileBuilder.appendLine(returnStatement)
        
        fileBuilder.appendLine("}", preDec: true)
    }
}
