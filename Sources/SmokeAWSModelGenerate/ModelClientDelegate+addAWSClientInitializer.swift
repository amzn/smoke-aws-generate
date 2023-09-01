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

public enum DelegateStatementType {
    case localVariable
    case fromConfig
    case instanceVariableDeclaration
    case instanceVariableAssignment
}

extension ModelClientDelegate {
    func addAWSClientInitializerAndMembers(fileBuilder: FileBuilder, baseName: String,
                                           clientAttributes: AWSClientAttributes,
                                           codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
                                           targetsAPIGateway: Bool,
                                           contentType: String,
                                           sortedOperations: [(String, OperationDescription)],
                                           defaultInvocationTraceContext: InvocationTraceContextDeclaration,
                                           entityType: ClientEntityType) {
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
        let targetAssignmentFromConfig: String
        let targetAssignmentFromOperationsClient: String
        let contentTypeAssignment: String
        
        // Use a specific initializer for queries
        switch contentType.contentTypeDefaultInputLocation {
        case .query:
            addAWSClientQueryMembers(
                fileBuilder: fileBuilder, contentType: contentType, baseName: baseName,
                httpClientConfiguration: httpClientConfiguration,
                codeGenerator: codeGenerator, entityType: entityType)
            
            // accept the api version rather than the target
            targetOrVersionParameterNormalConstructor = "apiVersion: String = \"\(clientAttributes.apiVersion)\""
            targetOrVersionParameterCopyConstructor = "apiVersion: String"
            targetAssignment = "self.target = nil"
            targetAssignmentFromConfig = "self.target = nil"
            targetAssignmentFromOperationsClient = "self.target = nil"
            
            // use 'application/octet-stream' as the content type
            contentTypeAssignment = "contentType: String = \"application/octet-stream\""
        case .body:
            addAWSClientBodyMembers(
                fileBuilder: fileBuilder, contentType: contentType, baseName: baseName,
                httpClientConfiguration: httpClientConfiguration,
                codeGenerator: codeGenerator, targetsAPIGateway: targetsAPIGateway, entityType: entityType)
            
            // accept the target and pass it to the AWS client
            targetOrVersionParameterNormalConstructor = "target: String? = \(targetValue)"
            targetOrVersionParameterCopyConstructor = "target: String?"
            targetAssignment = "self.target = target"
            targetAssignmentFromConfig = "self.target = config.target"
            targetAssignmentFromOperationsClient = "self.target = operationsClient.config.target"
            
            // use the content type from the client attributes as the default
            contentTypeAssignment = "contentType: String = \"\(clientAttributes.contentType)\""
        }
        
        let initializerType: InitializerType
        switch entityType {
        case .clientImplementation:
            initializerType = .standard
        case .configurationObject, .operationsClient:
            initializerType = .genericTraceContextType
        case .clientGenerator:
            initializerType = .forGenerator
        }
        
        addClientOperationMetricsParameters(fileBuilder: fileBuilder, baseName: baseName,
                                            codeGenerator: codeGenerator, sortedOperations: sortedOperations,
                                            entityType: entityType)
        
        addAWSClientInitializer(fileBuilder: fileBuilder, baseName: baseName, clientAttributes: clientAttributes,
                                codeGenerator: codeGenerator, endpointDefault: endpointDefault, regionDefault: regionDefault,
                                regionAssignmentPostfix: regionAssignmentPostfix, targetsAPIGateway: targetsAPIGateway,
                                contentType: contentType, contentTypeAssignment: contentTypeAssignment,
                                targetAssignment: targetAssignment, httpClientConfiguration: httpClientConfiguration,
                                targetOrVersionParameter: targetOrVersionParameterNormalConstructor, sortedOperations: sortedOperations,
                                entityType: entityType, initializerType: initializerType)
        
        if !entityType.isGenerator {
            addAWSClientInitializer(fileBuilder: fileBuilder, baseName: baseName, clientAttributes: clientAttributes,
                                    codeGenerator: codeGenerator, endpointDefault: endpointDefault, regionDefault: regionDefault,
                                    regionAssignmentPostfix: regionAssignmentPostfix, targetsAPIGateway: targetsAPIGateway,
                                    contentType: contentType, contentTypeAssignment: contentTypeAssignment,
                                    targetAssignment: targetAssignment, httpClientConfiguration: httpClientConfiguration,
                                    targetOrVersionParameter: targetOrVersionParameterNormalConstructor, sortedOperations: sortedOperations,
                                    entityType: entityType, initializerType: .usesDefaultReportingType(defaultInvocationTraceContext: defaultInvocationTraceContext))
            
            if case .clientImplementation = entityType {
                // add the internal copy initializer
                addAWSClientInitializer(fileBuilder: fileBuilder, baseName: baseName, clientAttributes: clientAttributes,
                                        codeGenerator: codeGenerator, endpointDefault: endpointDefault, regionDefault: regionDefault,
                                        regionAssignmentPostfix: regionAssignmentPostfix, targetsAPIGateway: targetsAPIGateway,
                                        contentType: contentType, contentTypeAssignment: contentTypeAssignment,
                                        targetAssignment: targetAssignment, httpClientConfiguration: httpClientConfiguration,
                                        targetOrVersionParameter: targetOrVersionParameterCopyConstructor, sortedOperations: sortedOperations,
                                        entityType: entityType, initializerType: .copyInitializer)
            }
        }
        
        addOperationsClientConfigInitializer(fileBuilder: fileBuilder, entityType: entityType)
        
        // if this is the client implementation where the configuration object and operations client are also
        // being generated. Add initializers create a client implementation from these types.
        if case .clientImplementation(initializationStructs: let initializationStructsOptional) = entityType,
                let initializationStructs = initializationStructsOptional {
            addClientInitializerFromConfigWithInvocationAttributes(fileBuilder: fileBuilder,
                                                                   configurationObjectName: initializationStructs.configurationObjectName)
            
            addAWSClientInitializer(fileBuilder: fileBuilder, baseName: baseName, clientAttributes: clientAttributes,
                                    codeGenerator: codeGenerator, endpointDefault: endpointDefault, regionDefault: regionDefault,
                                    regionAssignmentPostfix: regionAssignmentPostfix, targetsAPIGateway: targetsAPIGateway,
                                    contentType: contentType, contentTypeAssignment: contentTypeAssignment,
                                    targetAssignment: targetAssignmentFromConfig, httpClientConfiguration: httpClientConfiguration,
                                    targetOrVersionParameter: targetOrVersionParameterNormalConstructor, sortedOperations: sortedOperations,
                                    entityType: entityType,
                                    initializerType: .traceContextTypeFromConfig(configurationObjectName: initializationStructs.configurationObjectName))
            
            addClientInitializerFromOperationsWithInvocationAttributes(fileBuilder: fileBuilder,
                                                                       operationsClientName: initializationStructs.operationsClientName)
            
            addAWSClientInitializer(fileBuilder: fileBuilder, baseName: baseName, clientAttributes: clientAttributes,
                                    codeGenerator: codeGenerator, endpointDefault: endpointDefault, regionDefault: regionDefault,
                                    regionAssignmentPostfix: regionAssignmentPostfix, targetsAPIGateway: targetsAPIGateway,
                                    contentType: contentType, contentTypeAssignment: contentTypeAssignment,
                                    targetAssignment: targetAssignmentFromOperationsClient, httpClientConfiguration: httpClientConfiguration,
                                    targetOrVersionParameter: targetOrVersionParameterNormalConstructor, sortedOperations: sortedOperations,
                                    entityType: entityType,
                                    initializerType: .traceContextTypeFromOperationsClient(operationsClientName: initializationStructs.operationsClientName))
        }
    }
    
