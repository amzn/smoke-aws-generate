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
// HelperStructures.swift
// CoralToJSONServiceModel
//

import Foundation
import ServiceModelEntities

/// Content type for a request using amazon query
let amazonQueryContentType = "application/x-amz-query"
let amazonEC2ContentType = "application/x-amz-ec2"
let amazonRestXmlContentType = "application/x-amz-rest-xml"

public enum PayloadType {
    case json
    case xml
}

extension String {
    public var contentTypePayloadType: PayloadType {
        if self == amazonQueryContentType || self == amazonEC2ContentType
            || self == amazonRestXmlContentType {
            return .xml
        }
        
        return .json
    }
    
    public var contentTypeDefaultInputLocation: DefaultInputLocation {
        if self == amazonQueryContentType || self == amazonEC2ContentType {
            return .query
        }
        
        return .body
    }
}

/**
 Specifies a result wrapper mapping. A result wrapper adds an additional
 structure between an the output structure specified by an operation and
 the fields of that structure.
 
 This is handled by creating a operation-specific structure that has one
 field with the name of the result wrapper and of the original output structure type
 */
internal struct ResultWrapperMapping {
    /// The name of the operation-specific structure.
    let wrappingStructName: String
    /// The name of the original operation output structure
    let originalStructName: String
    /// The name of the result wrapper to be inserted.
    let resultWrapperName: String
}

/**
 Struct that models the HttpBindings of the C2J model.
 */
internal struct HttpBinding: Codable {
    let method: String
    let requestUri: String
}

internal enum MemberLocation: String, Codable {
    case uri
    case query = "querystring"
    case header
    case headers
}

/**
 Struct that models an Operations input, output or error shapes.
 */
internal struct ShapeReference: Codable {
    let shape: String
    let resultWrapper: String?
    let documentation: String?
    let locationName: String?
    let location: MemberLocation?
    let deprecated: Bool?
}

/**
 Struct that models an Operation.
 */
internal struct Operation: Codable {
    let name: String
    let http: HttpBinding?
    let input: ShapeReference?
    let output: ShapeReference?
    let errors: [ShapeReference]?
    let documentation: String?
}

internal struct StructureErrorAttributes: Codable {
    let code: String
    let httpStatusCode: Int
    let senderFault: Bool?
}

internal struct StructureStructureAttributes {
    let structureDescription: StructureDescription
    let memberLocations: [String: MemberLocation]
    let payloadAsMember: String?
    let errorAttributes: StructureErrorAttributes?
}
