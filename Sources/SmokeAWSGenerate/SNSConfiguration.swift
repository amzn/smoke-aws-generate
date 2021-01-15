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
// SNSConfiguration.swift
// SmokeAWSGenerate
//

import Foundation
import ServiceModelEntities

internal struct SNSConfiguration {
    static let modelOverride = ModelOverride(
        codingKeyOverrides: ["AuthorizationErrorException.message": "Message",
                             "EndpointDisabledException.message": "Message",
                             "FilterPolicyLimitExceededException.message": "Message",
                             "InternalErrorException.message": "Message",
                             "InvalidParameterException.message": "Message",
                             "InvalidParameterValueException.message": "Message",
                             "InvalidSecurityException.message": "Message",
                             "KMSAccessDeniedException.message": "Message",
                             "KMSDisabledException.message": "Message",
                             "KMSInvalidStateException.message": "Message",
                             "KMSNotFoundException.message": "Message",
                             "KMSThrottlingException.message": "Message",
                             "NotFoundException.message": "Message",
                             "PlatformApplicationDisabledException.message": "Message",
                             "SubscriptionLimitExceededException.message": "Message",
                             "ThrottledException.message": "Message",
                             "TopicLimitExceededException.message": "Message"])
    
    static let httpClientConfiguration = HttpClientConfiguration(
        retryOnUnknownError: true,
        knownErrorsDefaultRetryBehavior: .fail,
        unretriableUnknownErrors: [],
        retriableUnknownErrors: ["FilterPolicyLimitExceededException", "KMSThrottlingException",
                                 "SubscriptionLimitExceededException", "ThrottledException",
                                 "TopicLimitExceededException"])
    
    static let serviceModelDetails = ServiceModelDetails(
        serviceName: "sns", serviceVersion: "2010-03-31",
        baseName: "SimpleNotification", modelOverride: modelOverride,
        httpClientConfiguration: httpClientConfiguration,
        signAllHeaders: false)
}
