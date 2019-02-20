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
// ShapeAttributes.swift
// CoralToJSONServiceModel
//

import Foundation
import ServiceModelEntities

/**
 Enumeration that is used to decode the C2J model into
 either Fields or StructureDescription.
 */
internal enum ShapeAttributes: Decodable {
    case field(Fields)
    case structure(StructureStructureAttributes)
    
    enum CodingKeys: String, CodingKey {
        case type
        case enumValues = "enum"
        case max
        case min
        case pattern
        case required
        case members
        case key
        case value
        case member
        case documentation
        case payload
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        let payloadAsMember = try values.decodeIfPresent(String.self, forKey: .payload)
        
        switch type {
        case "string":
            self = try .getStringShapeAttribute(values: values)
        case "long":
            self = try .getLongShapeAttribute(values: values)
        case "integer":
            self = try .getIntShapeAttribute(values: values)
        case "double", "float":
            self = try .getDoubleShapeAttribute(values: values)
        case "boolean":
            self = .field(.boolean)
        case "timestamp":
            self = .field(.timestamp)
        case "blob":
            self = .field(.data)
        case "map":
            self = try .getMapShapeAttribute(values: values)
        case "list":
            self = try .getListShapeAttribute(values: values)
        case "structure":
            self = try .getStructureShapeAttribute(values: values,
                                                   payloadAsMember: payloadAsMember)
        default:
            fatalError("Unknown shape type '\(type)'")
        }
    }
    
    static func getStringShapeAttribute(
            values: KeyedDecodingContainer<ShapeAttributes.CodingKeys>) throws
    -> ShapeAttributes {
        let min = try values.decodeIfPresent(Int.self, forKey: .min)
        let max = try values.decodeIfPresent(Int.self, forKey: .max)
        let pattern = try values.decodeIfPresent(String.self, forKey: .pattern)
        let enumValues = try values.decodeIfPresent([String].self, forKey: .enumValues)
        
        let lengthConstraint = LengthRangeConstraint<Int>(
            minimum: min, maximum: max)
        let valueContraints = enumValues?.map { value in
            return (name: value, value: value)
            } ?? []
        
        return .field(.string(regexConstraint: pattern,
                              lengthConstraint: lengthConstraint,
                              valueConstraints: valueContraints))
    }
    
    static func getLongShapeAttribute(
        values: KeyedDecodingContainer<ShapeAttributes.CodingKeys>) throws
    -> ShapeAttributes {
        let min = try values.decodeIfPresent(Int.self, forKey: .min)
        let max = try values.decodeIfPresent(Int.self, forKey: .max)
        
        let numericRangeConstraint = NumericRangeConstraint<Int>(
            minimum: min, maximum: max)
        
        return .field(.long(rangeConstraint: numericRangeConstraint))
    }
    
    static func getIntShapeAttribute(
        values: KeyedDecodingContainer<ShapeAttributes.CodingKeys>) throws
    -> ShapeAttributes {
        let min = try values.decodeIfPresent(Int.self, forKey: .min)
        let max = try values.decodeIfPresent(Int.self, forKey: .max)
        
        let numericRangeConstraint = NumericRangeConstraint<Int>(
            minimum: min, maximum: max)
        
        return .field(.integer(rangeConstraint: numericRangeConstraint))
    }
    
    static func getDoubleShapeAttribute(
        values: KeyedDecodingContainer<ShapeAttributes.CodingKeys>) throws
    -> ShapeAttributes {
        let min = try values.decodeIfPresent(Double.self, forKey: .min)
        let max = try values.decodeIfPresent(Double.self, forKey: .max)
        
        let numericRangeConstraint = NumericRangeConstraint<Double>(
                    minimum: min, maximum: max)
        
        return .field(.double(rangeConstraint: numericRangeConstraint))
    }
    
    static func getStructureShapeAttribute(
            values: KeyedDecodingContainer<ShapeAttributes.CodingKeys>,
            payloadAsMember: String?) throws -> ShapeAttributes {
        let members = try values.decode([String: ShapeReference].self, forKey: .members)
        let required = try values.decodeIfPresent(Set<String>.self, forKey: .required) ?? []
        let documentation = try values.decodeIfPresent(String.self, forKey: .documentation)
        
        // the map of members is returned without ordering; create a predictable ordering
        let sortedMembers = members.sorted { (left, right) -> Bool in left.key < right.key }
        
        var transformedMembers: [String: Member] = [:]
        var memberLocations: [String: MemberLocation] = [:]
        for (index, member) in sortedMembers.enumerated() {
            // ignore deprecated members
            if member.value.deprecated ?? false {
                continue
            }
            
            let transformedMember = Member(value: member.value.shape,
                                           position: index,
                                           locationName: member.value.locationName,
                                           required: required.contains(member.key),
                                           documentation: member.value.documentation)
            
            transformedMembers[member.key] = transformedMember
            
            if let location = member.value.location {
                memberLocations[member.key] = location
            }
        }
        
        let structure = StructureDescription(members: transformedMembers,
                                             documentation: documentation)
        let attributes = StructureStructureAttributes(
            structureDescription: structure,
            memberLocations: memberLocations,
            payloadAsMember: payloadAsMember)
        return .structure(attributes)
    }
    
    static func getListShapeAttribute(
            values: KeyedDecodingContainer<ShapeAttributes.CodingKeys>) throws
    -> ShapeAttributes {
        let listType = try values.decode(ShapeReference.self, forKey: .member)
        
        let min = try values.decodeIfPresent(Int.self, forKey: .min)
        let max = try values.decodeIfPresent(Int.self, forKey: .max)
        
        let lengthConstraint = LengthRangeConstraint<Int>(
            minimum: min, maximum: max)
        
        return .field(.list(type: listType.shape, lengthConstraint: lengthConstraint))
    }
    
    static func getMapShapeAttribute(
        values: KeyedDecodingContainer<ShapeAttributes.CodingKeys>) throws
    -> ShapeAttributes {
        let keyType = try values.decode(ShapeReference.self, forKey: .key)
        let valueType = try values.decode(ShapeReference.self, forKey: .value)
        
        let min = try values.decodeIfPresent(Int.self, forKey: .min)
        let max = try values.decodeIfPresent(Int.self, forKey: .max)
        
        let lengthConstraint = LengthRangeConstraint<Int>(
            minimum: min, maximum: max)
        
        return .field(.map(keyType: keyType.shape, valueType: valueType.shape,
                           lengthConstraint: lengthConstraint))
    }
}
