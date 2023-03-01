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
// APIGatewayClientCodeGeneration.swift
// APIGatewayClientModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import ServiceModelGenerate
import SmokeAWSModelGenerate

/**
 The supported generation types.
 */
public enum GenerationType: String, Codable {
    case codeGenModel
    case codeGenClient
}

public struct APIGatewayClientCodeGeneration {
    public static func generateFromModel<ModelType: ServiceModel>(
        modelFilePath: String,
        modelType: ModelType.Type,
        generationType: GenerationType,
        modelTargetName: String, clientTargetName: String,
        customizations: CodeGenerationCustomizations,
        applicationDescription: ApplicationDescription,
        modelOverride: ModelOverride<ModelType.OverridesType>?) throws
    -> ModelType {
        let targetSupport = ModelAndClientTargetSupport(modelTargetName: modelTargetName,
                                                        clientTargetName: clientTargetName)
        
        return try ServiceModelGenerate.generateFromModel(
            modelFilePath: modelFilePath,
            customizations: customizations,
            applicationDescription: applicationDescription,
            modelOverride: modelOverride,
            targetSupport: targetSupport) { (codeGenerator, serviceModel) in
                try codeGenerator.generateFromModel(serviceModel: serviceModel,
                                                    generationType: generationType,
                                                    asyncAwaitAPIs: customizations.asyncAwaitAPIs,
                                                    eventLoopFutureClientAPIs: customizations.eventLoopFutureClientAPIs,
                                                    minimumCompilerSupport: customizations.minimumCompilerSupport,
                                                    clientConfigurationType: customizations.clientConfigurationType)
            }
    }
    
    public static func generateFromModel<ModelType: ServiceModel>(
        modelFilePaths: [String],
        modelType: ModelType.Type,
        generationType: GenerationType,
        modelTargetName: String, clientTargetName: String,
        customizations: CodeGenerationCustomizations,
        applicationDescription: ApplicationDescription,
        modelOverride: ModelOverride<ModelType.OverridesType>?) throws {
            let targetSupport = ModelAndClientTargetSupport(modelTargetName: modelTargetName,
                                                            clientTargetName: clientTargetName)
            
            _ = try ServiceModelGenerate.generateFromModel(
                    modelFilePaths: modelFilePaths,
                    customizations: customizations,
                    applicationDescription: applicationDescription,
                    modelOverride: modelOverride,
                    targetSupport: targetSupport) { (codeGenerator, serviceModel: ModelType) in
                        try codeGenerator.generateFromModel(serviceModel: serviceModel,
                                                            generationType: generationType,
                                                            asyncAwaitAPIs: customizations.asyncAwaitAPIs,
                                                            eventLoopFutureClientAPIs: customizations.eventLoopFutureClientAPIs,
                                                            minimumCompilerSupport: customizations.minimumCompilerSupport,
                                                            clientConfigurationType: customizations.clientConfigurationType)
                    }
    }
    
    public static func generateFromModel<ModelType: ServiceModel>(
        modelDirectoryPaths: [String], fileExtension: String,
        modelType: ModelType.Type,
        generationType: GenerationType,
        modelTargetName: String, clientTargetName: String,
        customizations: CodeGenerationCustomizations,
        applicationDescription: ApplicationDescription,
        modelOverride: ModelOverride<ModelType.OverridesType>?) throws {
            let targetSupport = ModelAndClientTargetSupport(modelTargetName: modelTargetName,
                                                            clientTargetName: clientTargetName)
            
            _ = try ServiceModelGenerate.generateFromModel(
                    modelDirectoryPaths: modelDirectoryPaths,
                    fileExtension: fileExtension,
                    customizations: customizations,
                    applicationDescription: applicationDescription,
                    modelOverride: modelOverride,
                    targetSupport: targetSupport) { (codeGenerator, serviceModel: ModelType) in
                        try codeGenerator.generateFromModel(serviceModel: serviceModel,
                                                            generationType: generationType,
                                                            asyncAwaitAPIs: customizations.asyncAwaitAPIs,
                                                            eventLoopFutureClientAPIs: customizations.eventLoopFutureClientAPIs,
                                                            minimumCompilerSupport: customizations.minimumCompilerSupport,
                                                            clientConfigurationType: customizations.clientConfigurationType)
                    }
    }
    
