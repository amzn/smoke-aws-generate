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
// main.swift
// SmokeAWSGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import ServiceModelGenerate
import SmokeAWSModelGenerate
import ArgumentParser

struct CommonConfiguration {
    static let integerDateOverride = RawTypeOverride(typeName: "Double",
                                                     defaultValue: "1.52953091375E9")
    static let longDateOverride = RawTypeOverride(typeName: "Int64",
                                                  defaultValue: "0")
    static let intOverride = RawTypeOverride(typeName: "Int", defaultValue: "0")
    
    static let defaultHttpClientConfiguration = HttpClientConfiguration(
        retryOnUnknownError: true,
        knownErrorsDefaultRetryBehavior: .fail,
        unretriableUnknownErrors: [],
        retriableUnknownErrors: [])
}

var isUsage = CommandLine.arguments.count == 2 && CommandLine.arguments[1] == "--help"
let goRepositoryTag = "v1.44.174"

let fileHeader = """
    // Copyright 2018-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
    """

// Function to fork a process and get its standard output
func call(arguments: [String], environment: [String: String]? = nil,
          errorHandler: ((Int32, String) -> Data?)? = nil) -> Data {
    let outputPipe = Pipe()
    let errorPipe = Pipe()

    let processEnvironment: [String: String]
    if let environment = environment {
        processEnvironment = ProcessInfo.processInfo.environment.merging(environment) { (_, new) in new }
    } else {
       processEnvironment = ProcessInfo.processInfo.environment
    }
    
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.environment = processEnvironment
    task.arguments = arguments
    task.standardOutput = outputPipe
    task.standardError = errorPipe
    task.launch()
    task.waitUntilExit()
    
    if task.terminationStatus != 0 {
        let errorData = errorPipe.fileHandleForReading.availableData
        let errorMessage = String(data: errorData, encoding: .utf8) ?? "<none>"
        
        if let errorData = errorHandler?(task.terminationStatus, errorMessage) {
            return errorData
        }
        
        print("Process failed with termination status '\(task.terminationStatus)': '\(errorMessage)'")
        
        exit(-1)
    }

    return outputPipe.fileHandleForReading.availableData
}

struct AWSServiceModelDetails {
    let packageName: String
    let baseName: String
}

func getPackageProductEntriesPackageFile(name: String) -> String {
    return """
                    .library(
                        name: "\(name)Client",
                        targets: ["\(name)Client"]),
                    .library(
                        name: "\(name)Model",
                        targets: ["\(name)Model"]),\n
            """
}

func getPackageTargetEntriesPackageFile(name: String) -> String {
    return """
                    .target(
                        name: "\(name)Client", dependencies: [
                            .target(name: "\(name)Model"),
                            .product(name: "AWSHttp", package: "smoke-aws-support"),
                        ]),
                    .target(
                        name: "\(name)Model", dependencies: [
                            .product(name: "Logging", package: "swift-log"),
                        ]),\n
            """
}

