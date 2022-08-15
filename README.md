<p align="center">
<a href="https://github.com/amzn/smoke-aws-generate/actions">
<img src="https://github.com/amzn/smoke-aws-generate/actions/workflows/swift.yml/badge.svg?branch=main" alt="Build - main Branch">
</a>
<a href="http://swift.org">
<img src="https://img.shields.io/badge/swift-5.4|5.5|5.6-orange.svg?style=flat" alt="Swift 5.4, 5.5 and 5.6 Tested">
</a>
<a href="https://gitter.im/SmokeServerSide">
<img src="https://img.shields.io/badge/chat-on%20gitter-ee115e.svg?style=flat" alt="Join the Smoke Server Side community on gitter">
</a>
<img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
</p>

# SmokeAWSGenerate

SmokeAWSGenerate primarily provides a code generator that will generate a Swift client package 
using a Open API/Swagger model for endpoints hosted by AWS API Gateway.

By default, the generator will create two targets in the Swift client package, a Model target and a Client target.
* The model target will create Swift types and enumerations for the objects specified in the model
* The client target will create 
  1. a Swift protocol based on the model operations.
  2. an API Gateway client implementation that conforms to the protocol.
  3. a Mock implementation that conforms to the protocol with optional overrides for each API.
     By default returns a default instance of each APIs return type.
  4. a Throwing Mock implementation that conforms to the protocol with optional overrides for each API.
     By default throws a specified error.
  5. a Configuration type that can used to share client configuration between clients.
  6. an Operations client that can be used to share the underlying http client between clients.

## Step 1: Prepare the location for the new Swift Client

This might be a Github repository or some other repository. Check out this location
so you can add files to it.

## Step 2: Prepare your OpenAPI 3.0 or Swagger model

Depending on your use case, this model can either be hosted with the same Swift package 
as the Swift client or in a separate package. 

### Step 1A: Model in the same Swift package

