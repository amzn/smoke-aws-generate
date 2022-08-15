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
    let baseName: String
}
