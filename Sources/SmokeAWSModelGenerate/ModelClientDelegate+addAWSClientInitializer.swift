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
// ModelClientDelegate+addAWSClientInitializer.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import ServiceModelGenerate
import CoralToJSONServiceModel

extension ModelClientDelegate {
    func addAWSClientInitializerAndMembers(fileBuilder: FileBuilder, baseName: String,
                                           clientAttributes: AWSClientAttributes,
                                           codeGenerator: ServiceModelCodeGenerator,
                                           targetsAPIGateway: Bool,
                                           contentType: String,
                                           sortedOperations: [(String, OperationDescription)],
                                           isGenerator: Bool) {
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
        
        let targetOrVersionParameterNormalConstructor: String
        let targetOrVersionParameterCopyConstructor: String
        let targetAssignment: String
        let contentTypeAssignment: String
        
        // Use a specific initializer for queries
        switch contentType.contentTypeDefaultInputLocation {
        case .query:
            addAWSClientQueryMembers(
                fileBuilder: fileBuilder,
                httpClientConfiguration: httpClientConfiguration,
                codeGenerator: codeGenerator, isGenerator: isGenerator)
            
            // accept the api version rather than the target
            targetOrVersionParameterNormalConstructor = "apiVersion: String = \"\(clientAttributes.apiVersion)\""
            targetOrVersionParameterCopyConstructor = "apiVersion: String"
            targetAssignment = "self.target = nil"
            
            // use 'application/octet-stream' as the content type
            contentTypeAssignment = "contentType: String = \"application/octet-stream\""
        case .body:
            addAWSClientBodyMembers(
                fileBuilder: fileBuilder,
                httpClientConfiguration: httpClientConfiguration,
                codeGenerator: codeGenerator, targetsAPIGateway: targetsAPIGateway, isGenerator: isGenerator)
            
            // accept the target and pass it to the AWS client
            targetOrVersionParameterNormalConstructor = "target: String? = \(targetValue)"
            targetOrVersionParameterCopyConstructor = "target: String?"
            targetAssignment = "self.target = target"
            
            // use the content type from the client attributes as the default
            contentTypeAssignment = "contentType: String = \"\(clientAttributes.contentType)\""
        }
        
        fileBuilder.appendEmptyLine()
        addAWSClientOperationMetricsParameters(fileBuilder: fileBuilder, baseName: baseName,
                                               codeGenerator: codeGenerator, sortedOperations: sortedOperations, isGenerator: isGenerator)
        
        addAWSClientInitializer(fileBuilder: fileBuilder, baseName: baseName, clientAttributes: clientAttributes,
                                codeGenerator: codeGenerator, endpointDefault: endpointDefault, regionDefault: regionDefault,
                                regionAssignmentPostfix: regionAssignmentPostfix, targetsAPIGateway: targetsAPIGateway,
                                contentType: contentType, contentTypeAssignment: contentTypeAssignment,
                                targetAssignment: targetAssignment, httpClientConfiguration: httpClientConfiguration,
                                targetOrVersionParameter: targetOrVersionParameterNormalConstructor, sortedOperations: sortedOperations,
                                isCopyInitializer: false, isGenerator: isGenerator)
        
        if !isGenerator {
            // add the internal copy initializer
            addAWSClientInitializer(fileBuilder: fileBuilder, baseName: baseName, clientAttributes: clientAttributes,
                                    codeGenerator: codeGenerator, endpointDefault: endpointDefault, regionDefault: regionDefault,
                                    regionAssignmentPostfix: regionAssignmentPostfix, targetsAPIGateway: targetsAPIGateway,
                                    contentType: contentType, contentTypeAssignment: contentTypeAssignment,
                                    targetAssignment: targetAssignment, httpClientConfiguration: httpClientConfiguration,
                                    targetOrVersionParameter: targetOrVersionParameterCopyConstructor, sortedOperations: sortedOperations,
                                    isCopyInitializer: true, isGenerator: isGenerator)
        }
    }
    
