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
// ECSConfiguration.swift
// SmokeAWSGenerate
//

import Foundation
import ServiceModelEntities

private let additionalErrors: Set<String> = [
    "AccessDeniedException",
    "IncompleteSignature",
    "InternalFailure",
    "InvalidAction",
    "InvalidClientTokenId",
    "InvalidParameterCombination",
    "InvalidParameterValue",
    "InvalidQueryParameter",
    "MalformedQueryString",
    "MissingAction",
    "MissingAuthenticationToken",
    "MissingParameter",
    "OptInRequired",
    "RequestExpired",
    "ServiceUnavailable",
    "ThrottlingException",
    "ValidationError"]

internal struct CloudFormationConfiguration {
    static let modelOverride = ModelOverride<NoModelTypeOverrides>(enumerations:
        EnumerationNaming(usingUpperCamelCase: ["ChangeSource", "ChangeAction", "ChangeType", "EvaluationType",
                                                "HandlerErrorCode", "Replacement", "RequiresRecreation", "ResourceAttribute"]),
                                             additionalErrors: additionalErrors)
    
    static let httpClientConfiguration = HttpClientConfiguration(
        retryOnUnknownError: true,
        knownErrorsDefaultRetryBehavior: .fail,
        unretriableUnknownErrors: [],
        retriableUnknownErrors: ["ThrottlingException"],
        clientDelegateParameters: ["outputListDecodingStrategy: .collapseListUsingItemTag(\"member\")",
                                   "inputQueryListEncodingStrategy: .expandListWithIndexAndItemTag(itemTag: \"member\")"])
    
    static let serviceModelDetails = ServiceModelDetails(
        serviceName: "cloudformation", serviceVersion: "2010-05-15",
        baseName: "Cloudformation", modelOverride: modelOverride,
        httpClientConfiguration: httpClientConfiguration,
        signAllHeaders: false)
}
