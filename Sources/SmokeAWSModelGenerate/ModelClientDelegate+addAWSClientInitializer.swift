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
// ModelClientDelegate+addAWSClientInitializer.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import ServiceModelGenerate
import CoralToJSONServiceModel

extension ModelClientDelegate {
    func addAWSClientInitializer(fileBuilder: FileBuilder, baseName: String,
                                 clientAttributes: AWSClientAttributes,
                                 codeGenerator: ServiceModelCodeGenerator,
                                 targetsAPIGateway: Bool,
                                 contentType: String) {
        let targetValue: String
        if let target = clientAttributes.target {
            targetValue = "\"\(target)\""
        } else {
            targetValue = "nil"
        }
        
        let endpointDefault: String
        let regionDefault: String
        let regionAssignmentPostfix: String
        // If there is a global endpoint, use it as the default endpoint
        // and make the region optional and nil by default
        if let globalEndpoint = clientAttributes.globalEndpoint {
            endpointDefault = " = \"\(globalEndpoint)\""
            regionDefault = "? = nil"
            regionAssignmentPostfix = " ?? .us_east_1"
        } else {
            endpointDefault = ""
            regionDefault = ""
            regionAssignmentPostfix = ""
        }
        let httpClientConfiguration = codeGenerator.customizations.httpClientConfiguration
        
        let targetOrVersionParameter: String
        let targetAssignment: String
        let contentTypeAssignment: String
        
        // Use a specific initializer for queries
        switch contentType.contentTypeDefaultInputLocation {
        case .query:
            addAWSClientQueryMembers(
                fileBuilder: fileBuilder,
                httpClientConfiguration: httpClientConfiguration,
                codeGenerator: codeGenerator)
            
            // accept the api version rather than the target
            targetOrVersionParameter = "apiVersion: String = \"\(clientAttributes.apiVersion)\""
            targetAssignment = "self.target = nil"
            
            // use 'application/octet-stream' as the content type
            contentTypeAssignment = "contentType: String = \"application/octet-stream\""
        case .body:
            addAWSClientBodyMembers(
                fileBuilder: fileBuilder,
                httpClientConfiguration: httpClientConfiguration,
                codeGenerator: codeGenerator, targetsAPIGateway: targetsAPIGateway)
            
            // accept the target and pass it to the AWS client
            targetOrVersionParameter = "target: String? = \(targetValue)"
            targetAssignment = "self.target = target"
            
            // use the content type from the client attributes as the default
            contentTypeAssignment = "contentType: String = \"\(clientAttributes.contentType)\""
        }
        
        addAWSClientInitializerSignature(
            fileBuilder: fileBuilder, regionDefault: regionDefault,
            endpointDefault: endpointDefault, targetsAPIGateway: targetsAPIGateway,
            clientAttributes: clientAttributes,
            contentTypeAssignment: contentTypeAssignment,
            targetOrVersionParameter: targetOrVersionParameter)
        
        addAWSClientInitializerBody(
            fileBuilder: fileBuilder, contentType: contentType,
            httpClientConfiguration: httpClientConfiguration, baseName: baseName,
            codeGenerator: codeGenerator, regionAssignmentPostfix: regionAssignmentPostfix,
            targetAssignment: targetAssignment, targetsAPIGateway: targetsAPIGateway)
        fileBuilder.appendLine("}")
    }
    