    public static func generateWithNoModel(modelLocation: ModelLocation,
                                           modelTargetName: String, clientTargetName: String,
                                           modelPackageDependency: ModelPackageDependency?,
                                           applicationDescription: ApplicationDescription,
                                           fileHeader: String?,
                                           clientCodeGenerator: ClientCodeGenerator = .this) {
        let targetSupport = ModelAndClientTargetSupport(modelTargetName: modelTargetName,
                                                        clientTargetName: clientTargetName)
        
        let codeGen = APIGatewayClientCodeGenerator(applicationDescription: applicationDescription, fileHeader: fileHeader,
                                                    targetSupport: targetSupport)
        
        codeGen.generateClientApplicationFiles(modelLocation: modelLocation,
                                               modelPackageDependency: modelPackageDependency,
                                               clientCodeGenerator: clientCodeGenerator)
        codeGen.generateCodeGenDummyFile(targetName: modelTargetName,
                                         plugin: clientCodeGenerator.modelCodeGenPluginName)
        codeGen.generateCodeGenDummyFile(targetName: clientTargetName,
                                         plugin: clientCodeGenerator.clientCodeGenPluginName)
    }
}

struct APIGatewayClientCodeGenerator<TargetSupportType> {
    let applicationDescription: ApplicationDescription
    let fileHeader: String?
    let targetSupport: TargetSupportType
    
    // Due to a current limitation of the SPM plugins for code generators, a placeholder Swift file
    // is required in each package to avoid the package as being seen as empty. These files need to
    // be a Swift file but doesn't require any particular contents.
    func generateCodeGenDummyFile(targetName: String,
                                  plugin: String) {
        let fileBuilder = FileBuilder()
        let baseFilePath = applicationDescription.baseFilePath
        let fileName = "codegen.swift"
        let filePath = "\(baseFilePath)/Sources/\(targetName)"
        
        fileBuilder.appendLine("""
            //
            //  This package is code generated by the api-gateway-client-generate \(plugin) plugin.
            //
            """)
        
        fileBuilder.write(toFile: fileName,
                          atFilePath: filePath)
    }
}

extension ServiceModelCodeGenerator where TargetSupportType: ModelTargetSupport & ClientTargetSupport {
    
    func generateFromModel(serviceModel: ModelType,
                           generationType: GenerationType,
                           asyncAwaitAPIs: CodeGenFeatureStatus,
                           eventLoopFutureClientAPIs: CodeGenFeatureStatus,
                           minimumCompilerSupport: MinimumCompilerSupport,
                           clientConfigurationType: ClientConfigurationType) throws {
        switch generationType {
        case .codeGenModel:
            let awsModelErrorsDelegate = APIGatewayClientModelErrorsDelegate()
            
            generateModelOperationsEnum(delegate: awsModelErrorsDelegate)
            generateModelStructures()
            generateModelTypes()
            generateModelErrors(delegate: awsModelErrorsDelegate)
            generateDefaultInstances(generationType: .internalTypes)
        case .codeGenClient:
            let clientProtocolDelegate = ClientProtocolDelegate<ModelType, TargetSupportType>(
                baseName: applicationDescription.baseName,
                asyncAwaitAPIs: asyncAwaitAPIs,
                eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
                minimumCompilerSupport: minimumCompilerSupport)
            let mockClientDelegate = MockAWSClientDelegate<ModelType, TargetSupportType>(
                baseName: applicationDescription.baseName,
                isThrowingMock: false,
                asyncAwaitAPIs: asyncAwaitAPIs,
                eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
                minimumCompilerSupport: minimumCompilerSupport)
            let throwingClientDelegate = MockAWSClientDelegate<ModelType, TargetSupportType>(
                baseName: applicationDescription.baseName,
                isThrowingMock: true,
                asyncAwaitAPIs: asyncAwaitAPIs,
                eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
                minimumCompilerSupport: minimumCompilerSupport)
            let apiGatewayClientDelegate = APIGatewayClientDelegate<ModelType, TargetSupportType>(
                baseName: applicationDescription.baseName,
                asyncAwaitAPIs: asyncAwaitAPIs,
                eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
                minimumCompilerSupport: minimumCompilerSupport,
                contentType: "application/json", signAllHeaders: false)
            
            let generatorFileType: ClientFileType
            switch clientConfigurationType {
            case .configurationObject:
                generatorFileType = .clientConfiguration
            case .generator:
                generatorFileType = .clientGenerator
            }
            
            generateAWSClient(delegate: clientProtocolDelegate, fileType: .clientImplementation)
            generateAWSClient(delegate: mockClientDelegate, fileType: .clientImplementation)
            generateAWSClient(delegate: throwingClientDelegate, fileType: .clientImplementation)
            generateAWSClient(delegate: apiGatewayClientDelegate, fileType: .clientImplementation)
            generateAWSClient(delegate: apiGatewayClientDelegate, fileType: generatorFileType)
            generateAWSOperationsReporting()
            generateAWSInvocationsReporting()
            generateModelOperationClientInput()
            generateModelOperationClientOutput()
        }
    }
}
