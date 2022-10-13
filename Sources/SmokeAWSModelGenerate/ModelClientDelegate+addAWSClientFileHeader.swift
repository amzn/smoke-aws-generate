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
// ModelClientDelegate+addAWSClientFileHeader.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import ServiceModelGenerate
import CoralToJSONServiceModel

extension ModelClientDelegate where TargetSupportType: ModelTargetSupport {
    func addAWSClientFileHeader(codeGenerator: ServiceModelCodeGenerator<TargetSupportType>,
                                fileBuilder: FileBuilder, baseName: String,
                                fileType: ClientFileType, defaultInvocationTraceContext: InvocationTraceContextDeclaration) {
        fileBuilder.appendLine("""
            import AWSCore
            import AWSHttp
            import NIO
            import AsyncHTTPClient
            import Logging
            """)
        
        let specificErrorBehaviour = getSpecificErrors(codeGenerator: codeGenerator, baseName: baseName)
        
        if let importPackage = defaultInvocationTraceContext.importPackage {
            fileBuilder.appendLine("""
                import \(importPackage)
                """)
        }
        
        if case .clientImplementation = fileType {
            fileBuilder.appendLine("""
                
                public enum \(baseName)ClientError: Swift.Error {
                    case invalidEndpoint(String)
                    case unsupportedPayload
                    case unknownError(String?)
                }
                """)
        
            addTypedErrorRetriableExtension(codeGenerator: codeGenerator, fileBuilder: fileBuilder,
                                            baseName: baseName, specificErrorBehaviour: specificErrorBehaviour)
        }
        
        if !(specificErrorBehaviour.retriableErrors.isEmpty && specificErrorBehaviour.unretriableErrors.isEmpty) {
            addErrorRetriableExtension(codeGenerator: codeGenerator, fileBuilder: fileBuilder, baseName: baseName)
        }
    }
}
