// swift-tools-version:4.2
//
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

import PackageDescription

let package = Package(
    name: "SmokeAWSGenerate",
    products: [
        .executable(
            name: "SmokeAWSGenerate",
            targets: ["SmokeAWSGenerate"]),
        .executable(
            name: "APIGatewayClientGenerate",
            targets: ["APIGatewayClientGenerate"]),
        .library(
            name: "SmokeAWSModelGenerate",
            targets: ["SmokeAWSModelGenerate"]),
        .library(
            name: "APIGatewayClientModelGenerate",
            targets: ["APIGatewayClientModelGenerate"]),
        .library(
            name: "CoralToJSONServiceModel",
            targets: ["CoralToJSONServiceModel"]),
    ],
    dependencies: [
        .package(url: "https://github.com/amzn/service-model-swift-code-generate.git", from: "2.0.0-alpha.2")
    ],
    targets: [
        .target(
            name: "SmokeAWSGenerate",
            dependencies: ["SmokeAWSModelGenerate"]),
        .target(
            name: "APIGatewayClientGenerate",
            dependencies: ["APIGatewayClientModelGenerate"]),
        .target(
            name: "CoralToJSONServiceModel",
            dependencies: ["ServiceModelEntities"]),
        .target(
            name: "SmokeAWSModelGenerate",
            dependencies: ["ServiceModelGenerate", "CoralToJSONServiceModel"]),
        .target(
            name: "APIGatewayClientModelGenerate",
            dependencies: ["SmokeAWSModelGenerate"]),
    ]
)