For models in the same Swift package, just go ahead and create the model according to 
the [Open API spec](https://swagger.io/specification/) or [Swagger spec](https://swagger.io/specification/v2/).
Typically this model will be in the root directory of the Client package.

### Step 1B: Model in the separate Swift Package

If the model is hosted in a separate Swift Package, the model file will need to be specified as a resource
of that package. The following shows the minimal Swift Package manifest that is required for a model package.

```
// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ServiceModel",
    products: [
        .library(
            name: "ServiceModel",
            targets: ["ServiceModel"]),
    ],
    targets: [
        .target(
            name: "ServiceModel",
            dependencies: [],
            path: "api",
            resources: [.copy("OpenAPI30.yaml")]),
    ]
)
```

This model package can have other products and targets if required. If your model package has only 
your model file (for example if you want to share your model across your service and client 
packages independently of anything else), **you will need to add an empty Swift file in the base
directory of the target (in this case /api)** due to a current limitation of SwiftPM.

Then go ahead and create the model according to 
the [Open API spec](https://swagger.io/specification/) or [Swagger spec](https://swagger.io/specification/v2/).

## Step 2: Generate the Client package

Clone this repository (smoke-aws-generate) and from its base directory, run the following command, replacing values as appropriate.

This command will generate the package manifest and other scaffolding required to build the client package. 

### Step 2A: Model in the same Swift package

```
swift run APIGatewayClientInitialize -c release --base-file-path <path-to-the-client-package> \
--base-name "PersistenceExample" \
--model-format "OPENAPI3_0" \
--model-path "OpenAPI30.yaml"
```

### Step 2B: Model in the separate Swift Package

```
swift run APIGatewayClientInitialize -c release --base-file-path <path-to-the-client-package> \
--base-name "PersistenceExample" \
--model-format "OPENAPI3_0" \
--model-path "OpenAPI30.yaml" \
--model-product-dependency "ServiceModel" \
--package-location "https://github.com/example/service-model.git" \
--version-requirement-type "from"
--version-requirement "1.0.0"
```

**Note:** `SWAGGER` must be used for the `--model-format` parameter when using Swagger 2.0 model files.

**Note:** You can optionally specify a `--model-target-dependency` parameter if the target where the
model file is hosted is not the same as the product name.

**Note:** You can also manually generate a Swift package manifest and structure along with the configuration file (see next step). 
The `APIGatewayClientInitialize` executable is simply a convenience and not required to build the client package.

## Step 3: Update the codegen configuration

As part of the previous step, a configuration file called `api-gateway-client-swift-codegen.json`
will have been generated in the base directory of the client package. This file stores configuration 
options for the build-time code generation. 

```
{
  "baseName" : "PersistenceExample",
  "modelFormat" : "OPENAPI3_0",
  "modelLocations" : {
    "default" : {
      "modelFilePath" : "OpenAPI30.yaml",
      "modelProductDependency" : "ServiceModel"
    }
  }
}
```
You can add the following additional options to this configuration file-

* **modelFormat**: The expected format of the model file. Optional; defaulting to `OPENAPI3_0`. `SWAGGER` can also be specified.
* **modelOverride**: A set of overrides to apply to the model. Optional.
* **httpClientConfiguration**: Configuration for the generated http service clients. Optional.
* **shapeProtocols**: `ENABLED` will conform model types to shape protocols that allow for easy conversion between
        different models. Optional; defaulting to `DISABLED`.
* **eventLoopFutureClientAPIs**: `ENABLED` will generate EventLoopFuture-returning client APIs. Mock and Throwing Mock will require an
        EventLoop passed to their initializer. Optional; defaulting to `DISABLED`.
* **minimumCompilerSupport**: `UNKNOWN` will generate a client that supports Swift 5.5 and 5.4. Optional; defaulting to `5.6`.
* **clientConfigurationType**: `GENERATOR` will generate a legacy client generator type instead of the configuration and 
        operations clients types. Optional; defaulting to `CONFIGURATION_OBJECT`.

The schemas for the `modelOverride` and `httpClientConfiguration` fields can be found here - https://github.com/amzn/service-model-swift-code-generate/blob/main/Sources/ServiceModelEntities/ModelOverride.swift.

An example configuration - including `modelOverride` configuration - can be found here - https://github.com/amzn/smoke-framework-examples/blob/612fd9dca5d8417d2293a203aca4b02672889d12/PersistenceExampleService/smoke-framework-codegen.json.

Shape protocols allow you to convert between similar types in different models

```
extension Model1.Location: Model2.LocationShape {}

let model2Location = model1.asModel2Location()
```

## Step 4: Depend on the client package

You can now use the client package from other Swift packages by depending on the Client target.


The easiest way to use the client is to initialize it directly and then at some later point shut it down.

```
let client = APIGatewayPersistenceExampleClient(credentialsProvider: credentialsProvider, 
                                                awsRegion: awsRegion,
                                                endpointHostName: endpointHostName)

...
// Use the client
...

try await client.shutdown()
```

Credential Providers need to conform to the 
[CredentialsProvider protocol from SmokeAWSCore](https://github.com/amzn/smoke-aws/blob/main/Sources/SmokeAWSCore/CredentialsProvider.swift). 
[Smoke AWS Credentials](https://github.com/amzn/smoke-aws-credentials) provides implementations for obtaining or 
assuming short-lived rotating AWS IAM credentials.

The client initializer can also optionally accept `logger`, `timeoutConfiguration`, `connectionPoolConfiguration`,
`retryConfiguration`, `eventLoopProvider` and `reportingConfiguration`.

For use cases where you want to reuse the underlying HTTP client between instances, you can use the operations client type
(or similarly the configuration object type to share client configuration but not the underlying HTTP client).

```
// Start of application
let operationsClient = APIGatewayPersistenceExampleOperationsClient(credentialsProvider: credentialsProvider, 
                                                                    awsRegion: awsRegion,
                                                                    endpointHostName: endpointHostName)
                                                                    
// Per-request
let client = APIGatewayPersistenceExampleClient(operationsClient: operationsClient,
                                                logger: logger)
// Use the client within the request
// This client doesn't need to be explicitly shutdown as it doesn't own the underlying http client

// End of application
try await operationsClient.shutdown()
```

Finally you can use the Mock and Throwing Mock client implementations for unit testing. These implementations 
conform to the generated client protocol. Using this protocol within application code will allow you to test
using a mock client and use the API Gateway client for actual usage.

Each client API can be overridden with any logic required for a unit test.

```
func testCodeThatUsesGetCustomerDetails() {
    func getCustomerDetails(input: PersistenceExampleModel.GetCustomerDetailsRequest) async throws 
    -> PersistenceExampleModel.CustomerAttributes {
       // mock behaviour of the API
    }
    
    let mockClient = MockPersistenceExampleClient(getCustomerDetails: getCustomerDetails)

    // run a test using the mock client
```

# Generate the SmokeAWS library

The `SmokeAWSGenerate` executable is a code generator for the [SmokeAWS](https://github.com/amzn/smoke-aws) library.

## Step 1: Check out the SmokeAWS repository

Clone the SmokeAWS repository to your local machine.

## Step 2: Check out this repository

Clone this repository to your local machine.

## Step 3: Run the code generator

From within your checked out copy of this repository, run this command-

```bash
swift run -c release SmokeAWSGenerate \
  --base-file-path <path_to_the_smoke_aws_repository>
```

## License

This library is licensed under the Apache 2.0 License.