    private func addAWSClientInitializerBody(
            fileBuilder: FileBuilder,
            contentType: String,
            httpClientConfiguration: HttpClientConfiguration,
            baseName: String,
            codeGenerator: ServiceModelCodeGenerator,
            regionAssignmentPostfix: String,
            targetAssignment: String,
            targetsAPIGateway: Bool) {
        fileBuilder.incIndent()
        switch contentType.contentTypePayloadType {
        case .xml:
            addXmlDelegate(fileBuilder: fileBuilder,
                           httpClientConfiguration: httpClientConfiguration,
                           baseName: baseName)
        case .json:
            addJsonDelegate(fileBuilder: fileBuilder,
                            httpClientConfiguration: httpClientConfiguration,
                            baseName: baseName)
        }
        
        fileBuilder.appendLine("""
            self.httpClient = HTTPClient(endpointHostName: endpointHostName,
                                         endpointPort: endpointPort,
                                         contentType: contentType,
                                         clientDelegate: clientDelegate,
                                         connectionTimeoutSeconds: connectionTimeoutSeconds,
                                         eventLoopProvider: eventLoopProvider)
            """)
        
        addAdditionalHttpClients(
            httpClientConfiguration: httpClientConfiguration,
            codeGenerator: codeGenerator, fileBuilder: fileBuilder)
        
        fileBuilder.appendLine("""
            self.awsRegion = awsRegion\(regionAssignmentPostfix)
            self.service = service
            \(targetAssignment)
            self.credentialsProvider = credentialsProvider
            self.retryConfiguration = retryConfiguration
            self.retryOnErrorProvider = { error in error.isRetriable() }
            """)
        
        // If this is a query, set the apiVersion
        if case .query = contentType.contentTypeDefaultInputLocation {
            fileBuilder.appendLine("""
                self.apiVersion = apiVersion
                """)
        }
        
        // If this is an API Gateway client, store the stage
        if targetsAPIGateway {
            fileBuilder.appendLine("""
                self.stage = stage
                """)
        }
        fileBuilder.decIndent()
    }
    
    private func addAdditionalHttpClients(
            httpClientConfiguration: HttpClientConfiguration,
            codeGenerator: ServiceModelCodeGenerator,
            fileBuilder: FileBuilder) {
        httpClientConfiguration.additionalClients?.forEach { (key, _) in
            let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
            let postfix = key.startingWithUppercase
            fileBuilder.appendLine("""
                self.\(variableName) = HTTPClient(endpointHostName: endpointHostName,
                                                  endpointPort: endpointPort,
                                                  contentType: contentType,
                                                  clientDelegate: clientDelegateFor\(postfix),
                                                  connectionTimeoutSeconds: connectionTimeoutSeconds,
                                                  eventLoopProvider: eventLoopProvider)
                """)
        }
    }
    
    private func createDelegate(name: String, fileBuilder: FileBuilder, delegateName: String, errorType: String, parameters: [String]?) {
        guard let concreteParameters = parameters, !concreteParameters.isEmpty else {
            fileBuilder.appendLine("let \(name) = \(delegateName)<\(errorType)>()")
            return
        }
        
        fileBuilder.appendLine("let \(name) = \(delegateName)<\(errorType)>(")
        
        fileBuilder.incIndent()
        concreteParameters.enumerated().forEach { (index, parameter) in
            if index == concreteParameters.count - 1 {
                fileBuilder.appendLine("\(parameter))")
            } else {
                fileBuilder.appendLine("\(parameter), ")
            }
        }
        fileBuilder.decIndent()
    }
    
    private func addXmlDelegate(
            fileBuilder: FileBuilder,
            httpClientConfiguration: HttpClientConfiguration,
            baseName: String) {
        let delegateName = httpClientConfiguration.clientDelegateNameOverride
            ?? "XMLAWSHttpClientDelegate"
        // pass a QueryXMLAWSHttpClientDelegate to the AWS client
        createDelegate(name: "clientDelegate", fileBuilder: fileBuilder, delegateName: delegateName, errorType: "\(baseName)Error",
            parameters: httpClientConfiguration.clientDelegateParameters)
        fileBuilder.appendEmptyLine()
    
        httpClientConfiguration.additionalClients?.forEach { (key, value) in
            let postfix = key.startingWithUppercase
            let additionalDelegateName = value.clientDelegateNameOverride
                ?? "XMLAWSHttpClientDelegate"
            
            createDelegate(name: "clientDelegateFor\(postfix)", fileBuilder: fileBuilder, delegateName: additionalDelegateName,
                           errorType: "\(baseName)Error", parameters: value.clientDelegateParameters)
            fileBuilder.appendEmptyLine()
        }
    }
    
