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
// AWSClientDelegate.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

/**
 A ModelClientDelegate that can be used to generate an
 AWS Client from a Service Model.
 */
public struct AWSClientDelegate: ModelClientDelegate {
    public let clientType: ClientType
    public let clientAttributes: AWSClientAttributes
    public let asyncResultType: AsyncResultType?
    public let baseName: String
    public let signAllHeaders: Bool
    public let awsCustomizations: AWSCodeGenerationCustomizations
    
    struct AWSClientFunction {
        let name: String
        let inputType: String?
        let outputType: String?
    }
    
    /**
     Initializer.
 
     - Parameters:
        - baseName: The base name of the Service.
        - asyncResultType: The name of the result type to use for async functions.
     */
    public init(baseName: String,
                clientAttributes: AWSClientAttributes,
                signAllHeaders: Bool,
                asyncResultType: AsyncResultType? = nil,
                awsCustomizations: AWSCodeGenerationCustomizations) {
        self.baseName = baseName
        self.clientAttributes = clientAttributes
        self.asyncResultType = asyncResultType
        let genericParameters: [(String, String?)] = [("InvocationReportingType", "HTTPClientCoreInvocationReporting & Sendable")]
        self.clientType = .struct(name: "AWS\(baseName)Client", genericParameters: genericParameters,
                                  conformingProtocolName: "\(baseName)ClientProtocol")
        self.signAllHeaders = signAllHeaders
        self.awsCustomizations = awsCustomizations
    }
    
    public func getFileDescription(isGenerator: Bool) -> String {
        if isGenerator {
            return "AWS Client Generator for the \(baseName) service."
        } else {
            return "AWS Client for the \(baseName) service."
        }
    }
    
    public func addCustomFileHeader(codeGenerator: ServiceModelCodeGenerator,
                                    delegate: ModelClientDelegate,
                                    fileBuilder: FileBuilder,
                                    isGenerator: Bool) {
        addAWSClientFileHeader(codeGenerator: codeGenerator, fileBuilder: fileBuilder, baseName: baseName, isGenerator: isGenerator,
                               defaultInvocationTraceContext: self.clientAttributes.defaultInvocationTraceContext)
    }
    
    public func addCommonFunctions(codeGenerator: ServiceModelCodeGenerator,
                                   delegate: ModelClientDelegate,
                                   fileBuilder: FileBuilder,
                                   sortedOperations: [(String, OperationDescription)],
                                   isGenerator: Bool) {
        addAWSClientCommonFunctions(fileBuilder: fileBuilder, baseName: baseName,
                                    clientAttributes: clientAttributes,
                                    codeGenerator: codeGenerator,
                                    targetsAPIGateway: false,
                                    contentType: clientAttributes.contentType,
                                    sortedOperations: sortedOperations,
                                    isGenerator: isGenerator,
                                    awsCustomization: self.awsCustomizations)
    }
    
    public func addOperationBody(codeGenerator: ServiceModelCodeGenerator,
                                 delegate: ModelClientDelegate,
                                 fileBuilder: FileBuilder,
                                 invokeType: InvokeType,
                                 operationName: String,
                                 operationDescription: OperationDescription,
                                 functionInputType: String?,
                                 functionOutputType: String?,
                                 isGenerator: Bool) {
        guard let httpVerb = operationDescription.httpVerb,
            let httpUrl = operationDescription.httpUrl else {
            fatalError("Unable to create an AWSClient operation that doesn't have a HTTP verb or path")
        }
        
        let functionName = operationName.upperToLowerCamelCase
        
        let function = AWSClientFunction(name: functionName,
                                         inputType: functionInputType,
                                         outputType: functionOutputType)
        let http = (verb: httpVerb, url: httpUrl)
        
        switch clientAttributes.contentType.contentTypeDefaultInputLocation {
        case .query:
            addAWSClientQueryOperationBody(
                name: operationName, fileBuilder: fileBuilder,
                codeGenerator: codeGenerator,
                function: function, http: http, invokeType: invokeType,
                signAllHeaders: signAllHeaders)
        case .body:
            addAWSClientOperationBody(
                name: operationName, fileBuilder: fileBuilder,
                codeGenerator: codeGenerator,
                function: function, http: http, invokeType: invokeType,
                signAllHeaders: signAllHeaders)
        }
    }
}
