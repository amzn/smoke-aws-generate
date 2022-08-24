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
// ServiceModelCodeGeneration+generateServerApplicationFiles.swift
// APIGatewayClientModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ArgumentParser

public enum VersionRequirementType: String, Codable, ExpressibleByArgument {
    case from
    case branch
    case path
}

public struct ModelPackageDependency {
    public let versionRequirementType: VersionRequirementType
    public let versionRequirement: String?
    public let packageLocation: String
    
    public init (versionRequirementType: VersionRequirementType,
                 versionRequirement: String?,
                 packageLocation: String) {
        self.versionRequirementType = versionRequirementType
        self.versionRequirement = versionRequirement
        self.packageLocation = packageLocation
    }
}

public struct ModelLocation: Codable {
    public let modelProductDependency: String?
    public let modelTargetDependency: String?
    public let modelFilePath: String
    
    public init (modelFilePath: String,
                 modelProductDependency: String?,
                 modelTargetDependency: String?) {
        self.modelFilePath = modelFilePath
        self.modelProductDependency = modelProductDependency
        self.modelTargetDependency = modelTargetDependency
    }
}

extension APIGatewayClientCodeGeneration {
    /**
     Generate the main Swift file for the generated application as a Container Server.
     */
    func generateClientApplicationFiles(modelLocation: ModelLocation,
                                        modelPackageDependency: ModelPackageDependency?) {
        generatePackageFile(fileName: "Package.swift", modelLocation: modelLocation,
                            modelPackageDependency: modelPackageDependency)
        generateGitIgnoreFile()
    }
    
    private func generatePackageFile(fileName: String, modelLocation: ModelLocation,
                                     modelPackageDependency: ModelPackageDependency?) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        
        fileBuilder.appendLine("""
            // swift-tools-version:5.6
            """)
        
        if let fileHeader = self.fileHeader {
            fileBuilder.appendLine(fileHeader)
        }

        fileBuilder.appendLine("""
            
            import PackageDescription

            let package = Package(
                name: "\(baseName)SwiftClient",
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
            """)
        
        let modelProduct: (name: String, package: String)?
        if let modelProductDependency = modelLocation.modelProductDependency, let modelPackageDependency = modelPackageDependency {
            let versionRequirementType = modelPackageDependency.versionRequirementType
            let packageLocation = modelPackageDependency.packageLocation
            
            let packageName: String
            if let lastPackageComponent = packageLocation.split(separator: "/").last {
                if lastPackageComponent.hasSuffix(".git") {
                    packageName = String(lastPackageComponent.dropLast(".git".count))
                } else {
                    packageName = String(lastPackageComponent)
                }
            } else {
                packageName = packageLocation
            }
            
            if case .path = versionRequirementType {
                fileBuilder.appendLine("""
                            .package(path: "\(packageLocation)"),
                    """)
            } else if let versionRequirement = modelPackageDependency.versionRequirement {
                fileBuilder.appendLine("""
                            .package(url: "\(packageLocation)", \(versionRequirementType): "\(versionRequirement)"),
                    """)
            } else {
                fatalError("Version requirement needed for type: \(versionRequirementType)")
            }
            
            modelProduct = (modelProductDependency, packageName)
        } else {
            modelProduct = nil
        }
        
        fileBuilder.appendLine("""
                    .package(url: "https://github.com/amzn/smoke-aws.git", from: "2.35.31"),
                    .package(url: "https://github.com/amzn/smoke-http.git", from: "2.14.0"),
                    .package(url: "https://github.com/apple/swift-log", from: "1.0.0"),
                    .package(url: "https://github.com/amzn/smoke-aws-generate.git", from: "3.0.0-beta.5"),
                    ],
                targets: [
                    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
                    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
                    .target(name: "\(baseName)Model", dependencies: [
                        .product(name: "Logging", package: "swift-log"),
            """)
        
        if let modelProduct = modelProduct {
            fileBuilder.appendLine("""
                                .product(name: "\(modelProduct.name)", package: "\(modelProduct.package)"),
                """)
        }
        
        fileBuilder.appendLine("""
                            .product(name: "APIGatewayClientModelGenerate", package: "smoke-aws-generate")
                        ],
                        plugins: [
                            .plugin(name: "APIGatewaySwiftGenerateModel", package: "smoke-aws-generate")
                        ]
                    ),
                    .target(name: "\(baseName)Client", dependencies: [
                        .target(name: "\(baseName)Model"),
            """)
        
        if let modelProduct = modelProduct {
            fileBuilder.appendLine("""
                                .product(name: "\(modelProduct.name)", package: "\(modelProduct.package)"),
                """)
        }
        
        fileBuilder.appendLine("""
                        .product(name: "SmokeAWSHttp", package: "smoke-aws"),
                        .product(name: "SmokeHTTPClient", package: "smoke-http"),
                        .product(name: "APIGatewayClientModelGenerate", package: "smoke-aws-generate")
                        ],
                        plugins: [
                            .plugin(name: "APIGatewaySwiftGenerateClient", package: "smoke-aws-generate")
                        ]
                    ),
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
            .swift-version
            .swiftpm/
            *~
            .vscode/
            """)

        let fileName = ".gitignore"
       
        fileBuilder.write(toFile: fileName, atFilePath: baseFilePath)
    }
}
