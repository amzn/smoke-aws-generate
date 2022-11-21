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
// S3Configuration.swift
// SmokeAWSGenerate
//

import Foundation
import ServiceModelEntities

internal struct S3Configuration {
    static let additionalHttpClient = AdditionalHttpClient(
        clientDelegateNameOverride: "DataAWSHttpClientDelegate",
        operations: ["PutObject", "UploadPart", "GetObject", "GetObjectTorrent"])
    
    static let httpClientConfiguration = HttpClientConfiguration(
        retryOnUnknownError: true,
        knownErrorsDefaultRetryBehavior: .fail,
        unretriableUnknownErrors: [],
        retriableUnknownErrors: [],
        additionalClients: ["dataHttpClient": additionalHttpClient])
    
    static let modelOverride = ModelOverride<NoModelTypeOverrides>(enumerations:
        EnumerationNaming(usingUpperCamelCase: ["Event"]),
                                             fieldRawTypeOverride: ["Long": CommonConfiguration.intOverride])
    
    static let serviceModelDetails = ServiceModelDetails(
        serviceName: "s3", serviceVersion: "2006-03-01",
        baseName: "S3", modelOverride: modelOverride,
        httpClientConfiguration: httpClientConfiguration,
        signAllHeaders: true)
}
