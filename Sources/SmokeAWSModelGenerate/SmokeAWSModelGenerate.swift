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
// SmokeAWSModelGenerate.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import CoralToJSONServiceModel
import ServiceModelGenerate

public struct SmokeAWSModelGenerate {
    
    public static func generateFromModel(
        modelFilePath: String,
        customizations: CodeGenerationCustomizations,
        applicationDescription: ApplicationDescription,
        modelOverride: ModelOverride?,
        signAllHeaders: Bool) throws
    -> CoralToJSONServiceModel {
        return try ServiceModelGenerate.generateFromModel(
            modelFilePath: modelFilePath,
            customizations: customizations,
            applicationDescription: applicationDescription,
            modelOverride: modelOverride) { (codeGenerator, serviceModel) in
                try codeGenerator.generateFromCoralToJSONServiceModel(
                    coralToJSONServiceModel: serviceModel,
                    asyncAwaitAPIs: customizations.asyncAwaitAPIs,
                    signAllHeaders: signAllHeaders)
            }
    }
}

extension ServiceModelCodeGenerator where TargetSupportType: ModelTargetSupport & ClientTargetSupport {
    
    func generateFromCoralToJSONServiceModel(
            coralToJSONServiceModel: CoralToJSONServiceModel,
            asyncAwaitAPIs: CodeGenFeatureStatus,
            signAllHeaders: Bool) throws {
        let awsClientAttributes = coralToJSONServiceModel.getAWSClientAttributes()
        
        let clientProtocolDelegate = ClientProtocolDelegate<TargetSupportType>(
            baseName: applicationDescription.baseName,
            asyncAwaitAPIs: asyncAwaitAPIs)
        let mockClientDelegate = MockAWSClientDelegate<TargetSupportType>(
            baseName: applicationDescription.baseName,
            isThrowingMock: false,
            asyncAwaitAPIs: asyncAwaitAPIs)
        let throwingClientDelegate = MockAWSClientDelegate<TargetSupportType>(
            baseName: applicationDescription.baseName,
            isThrowingMock: true,
            asyncAwaitAPIs: asyncAwaitAPIs)
        let awsClientDelegate = AWSClientDelegate<TargetSupportType>(
            baseName: applicationDescription.baseName,
            clientAttributes: awsClientAttributes,
            signAllHeaders: signAllHeaders,
            asyncAwaitAPIs: asyncAwaitAPIs)
        let awsModelErrorsDelegate = AWSModelErrorsDelegate(awsClientAttributes: awsClientAttributes)
        
        generateAWSClient(delegate: clientProtocolDelegate, fileType: .clientImplementation)
        generateAWSClient(delegate: mockClientDelegate, fileType: .clientImplementation)
        generateAWSClient(delegate: throwingClientDelegate, fileType: .clientImplementation)
        generateAWSClient(delegate: awsClientDelegate, fileType: .clientImplementation)
        generateAWSClient(delegate: awsClientDelegate, fileType: .clientGenerator)
        generateModelOperationsEnum()
        generateAWSOperationsReporting()
        generateAWSInvocationsReporting()
        generateModelOperationClientInput()
        generateModelOperationClientOutput()
        generateModelStructures()
        generateModelTypes()
        generateModelErrors(delegate: awsModelErrorsDelegate)
        generateDefaultInstances(generationType: .internalTypes)
    }
}

public extension ServiceModelCodeGenerator where TargetSupportType: ModelTargetSupport & ClientTargetSupport {
    func generateAWSClient<DelegateType: ModelClientDelegate>(delegate: DelegateType, fileType: ClientFileType)
    where DelegateType.TargetSupportType == TargetSupportType {
        let defaultTraceContextType = DefaultTraceContextType(typeName: "AWSClientInvocationTraceContext",
                                                              importTargetName: "AWSHttp")
        generateClient(delegate: delegate, fileType: fileType, defaultTraceContextType: defaultTraceContextType)
    }
    
    func generateAWSOperationsReporting() {
        let operationsReportingType = OperationsReportingType(
            typeName: "StandardSmokeAWSOperationReporting",
            targetImportName: "AWSCore") { (variableName, thePrefix, fileBuilder) in
                fileBuilder.appendLine("""
                    \(thePrefix)StandardSmokeAWSOperationReporting(
                        clientName: clientName, operation: .\(variableName), configuration: reportingConfiguration)
                    """)
                }
        
        generateOperationsReporting(operationsReportingType: operationsReportingType)
    }
    
    func generateAWSInvocationsReporting() {
        let invocationReportingType = InvocationReportingType(
            typeName: "SmokeAWSHTTPClientInvocationReporting",
            targetImportName: "AWSHttp") { (variableName, thePrefix, fileBuilder) in
                fileBuilder.appendLine("""
                    \(thePrefix)SmokeAWSHTTPClientInvocationReporting(smokeAWSInvocationReporting: reporting,
                        smokeAWSOperationReporting: operationsReporting.\(variableName))
                    """)
                }
        
        generateInvocationsReporting(invocationReportingType: invocationReportingType)
    }
}

public typealias MockAWSClientDelegate = MockClientDelegate

public extension MockAWSClientDelegate {
    init(baseName: String, isThrowingMock: Bool,
         asyncAwaitAPIs: CodeGenFeatureStatus,
         eventLoopFutureClientAPIs: CodeGenFeatureStatus = .enabled,
         minimumCompilerSupport: MinimumCompilerSupport = .unknown) {
        let supportingTargetName: String?
        switch eventLoopFutureClientAPIs {
        case .disabled:
            supportingTargetName = nil
        case .enabled:
            supportingTargetName = "AWSHttp"
        }
        
        self.init(baseName: baseName, isThrowingMock: isThrowingMock,
                  asyncAwaitAPIs: asyncAwaitAPIs,
                  eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
                  supportingTargetName: supportingTargetName,
                  minimumCompilerSupport: minimumCompilerSupport)
    }
}
