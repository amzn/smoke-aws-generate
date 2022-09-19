// Copyright 2019-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
// ServiceModelCodeGenerator+generateProtocolAsyncExtensions.swift
// ServiceModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

public extension ServiceModelCodeGenerator {
    private struct OperationSignature {
        let input: String
        let functionInputType: String?
        let output: String
        let functionOutputType: String?
        let errors: String
    }
    
    /**
     Generate async extensions for a client protocol from the Service Model.
     */
    func generateProtocolAsyncExtensions() {
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let typeName = baseName + "ClientProtocol"
        addFileHeader(fileBuilder: fileBuilder, typeName: "\(typeName)+async")
        
        fileBuilder.appendLine("""
            
            #if (os(Linux) && compiler(>=5.5)) || (!os(Linux) && compiler(>=5.5.2)) && canImport(_Concurrency)
            
            /**
             Async extensions for the \(typeName) type.
             */
            public extension \(typeName) {
            """)
        
        fileBuilder.incIndent()
        
        let sortedOperations = model.operationDescriptions.sorted { (left, right) in left.key < right.key }
        
        // for each of the operations
        for (name, operationDescription) in sortedOperations {
            addOperation(fileBuilder: fileBuilder, name: name,
                         operationDescription: operationDescription)
        }
        
        fileBuilder.appendLine("}", preDec: true)
        fileBuilder.appendEmptyLine()
        fileBuilder.appendLine("#endif")
        let baseFilePath = applicationDescription.baseFilePath
        
        let fileName = "\(typeName)+async.swift"
        fileBuilder.write(toFile: fileName,
                          atFilePath: "\(baseFilePath)/Sources/\(baseName)Client")
    }
    
    private func addOperationInput(fileBuilder: FileBuilder,
                                   operationDescription: OperationDescription) -> (input: String, functionInputType: String?) {
        let input: String
        let functionInputType: String?
        let baseName = applicationDescription.baseName
        if let inputType = operationDescription.input {
            let type = inputType.getNormalizedTypeName(forModel: model)
            
            input = "input: \(baseName)Model.\(type)"
            
            fileBuilder.appendEmptyLine()
            fileBuilder.appendLine(" - Parameters:")
            fileBuilder.appendLine("     - input: The validated \(type) object being passed to this operation.")
            functionInputType = type
        } else {
            input = ""
            functionInputType = nil
        }
        
        return (input: input, functionInputType: functionInputType)
    }
    
    private func addOperationOutput(fileBuilder: FileBuilder,
                                    operationDescription: OperationDescription) -> (output: String, functionOutputType: String?) {
        let output: String
        let functionOutputType: String?
        let baseName = applicationDescription.baseName
        if let outputType = operationDescription.output {
            let type = outputType.getNormalizedTypeName(forModel: model)
            
            output = " -> \(baseName)Model.\(type)"
            fileBuilder.appendLine(" - Returns: The \(type) object to be passed back from the caller of this operation.")
            fileBuilder.appendLine("     Will be validated before being returned to caller.")
            functionOutputType = type
        } else {
            output = ""
            
            functionOutputType = nil
        }
        
        return (output: output, functionOutputType: functionOutputType)
    }
    
    func addOperationError(fileBuilder: FileBuilder,
                           operationDescription: OperationDescription) -> String {
        let errors = " throws"
        if !operationDescription.errors.isEmpty {
            var description = " - Throws: "
            
            let errors = operationDescription.errors
                .sorted(by: <)
                .map { $0.type.normalizedErrorName }
                .joined(separator: ", ")
            
            description += "\(errors)."
            fileBuilder.appendLine(description)
        }
        
        return errors
    }
    