    private func addAWSClientInitializer(fileBuilder: FileBuilder, baseName: String,
                                         clientAttributes: AWSClientAttributes,
                                         codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
                                         endpointDefault: String, regionDefault: String,
                                         regionAssignmentPostfix: String, targetsAPIGateway: Bool,
                                         contentType: String, contentTypeAssignment: String, targetAssignment: String,
                                         httpClientConfiguration: HttpClientConfiguration,
                                         targetOrVersionParameter: String,
                                         sortedOperations: [(String, OperationDescription)],
                                         entityType: ClientEntityType,
                                         initializerType: InitializerType) {
        addAWSClientInitializerSignature(
            fileBuilder: fileBuilder, baseName: baseName, httpClientConfiguration: httpClientConfiguration,
            codeGenerator: codeGenerator, regionDefault: regionDefault,
            endpointDefault: endpointDefault, targetsAPIGateway: targetsAPIGateway,
            clientAttributes: clientAttributes,
            contentTypeAssignment: contentTypeAssignment,
            targetOrVersionParameter: targetOrVersionParameter, entityType: entityType, initializerType: initializerType)
        
        addAWSClientInitializerBody(
            fileBuilder: fileBuilder, contentType: contentType,
            httpClientConfiguration: httpClientConfiguration, baseName: baseName,
            codeGenerator: codeGenerator, regionAssignmentPostfix: regionAssignmentPostfix,
            targetAssignment: targetAssignment, targetsAPIGateway: targetsAPIGateway, sortedOperations: sortedOperations,
            entityType: entityType, initializerType: initializerType)
        fileBuilder.appendLine("}")
    }
    