func generatePackageFile(baseNames: [String]) -> String {
    
    var packageFileContents = """
        // swift-tools-version:5.5
        //
        \(fileHeader)
        
        import PackageDescription

        let package = Package(
            name: "smoke-aws",
            platforms: [
                .macOS(.v10_15), .iOS(.v13), .tvOS(.v13)
                ],
            products: [\n
        """
    
    baseNames.forEach { name in
        packageFileContents += getPackageProductEntriesPackageFile(name: name)
    }

    packageFileContents += """
                .library(
                    name: "SmokeAWSMetrics",
                    targets: ["SmokeAWSMetrics"]),
            ],
            dependencies: [
                .package(url: "https://github.com/apple/swift-log", from: "1.0.0"),
                .package(url: "https://github.com/apple/swift-metrics.git", "1.0.0"..<"3.0.0"),
                .package(path: "/Users/simonpi/Packages/smoke-http"),
                .package(path: "/Users/simonpi/Packages/smoke-aws-support"),
            ],
            targets: [\n
        """
    
        baseNames.forEach { name in
        packageFileContents += getPackageTargetEntriesPackageFile(name: name)
    }
    
    packageFileContents += """
                .target(
                    name: "SmokeAWSMetrics", dependencies: [
                        .product(name: "Logging", package: "swift-log"),
                        .product(name: "Metrics", package: "swift-metrics"),
                        .target(name: "CloudWatchClient"),
                    ]),
                .testTarget(
                    name: "S3ClientTests", dependencies: [
                        .target(name: "S3Client"),
                    ]),
                .testTarget(
                    name: "SimpleQueueClientTests", dependencies: [
                        .target(name: "SimpleQueueClient"),
                    ]),
                .testTarget(
                    name: "SecurityTokenClientTests", dependencies: [
                        .target(name: "SecurityTokenClient"),
                    ]),
                .testTarget(
                    name: "SimpleNotificationClientTests", dependencies: [
                        .target(name: "SimpleNotificationClient"),
                    ]),
                .testTarget(
                    name: "ElasticComputeCloudClientTests", dependencies: [
                        .target(name: "ElasticComputeCloudClient"),
                    ]),
                .testTarget(
                    name: "RDSClientTests", dependencies: [
                        .target(name: "RDSClient"),
                    ]),
                .testTarget(
                    name: "AppConfigClientTests", dependencies: [
                        .target(name: "AppConfigClient"),
                    ]),
            ],
            swiftLanguageVersions: [.v5]
        )
        
        """
    
    return packageFileContents
}

struct ServiceModelDetails {
    let serviceName: String
    let serviceVersion: String
    let baseName: String
    let modelOverride: ModelOverride<NoModelTypeOverrides>?
    let httpClientConfiguration: HttpClientConfiguration
    let signAllHeaders: Bool
    let awsCodeGenerationCustomizations: AWSCodeGenerationCustomizations

    init(serviceName: String,
         serviceVersion: String,
         baseName: String,
         modelOverride: ModelOverride<NoModelTypeOverrides>?,
         httpClientConfiguration: HttpClientConfiguration,
         signAllHeaders: Bool,
         awsCodeGenerationCustomizations: AWSCodeGenerationCustomizations = AWSCodeGenerationCustomizations(contentTypeHeaderOverride: nil)) {
        self.serviceName = serviceName
        self.serviceVersion = serviceVersion
        self.baseName = baseName
        self.modelOverride = modelOverride
        self.httpClientConfiguration = httpClientConfiguration
        self.signAllHeaders = signAllHeaders
        self.awsCodeGenerationCustomizations = awsCodeGenerationCustomizations
    }
}

