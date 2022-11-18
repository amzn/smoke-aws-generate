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
                                   codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
                                   targetsAPIGateway: Bool,
                                   contentType: String,
                                   entityType: ClientEntityType) {
        if case .configurationObject = entityType {
            // nothing to do
            return
        }
        
        fileBuilder.appendEmptyLine()
        fileBuilder.appendLine("""
            /**
             Gracefully shuts down this client. This function is idempotent and
             will handle being called multiple times. Will block until shutdown is complete.
             */
            """)
        addShutdownMethod(methodName: "syncShutdown", isAsync: false, fileBuilder: fileBuilder,
                          codeGenerator: codeGenerator, entityType: entityType)
        
        fileBuilder.appendEmptyLine()
        if case .unknown = self.minimumCompilerSupport {
            fileBuilder.appendLine("""
                // renamed `syncShutdown` to make it clearer this version of shutdown will block.
                @available(*, deprecated, renamed: "syncShutdown")
                """)
            addShutdownMethod(methodName: "close", isAsync: false, fileBuilder: fileBuilder,
                              codeGenerator: codeGenerator, entityType: entityType)
            
            fileBuilder.appendEmptyLine()
        }
        
        fileBuilder.appendLine("""
            /**
             Gracefully shuts down this client. This function is idempotent and
             will handle being called multiple times. Will return when shutdown is complete.
             */
            """)
        if case .unknown = self.minimumCompilerSupport {
            fileBuilder.appendLine("""
                #if (os(Linux) && compiler(>=5.5)) || (!os(Linux) && compiler(>=5.5.2)) && canImport(_Concurrency)
                """)
        }
        addShutdownMethod(methodName: "shutdown", isAsync: true, fileBuilder: fileBuilder,
                          codeGenerator: codeGenerator, entityType: entityType)
        if case .unknown = self.minimumCompilerSupport {
            fileBuilder.appendLine("""
                #endif
                """)
        }
    }
    
    private func addShutdownMethod(methodName: String,
                                   isAsync: Bool,
                                   fileBuilder: FileBuilder,
                                   codeGenerator: ServiceModelCodeGenerator<ModelType, TargetSupportType>,
                                   entityType: ClientEntityType) {
        let httpClientConfiguration = codeGenerator.customizations.httpClientConfiguration
        
        let asyncInfix: String
        let awaitInfix: String
        if isAsync {
            asyncInfix = "async "
            awaitInfix = " await"
        } else {
            asyncInfix = ""
            awaitInfix = ""
        }

        fileBuilder.appendLine("""
            public func \(methodName)() \(asyncInfix)throws {
            """)
        
        if case .clientImplementation = entityType {
            fileBuilder.appendLine("""
                if self.ownsHttpClients {
            """)
            fileBuilder.incIndent()
        }
        
        fileBuilder.appendLine("""
            try\(awaitInfix) self.httpClient.\(methodName)()
        """)
        
        fileBuilder.incIndent()
        httpClientConfiguration.additionalClients?.forEach { (key, _) in
            let clientName = codeGenerator.getNormalizedVariableName(modelTypeName: key)
            fileBuilder.appendLine("try\(awaitInfix) self.\(clientName).\(methodName)()")
        }
        fileBuilder.decIndent()
        
        if case .clientImplementation = entityType {
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