    private func addDefaultReportingTypeConfigurationObjectBody(fileBuilder: FileBuilder,
                                                                defaultReportingType: InvocationTraceContextDeclaration) {
        fileBuilder.appendLine("""
            self.init(credentialsProvider: credentialsProvider,
                      awsRegion: awsRegion,
                      endpointHostName: endpointHostName,
                      stage: stage,
                      endpointPort: endpointPort,
                      requiresTLS: requiresTLS,
                      service: service,
                      contentType: contentType,
                      target: target,
                      traceContext: \(defaultReportingType.name)(),
                      timeoutConfiguration: timeoutConfiguration,
                      connectionPoolConfiguration: connectionPoolConfiguration,
                      retryConfiguration: retryConfiguration,
                      eventLoopProvider: eventLoopProvider,
                      reportingConfiguration: reportingConfiguration)
            """)
    }
    
    private func addOperationClientInitializerBody(fileBuilder: FileBuilder,
                                                   configurationObjectName: String,
                                                   traceContextValue: String) {
        fileBuilder.appendLine("""
            self.config = \(configurationObjectName)(
                credentialsProvider: credentialsProvider,
                awsRegion: awsRegion,
                endpointHostName: endpointHostName,
                stage: stage,
                endpointPort: endpointPort,
                requiresTLS: requiresTLS,
                service: service,
                contentType: contentType,
                target: target,
                ignoreInvocationEventLoop: ignoreInvocationEventLoop,
                traceContext: \(traceContextValue),
                timeoutConfiguration: timeoutConfiguration,
                connectionPoolConfiguration: connectionPoolConfiguration,
                retryConfiguration: retryConfiguration,
                eventLoopProvider: eventLoopProvider,
                reportingConfiguration: reportingConfiguration)
            self.httpClient = self.config.createHTTPOperationsClient()
            """)
    }
    
