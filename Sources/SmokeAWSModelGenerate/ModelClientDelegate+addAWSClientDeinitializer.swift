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
// ModelClientDelegate+addAWSClientDeinitializer.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import ServiceModelGenerate
import CoralToJSONServiceModel

extension ModelClientDelegate {
    func addAWSClientDeinitializer(fileBuilder: FileBuilder, baseName: String,
                                   clientAttributes: AWSClientAttributes,
                                   codeGenerator: ServiceModelCodeGenerator,
                                   targetsAPIGateway: Bool,
                                   contentType: String,
                                   isGenerator: Bool) {
        let httpClientConfiguration = codeGenerator.customizations.httpClientConfiguration

        fileBuilder.appendEmptyLine()
        fileBuilder.appendLine("""
            /**
             Gracefully shuts down this client. This function is idempotent and
             will handle being called multiple times.
             */
            public func close() throws {
            """)
        
        if !isGenerator {
            fileBuilder.appendLine("""
                if self.ownsHttpClients {
            """)
            fileBuilder.incIndent()
        }
        
        fileBuilder.appendLine("""
            try httpClient.close()
        """)
        
        fileBuilder.incIndent()
        httpClientConfiguration.additionalClients?.forEach { (key, _) in
            let clientName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
            fileBuilder.appendLine("try \(clientName).close()")
        }
        fileBuilder.decIndent()
        
        if !isGenerator {
            fileBuilder.decIndent()
            fileBuilder.appendLine("""
                }
            """)
        }
        
        fileBuilder.appendLine("""
            }
            """)
    }
}
