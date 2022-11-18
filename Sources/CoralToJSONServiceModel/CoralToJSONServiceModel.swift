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
// CoralToJSONServiceModel.swift
// CoralToJSONServiceModel
//

import Foundation
import ServiceModelEntities

/**
 Struct that models the Coral To JSON model.
 */
public struct CoralToJSONServiceModel: Decodable {
    public let metadata: Metadata
    public let serviceDescriptions: [String: ServiceDescription]
    public let operationDescriptions: [String: OperationDescription]
    public let fieldDescriptions: [String: Fields]
    public let structureDescriptions: [String: StructureDescription]
    public let errorTypes: Set<String>
    public var typeMappings: [String: String]
    public var errorCodeMappings: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case metadata
        case operations
        case shapes
    }
    
    private static func getServiceDescriptionFromOperations(_ operations: [String: Operation]) -> ServiceDescription {
        let operationNames = Array(operations.keys)
        
        return ServiceDescription(operations: operationNames)
    }
    
    private static func getOperationInputDescription(
            input: String?,
            operationName: String,
            contentType: String,
            structureMemberLocations: [String: [String: MemberLocation]],
            structurePayloadAsMember: [String: String]) -> OperationInputDescription {
        let memberLocations: [String: MemberLocation]
        let payloadAsMember: String?
        if let currentInput = input {
            guard let currentMemberLocations = structureMemberLocations[currentInput] else {
                fatalError("No member locations for operation '\(operationName)' input '\(currentInput)'")
            }
            
            memberLocations = currentMemberLocations
            payloadAsMember = structurePayloadAsMember[currentInput]
        } else {
            memberLocations = [:]
            payloadAsMember = nil
        }
        
        let defaultInputLocation: DefaultInputLocation = contentType.contentTypeDefaultInputLocation
        var pathFields: [String] = []
        var queryFields: [String] = []
        var additionalHeaderFields: [String] = []

        memberLocations.forEach { (memberName, location) in
            switch location {
            case .uri:
                pathFields.append(memberName)
            case .query:
                queryFields.append(memberName)
            case .header, .headers:
                additionalHeaderFields.append(memberName)
            }
        }

        return OperationInputDescription(pathFields: pathFields,
                                         queryFields: queryFields,
                                         additionalHeaderFields: additionalHeaderFields,
                                         defaultInputLocation: defaultInputLocation,
                                         payloadAsMember: payloadAsMember)
    }
    
    private static func getOperationOutputDescription(
            output: String?,
            operationName: String,
            structureMemberLocations: [String: [String: MemberLocation]],
            structurePayloadAsMember: [String: String]) -> OperationOutputDescription {
        let memberLocations: [String: MemberLocation]
        let payloadAsMember: String?
        if let currentOutput = output {
            guard let currentMemberLocations = structureMemberLocations[currentOutput] else {
                fatalError("No member locations for operation '\(operationName)' input '\(currentOutput)'")
            }
            
            memberLocations = currentMemberLocations
            payloadAsMember = structurePayloadAsMember[currentOutput]
        } else {
            memberLocations = [:]
            payloadAsMember = nil
        }
        
        var headerFields: [String] = []

        memberLocations.forEach { (memberName, location) in
            switch location {
            case .uri, .query:
                fatalError("Invalid output location")
            case .header, .headers:
                headerFields.append(memberName)
            }
        }

        return OperationOutputDescription(headerFields: headerFields,
                                          payloadAsMember: payloadAsMember)
    }
    
    private static func getOperationDescriptionsFromOperations(
        _ operations: [String: Operation], contentType: String,
        structureMemberLocations: [String: [String: MemberLocation]],
        structurePayloadAsMember: [String: String])
        -> (operations: [String: OperationDescription], resultWrappers: [ResultWrapperMapping]) {
            var resultWrappers: [ResultWrapperMapping] = []
        
            let operationDescriptions: [String: OperationDescription] =
                operations.mapValues { operation in
                let input = operation.input?.shape
                let output: String?
            
                if let operationOutput = operation.output, let resultWrapper = operationOutput.resultWrapper {
                    let wrappingStructName = "\(operationOutput.shape)For\(operation.name)"
                    
                    let resultWrapperMapping = ResultWrapperMapping(wrappingStructName: wrappingStructName,
                                                                    originalStructName: operationOutput.shape,
                                                                    resultWrapperName: resultWrapper)
                    
                    resultWrappers.append(resultWrapperMapping)
                    output = wrappingStructName
                } else {
                    output = operation.output?.shape
                }
                let httpVerb = operation.http?.method
                let httpUrl = operation.http?.requestUri
                let errors = operation.errors?.map { error in (type: error.shape, code: 400) } ?? []
                    
                let inputDescription = getOperationInputDescription(
                    input: input, operationName: operation.name,
                    contentType: contentType,
                    structureMemberLocations: structureMemberLocations,
                    structurePayloadAsMember: structurePayloadAsMember)
                let outputDescription = getOperationOutputDescription(
                    output: operation.output?.shape, operationName: operation.name,
                    structureMemberLocations: structureMemberLocations,
                    structurePayloadAsMember: structurePayloadAsMember)
                    
                let operationDescription = OperationDescription(
                    input: input,
                    output: output,
                    httpVerb: httpVerb,
                    httpUrl: httpUrl,
                    errors: errors,
                    inputDescription: inputDescription,
                    outputDescription: outputDescription)
                
                return operationDescription
            }
        
            return (operations: operationDescriptions, resultWrappers: resultWrappers)
    }
    
    private static func getErrorTypesFromOperations(_ operations: [String: Operation]) -> Set<String> {
        var errorTypes: Set<String> = []
        
        operations.values.forEach { operation in operation.errors?.forEach { error in errorTypes.insert(error.shape) } }
        
        return errorTypes
    }
    
    private static func getErrorCodeMappings(_ errorTypes: Set<String>, shapes: [String: ShapeAttributes]) -> [String: String] {
        var errorCodeMapping: [String: String] = [:]
        
        errorTypes.forEach { errorType in
            if let shape = shapes[errorType],
                case let .structure(attributes) = shape, let errorAttributes = attributes.errorAttributes {
                errorCodeMapping[errorType] = errorAttributes.code
            }
        }
        
        return errorCodeMapping
    }
    
    private static func getFieldsFromShapes(_ shapes: [String: ShapeAttributes]) -> [String: Fields] {
        
        let fields: [String: Fields?] = shapes.mapValues { shape in
            guard case .field(let field) = shape else {
                return nil
            }
            
            return field
        }
        
        return fields.filter { (_, value) in value != nil }
            .mapValues { value in value! }
    }
    
    private static func getStructuresFromShapes(_ shapes: [String: ShapeAttributes]) -> [String: StructureDescription] {
        
        let fields: [String: StructureDescription?] = shapes.mapValues { shape in
            guard case .structure(let attributes) = shape else {
                return nil
            }
            
            return attributes.structureDescription
        }
        
        return fields.filter { (_, value) in value != nil }
            .mapValues { value in value! }
    }
    
    private static func getStructureMemberLocationsFromShapes(_ shapes: [String: ShapeAttributes]) -> [String: [String: MemberLocation]] {
        
        let fields: [String: [String: MemberLocation]?] = shapes.mapValues { shape in
            guard case .structure(let attributes) = shape else {
                return nil
            }
            
            return attributes.memberLocations
        }
        
        return fields.filter { (_, value) in value != nil }
            .mapValues { value in value! }
    }
    
    private static func getStructurePayloadAsMemberFromShapes(_ shapes: [String: ShapeAttributes]) -> [String: String] {
        
        let fields: [String: String?] = shapes.mapValues { shape in
            guard case .structure(let attributes) = shape else {
                return nil
            }
            
            return attributes.payloadAsMember
        }
        
        return fields.filter { (_, value) in value != nil }
            .mapValues { value in value! }
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        metadata = try values.decode(Metadata.self, forKey: .metadata)
        let operations = try values.decode([String: Operation].self, forKey: .operations)
        let shapeAttributes = try values.decode([String: ShapeAttributes].self, forKey: .shapes)
        
        let serviceDescription = CoralToJSONServiceModel.getServiceDescriptionFromOperations(operations)
        serviceDescriptions = [metadata.endpointPrefix: serviceDescription]
        
        let contentType = "application/x-amz-\(metadata.protocolName)"
        
        let structureMemberLocations = CoralToJSONServiceModel.getStructureMemberLocationsFromShapes(shapeAttributes)
        let structurePayloadAsMember =
            CoralToJSONServiceModel.getStructurePayloadAsMemberFromShapes(shapeAttributes)
        
        let (newOperationDescriptions, resultWrappers) = CoralToJSONServiceModel.getOperationDescriptionsFromOperations(
            operations,
            contentType: contentType,
            structureMemberLocations: structureMemberLocations,
            structurePayloadAsMember: structurePayloadAsMember)
        operationDescriptions = newOperationDescriptions
        fieldDescriptions = CoralToJSONServiceModel.getFieldsFromShapes(shapeAttributes)
        errorTypes = CoralToJSONServiceModel.getErrorTypesFromOperations(operations)
        
        errorCodeMappings = CoralToJSONServiceModel.getErrorCodeMappings(errorTypes, shapes: shapeAttributes)
        
        var modelStructureDescriptions = CoralToJSONServiceModel.getStructuresFromShapes(shapeAttributes)
        
        resultWrappers.forEach { mapping in
            // create a structure for the wrapping structure that has one member which is the result wrapper
            // of the original type
            let wrappingMember = Member(value: mapping.originalStructName, position: 1,
                                        required: true, documentation: nil)
            let wrappingStructureDefinition = StructureDescription(members: [mapping.resultWrapperName: wrappingMember],
                                                                   documentation: nil)
            modelStructureDescriptions[mapping.wrappingStructName] = wrappingStructureDefinition
        }
        structureDescriptions = modelStructureDescriptions
        typeMappings = CoralToJSONServiceModel.getTypeMappings(structureDescriptions: structureDescriptions,
                                                               fieldDescriptions: fieldDescriptions)
    }
}

/// Use CoralToJSONModel as a ServiceModel
extension CoralToJSONServiceModel: ServiceModel {
    public static func create(data: Data, modelFormat: ModelFormat, modelOverride: ModelOverride<OverridesType>?) throws -> CoralToJSONServiceModel {
        let decoder = JSONDecoder()
        
        return try decoder.decode(CoralToJSONServiceModel.self, from: data)
    }
}
