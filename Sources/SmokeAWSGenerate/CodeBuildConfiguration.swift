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
// CodeBuildConfiguration.swift
// SmokeAWSGenerate
//

import Foundation
import ServiceModelEntities

internal struct CodeBuildConfiguration {
    static let modelOverride = ModelOverride(matchCase: [])
    
    static let httpClientConfiguration = HttpClientConfiguration(
        retryOnUnknownError: true,
        knownErrorsDefaultRetryBehavior: .fail,
        unretriableUnknownErrors: [],
        retriableUnknownErrors: [])
    
    static let serviceModelDetails = ServiceModelDetails(
        serviceName: "codebuild", serviceVersion: "2016-10-06",
        baseName: "CodeBuild", modelOverride: modelOverride,
        httpClientConfiguration: httpClientConfiguration,
        signAllHeaders: false)
}
