<p align="center">
<a href="https://travis-ci.com/amzn/smoke-aws-generate">
<img src="https://travis-ci.com/amzn/smoke-aws-generate.svg?branch=master" alt="Build - Master Branch">
</a>
<a href="http://swift.org">
<img src="https://img.shields.io/badge/swift-5.1|5.2|5.3-orange.svg?style=flat" alt="Swift 5.1, 5.2 and 5.3 Tested">
</a>
<img src="https://img.shields.io/badge/ubuntu-16.04|18.04|20.04-yellow.svg?style=flat" alt="Ubuntu 16.04, 18.04 and 20.04 Tested">
<img src="https://img.shields.io/badge/CentOS-8-yellow.svg?style=flat" alt="CentOS 8 Tested">
<img src="https://img.shields.io/badge/AmazonLinux-2-yellow.svg?style=flat" alt="Amazon Linux 2 Tested">
<a href="https://gitter.im/SmokeServerSide">
<img src="https://img.shields.io/badge/chat-on%20gitter-ee115e.svg?style=flat" alt="Join the Smoke Server Side community on gitter">
</a>
<img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
</p>

# SwiftAWSGenerate

SwiftAWSGenerate is a code generator for the [SmokeAWS](https://github.com/amzn/smoke-aws) library.

# Generate the SmokeAWS library

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

# Generate a standalone API Gateway client package from a Swagger 2.0 specification file

You can also use this package to generate a stand-alone API Gateway client package from a Swagger 2.0 specification file. To do this
you can run the following command-

```bash
swift run -c release APIGatewayClientGenerate \
  --base-file-path <output_file_path> \
  --base-name <base_client_name> \
  --model-path <file_path_to_model> \
 [--model-override-path <file_path_to_model_override>]
```

## License

This library is licensed under the Apache 2.0 License.
