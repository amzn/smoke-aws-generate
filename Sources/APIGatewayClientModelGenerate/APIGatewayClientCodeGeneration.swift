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
import ArgumentParser

/**
 The supported generation types.
 */
public enum GenerationType: String, Codable, ExpressibleByArgument {
    case codeGenModel
    case codeGenClient
}

public struct APIGatewayClientCodeGeneration {
    
    public static func generateFromModel<ModelType: ServiceModel>(
        modelFilePath: String,
        modelType: ModelType.Type,
        generationType: GenerationType,
        customizations: CodeGenerationCustomizations,
        applicationDescription: ApplicationDescription,
        modelOverride: ModelOverride?) throws -> ModelType {
            func generatorFunction(codeGenerator: ServiceModelCodeGenerator,
                                   serviceModel: ModelType) throws {
                try codeGenerator.generateFromModel(serviceModel: serviceModel,
                                                    generationType: generationType,
                                                    asyncAwaitAPIs: customizations.asyncAwaitAPIs,
                                                    eventLoopFutureClientAPIs: customizations.eventLoopFutureClientAPIs,
                                                    minimumCompilerSupport: customizations.minimumCompilerSupport,
                                                    clientConfigurationType: customizations.clientConfigurationType)
            }
        
            return try ServiceModelGenerate.generateFromModel(
                    modelFilePath: modelFilePath,
                    customizations: customizations,
                    applicationDescription: applicationDescription,
                    modelOverride: modelOverride,
                    generatorFunction: generatorFunction)
    }
    
    public static func generateWithNoModel(modelLocation: ModelLocation?,
                                           customizations: CodeGenerationCustomizations,
                                           applicationDescription: ApplicationDescription,
                                           modelOverride: ModelOverride?) {
        let generator = ServiceModelCodeGenerator(model: EmptyServiceModel(),
                                                  applicationDescription: applicationDescription,
                                                  customizations: customizations,
                                                  modelOverride: modelOverride)
        
        generator.generateWithNoModel(modelLocation: modelLocation)
    }
}

extension ServiceModelCodeGenerator {
    
    func generateWithNoModel(modelLocation: ModelLocation?) {
        generateClientApplicationFiles(modelLocation: modelLocation)
        generateCodeGenDummyFile(forPackagePostfix: "Model",
                                 plugin: "APIGatewaySwiftGenerateModel")
        generateCodeGenDummyFile(forPackagePostfix: "Client",
                                 plugin: "APIGatewaySwiftGenerateClient")
    }
    
    func generateFromModel<ModelType: ServiceModel>(serviceModel: ModelType,
                                                    generationType: GenerationType,
                                                    asyncAwaitAPIs: CodeGenFeatureStatus,
                                                    eventLoopFutureClientAPIs: CodeGenFeatureStatus,
                                                    minimumCompilerSupport: MinimumCompilerSupport,
                                                    clientConfigurationType: ClientConfigurationType) throws {
        switch generationType {
        case .codeGenModel:
            let awsModelErrorsDelegate = APIGatewayClientModelErrorsDelegate()
            
            generateModelOperationsEnum()
            generateModelStructures()
            generateModelTypes()
            generateModelErrors(delegate: awsModelErrorsDelegate)
            generateDefaultInstances(generationType: .internalTypes)
        case .codeGenClient:
            let clientProtocolDelegate = ClientProtocolDelegate(
                baseName: applicationDescription.baseName,
                asyncAwaitAPIs: asyncAwaitAPIs,
                eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
                minimumCompilerSupport: minimumCompilerSupport)
            let mockClientDelegate = MockClientDelegate(
                baseName: applicationDescription.baseName,
                isThrowingMock: false,
                asyncAwaitAPIs: asyncAwaitAPIs,
                eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
                minimumCompilerSupport: minimumCompilerSupport)
            let throwingClientDelegate = MockClientDelegate(
                baseName: applicationDescription.baseName,
                isThrowingMock: true,
                asyncAwaitAPIs: asyncAwaitAPIs,
                eventLoopFutureClientAPIs: eventLoopFutureClientAPIs,
                minimumCompilerSupport: minimumCompilerSupport)
            let apiGatewayClientDelegate = APIGatewayClientDelegate(
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
            
            generateClient(delegate: clientProtocolDelegate, fileType: .clientImplementation)
            generateClient(delegate: mockClientDelegate, fileType: .clientImplementation)
            generateClient(delegate: throwingClientDelegate, fileType: .clientImplementation)
            generateClient(delegate: apiGatewayClientDelegate, fileType: .clientImplementation)
            generateClient(delegate: apiGatewayClientDelegate, fileType: generatorFileType)
            generateOperationsReporting()
            generateInvocationsReporting()
            generateModelOperationClientInput()
            generateModelOperationClientOutput()
        }
    }
    
    // Due to a current limitation of the SPM plugins for code generators, a placeholder Swift file
    // is required in each package to avoid the package as being seen as empty. These files need to
    // be a Swift file but doesn't require any particular contents.
    func generateCodeGenDummyFile(forPackagePostfix packagePostix: String,
                                  plugin: String) {
        let fileBuilder = FileBuilder()
        let baseFilePath = applicationDescription.baseFilePath
        let fileName = "codegen.swift"
        let filePath = "\(baseFilePath)/Sources/\(applicationDescription.baseName)\(packagePostix)"
        
        fileBuilder.appendLine("""
            //
            //  This package is code generated by the api-gateway-client-generate \(plugin) plugin.
            //
            """)
        
        fileBuilder.write(toFile: fileName,
                          atFilePath: filePath)
    }
}

struct EmptyServiceModel: ServiceModel {
    static func create(data: Data, modelFormat: ModelFormat, modelOverride: ModelOverride?) throws -> EmptyServiceModel {
        return .init()
    }
    
    let serviceDescriptions: [String : ServiceDescription] = [:]
    
    let structureDescriptions: [String : StructureDescription] = [:]
    
    let operationDescriptions: [String : OperationDescription] = [:]
    
    let fieldDescriptions: [String : Fields] = [:]
    
    let errorTypes: Set<String> = []
    
    let typeMappings: [String : String] = [:]
    
    let errorCodeMappings: [String : String] = [:]
}
