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
// AWSClientAttributes.swift
// SmokeAWSModelGenerate
//

import Foundation
import CoralToJSONServiceModel
import ServiceModelCodeGeneration

/**
 Structure that specifies the attributes of an AWS client.
 */
public struct AWSClientAttributes {
    /// The API version of this client.
    public let apiVersion: String
    /// The service name this client is targeting.
    public let service: String
    /// The service target this client is targeting.
    public let target: String?
    /// The request content type used by this client.
    public let contentType: String
    /// If the service has a global endpoint that should be used as its default endpoint.
    public let globalEndpoint: String?
    /// The name of the InvocationTraceContext implementation to use.
    public let defaultInvocationTraceContext: InvocationTraceContextDeclaration
    
    /**
     Initializer.
 
     - Parameters:
        - apiVersion: The API version of this client.
        - service: The service name this client is targeting.
        - target: The service target this client is targeting.
        - contentType: The request content type used by this client.
        - globalEndpoint: If the service has a global endpoint that should be used as its default endpoint.
        - defaultInvocationTraceContextName: The name of the InvocationTraceContext implementation to use.
     */
    public init(apiVersion: String,
                service: String,
                target: String?,
                contentType: String,
                globalEndpoint: String?,
                defaultInvocationTraceContext: InvocationTraceContextDeclaration = InvocationTraceContextDeclaration(name: "AWSClientInvocationTraceContext")) {
        self.apiVersion = apiVersion
        self.service = service
        self.target = target
        self.contentType = contentType
        self.globalEndpoint = globalEndpoint
        self.defaultInvocationTraceContext = defaultInvocationTraceContext
    }
}
