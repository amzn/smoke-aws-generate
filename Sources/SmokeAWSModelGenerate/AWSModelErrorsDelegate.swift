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
// AWSModelErrorsDelegate.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

struct AWSModelErrorsDelegate: ModelErrorsDelegate {
    let optionSetGeneration: ErrorOptionSetGeneration = .noGeneration
    let generateEncodableConformance: Bool = false
    let generateCustomStringConvertibleConformance: Bool = false
    let canExpectValidationError: Bool = false
    let awsClientAttributes: AWSClientAttributes
    
    func errorTypeInitializerGenerator(fileBuilder: FileBuilder,
                                       errorTypes: [String],
                                       codingErrorUnknownError: String) {
        let typeCodingKey: String
        let messageCodingKey: String
        
        switch awsClientAttributes.contentType.contentTypePayloadType {
        case .xml:
            typeCodingKey = "Code"
            messageCodingKey = "Message"
        case .json:
            typeCodingKey = "__type"
            messageCodingKey = "message"
        }
    
        fileBuilder.appendLine("""

            enum CodingKeys: String, CodingKey {
                case type = "\(typeCodingKey)"
                case message = "\(messageCodingKey)"
            }

            public init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                var errorReason = try values.decode(String.self, forKey: .type)
                let errorMessage = try values.decodeIfPresent(String.self, forKey: .message)

                if let index = errorReason.index(of: "#") {
                    errorReason = String(errorReason[errorReason.index(index, offsetBy: 1)...])
                }

                switch errorReason {
            """)
    }
}