    private func addOperationBody(fileBuilder: FileBuilder, name: String,
                                  operationDescription: OperationDescription,
                                  operationSignature: OperationSignature) {
        let functionName = name.upperToLowerCamelCase
        fileBuilder.appendLine(" */")
        
        let input = operationSignature.input
        let output = operationSignature.output
        let errors = operationSignature.errors
        
        if input.isEmpty {
            if output.isEmpty {
                fileBuilder.appendLine("""
                    func \(functionName)() async\(errors)\(output) {
                    """)
            } else {
                fileBuilder.appendLine("""
                    func \(functionName)() async\(errors)
                    \(output) {
                    """)
            }
        } else {
            if output.isEmpty {
                fileBuilder.appendLine("""
                    func \(functionName)(\(input)) async\(errors)\(output) {
                    """)
            } else {
                fileBuilder.appendLine("""
                    func \(functionName)(\(input)) async\(errors)
                    \(output) {
                    """)
            }
        }
        
        fileBuilder.incIndent()
        
        fileBuilder.appendLine("""
            return try await withUnsafeThrowingContinuation { cont in
            """)
        fileBuilder.incIndent()
        
        let errorPrefix: String
        if !errors.isEmpty {
            errorPrefix = "try "
            
            fileBuilder.appendLine("""
                do {
                """)
            
            fileBuilder.incIndent()
        } else {
            errorPrefix = ""
        }
        
        if input.isEmpty {
            if output.isEmpty {
                fileBuilder.appendLine("""
                    \(errorPrefix)\(functionName)Async { error in
                        if let error = error {
                            cont.resume(throwing: error)
                        } else {
                            cont.resume(returning: ())
                        }
                    }
                    """)
            } else {
                fileBuilder.appendLine("""
                    \(errorPrefix)\(functionName)Async { result in
                        switch result {
                        case .failure(let error):
                            cont.resume(throwing: error)
                        case .success(let response):
                            cont.resume(returning: response)
                        }
                    }
                    """)
            }
        } else {
            if output.isEmpty {
                fileBuilder.appendLine("""
                    \(errorPrefix)\(functionName)Async(input: input) { error in
                        if let error = error {
                            cont.resume(throwing: error)
                        } else {
                            cont.resume(returning: ())
                        }
                    }
                    """)
            } else {
                fileBuilder.appendLine("""
                    \(errorPrefix)\(functionName)Async(input: input) { result in
                        switch result {
                        case .failure(let error):
                            cont.resume(throwing: error)
                        case .success(let response):
                            cont.resume(returning: response)
                        }
                    }
                    """)
            }
        }
        
        if !errors.isEmpty {
            fileBuilder.decIndent()
            
            fileBuilder.appendLine("""
                } catch {
                    cont.resume(throwing: error)
                }
                """)
        }
        
        fileBuilder.appendLine("}", preDec: true)
        
        fileBuilder.appendLine("}", preDec: true)
    }
    
    /**
     Generates an operation on the client.
 
     - Parameters:
        - fileBuilder: The FileBuilder to output to.
        - name: The operation name.
        - operationDescription: the description of the operation.
     */
    internal func addOperation(fileBuilder: FileBuilder, name: String,
                               operationDescription: OperationDescription) {
        fileBuilder.appendEmptyLine()
        fileBuilder.appendLine("""
            /**
             Invokes the \(name) operation and asynchronously returning the response.
            """)
        
        // if there is input
        let operationInput = addOperationInput(fileBuilder: fileBuilder, operationDescription: operationDescription)
        
        // if there is output
        let operationOuput = addOperationOutput(fileBuilder: fileBuilder, operationDescription: operationDescription)
        
        // if there can be errors
        let errors = addOperationError(fileBuilder: fileBuilder, operationDescription: operationDescription)
        
        let operationSignature = OperationSignature(input: operationInput.input,
                                                    functionInputType: operationInput.functionInputType,
                                                    output: operationOuput.output,
                                                    functionOutputType: operationOuput.functionOutputType,
                                                    errors: errors)
        
        addOperationBody(fileBuilder: fileBuilder, name: name, operationDescription: operationDescription,
                         operationSignature: operationSignature)
    }
    
    func addGeneratedFileHeader(fileBuilder: FileBuilder) {
        fileBuilder.appendLine("""
            // swiftlint:disable superfluous_disable_command
            // swiftlint:disable file_length line_length identifier_name type_name vertical_parameter_alignment
            // swiftlint:disable type_body_length function_body_length generic_type_name cyclomatic_complexity
            // -- Generated Code; do not edit --
            //
            """)
    }
    
    private func addFileHeader(fileBuilder: FileBuilder,
                               typeName: String) {
        let baseName = applicationDescription.baseName
        if let fileHeader = customizations.fileHeader {
            fileBuilder.appendLine(fileHeader)
        }
        
        addGeneratedFileHeader(fileBuilder: fileBuilder)
        
        fileBuilder.appendLine("""
            // \(typeName).swift
            // \(baseName)Client
            //
            
            import Foundation
            import \(baseName)Model
            """)
    }
    
    func getHttpClientForOperation(name: String, httpClientConfiguration: HttpClientConfiguration?) -> String {
        if let additionalClients = httpClientConfiguration?.additionalClients {
            for (key, value) in additionalClients {
                if value.operations?.contains(name) ?? false {
                    return key
                }
            }
        }
        
        return "httpClient"
    }
}