    private func addJsonDelegate(
            fileBuilder: FileBuilder,
            httpClientConfiguration: HttpClientConfiguration,
            baseName: String) {
        let delegateName = httpClientConfiguration.clientDelegateNameOverride
                ?? "JSONAWSHttpClientDelegate"
        // pass a JSONAWSHttpClientDelegate to the AWS client
        createDelegate(name: "clientDelegate", fileBuilder: fileBuilder, delegateName: delegateName, errorType: "\(baseName)Error",
            parameters: httpClientConfiguration.clientDelegateParameters)
        fileBuilder.appendEmptyLine()
    
        httpClientConfiguration.additionalClients?.forEach { (key, value) in
            let postfix = key.startingWithUppercase
            let additionalDelegateName = value.clientDelegateNameOverride
                ?? "JSONAWSHttpClientDelegate"
            
            createDelegate(name: "clientDelegateFor\(postfix)", fileBuilder: fileBuilder, delegateName: additionalDelegateName,
                           errorType: "\(baseName)Error", parameters: value.clientDelegateParameters)
            fileBuilder.appendEmptyLine()
        }
    }
    
    private func addAWSClientQueryMembers(
            fileBuilder: FileBuilder,
            httpClientConfiguration: HttpClientConfiguration,
            codeGenerator: ServiceModelCodeGenerator) {
        fileBuilder.appendLine("""
                let httpClient: HTTPClient
                """)
        
        httpClientConfiguration.additionalClients?.forEach { (key, _) in
            let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
            fileBuilder.appendLine("""
                let \(variableName): HTTPClient
                """)
        }
        
        fileBuilder.appendLine("""
                let awsRegion: AWSRegion
                let service: String
                let apiVersion: String
                let target: String?
                let retryConfiguration: HTTPClientRetryConfiguration
                let retryOnErrorProvider: (Swift.Error) -> Bool
                let credentialsProvider: CredentialsProvider
                """)
    }
    
    private func addAWSClientBodyMembers(
            fileBuilder: FileBuilder,
            httpClientConfiguration: HttpClientConfiguration,
            codeGenerator: ServiceModelCodeGenerator,
            targetsAPIGateway: Bool) {
        fileBuilder.appendLine("""
                let httpClient: HTTPClient
                """)
        
        httpClientConfiguration.additionalClients?.forEach { (key, _) in
            let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
            fileBuilder.appendLine("""
                let \(variableName): HTTPClient
                """)
        }
        
        fileBuilder.appendLine("""
                let awsRegion: AWSRegion
                let service: String
                let target: String?
                let retryConfiguration: HTTPClientRetryConfiguration
                let retryOnErrorProvider: (Swift.Error) -> Bool
                let credentialsProvider: CredentialsProvider
                """)
        
        // If this is an API Gateway client, store the stage
        if targetsAPIGateway {
            fileBuilder.appendLine("""
                    let stage: String
                    """)
        }
    }
    
    private func addAWSClientInitializerSignature(
            fileBuilder: FileBuilder,
            regionDefault: String,
            endpointDefault: String,
            targetsAPIGateway: Bool,
            clientAttributes: AWSClientAttributes,
            contentTypeAssignment: String,
            targetOrVersionParameter: String) {
        fileBuilder.appendLine("""
            
            public init(credentialsProvider: CredentialsProvider, awsRegion: AWSRegion\(regionDefault),
                        endpointHostName: String\(endpointDefault),
            """)
        
        // If this is an API Gateway client, accept the stage in the constructor
        if targetsAPIGateway {
            fileBuilder.appendLine("""
                            stage: String,
                """)
        }
        
        fileBuilder.appendLine("""
                        endpointPort: Int = 443,
                        service: String = "\(clientAttributes.service)",
                        \(contentTypeAssignment),
                        \(targetOrVersionParameter),
                        connectionTimeoutSeconds: Int = 10,
                        retryConfiguration: HTTPClientRetryConfiguration = .default,
                        eventLoopProvider: HTTPClient.EventLoopProvider = .spawnNewThreads) {
            """)
    }
}
