//
//  APIGatewayClientSwiftCodeGen.swift
//  APIGatewayClientGenerate
//

import ServiceModelEntities
import ServiceModelCodeGeneration
import APIGatewayClientModelGenerate

enum ModelFormat: String, Codable {
    case swagger = "SWAGGER"
    case openAPI30 = "OPENAPI3_0"
}

struct APIGatewayClientSwiftCodeGen: Decodable {
    let modelFormat: ModelFormat?
    let baseName: String
    let modelOverride: ModelOverride?
    let httpClientConfiguration: HttpClientConfiguration?
    let shapeProtocols: CodeGenFeatureStatus?
    let eventLoopFutureClientAPIs: CodeGenFeatureStatus?
    let minimumCompilerSupport: MinimumCompilerSupport?
    let clientConfigurationType: ClientConfigurationType?
}
