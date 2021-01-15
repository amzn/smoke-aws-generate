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
// SimpleWorkflowConfiguration.swift
// SmokeAWSGenerate
//

import Foundation
import ServiceModelEntities

internal struct SimpleWorkflowConfiguration {
    static let modelOverride = ModelOverride(
        fieldRawTypeOverride:
            [Fields.timestamp.typeDescription: CommonConfiguration.integerDateOverride,
             "Long": CommonConfiguration.intOverride])
    
    static let httpClientConfiguration = HttpClientConfiguration(
        retryOnUnknownError: true,
        knownErrorsDefaultRetryBehavior: .fail,
        unretriableUnknownErrors: [],
        retriableUnknownErrors: ["LimitExceededFault"])
    
    static let serviceModelDetails = ServiceModelDetails(
        serviceName: "swf", serviceVersion: "2012-01-25",
        baseName: "SimpleWorkflow", modelOverride: modelOverride,
        httpClientConfiguration: httpClientConfiguration,
        signAllHeaders: false)
}