private func generateSmokeAWS(tempDirURL: URL,
                              serviceModelDetails: [ServiceModelDetails],
                              baseFilePath: String) throws {
    let repositoryName = "aws-sdk-go"
    let modelBase = tempDirURL.appendingPathComponent(repositoryName)
    let modelBaseFilePath = String(modelBase.absoluteString.dropFirst(7))
    
    var isDirectory = ObjCBool(true)
    if FileManager.default.fileExists(atPath: modelBaseFilePath, isDirectory: &isDirectory) {
        try FileManager.default.removeItem(at: modelBase)
    }

    print("Cloning \(repositoryName) model @ \(goRepositoryTag)")

    _ = call(arguments: ["git", "clone", "--branch", goRepositoryTag, "--depth=1", "https://github.com/aws/\(repositoryName).git",
                         modelBaseFilePath])

    print("Cloned \(repositoryName) model to \(modelBaseFilePath)")

    try serviceModelDetails.forEach { (details) in
        print("Generating model for \(details.baseName)")

        let applicationDescription = "The \(details.baseName)Service."
        
        let unrecognizedErrorDeclaration =
            ErrorDeclaration.internal
        
        let customizations = CodeGenerationCustomizations(
            validationErrorDeclaration: .internal,
            unrecognizedErrorDeclaration: unrecognizedErrorDeclaration,
            asyncAwaitAPIs: .enabled,
            eventLoopFutureClientAPIs: .disabled,
            minimumCompilerSupport: .v5_6,
            clientConfigurationType: .configurationObject,
            generateModelShapeConversions: false,
            optionalsInitializeEmpty: true,
            fileHeader: fileHeader,
            httpClientConfiguration: details.httpClientConfiguration)
        
        let modelPath = modelBase.appendingPathComponent("models")
            .appendingPathComponent("apis")
            .appendingPathComponent(details.serviceName)
            .appendingPathComponent(details.serviceVersion)
            .appendingPathComponent("api-2.json")
        let modelFilePath = String(modelPath.absoluteString.dropFirst(7))
        
        let fullApplicationDescription = ApplicationDescription(
            baseName: details.baseName,
            baseFilePath: baseFilePath,
            applicationDescription: applicationDescription,
            applicationSuffix: "Service")
        
        _ = try SmokeAWSModelGenerate.generateFromModel(
            modelFilePath: modelFilePath,
            customizations: customizations,
            awsCustomizations: details.awsCodeGenerationCustomizations,
            applicationDescription: fullApplicationDescription,
            modelOverride: details.modelOverride,
            signAllHeaders: details.signAllHeaders)
    }
    
    try FileManager.default.removeItem(at: modelBase)
    
    try FileManager.default.removeItem(at: tempDirURL)
    
    let baseNames = serviceModelDetails.map { (details) in details.baseName }
        .sorted(by: <)
    let packageFile = generatePackageFile(baseNames: baseNames)
    try packageFile.write(toFile: baseFilePath + "/Package.swift", atomically: false, encoding: String.Encoding.utf8)
}

func createTempDirectory(errorMessage: inout String?) -> URL? {
    let tempDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("codegen-resources")
    if let tempDirURL = tempDirURL {
        do {
            try FileManager.default.createDirectory(at: tempDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            errorMessage = "Unable to create temporary directory."
        }
    } else {
        errorMessage = "Unable to create temporary directory path."
    }
    
    return tempDirURL
}

func handleApplication(baseFilePath: String) throws {    
    let serviceModelDetails: [ServiceModelDetails] = [
        CloudFormationConfiguration.serviceModelDetails,
        EC2Configuration.serviceModelDetails,
        ECSConfiguration.serviceModelDetails,
        S3Configuration.serviceModelDetails,
        SimpleQueueConfiguration.serviceModelDetails,
        StepFunctionsConfiguration.serviceModelDetails,
        STSConfiguration.serviceModelDetails,
        SNSConfiguration.serviceModelDetails,
        DynamoDBConfiguration.serviceModelDetails,
        SimpleWorkflowConfiguration.serviceModelDetails,
        CloudwatchConfiguration.serviceModelDetails,
        RDSConfiguration.serviceModelDetails,
        RDSDataConfiguration.serviceModelDetails,
        // disabled; currently untested
        //CodeBuildConfiguration.serviceModelDetails,
        CodePipelineConfiguration.serviceModelDetails,
        ECRConfiguration.serviceModelDetails,
        AppConfigConfiguration.serviceModelDetails]
    
    var errorMessage: String?
    let tempDirURL = createTempDirectory(errorMessage: &errorMessage)
    
    if errorMessage == nil, let tempDirURL = tempDirURL {
        try generateSmokeAWS(tempDirURL: tempDirURL,
                             serviceModelDetails: serviceModelDetails,
                             baseFilePath: baseFilePath)
    }
    
    if let errorMessage = errorMessage {
        print("ERROR: \(errorMessage)\n")
    }
}

struct SmokeAWSGenerateCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        return CommandConfiguration(
            commandName: "SmokeAWSGenerate",
            abstract: "Retrieves the current AWS service models and updated the SmokeAWS package."
        )
    }
    
    @Option(name: .customLong("base-file-path"), help: "The file path to place the root of the generated Swift package.")
    var baseFilePath: String

    mutating func run() throws {
        try handleApplication(baseFilePath: baseFilePath)
    }
}

SmokeAWSGenerateCommand.main()
