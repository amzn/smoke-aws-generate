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
// AppConfigConfiguration.swift
// SmokeAWSGenerate
//

import Foundation
import ServiceModelEntities

private let errorTypeHTTPHeaderName = "x-amzn-ErrorType"

internal struct AppConfigConfiguration {
    static let modelOverride = ModelOverride(
        namedFieldOverride: ["Tags": "[:] as [String:String]"],
        codingKeyOverrides: ["AppConfigError.message": "Message"],
        additionalErrors: ["AccessDeniedException"])
    
    static let additionalHttpClient = AdditionalHttpClient(
        clientDelegateNameOverride: "DataAWSHttpClientDelegate",
        clientDelegateParameters: ["errorTypeHTTPHeader: \"\(errorTypeHTTPHeaderName)\""],
        operations: ["GetConfiguration", "GetHostedConfigurationVersion"])
    
    static let httpClientConfiguration = HttpClientConfiguration(
        retryOnUnknownError: true,
        knownErrorsDefaultRetryBehavior: .fail,
        unretriableUnknownErrors: [],
        retriableUnknownErrors: [],
        clientDelegateParameters: ["errorTypeHTTPHeader: \"\(errorTypeHTTPHeaderName)\""],
        additionalClients: ["dataHttpClient": additionalHttpClient])
    
    static let serviceModelDetails = ServiceModelDetails(
        serviceName: "appconfig",
        serviceVersion: "2019-10-09",
        baseName: "AppConfig",
        modelOverride: modelOverride,
        httpClientConfiguration: httpClientConfiguration,
        signAllHeaders: false)
}