    private func addAWSClientInitializerBody(
            fileBuilder: FileBuilder,
            contentType: String,
            httpClientConfiguration: HttpClientConfiguration,
            baseName: String,
            codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
            regionAssignmentPostfix: String,
            targetAssignment: String,
            targetsAPIGateway: Bool,
            sortedOperations: [(String, OperationDescription)],
            entityType: ClientEntityType,
            initializerType: InitializerType) {
        fileBuilder.incIndent()
                
        if case .usesDefaultReportingType(let defaultReportingType) = initializerType, case .configurationObject = entityType {
            addDefaultReportingTypeConfigurationObjectBody(fileBuilder: fileBuilder,
                                                           defaultReportingType: defaultReportingType)
            fileBuilder.decIndent()
            return
        } else if case .operationsClient(let configurationObjectName) = entityType {
            let traceContextValue: String
            if case .usesDefaultReportingType(let defaultReportingType) = initializerType {
                traceContextValue = defaultReportingType.name + "()"
            } else {
                traceContextValue = "traceContext"
            }
            
            addOperationClientInitializerBody(fileBuilder: fileBuilder,
                                              configurationObjectName: configurationObjectName,
                                              traceContextValue: traceContextValue)
            fileBuilder.decIndent()
            return
        }
                
        let connectionTimeoutEqualityLine: String
        if case .standard = initializerType {
            connectionTimeoutEqualityLine = "connectionTimeoutSeconds: connectionTimeoutSeconds"
        } else {
            connectionTimeoutEqualityLine = "timeoutConfiguration: timeoutConfiguration"
        }
        
        if !initializerType.isCopyInitializer {
            switch initializerType {
            case .standard, .forGenerator, .copyInitializer, .genericTraceContextType, .usesDefaultReportingType:
                fileBuilder.appendLine("""
                    self.eventLoopGroup = AWSClientHelper.getEventLoop(eventLoopGroupProvider: eventLoopProvider)
                    let useTLS = requiresTLS ?? AWSHTTPClientDelegate.requiresTLS(forEndpointPort: endpointPort)
                    """)
            case .traceContextTypeFromConfig:
                fileBuilder.appendLine("""
                    self.eventLoopGroup = eventLoop ?? config.eventLoopGroup
                    """)
            case .traceContextTypeFromOperationsClient:
                fileBuilder.appendLine("""
                    self.eventLoopGroup = eventLoop ?? operationsClient.config.eventLoopGroup
                    """)
            }
            
            let statementType: DelegateStatementType
            switch initializerType {
            case .standard, .forGenerator, .copyInitializer, .usesDefaultReportingType:
                statementType = .localVariable
            case .genericTraceContextType:
                statementType = .instanceVariableAssignment
            case .traceContextTypeFromConfig, .traceContextTypeFromOperationsClient:
                statementType = .fromConfig
            }
            
            switch contentType.contentTypePayloadType {
            case .xml:
                addXmlDelegate(fileBuilder: fileBuilder,
                               httpClientConfiguration: httpClientConfiguration,
                               baseName: baseName, statementType: statementType)
            case .json:
                addJsonDelegate(fileBuilder: fileBuilder,
                                httpClientConfiguration: httpClientConfiguration,
                                baseName: baseName, statementType: statementType)
            }
            
            if case .usesDefaultReportingType(let defaultInvocationTraceContext) = initializerType {
                fileBuilder.appendLine("""
                    let reporting = StandardHTTPClientCoreInvocationReporting(
                        logger: logger,
                        internalRequestId: internalRequestId,
                        traceContext: \(defaultInvocationTraceContext.name)(),
                        eventLoop: self.eventLoopGroup.next())
                    """)
            }
            
            if entityType.isGenerator || entityType.isClientImplementation {
                switch initializerType {
                case .standard, .forGenerator, .copyInitializer, .genericTraceContextType, .usesDefaultReportingType:
                    fileBuilder.appendLine("""
                        self.httpClient = HTTPOperationsClient(
                            endpointHostName: endpointHostName,
                            endpointPort: endpointPort,
                            contentType: contentType,
                            clientDelegate: clientDelegate,
                            \(connectionTimeoutEqualityLine),
                            eventLoopProvider: .shared(self.eventLoopGroup),
                            connectionPoolConfiguration: connectionPoolConfiguration)
                        """)
                case .traceContextTypeFromConfig:
                    fileBuilder.appendLine("""
                        self.httpClient = httpClient ?? config.createHTTPOperationsClient(eventLoopOverride: eventLoop)
                        """)
                case .traceContextTypeFromOperationsClient:
                    fileBuilder.appendLine("""
                        self.httpClient = operationsClient.httpClient
                        """)
                }
            }
        } else {
            fileBuilder.appendLine("""
                self.eventLoopGroup = eventLoopGroup
                self.httpClient = httpClient
                """)
        }
        
        if entityType.isGenerator || entityType.isClientImplementation {
            addAdditionalHttpClients(
                httpClientConfiguration: httpClientConfiguration,
                codeGenerator: codeGenerator, fileBuilder: fileBuilder, initializerType: initializerType,
                connectionTimeoutEqualityLine: connectionTimeoutEqualityLine)
            
            switch initializerType {
            case .standard, .copyInitializer, .genericTraceContextType, .usesDefaultReportingType:
                fileBuilder.appendLine("""
                    self.ownsHttpClients = \(String(describing: !initializerType.isCopyInitializer))
                    """)
            case .traceContextTypeFromConfig:
                fileBuilder.appendLine("""
                    if httpClient != nil {
                        self.ownsHttpClients = false
                    } else {
                        self.ownsHttpClients = true
                    }
                    """)
            case .traceContextTypeFromOperationsClient:
                fileBuilder.appendLine("""
                    self.ownsHttpClients = false
                    """)
            case .forGenerator:
                break
                //nothing to do
            }
        }
                
        if case .genericTraceContextType = initializerType {
            fileBuilder.appendLine("""
                self.endpointHostName = endpointHostName
                self.endpointPort = endpointPort
                self.contentType = contentType
                self.traceContext = traceContext
                self.timeoutConfiguration = timeoutConfiguration
                self.connectionPoolConfiguration = connectionPoolConfiguration
                """)
        }
                
        let inputPrefix: String
        switch initializerType {
        case .standard, .forGenerator, .copyInitializer, .genericTraceContextType, .usesDefaultReportingType:
            inputPrefix = ""
        case .traceContextTypeFromConfig:
            inputPrefix = "config."
        case .traceContextTypeFromOperationsClient:
            inputPrefix = "operationsClient.config."
        }
        
        fileBuilder.appendLine("""
            self.awsRegion = \(inputPrefix)awsRegion\(regionAssignmentPostfix)
            self.service = \(inputPrefix)service
            \(targetAssignment)
            self.credentialsProvider = \(inputPrefix)credentialsProvider
            self.retryConfiguration = \(inputPrefix)retryConfiguration
            """)
        
        if case .traceContextTypeFromConfig = initializerType {
            fileBuilder.appendLine("""
                self.reporting = StandardHTTPClientCoreInvocationReporting(
                    logger: logger,
                    internalRequestId: internalRequestId,
                    traceContext: config.traceContext,
                    eventLoop: eventLoop,
                    outwardsRequestAggregator: outwardsRequestAggregator)
                """)
        } else if case .traceContextTypeFromOperationsClient = initializerType {
            fileBuilder.appendLine("""
                self.reporting = StandardHTTPClientCoreInvocationReporting(
                    logger: logger,
                    internalRequestId: internalRequestId,
                    traceContext: operationsClient.config.traceContext,
                    eventLoop: eventLoop,
                    outwardsRequestAggregator: outwardsRequestAggregator)
                """)
        } else if entityType.isClientImplementation {
            fileBuilder.appendLine("""
                self.reporting = reporting
                """)
        }
        
        if entityType.isClientImplementation || entityType.isGenerator {
            if !initializerType.isCopyInitializer {
                fileBuilder.appendLine("""
                    self.retryOnErrorProvider = { error in error.isRetriable() }
                    """)
            } else {
                fileBuilder.appendLine("""
                    self.retryOnErrorProvider = retryOnErrorProvider
                    """)
            }
        }
        
        // If this is a query, set the apiVersion
        if case .query = contentType.contentTypeDefaultInputLocation {
            fileBuilder.appendLine("""
                self.apiVersion = \(inputPrefix)apiVersion
                """)
        }
        
        // If this is an API Gateway client, store the stage
        if targetsAPIGateway {
            fileBuilder.appendLine("""
                self.stage = \(inputPrefix)stage
                """)
        }
                
        if case .genericTraceContextType = initializerType {
            fileBuilder.appendLine("""
                self.reportingConfiguration = reportingConfiguration
                self.ignoreInvocationEventLoop = ignoreInvocationEventLoop
                                
                self.reportingProvider = { (logger, internalRequestId, eventLoop) in
                    return StandardHTTPClientCoreInvocationReporting(
                        logger: logger,
                        internalRequestId: internalRequestId,
                        traceContext: traceContext,
                        eventLoop: eventLoop)
                }
                """)
        }
        
        addClientOperationMetricsInitializerBody(fileBuilder: fileBuilder, baseName: baseName,
                                                 codeGenerator: codeGenerator, sortedOperations: sortedOperations,
                                                 entityType: entityType,
                                                 initializerType: initializerType, inputPrefix: inputPrefix)
        
        fileBuilder.decIndent()
    }
    
