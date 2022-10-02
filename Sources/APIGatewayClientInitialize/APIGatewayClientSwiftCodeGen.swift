//
//  APIGatewayClientSwiftCodeGen.swift
//  APIGatewayClientGenerate
//

import ServiceModelEntities
import ServiceModelCodeGeneration
import APIGatewayClientModelGenerate
import ArgumentParser

struct ModelLocations: Encodable {
    let `default`: ModelLocation?
    
    init(`default`: ModelLocation?) {
        self.default = `default`
    }
}

enum ModelFormat: String, Codable, ExpressibleByArgument {
    case swagger = "SWAGGER"
    case openAPI30 = "OPENAPI3_0"
}

struct APIGatewayClientSwiftCodeGen: Encodable {
    let modelFormat: ModelFormat?
    let modelLocations: ModelLocations?
    let modelTargets: ModelTargets?
    let baseName: String
}

struct ModelTarget: Encodable {
    let modelTargetName: String?
}

struct ModelTargets: Encodable {
    let `default`: ModelTarget?
    let targetMap: [String: ModelTarget]
    
    enum CodingKeys: String, CodingKey {
        case `default`
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let theDefault = self.default {
            try container.encode(theDefault, forKey: .default)
        }
        
        try self.targetMap.encode(to: encoder)
    }
}
