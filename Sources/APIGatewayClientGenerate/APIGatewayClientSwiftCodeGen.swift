//
//  APIGatewayClientSwiftCodeGen.swift
//  APIGatewayClientGenerate
//

import ServiceModelEntities
import ServiceModelCodeGeneration
import APIGatewayClientModelGenerate

struct ModelLocations: Decodable {
    let `default`: ModelLocation?
    let targetMap: [String: ModelLocation]
    
    enum CodingKeys: String, CodingKey {
        case `default`
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.`default` = try values.decodeIfPresent(ModelLocation.self, forKey: .default)
        self.targetMap = try [String: ModelLocation].init(from: decoder)
    }
}

enum ModelFormat: String, Codable {
    case swagger = "SWAGGER"
    case openAPI30 = "OPENAPI3_0"
}

struct APIGatewayClientSwiftCodeGen: Decodable {
    let modelFormat: ModelFormat?
    let modelLocations: ModelLocations?
    let baseName: String
    let modelOverride: ModelOverride?
    let httpClientConfiguration: HttpClientConfiguration?
    let shapeProtocols: CodeGenFeatureStatus?
    let eventLoopFutureClientAPIs: CodeGenFeatureStatus?
    let minimumCompilerSupport: MinimumCompilerSupport?
    let clientConfigurationType: ClientConfigurationType?
}