    private func addAWSClientInitializer(fileBuilder: FileBuilder, baseName: String,
                                         clientAttributes: AWSClientAttributes,
                                         codeGenerator: ServiceModelCodeGenerator,
                                         endpointDefault: String, regionDefault: String,
                                         regionAssignmentPostfix: String, targetsAPIGateway: Bool,
                                         contentType: String, contentTypeAssignment: String, targetAssignment: String,
                                         httpClientConfiguration: HttpClientConfiguration,
                                         targetOrVersionParameter: String,
                                         sortedOperations: [(String, OperationDescription)],
                                         isCopyInitializer: Bool, isGenerator: Bool) {
        addAWSClientInitializerSignature(
            fileBuilder: fileBuilder, baseName: baseName, httpClientConfiguration: httpClientConfiguration,
            codeGenerator: codeGenerator, regionDefault: regionDefault,
            endpointDefault: endpointDefault, targetsAPIGateway: targetsAPIGateway,
            clientAttributes: clientAttributes,
            contentTypeAssignment: contentTypeAssignment,
            targetOrVersionParameter: targetOrVersionParameter, isCopyInitializer: isCopyInitializer, isGenerator: isGenerator)
        
        addAWSClientInitializerBody(
            fileBuilder: fileBuilder, contentType: contentType,
            httpClientConfiguration: httpClientConfiguration, baseName: baseName,
            codeGenerator: codeGenerator, regionAssignmentPostfix: regionAssignmentPostfix,
            targetAssignment: targetAssignment, targetsAPIGateway: targetsAPIGateway, sortedOperations: sortedOperations,
            isCopyInitializer: isCopyInitializer, isGenerator: isGenerator)
        fileBuilder.appendLine("}")
    }
    
    private func addAWSClientOperationMetricsParameters(fileBuilder: FileBuilder, baseName: String,
                                              codeGenerator: ServiceModelCodeGenerator,
                                              sortedOperations: [(String, OperationDescription)],
                                              isGenerator: Bool) {
        fileBuilder.appendLine("""
            let operationsReporting: \(baseName)OperationsReporting
            """)
        
        if !isGenerator {
            fileBuilder.appendLine("""
                let invocationsReporting: \(baseName)InvocationsReporting<InvocationReportingType>
                """)
        }
    }
    
    private func addAWSClientOperationMetricsInitializerBody(fileBuilder: FileBuilder, baseName: String,
                                              codeGenerator: ServiceModelCodeGenerator,
                                              sortedOperations: [(String, OperationDescription)],
                                              isCopyInitializer: Bool, isGenerator: Bool) {
        guard case .struct(let clientName, _, _) = clientType else {
            fatalError()
        }
        
        if !isCopyInitializer {
            fileBuilder.appendLine("""
                self.operationsReporting = \(baseName)OperationsReporting(clientName: "\(clientName)", reportingConfiguration: reportingConfiguration)
                """)
        } else {
            fileBuilder.appendLine("""
                self.operationsReporting = operationsReporting
                """)
        }
        
        if !isGenerator {
            fileBuilder.appendLine("""
                self.invocationsReporting = \(baseName)InvocationsReporting(reporting: reporting, operationsReporting: self.operationsReporting)
                """)
        }
    }
    
