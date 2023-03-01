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
// ModelClientDelegate+commonAWSFunctions.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import ServiceModelGenerate
import CoralToJSONServiceModel

extension ModelClientDelegate {
    func addAWSClientCommonFunctions(fileBuilder: FileBuilder, baseName: String,
                                     clientAttributes: AWSClientAttributes,
                                     codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
                                     targetsAPIGateway: Bool,
                                     contentType: String,
                                     sortedOperations: [(String, OperationDescription)],
                                     defaultInvocationTraceContext: InvocationTraceContextDeclaration,
                                     entityType: ClientEntityType,
                                     awsCustomization: AWSCodeGenerationCustomizations) {
        addAWSClientInitializerAndMembers(fileBuilder: fileBuilder,
                                          baseName: baseName,
                                          clientAttributes: clientAttributes,
                                          codeGenerator: codeGenerator,
                                          targetsAPIGateway: targetsAPIGateway,
                                          contentType: contentType,
                                          sortedOperations: sortedOperations,
                                          defaultInvocationTraceContext: defaultInvocationTraceContext,
                                          entityType: entityType,
                                          awsCustomization: awsCustomization)
        
        if entityType.isGenerator {
            addAWSClientGeneratorWithReporting(
                fileBuilder: fileBuilder, baseName: baseName,
                codeGenerator: codeGenerator, targetsAPIGateway: targetsAPIGateway,
                contentType: contentType)
            
            addClientGeneratorWithTraceContext(
                fileBuilder: fileBuilder, baseName: baseName,
                codeGenerator: codeGenerator, targetsAPIGateway: targetsAPIGateway,
                contentType: contentType)
            
            addAWSClientGeneratorWithLogger(
                fileBuilder: fileBuilder, baseName: baseName,
                codeGenerator: codeGenerator, targetsAPIGateway: targetsAPIGateway,
                invocationTraceContext: clientAttributes.defaultInvocationTraceContext, contentType: contentType)
        }
        
        if case .configurationObject = entityType {
            fileBuilder.appendLine("""
                
                internal func createHTTPOperationsClient() -> HTTPOperationsClient {
                    return HTTPOperationsClient(
                        endpointHostName: self.endpointHostName,
                        endpointPort: self.endpointPort,
                        contentType: self.contentType,
                        clientDelegate: self.clientDelegate,
                        runtimeConfig: self.runtimeConfig)
                }
                """)
            
            let httpClientConfiguration = codeGenerator.customizations.httpClientConfiguration
            
            httpClientConfiguration.additionalClients?.forEach { (key, value) in
                let postfix = key.startingWithUppercase
                
                fileBuilder.appendLine("""
                    
                    internal func createHTTPOperationsClientFor\(postfix)() -> HTTPOperationsClient {
                        return HTTPOperationsClient(
                            endpointHostName: self.endpointHostName,
                            endpointPort: self.endpointPort,
                            contentType: self.contentType,
                            clientDelegate: self.clientDelegateFor\(postfix),
                            runtimeConfig: self.runtimeConfig)
                    }
                    """)
            }
        }
    }
}
