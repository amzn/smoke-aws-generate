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
// SimpleQueueConfiguration.swift
// SmokeAWSGenerate
//

import Foundation
import ServiceModelEntities

internal struct SimpleQueueConfiguration {
    static let overrideInputDescription = OperationInputDescription(
        pathTemplateField: "QueueUrl",
        defaultInputLocation: .query)
    
    static let operationInputOverrides: [String: OperationInputDescription] =
        ["AddPermission": overrideInputDescription,
         "ChangeMessageVisibility": overrideInputDescription,
         "ChangeMessageVisibilityBatch": overrideInputDescription,
         "DeleteMessage": overrideInputDescription,
         "DeleteMessageBatch": overrideInputDescription,
         "DeleteQueue": overrideInputDescription,
         "GetQueueAttributes": overrideInputDescription,
         "ListDeadLetterSourceQueues": overrideInputDescription,
         "ListQueueTags": overrideInputDescription,
         "PurgeQueue": overrideInputDescription,
         "ReceiveMessage": overrideInputDescription,
         "RemovePermission": overrideInputDescription,
         "SendMessage": overrideInputDescription,
         "SendMessageBatch": overrideInputDescription,
         "SetQueueAttributes": overrideInputDescription,
         "TagQueue": overrideInputDescription,
         "UntagQueue": overrideInputDescription]
    
    static let modelOverride = ModelOverride(
        operationInputOverrides: operationInputOverrides,
        codingKeyOverrides: ["ReceiveMessageResult.Messages": "Message",
                             "ChangeMessageVisibilityBatchRequest.Entries": "ChangeMessageVisibilityBatchRequestEntry",
                             "ChangeMessageVisibilityBatchResult.Failed": "BatchResultErrorEntry",
                             "ChangeMessageVisibilityBatchResult.Successful": "ChangeMessageVisibilityBatchResultEntry",
                             "DeleteMessageBatchRequest.Entries": "DeleteMessageBatchRequestEntry",
                             "DeleteMessageBatchResult.Failed": "BatchResultErrorEntry",
                             "DeleteMessageBatchResult.Successful": "DeleteMessageBatchResultEntry",
                             "SendMessageBatchRequest.Entries": "SendMessageBatchRequestEntry",
                             "SendMessageBatchResult.Failed": "BatchResultErrorEntry",
                             "SendMessageBatchResult.Successful": "SendMessageBatchResultEntry",
                             "AddPermissionRequest.AWSAccountIds": "AWSAccountId",
                             "AddPermissionRequest.Actions": "ActionName",
                             "GetQueueAttributesRequest.AttributeNames": "AttributeName",
                             "ListDeadLetterSourceQueuesResult.queueUrls": "QueueUrl",
                             "ListQueuesResult.queueUrls": "QueueUrl",
                             "ReceiveMessageRequest.AttributeNames": "AttributeName",
                             "ReceiveMessageRequest.MessageAttributeNames": "MessageAttributeName",
                             "UntagQueueRequest.TagKeys": "TagKey"],
        requiredOverrides: ["ChangeMessageVisibilityBatchResult.Failed": false,
                            "ChangeMessageVisibilityBatchResult.Successful": false,
                            "DeleteMessageBatchResult.Failed": false,
                            "DeleteMessageBatchResult.Successful": false,
                            "SendMessageBatchResult.Failed": false,
                            "SendMessageBatchResult.Successful": false,
                            "ListDeadLetterSourceQueuesResult.queueUrls": false,
                            "ListQueuesResult.queueUrls": false])
    
    static let additionalHttpClient = AdditionalHttpClient(
        clientDelegateParameters: ["outputMapDecodingStrategy: .collapseMapUsingTags(keyTag: \"Key\", valueTag: \"Value\")",
                                   "inputQueryMapDecodingStrategy: .separateQueryEntriesWith(keyTag: \"Key\", valueTag: \"Value\")"],
        operations: ["GetQueueAttributes", "ListQueueTags", "SetQueueAttributes", "TagQueue"])
    
    static let httpClientConfiguration = HttpClientConfiguration(
        retryOnUnknownError: true,
        knownErrorsDefaultRetryBehavior: .fail,
        unretriableUnknownErrors: [],
        retriableUnknownErrors: ["OverLimit"],
        additionalClients: ["listHttpClient": additionalHttpClient])
    
    static let serviceModelDetails = ServiceModelDetails(
        serviceName: "sqs", serviceVersion: "2012-11-05",
        baseName: "SimpleQueue", modelOverride: modelOverride,
        httpClientConfiguration: httpClientConfiguration,
        signAllHeaders: false)
}