    private func addAWSClientInitializerBody(
            fileBuilder: FileBuilder,
            contentType: String,
            httpClientConfiguration: HttpClientConfiguration,
            baseName: String,
            codeGenerator: ServiceModelCodeGenerator,
            regionAssignmentPostfix: String,
            targetAssignment: String,
            targetsAPIGateway: Bool,
            sortedOperations: [(String, OperationDescription)],
            isCopyInitializer: Bool, isGenerator: Bool) {
        fileBuilder.incIndent()
        
        if !isCopyInitializer {
            fileBuilder.appendLine("""
                self.eventLoopGroup = AWSClientHelper.getEventLoop(eventLoopGroupProvider: eventLoopProvider)
                let useTLS = requiresTLS ?? AWSHTTPClientDelegate.requiresTLS(forEndpointPort: endpointPort)
                """)
            
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
                self.httpClient = HTTPOperationsClient(
                    endpointHostName: endpointHostName,
                    endpointPort: endpointPort,
                    contentType: contentType,
                    clientDelegate: clientDelegate,
                    connectionTimeoutSeconds: connectionTimeoutSeconds,
                    eventLoopProvider: .shared(self.eventLoopGroup))
                """)
        } else {
            fileBuilder.appendLine("""
                self.eventLoopGroup = eventLoopGroup
                self.httpClient = httpClient
                """)
        }
        
        addAdditionalHttpClients(
            httpClientConfiguration: httpClientConfiguration,
            codeGenerator: codeGenerator, fileBuilder: fileBuilder, isCopyInitializer: isCopyInitializer)
        
        if !isGenerator {
            fileBuilder.appendLine("""
                self.ownsHttpClients = \(String(describing: !isCopyInitializer))
                """)
        }
        
        fileBuilder.appendLine("""
            self.awsRegion = awsRegion\(regionAssignmentPostfix)
            self.service = service
            \(targetAssignment)
            self.credentialsProvider = credentialsProvider
            self.retryConfiguration = retryConfiguration
            """)
        
        if !isGenerator {
            fileBuilder.appendLine("""
                self.reporting = reporting
                """)
        }
        
        if !isCopyInitializer {
            fileBuilder.appendLine("""
                self.retryOnErrorProvider = { error in error.isRetriable() }
                """)
        } else {
            fileBuilder.appendLine("""
                self.retryOnErrorProvider = retryOnErrorProvider
                """)
        }
        
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
        
        addAWSClientOperationMetricsInitializerBody(fileBuilder: fileBuilder, baseName: baseName,
                                                    codeGenerator: codeGenerator, sortedOperations: sortedOperations,
                                                    isCopyInitializer: isCopyInitializer, isGenerator: isGenerator)
        
        fileBuilder.decIndent()
    }
    
    private func addAdditionalHttpClients(
            httpClientConfiguration: HttpClientConfiguration,
            codeGenerator: ServiceModelCodeGenerator,
            fileBuilder: FileBuilder, isCopyInitializer: Bool) {
        httpClientConfiguration.additionalClients?.forEach { (key, _) in
            let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
            
            if !isCopyInitializer {
                let postfix = key.startingWithUppercase
                fileBuilder.appendLine("""
                    self.\(variableName) = HTTPOperationsClient(
                        endpointHostName: endpointHostName,
                        endpointPort: endpointPort,
                        contentType: contentType,
                        clientDelegate: clientDelegateFor\(postfix),
                        connectionTimeoutSeconds: connectionTimeoutSeconds,
                        eventLoopProvider: .shared(self.eventLoopGroup))
                    """)
            } else {
                fileBuilder.appendLine("""
                    self.\(variableName) = \(variableName)
                    """)
            }
        }
    }
    
    private func createDelegate(name: String, fileBuilder: FileBuilder, delegateName: String, errorType: String, parameters: [String]?) {
        guard let concreteParameters = parameters, !concreteParameters.isEmpty else {
            fileBuilder.appendLine("let \(name) = \(delegateName)<\(errorType)>(requiresTLS: useTLS)")
            return
        }
        
        fileBuilder.appendLine("let \(name) = \(delegateName)<\(errorType)>(requiresTLS: useTLS,")
        
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
            codeGenerator: ServiceModelCodeGenerator,
            isGenerator: Bool) {
        fileBuilder.appendLine("""
                let httpClient: HTTPOperationsClient
                """)
        
        httpClientConfiguration.additionalClients?.forEach { (key, _) in
            let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
            fileBuilder.appendLine("""
                let \(variableName): HTTPOperationsClient
                """)
        }
        
        if !isGenerator {
            fileBuilder.appendLine("""
                let ownsHttpClients: Bool
                public let awsRegion: AWSRegion
                public let service: String
                public let apiVersion: String
                public let target: String?
                public let retryConfiguration: HTTPClientRetryConfiguration
                public let retryOnErrorProvider: (SmokeHTTPClient.HTTPClientError) -> Bool
                public let credentialsProvider: CredentialsProvider
                """)
        } else {
            fileBuilder.appendLine("""
                let awsRegion: AWSRegion
                let service: String
                let apiVersion: String
                let target: String?
                let retryConfiguration: HTTPClientRetryConfiguration
                let retryOnErrorProvider: (SmokeHTTPClient.HTTPClientError) -> Bool
                let credentialsProvider: CredentialsProvider
                """)
        }
        
        fileBuilder.appendLine("""

            public let eventLoopGroup: EventLoopGroup
            """)
        
        if !isGenerator {
            fileBuilder.appendLine("""
                public let reporting: InvocationReportingType
                """)
        }
    }
    
    private func addAWSClientBodyMembers(
            fileBuilder: FileBuilder,
            httpClientConfiguration: HttpClientConfiguration,
            codeGenerator: ServiceModelCodeGenerator,
            targetsAPIGateway: Bool,
            isGenerator: Bool) {
        fileBuilder.appendLine("""
                let httpClient: HTTPOperationsClient
                """)
        
        httpClientConfiguration.additionalClients?.forEach { (key, _) in
            let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
            fileBuilder.appendLine("""
                let \(variableName): HTTPOperationsClient
                """)
        }
        
        if !isGenerator {
            fileBuilder.appendLine("""
                let ownsHttpClients: Bool
                public let awsRegion: AWSRegion
                public let service: String
                public let target: String?
                public let retryConfiguration: HTTPClientRetryConfiguration
                public let retryOnErrorProvider: (SmokeHTTPClient.HTTPClientError) -> Bool
                public let credentialsProvider: CredentialsProvider
                """)
        } else {
            fileBuilder.appendLine("""
                let awsRegion: AWSRegion
                let service: String
                let target: String?
                let retryConfiguration: HTTPClientRetryConfiguration
                let retryOnErrorProvider: (SmokeHTTPClient.HTTPClientError) -> Bool
                let credentialsProvider: CredentialsProvider
                """)
        }
        
        fileBuilder.appendLine("""

            public let eventLoopGroup: EventLoopGroup
            """)
    
        if !isGenerator {
            fileBuilder.appendLine("""
                public let reporting: InvocationReportingType
                """)
        }
        
        // If this is an API Gateway client, store the stage
        if targetsAPIGateway {
            fileBuilder.appendLine("""
                    let stage: String?
                    """)
        }
    }
    
    private func addAWSClientInitializerSignature(
            fileBuilder: FileBuilder,
            baseName: String,
            httpClientConfiguration: HttpClientConfiguration,
            codeGenerator: ServiceModelCodeGenerator,
            regionDefault: String,
            endpointDefault: String,
            targetsAPIGateway: Bool,
            clientAttributes: AWSClientAttributes,
            contentTypeAssignment: String,
            targetOrVersionParameter: String,
            isCopyInitializer: Bool, isGenerator: Bool) {
        let accessModifier = isCopyInitializer ? "internal" : "public"
        fileBuilder.appendLine("""
            
            \(accessModifier) init(credentialsProvider: CredentialsProvider, awsRegion: AWSRegion\(regionDefault),
            """)
        
        if !isGenerator {
            fileBuilder.appendLine("""
                            reporting: InvocationReportingType,
                """)
        }
        
        if !isCopyInitializer {
            fileBuilder.appendLine("""
                            endpointHostName: String\(endpointDefault),
                """)
        } else {
            let additionalClients: [String]? = httpClientConfiguration.additionalClients?.map { (key, _) in
                let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
                return "\(variableName): HTTPOperationsClient"
            }
            let additionalClientsString: String
            if let additionalClients = additionalClients {
                additionalClientsString = ", " + additionalClients.joined(separator: ", ")
            } else {
                additionalClientsString = ""
            }
            
            fileBuilder.appendLine("""
                            httpClient: HTTPOperationsClient\(additionalClientsString),
                """)
        }
        
        // If this is an API Gateway client, accept the stage in the constructor
        if targetsAPIGateway {
            if !isCopyInitializer {
                fileBuilder.appendLine("""
                                stage: String? = nil,
                    """)
            } else {
                fileBuilder.appendLine("""
                                stage: String?,
                    """)
            }
        }
        
        if !isCopyInitializer {
            fileBuilder.appendLine("""
                            endpointPort: Int = 443,
                            requiresTLS: Bool? = nil,
                            service: String = "\(clientAttributes.service)",
                            \(contentTypeAssignment),
                            \(targetOrVersionParameter),
                            connectionTimeoutSeconds: Int64 = 10,
                            retryConfiguration: HTTPClientRetryConfiguration = .default,
                            eventLoopProvider: HTTPClient.EventLoopGroupProvider = .createNew,
                            reportingConfiguration: SmokeAWSClientReportingConfiguration<\(baseName)ModelOperations>
                                = SmokeAWSClientReportingConfiguration<\(baseName)ModelOperations>() ) {
                """)
        } else {
            fileBuilder.appendLine("""
                        service: String,
                        \(targetOrVersionParameter),
                        eventLoopGroup: EventLoopGroup,
                        retryOnErrorProvider: @escaping (SmokeHTTPClient.HTTPClientError) -> Bool,
                        retryConfiguration: HTTPClientRetryConfiguration,
                        operationsReporting: \(baseName)OperationsReporting) {
            """)
        }
    }

    public func addAWSClientGeneratorWithReporting(
            fileBuilder: FileBuilder,
            baseName: String,
            codeGenerator: ServiceModelCodeGenerator,
            targetsAPIGateway: Bool,
            clientAttributes: AWSClientAttributes,
            contentType: String) {
        addAWSClientGeneratorWithReporting(fileBuilder: fileBuilder,
                                           baseName: baseName,
                                           codeGenerator: codeGenerator,
                                           targetsAPIGateway: targetsAPIGateway,
                                           contentType: contentType)
    }
 
    public func addAWSClientGeneratorWithReporting(
            fileBuilder: FileBuilder,
            baseName: String,
            codeGenerator: ServiceModelCodeGenerator,
            targetsAPIGateway: Bool,
            contentType: String) {
        guard case .struct(let clientName, _, _) = clientType else {
            fatalError()
        }
        
        fileBuilder.appendLine("""
            
            public func with<NewInvocationReportingType: HTTPClientCoreInvocationReporting>(
                    reporting: NewInvocationReportingType) -> \(clientName)<NewInvocationReportingType> {
                return \(clientName)<NewInvocationReportingType>(
                    credentialsProvider: self.credentialsProvider,
                    awsRegion: self.awsRegion,
                    reporting: reporting,
                    httpClient: self.httpClient,
            """)
        
        let httpClientConfiguration = codeGenerator.customizations.httpClientConfiguration
        
        let additionalClients: [String]? = httpClientConfiguration.additionalClients?.map { (key, _) in
            let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
            return "\(variableName): self.\(variableName)"
        }
        
        additionalClients?.forEach { clientString in
            fileBuilder.appendLine("""
                    \(clientString),
            """)
        }
        
        // If this is an API Gateway client, accept the stage in the constructor
        if targetsAPIGateway {
            fileBuilder.appendLine("""
                        stage: self.stage,
                """)
        }
        
        let targetOrVersionParameter: String
        switch contentType.contentTypeDefaultInputLocation {
        case .query:
            targetOrVersionParameter = "apiVersion: self.apiVersion"
        case .body:
            targetOrVersionParameter = "target: self.target"
        }
        
        fileBuilder.appendLine("""
                service: self.service,
                \(targetOrVersionParameter),
                eventLoopGroup: self.eventLoopGroup,
                retryOnErrorProvider: self.retryOnErrorProvider,
                retryConfiguration: self.retryConfiguration,
                operationsReporting: self.operationsReporting)
        }
        """)
    }
   
    public func addAWSClientGeneratorWithTraceContext(
            fileBuilder: FileBuilder,
            baseName: String,
            codeGenerator: ServiceModelCodeGenerator,
            targetsAPIGateway: Bool,
            clientAttributes: AWSClientAttributes,
            contentType: String) {
        addAWSClientGeneratorWithTraceContext(fileBuilder: fileBuilder,
                                              baseName: baseName,
                                              codeGenerator: codeGenerator,
                                              targetsAPIGateway: targetsAPIGateway,
                                              contentType: contentType)
    }
    
    public func addAWSClientGeneratorWithTraceContext(
            fileBuilder: FileBuilder,
            baseName: String,
            codeGenerator: ServiceModelCodeGenerator,
            targetsAPIGateway: Bool,
            contentType: String) {
        guard case .struct(let clientName, _, _) = clientType else {
            fatalError()
        }
        
        fileBuilder.appendLine("""
            
            public func with<NewTraceContextType: InvocationTraceContext>(
                    logger: Logging.Logger,
                    internalRequestId: String = "none",
                    traceContext: NewTraceContextType,
                    eventLoop: EventLoop? = nil) -> \(clientName)<StandardHTTPClientCoreInvocationReporting<NewTraceContextType>> {
                let reporting = StandardHTTPClientCoreInvocationReporting(
                    logger: logger,
                    internalRequestId: internalRequestId,
                    traceContext: traceContext,
                    eventLoop: eventLoop)
                
                return with(reporting: reporting)
            }
            """)
    }
    
    public func addAWSClientGeneratorWithAWSTraceContext(
            fileBuilder: FileBuilder,
            baseName: String,
            codeGenerator: ServiceModelCodeGenerator,
            targetsAPIGateway: Bool,
            clientAttributes: AWSClientAttributes,
            contentType: String) {
        addAWSClientGeneratorWithLogger(fileBuilder: fileBuilder,
                                        baseName: baseName,
                                        codeGenerator: codeGenerator,
                                        targetsAPIGateway: targetsAPIGateway,
                                        invocationTraceContext: clientAttributes.defaultInvocationTraceContext,
                                        contentType: contentType)
    }
    
    public func addAWSClientGeneratorWithLogger(
            fileBuilder: FileBuilder,
            baseName: String,
            codeGenerator: ServiceModelCodeGenerator,
            targetsAPIGateway: Bool,
            invocationTraceContext: InvocationTraceContextDeclaration,
            contentType: String) {
        guard case .struct(let clientName, _, _) = clientType else {
            fatalError()
        }
        
        fileBuilder.appendLine("""
            
            public func with(
                    logger: Logging.Logger,
                    internalRequestId: String = "none",
                    eventLoop: EventLoop? = nil) -> \(clientName)<StandardHTTPClientCoreInvocationReporting<\(invocationTraceContext.name)>> {
                let reporting = StandardHTTPClientCoreInvocationReporting(
                    logger: logger,
                    internalRequestId: internalRequestId,
                    traceContext: \(invocationTraceContext.name)(),
                    eventLoop: eventLoop)
                
                return with(reporting: reporting)
            }
            """)
    }
}