    private func addAdditionalHttpClients(
            httpClientConfiguration: HttpClientConfiguration,
            codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
            fileBuilder: FileBuilder, initializerType: InitializerType,
            connectionTimeoutEqualityLine: String) {
        httpClientConfiguration.additionalClients?.forEach { (key, _) in
            let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
            
            if !initializerType.isCopyInitializer {
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
    
    private func createDelegate(name: String, fileBuilder: FileBuilder, delegateName: String, errorType: String, parameters: [String]?,
                                statementType: DelegateStatementType) {
        let statementPrefix: String
        switch statementType {
        case .localVariable:
            statementPrefix = "let "
        case .instanceVariableDeclaration:
            fileBuilder.appendLine("internal let \(name): \(delegateName)<\(errorType)>")
            return
        case .instanceVariableAssignment:
            statementPrefix = "self."
        case .fromConfig:
            return
        }

        guard let concreteParameters = parameters, !concreteParameters.isEmpty else {
            fileBuilder.appendLine("\(statementPrefix)\(name) = \(delegateName)<\(errorType)>(requiresTLS: useTLS)")
            return
        }
        
        fileBuilder.appendLine("\(statementPrefix)\(name) = \(delegateName)<\(errorType)>(requiresTLS: useTLS,")
        
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
    
    public func addXmlDelegate(
            fileBuilder: FileBuilder,
            httpClientConfiguration: HttpClientConfiguration,
            baseName: String,
            statementType: DelegateStatementType) {
        let delegateName = httpClientConfiguration.clientDelegateNameOverride
            ?? "XMLAWSHttpClientDelegate"
        // pass a QueryXMLAWSHttpClientDelegate to the AWS client
        createDelegate(name: "clientDelegate", fileBuilder: fileBuilder, delegateName: delegateName, errorType: "\(baseName)Error",
                       parameters: httpClientConfiguration.clientDelegateParameters, statementType: statementType)
        fileBuilder.appendEmptyLine()
    
        httpClientConfiguration.additionalClients?.forEach { (key, value) in
            let postfix = key.startingWithUppercase
            let additionalDelegateName = value.clientDelegateNameOverride
                ?? "XMLAWSHttpClientDelegate"
            
            createDelegate(name: "clientDelegateFor\(postfix)", fileBuilder: fileBuilder, delegateName: additionalDelegateName,
                           errorType: "\(baseName)Error", parameters: value.clientDelegateParameters, statementType: statementType)
            fileBuilder.appendEmptyLine()
        }
    }
    
    public func addJsonDelegate(
            fileBuilder: FileBuilder,
            httpClientConfiguration: HttpClientConfiguration,
            baseName: String,
            statementType: DelegateStatementType) {
        let delegateName = httpClientConfiguration.clientDelegateNameOverride
                ?? "JSONAWSHttpClientDelegate"
        // pass a JSONAWSHttpClientDelegate to the AWS client
        createDelegate(name: "clientDelegate", fileBuilder: fileBuilder, delegateName: delegateName, errorType: "\(baseName)Error",
                       parameters: httpClientConfiguration.clientDelegateParameters, statementType: statementType)
        fileBuilder.appendEmptyLine()
    
        httpClientConfiguration.additionalClients?.forEach { (key, value) in
            let postfix = key.startingWithUppercase
            let additionalDelegateName = value.clientDelegateNameOverride
                ?? "JSONAWSHttpClientDelegate"
            
            createDelegate(name: "clientDelegateFor\(postfix)", fileBuilder: fileBuilder, delegateName: additionalDelegateName,
                           errorType: "\(baseName)Error", parameters: value.clientDelegateParameters, statementType: statementType)
            fileBuilder.appendEmptyLine()
        }
    }
    
    private func addAWSClientQueryMembers(
            fileBuilder: FileBuilder,
            contentType: String,
            baseName: String,
            httpClientConfiguration: HttpClientConfiguration,
            codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
            entityType: ClientEntityType) {
        fileBuilder.appendLine("""
            let clientName = "\(baseName)Client"
            """)
                
        if entityType.isClientImplementation || entityType.isGenerator {
            fileBuilder.appendLine("""
                    let httpClient: HTTPOperationsClient
                    """)
            
            httpClientConfiguration.additionalClients?.forEach { (key, _) in
                let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
                fileBuilder.appendLine("""
                    let \(variableName): HTTPOperationsClient
                    """)
            }
        }
                
        switch entityType {
        case .clientImplementation:
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
        case .configurationObject:
            fileBuilder.appendLine("""
                public let endpointHostName: String
                public let endpointPort: Int
                public let contentType: String
                public let timeoutConfiguration: HTTPClient.Configuration.Timeout
                public let connectionPoolConfiguration: HTTPClient.Configuration.ConnectionPool?
                public let awsRegion: AWSRegion
                public let service: String
                public let apiVersion: String
                public let target: String?
                public let retryConfiguration: HTTPClientRetryConfiguration
                public let traceContext: InvocationReportingType.TraceContextType
                public let reportingConfiguration: HTTPClientReportingConfiguration<\(baseName)ModelOperations>
                public let ignoreInvocationEventLoop: Bool
                """)
        case .clientGenerator:
            fileBuilder.appendLine("""
                let awsRegion: AWSRegion
                let service: String
                let apiVersion: String
                let target: String?
                let retryConfiguration: HTTPClientRetryConfiguration
                let retryOnErrorProvider: (SmokeHTTPClient.HTTPClientError) -> Bool
                let credentialsProvider: CredentialsProvider
                """)
        case .operationsClient(let configurationObjectName):
            fileBuilder.appendLine("""
                public let config: \(configurationObjectName)<InvocationReportingType>
                public let httpClient: HTTPOperationsClient
                """)
            
            return
        }
        
        fileBuilder.appendLine("""

            public let eventLoopGroup: EventLoopGroup
            """)
        
        if case .clientImplementation = entityType {
            fileBuilder.appendLine("""
                public let reporting: InvocationReportingType
                """)
        }
                
        if case .configurationObject = entityType {
            fileBuilder.appendEmptyLine()
            switch contentType.contentTypePayloadType {
            case .xml:
                addXmlDelegate(fileBuilder: fileBuilder,
                               httpClientConfiguration: httpClientConfiguration,
                               baseName: baseName, statementType: .instanceVariableDeclaration)
            case .json:
                addJsonDelegate(fileBuilder: fileBuilder,
                                httpClientConfiguration: httpClientConfiguration,
                                baseName: baseName, statementType: .instanceVariableDeclaration)
            }
            
            fileBuilder.appendLine("""
                internal let reportingProvider: (Logger, String, EventLoop?) -> InvocationReportingType
                internal let credentialsProvider: CredentialsProvider
                """)
        }
    }
    
    private func addAWSClientBodyMembers(
            fileBuilder: FileBuilder,
            contentType: String,
            baseName: String,
            httpClientConfiguration: HttpClientConfiguration,
            codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
            targetsAPIGateway: Bool,
            entityType: ClientEntityType) {
        fileBuilder.appendLine("""
            let clientName = "\(baseName)Client"
            """)
                
        if entityType.isClientImplementation || entityType.isGenerator {
            fileBuilder.appendLine("""
                    let httpClient: HTTPOperationsClient
                    """)
            
            httpClientConfiguration.additionalClients?.forEach { (key, _) in
                let variableName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
                fileBuilder.appendLine("""
                    let \(variableName): HTTPOperationsClient
                    """)
            }
        }
                
        switch entityType {
        case .clientImplementation:
            fileBuilder.appendLine("""
                let ownsHttpClients: Bool
                public let awsRegion: AWSRegion
                public let service: String
                public let target: String?
                public let retryConfiguration: HTTPClientRetryConfiguration
                public let retryOnErrorProvider: (SmokeHTTPClient.HTTPClientError) -> Bool
                public let credentialsProvider: CredentialsProvider
                """)
        case .configurationObject:
            fileBuilder.appendLine("""
                public let endpointHostName: String
                public let endpointPort: Int
                public let contentType: String
                public let timeoutConfiguration: HTTPClient.Configuration.Timeout
                public let connectionPoolConfiguration: HTTPClient.Configuration.ConnectionPool?
                public let awsRegion: AWSRegion
                public let service: String
                public let target: String?
                public let retryConfiguration: HTTPClientRetryConfiguration
                public let traceContext: InvocationReportingType.TraceContextType
                public let reportingConfiguration: HTTPClientReportingConfiguration<\(baseName)ModelOperations>
                public let ignoreInvocationEventLoop: Bool
                """)
        case .clientGenerator:
            fileBuilder.appendLine("""
                let awsRegion: AWSRegion
                let service: String
                let target: String?
                let retryConfiguration: HTTPClientRetryConfiguration
                let retryOnErrorProvider: (SmokeHTTPClient.HTTPClientError) -> Bool
                let credentialsProvider: CredentialsProvider
                """)
        case .operationsClient(let configurationObjectName):
            fileBuilder.appendLine("""
                public let config: \(configurationObjectName)<InvocationReportingType>
                public let httpClient: HTTPOperationsClient
                """)
            
            return
        }
        
        fileBuilder.appendLine("""

            public let eventLoopGroup: EventLoopGroup
            """)
    
        if case .clientImplementation = entityType {
            fileBuilder.appendLine("""
                public let reporting: InvocationReportingType
                """)
        }
        
        // If this is an API Gateway client, store the stage
        if targetsAPIGateway {
            fileBuilder.appendLine("""
                    public let stage: String?
                    """)
        }
                
        if case .configurationObject = entityType {
            fileBuilder.appendEmptyLine()
            switch contentType.contentTypePayloadType {
            case .xml:
                addXmlDelegate(fileBuilder: fileBuilder,
                               httpClientConfiguration: httpClientConfiguration,
                               baseName: baseName, statementType: .instanceVariableDeclaration)
            case .json:
                addJsonDelegate(fileBuilder: fileBuilder,
                                httpClientConfiguration: httpClientConfiguration,
                                baseName: baseName, statementType: .instanceVariableDeclaration)
            }
            
            fileBuilder.appendLine("""
                internal let reportingProvider: (Logger, String, EventLoop?) -> InvocationReportingType
                internal let credentialsProvider: CredentialsProvider
                """)
        }
    }
    
    private func addAWSClientInitializerSignature(
            fileBuilder: FileBuilder,
            baseName: String,
            httpClientConfiguration: HttpClientConfiguration,
            codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
            regionDefault: String,
            endpointDefault: String,
            targetsAPIGateway: Bool,
            clientAttributes: AWSClientAttributes,
            contentTypeAssignment: String,
            targetOrVersionParameter: String,
            entityType: ClientEntityType,
            initializerType: InitializerType) {
        let accessModifier = initializerType.isCopyInitializer ? "internal" : "public"
                
        if case .traceContextTypeFromConfig(let configurationObjectName) = initializerType {
            fileBuilder.appendLine("""
                
                \(accessModifier) init<TraceContextType: InvocationTraceContext>(
                    config: \(configurationObjectName)<StandardHTTPClientCoreInvocationReporting<TraceContextType>>,
                    logger: Logging.Logger = Logger(label: "\(baseName)Client"),
                    internalRequestId: String = "none",
                    eventLoop: EventLoop? = nil,
                    httpClient: HTTPOperationsClient? = nil,
                    outwardsRequestAggregator: OutwardsRequestAggregator? = nil)
                where InvocationReportingType == StandardHTTPClientCoreInvocationReporting<TraceContextType> {
                """)
            return
        } else if case .traceContextTypeFromOperationsClient(let operationsClientName) = initializerType {
            fileBuilder.appendLine("""
                
                \(accessModifier) init<TraceContextType: InvocationTraceContext>(
                            operationsClient: \(operationsClientName)<StandardHTTPClientCoreInvocationReporting<TraceContextType>>,
                            logger: Logging.Logger = Logger(label: "\(baseName)Client"),
                            internalRequestId: String = "none",
                            eventLoop: EventLoop? = nil,
                            outwardsRequestAggregator: OutwardsRequestAggregator? = nil)
                where InvocationReportingType == StandardHTTPClientCoreInvocationReporting<TraceContextType> {
                """)
            return
        }
                
        let genericParameters: String
        if case .genericTraceContextType = initializerType {
            genericParameters = "<TraceContextType: InvocationTraceContext>"
        } else {
            genericParameters = ""
        }
                
        fileBuilder.appendLine("""
            
            \(accessModifier) init\(genericParameters)(credentialsProvider: CredentialsProvider, awsRegion: AWSRegion\(regionDefault),
            """)
        
        if case .clientImplementation = entityType, !initializerType.isDefaultReportingType {
            fileBuilder.appendLine("""
                            reporting: InvocationReportingType,
                """)
        }
                
        if initializerType.isDefaultReportingType && entityType.isClientImplementation {
            fileBuilder.appendLine("""
                            logger: Logging.Logger = Logger(label: "\(baseName)Client"),
                            internalRequestId: String = "none",
                """)
        }
        
        if !initializerType.isCopyInitializer {
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
            if !initializerType.isCopyInitializer {
                fileBuilder.appendLine("""
                                stage: String? = nil,
                    """)
            } else {
                fileBuilder.appendLine("""
                                stage: String?,
                    """)
            }
        }
        
        if !initializerType.isCopyInitializer {
            fileBuilder.appendLine("""
                            endpointPort: Int = 443,
                            requiresTLS: Bool? = nil,
                            service: String = "\(clientAttributes.service)",
                            \(contentTypeAssignment),
                            \(targetOrVersionParameter),
                """)
            
            switch entityType {
            case .clientImplementation, .clientGenerator:
                // nothing to do
                break
            case .configurationObject, .operationsClient:
                fileBuilder.appendLine("""
                        ignoreInvocationEventLoop: Bool = false,
                """)
            }
            
            if !entityType.isClientImplementation && !entityType.isGenerator {
                if case .genericTraceContextType = initializerType {
                    fileBuilder.appendLine("""
                                    traceContext: TraceContextType,
                        """)
                }
                
                fileBuilder.appendLine("""
                                timeoutConfiguration: HTTPClient.Configuration.Timeout = .init(),
                    """)
            } else {
                if case .standard = initializerType {
                    fileBuilder.appendLine("""
                                    connectionTimeoutSeconds: Int64 = 10,
                        """)
                } else {
                    fileBuilder.appendLine("""
                                    timeoutConfiguration: HTTPClient.Configuration.Timeout = .init(),
                        """)
                }
            }
            
            fileBuilder.appendLine("""
                            connectionPoolConfiguration: HTTPClient.Configuration.ConnectionPool? = nil,
                            retryConfiguration: HTTPClientRetryConfiguration = .default,
                            eventLoopProvider: HTTPClient.EventLoopGroupProvider = .singleton,
                            reportingConfiguration: HTTPClientReportingConfiguration<\(baseName)ModelOperations>
                """)
            
            switch initializerType {
            case .standard, .forGenerator, .copyInitializer:
                fileBuilder.appendLine("""
                                    = HTTPClientReportingConfiguration<\(baseName)ModelOperations>() ) {
                    """)
            case .genericTraceContextType, .traceContextTypeFromConfig:
                fileBuilder.appendLine("""
                                    = HTTPClientReportingConfiguration<\(baseName)ModelOperations>() )
                    where InvocationReportingType == StandardHTTPClientCoreInvocationReporting<TraceContextType> {
                    """)
            case .usesDefaultReportingType(let defaultInvocationTraceContext):
                fileBuilder.appendLine("""
                                    = HTTPClientReportingConfiguration<\(baseName)ModelOperations>() )
                    where InvocationReportingType == StandardHTTPClientCoreInvocationReporting<\(defaultInvocationTraceContext.name)> {
                    """)
            case .traceContextTypeFromOperationsClient:
                fileBuilder.appendLine("""
                                    = HTTPClientReportingConfiguration<\(baseName)ModelOperations>() )
                    where InvocationReportingType == StandardHTTPClientCoreInvocationReporting<OperationsClientInvocationReportingType.TraceContextType> {
                    """)
            }
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
            codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
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
            codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
            targetsAPIGateway: Bool,
            contentType: String) {
        guard case .struct(let clientName, _, _) = clientType else {
            fatalError()
        }
        
        fileBuilder.appendLine("""
            
            public func with<NewInvocationReportingType: HTTPClientCoreInvocationReporting>(
                    reporting: NewInvocationReportingType) -> Generic\(clientName)<NewInvocationReportingType> {
                return Generic\(clientName)<NewInvocationReportingType>(
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
    
    public func addAWSClientGeneratorWithAWSTraceContext(
            fileBuilder: FileBuilder,
            baseName: String,
            codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
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
            codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
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
                    eventLoop: EventLoop? = nil) -> Generic\(clientName)<StandardHTTPClientCoreInvocationReporting<\(invocationTraceContext.name)>> {
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
