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
// ServiceModelCodeGeneration+generateServerApplicationFiles.swift
// APIGatewayClientModelGenerate
//

import Foundation
import ServiceModelCodeGeneration

extension ServiceModelCodeGenerator {
    /**
     Generate the main Swift file for the generated application as a Container Server.
     */
    func generateServerApplicationFiles() {
        generatePackageFile(fileName: "Package.swift")
        generateLegacyPackageFile(fileName: "Package@swift-5.0.swift")
        generateLegacyPackageFile(fileName: "Package@swift-5.1.swift")
        generateGitIgnoreFile()
    }
    
    private func generatePackageFile(fileName: String) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        
        fileBuilder.appendLine("""
            // swift-tools-version:5.2
            """)
        
        if let fileHeader = customizations.fileHeader {
            fileBuilder.appendLine(fileHeader)
        }

        fileBuilder.appendLine("""
            
            import PackageDescription

            let package = Package(
                name: "\(baseName)",
                platforms: [
                    .macOS(.v10_15), .iOS(.v10)
                    ],
                products: [
                    // Products define the executables and libraries produced by a package, and make them visible to other packages.
                    .library(
                        name: "\(baseName)Model",
                        targets: ["\(baseName)Model"]),
                    .library(
                        name: "\(baseName)Client",
                        targets: ["\(baseName)Client"]),
                    ],
                dependencies: [
                    .package(url: "https://github.com/amzn/smoke-aws.git", from: "2.0.0-rc.1"),
                    .package(url: "https://github.com/apple/swift-log", from: "1.0.0"),
                    ],
                targets: [
                    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
                    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
                    .target(name: "\(baseName)Model", dependencies: [
                        .product(name: "Logging", package: "swift-log"),
                    ]),
                    .target(name: "\(baseName)Client", dependencies: [
                        .target(name: "\(baseName)Model"),
                        .product(name: "SmokeAWSHttp", package: "smoke-aws"),
                    ]),
                ],
                swiftLanguageVersions: [.v5]
            )
            """)

        fileBuilder.write(toFile: fileName, atFilePath: baseFilePath)
    }

    private func generateLegacyPackageFile(fileName: String) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        
        fileBuilder.appendLine("""
            // swift-tools-version:5.0
            """)
        
        if let fileHeader = customizations.fileHeader {
            fileBuilder.appendLine(fileHeader)
        }

        fileBuilder.appendLine("""
            
            import PackageDescription

            let package = Package(
                name: "\(baseName)",
                platforms: [
                    .macOS(.v10_12), .iOS(.v10)
                    ],
                products: [
                    // Products define the executables and libraries produced by a package, and make them visible to other packages.
                    .library(
                        name: "\(baseName)Model",
                        targets: ["\(baseName)Model"]),
                    .library(
                        name: "\(baseName)Client",
                        targets: ["\(baseName)Client"]),
                    ],
                dependencies: [
                    .package(url: "https://github.com/amzn/smoke-aws.git", from: "2.0.0-rc.1"),
                    .package(url: "https://github.com/apple/swift-log", from: "1.0.0"),
                    ],
                targets: [
                    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
                    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
                    .target(
                        name: "\(baseName)Model",
                        dependencies: ["Logging"]),
                    .target(
                        name: "\(baseName)Client",
                        dependencies: ["\(baseName)Model", "SmokeAWSHttp"]),
                ],
                swiftLanguageVersions: [.v5]
            )
            """)

        fileBuilder.write(toFile: fileName, atFilePath: baseFilePath)
    }
    
    /**
     Create a basic .gitignore file that ignores standard build
     related files.
     */
    func generateGitIgnoreFile() {
       
        let fileBuilder = FileBuilder()
        let baseFilePath = applicationDescription.baseFilePath
       
        fileBuilder.appendLine("""
            build
            .DS_Store
            .build/
            *.xcodeproj
            *~
            """)

        let fileName = ".gitignore"
       
        fileBuilder.write(toFile: fileName, atFilePath: baseFilePath)
    }
}
