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
// Metadata.swift
// CoralToJSONServiceModel
//

import Foundation
import ServiceModelEntities

/**
 Struct that models the Metadata of the C2J model.
 */
public struct Metadata: Codable {
    public let apiVersion: String
    public let endpointPrefix: String
    public let globalEndpoint: String?
    public let jsonVersion: String?
    public let protocolName: String
    public let serviceAbbreviation: String?
    public let serviceFullName: String
    public let serviceId: String?
    public let signatureVersion: String
    public let targetPrefix: String?
    public let uid: String?
    
    enum CodingKeys: String, CodingKey {
        case apiVersion
        case endpointPrefix
        case globalEndpoint
        case jsonVersion
        case protocolName = "protocol"
        case serviceAbbreviation
        case serviceFullName
        case serviceId
        case signatureVersion
        case targetPrefix
        case uid
    }
}
