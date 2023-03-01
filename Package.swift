// swift-tools-version:5.6
//
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

import PackageDescription

let package = Package(
    name: "SmokeAWSGenerate",
    platforms: [
        .macOS(.v10_15), .iOS(.v10)
    ],
    products: [
        .executable(
            name: "SmokeAWSGenerate",
            targets: ["SmokeAWSGenerate"]),
        .executable(
            name: "APIGatewayClientGenerate",
            targets: ["APIGatewayClientGenerate"]),
        .executable(
            name: "APIGatewayClientInitialize",
            targets: ["APIGatewayClientInitialize"]),
        .library(
            name: "SmokeAWSModelGenerate",
            targets: ["SmokeAWSModelGenerate"]),
        .library(
            name: "APIGatewayClientModelGenerate",
            targets: ["APIGatewayClientModelGenerate"]),
        .library(
            name: "CoralToJSONServiceModel",
            targets: ["CoralToJSONServiceModel"]),
        .plugin(
            name: "APIGatewaySwiftGenerateModel",
            targets: ["APIGatewaySwiftGenerateModel"]),
        .plugin(
            name: "APIGatewaySwiftGenerateClient",
            targets: ["APIGatewaySwiftGenerateClient"]),
    ],
    dependencies: [
        //.package(url: "https://github.com/amzn/service-model-swift-code-generate.git", from: "3.0.0-rc.2"),
        .package(path: "/Users/simonpi/Packages/CodeGeneration/service-model-swift-code-generate"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/amzn/openapi-swift-code-generate.git", from: "1.0.0-rc.1"),
    ],
    targets: [
        .plugin(
            name: "APIGatewaySwiftGenerateModel",
            capability: .buildTool(),
            dependencies: ["APIGatewayClientGenerate"]
        ),
        .plugin(
            name: "APIGatewaySwiftGenerateClient",
            capability: .buildTool(),
            dependencies: ["APIGatewayClientGenerate"]
        ),
        .executableTarget(
            name: "SmokeAWSGenerate", dependencies: [
                .target(name: "SmokeAWSModelGenerate"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "APIGatewayClientGenerate", dependencies: [
                .target(name: "APIGatewayClientModelGenerate"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "OpenAPIServiceModel", package: "openapi-swift-code-generate"),
                .product(name: "SwaggerServiceModel", package: "openapi-swift-code-generate"),
            ]
        ),
        .executableTarget(
            name: "APIGatewayClientInitialize", dependencies: [
                .target(name: "APIGatewayClientModelGenerate"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "OpenAPIServiceModel", package: "openapi-swift-code-generate"),
                .product(name: "SwaggerServiceModel", package: "openapi-swift-code-generate"),
            ]
        ),
        .target(
            name: "CoralToJSONServiceModel", dependencies: [
                .product(name: "ServiceModelEntities", package: "service-model-swift-code-generate"),
            ]
        ),
        .target(
            name: "SmokeAWSModelGenerate", dependencies: [
                .product(name: "ServiceModelEntities", package: "service-model-swift-code-generate"),
                .product(name: "ServiceModelCodeGeneration", package: "service-model-swift-code-generate"),
                .product(name: "ServiceModelGenerate", package: "service-model-swift-code-generate"),
                .target(name: "CoralToJSONServiceModel"),
            ]
        ),
        .target(
            name: "APIGatewayClientModelGenerate", dependencies: [
                .target(name: "SmokeAWSModelGenerate"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
