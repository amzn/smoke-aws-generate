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
// EC2Configuration.swift
// SmokeAWSGenerate
//

import Foundation
import ServiceModelEntities

private let additionalErrors: Set<String> = [
        "Auth",
        "Blocked",
        "DryRunOperation",
        "IdempotentParameterMismatch",
        "IncompleteSignature",
        "InvalidAction",
        "InvalidCharacter",
        "InvalidClientTokenId",
        "InvalidPaginationToken",
        "InvalidParameter",
        "InvalidParameterCombination",
        "InvalidParameterValue",
        "InvalidQueryParameter",
        "MalformedQueryString",
        "MissingAction",
        "MissingAuthenticationToken",
        "MissingParameter",
        "OptInRequired",
        "PendingVerification",
        "RequestExpired",
        "UnauthorizedOperation",
        "UnknownParameter",
        "UnsupportedInstanceAttribute",
        "UnsupportedOperation",
        "UnsupportedProtocol",
        "ValidationError",
        "ActiveVpcPeeringConnectionPerVpcLimitExceeded",
        "AddressLimitExceeded",
        "AsnConflict",
        "AttachmentLimitExceeded",
        "BootForVolumeTypeUnsupported",
        "BundlingInProgress",
        "CannotDelete",
        "ClientVpnAuthorizationRuleLimitExceeded",
        "ClientVpnCertificateRevocationListLimitExceeded",
        "ClientVpnEndpointAssociationExists",
        "ClientVpnEndpointLimitExceeded",
        "ClientVpnRouteLimitExceeded",
        "ClientVpnTerminateConnectionsLimitExceeded",
        "CidrConflict",
        "ConcurrentSnapshotLimitExceeded",
        "ConcurrentTagAccess",
        "CustomerGatewayLimitExceeded",
        "CustomerKeyHasBeenRevoked",
        "DeleteConversionTaskError",
        "DefaultSubnetAlreadyExistsInAvailabilityZone",
        "DefaultVpcAlreadyExists",
        "DefaultVpcDoesNotExist",
        "DependencyViolation",
        "DisallowedForDedicatedTenancyNetwork",
        "DiskImageSizeTooLarge",
        "DuplicateSubnetsInSameZone",
        "EIPMigratedToVpc",
        "EncryptedVolumesNotSupported",
        "ExistingVpcEndpointConnections",
        "FleetNotInModifiableState",
        "FlowLogAlreadyExists",
        "FlowLogsLimitExceeded",
        "FilterLimitExceeded",
        "Gateway.NotAttached",
        "HostAlreadyCoveredByReservation",
        "HostLimitExceeded",
        "IdempotentInstanceTerminated",
        "InaccessibleStorageLocation",
        "IncorrectInstanceState",
        "IncorrectModificationState",
        "IncorrectState",
        "IncompatibleHostRequirements",
        "InstanceAlreadyLinked",
        "InstanceCreditSpecification.NotSupported",
        "InstanceLimitExceeded",
        "InsufficientCapacityOnHost",
        "InsufficientFreeAddressesInSubnet",
        "InsufficientReservedInstancesCapacity",
        "InternetGatewayLimitExceeded",
        "InvalidAddress.Locked",
        "InvalidAddress.Malformed",
        "InvalidAddress.NotFound",
        "InvalidAddressID.NotFound",
        "InvalidAffinity",
        "InvalidAllocationID.NotFound",
        "InvalidAMIAttributeItemValue",
        "InvalidAMIID.Malformed",
        "InvalidAMIID.NotFound",
        "InvalidAMIID.Unavailable",
        "InvalidAMIName.Duplicate",
        "InvalidAMIName.Malformed",
        "InvalidAssociationID.NotFound",
        "InvalidAttachment.NotFound",
        "InvalidAttachmentID.NotFound",
        "InvalidAutoPlacement",
        "InvalidAvailabilityZone",
        "InvalidBlockDeviceMapping",
        "InvalidBundleID.NotFound",
        "InvalidCidr.InUse",
        "InvalidClientToken",
        "InvalidClientVpnAssociationIdNotFound",
        "InvalidClientVpnConnection.IdNotFound",
        "InvalidClientVpnConnection.UserNotFound",
        "InvalidClientVpnDuplicateAuthorizationRule",
        "InvalidClientVpnDuplicateRoute",
        "InvalidClientVpnEndpointAuthorizationRuleNotFound",
        "InvalidClientVpnRouteNotFound",
        "InvalidClientVpnSubnetId.DifferentAccount",
        "InvalidClientVpnSubnetId.DuplicateAz",
        "InvalidClientVpnSubnetId.NotFound",
        "InvalidClientVpnSubnetId.OverlappingCidr",
        "InvalidClientVpnActiveAssociationNotFound",
        "InvalidClientVpnEndpointId.NotFound",
        "InvalidConversionTaskId",
        "InvalidConversionTaskId.Malformed",
        "InvalidCpuCredits.Malformed",
        "InvalidCustomerGateway.DuplicateIpAddress",
        "InvalidCustomerGatewayId.Malformed",
        "InvalidCustomerGatewayID.NotFound",
        "InvalidCustomerGatewayState",
        "InvalidDevice.InUse",
        "InvalidDhcpOptionID.NotFound",
        "InvalidDhcpOptionsID.NotFound",
        "InvalidDhcpOptionsId.Malformed",
        "InvalidExportTaskID.NotFound",
        "InvalidFilter",
        "InvalidFlowLogId.NotFound",
        "InvalidFormat",
        "InvalidFpgaImageID.Malformed",
        "InvalidFpgaImageID.NotFound",
        "InvalidGatewayID.NotFound",
        "InvalidGroup.Duplicate",
        "InvalidGroupId.Malformed",
        "InvalidGroup.InUse",
        "InvalidGroup.NotFound",
        "InvalidGroup.Reserved",
        "InvalidHostConfiguration",
        "InvalidHostId",
        "InvalidHostID.Malformed",
        "InvalidHostId.Malformed",
        "InvalidHostID.NotFound",
        "InvalidHostId.NotFound",
        "InvalidHostReservationId.Malformed",
        "InvalidHostReservationOfferingId.Malformed",
        "InvalidHostState",
        "InvalidIamInstanceProfileArn.Malformed",
        "InvalidID",
        "InvalidInput",
        "InvalidInstanceAttributeValue",
        "InvalidInstanceCreditSpecification.DuplicateInstanceId",
        "InvalidInstanceID",
        "InvalidInstanceID.Malformed",
        "InvalidInstanceID.NotFound",
        "InvalidInstanceID.NotLinkable",
        "InvalidInstanceFamily",
        "InvalidInstanceState",
        "InvalidInstanceType",
        "InvalidInterface.IpAddressLimitExceeded",
        "InvalidInternetGatewayId.Malformed",
        "InvalidInternetGatewayID.NotFound",
        "InvalidIPAddress.InUse",
        "InvalidKernelId.Malformed",
        "InvalidKey.Format",
        "InvalidKeyPair.Duplicate",
        "InvalidKeyPair.Format",
        "InvalidKeyPair.NotFound",
        "InvalidCapacityReservationIdMalformedException",
        "InvalidCapacityReservationIdNotFoundException",
        "InvalidLaunchTemplateId.Malformed",
        "InvalidLaunchTemplateId.NotFound",
        "InvalidLaunchTemplateId.VersionNotFound",
        "InvalidLaunchTemplateName.AlreadyExistsException",
        "InvalidLaunchTemplateName.MalformedException",
        "InvalidLaunchTemplateName.NotFoundException",
        "InvalidManifest",
        "InvalidMaxResults",
        "InvalidNatGatewayID.NotFound",
        "InvalidNetworkAclEntry.NotFound",
        "InvalidNetworkAclId.Malformed",
        "InvalidNetworkAclID.NotFound",
        "InvalidNetworkLoadBalancerArn.Malformed",
        "InvalidNetworkLoadBalancerArn.NotFound",
        "InvalidNetworkInterfaceAttachmentId.Malformed",
        "InvalidNetworkInterface.InUse",
        "InvalidNetworkInterfaceId.Malformed",
        "InvalidNetworkInterfaceID.NotFound",
        "InvalidNextToken",
        "InvalidOption.Conflict",
        "InvalidPermission.Duplicate",
        "InvalidPermission.Malformed",
        "InvalidPermission.NotFound",
        "InvalidPlacementGroup.Duplicate",
        "InvalidPlacementGroup.InUse",
        "InvalidPlacementGroup.Unknown",
        "InvalidPolicyDocument",
        "InvalidPrefixListId.Malformed",
        "InvalidPrefixListId.NotFound",
        "InvalidProductInfo",
        "InvalidPurchaseToken.Expired",
        "InvalidPurchaseToken.Malformed",
        "InvalidQuantity",
        "InvalidRamDiskId.Malformed",
        "InvalidRegion",
        "InvalidRequest",
        "InvalidReservationID.Malformed",
        "InvalidReservationID.NotFound",
        "InvalidReservedInstancesId",
        "InvalidReservedInstancesOfferingId",
        "InvalidResourceType.Unknown",
        "InvalidRoute.InvalidState",
        "InvalidRoute.Malformed",
        "InvalidRoute.NotFound",
        "InvalidRouteTableId.Malformed",
        "InvalidRouteTableID.NotFound",
        "InvalidScheduledInstance",
        "InvalidSecurityGroupId.Malformed",
        "InvalidSecurityGroupID.NotFound",
        "InvalidSecurity.RequestHasExpired",
        "InvalidServiceName",
        "InvalidSnapshotID.Malformed",
        "InvalidSnapshot.InUse",
        "InvalidSnapshot.NotFound",
        "InvalidSpotDatafeed.NotFound",
        "InvalidSpotFleetRequestConfig",
        "InvalidSpotFleetRequestId.Malformed",
        "InvalidSpotFleetRequestId.NotFound",
        "InvalidSpotInstanceRequestID.Malformed",
        "InvalidSpotInstanceRequestID.NotFound",
        "InvalidState",
        "InvalidStateTransition",
        "InvalidSubnet",
        "InvalidSubnet.Conflict",
        "InvalidSubnetId.Malformed",
        "InvalidSubnetId.NotFound",
        "InvalidSubnetID.NotFound",
        "InvalidSubnet.Range",
        "InvalidTagKey.Malformed",
        "InvalidTargetArn.Unknown",
        "InvalidTenancy",
        "InvalidTime",
        "InvalidUserID.Malformed",
        "InvalidVolumeID.Duplicate",
        "InvalidVolumeID.Malformed",
        "InvalidVolumeID.ZoneMismatch",
        "InvalidVolume.NotFound",
        "InvalidVolume.ZoneMismatch",
        "InvalidVpcEndpointId.Malformed",
        "InvalidVpcEndpoint.NotFound",
        "InvalidVpcEndpointId.NotFound",
        "InvalidVpcEndpointService.NotFound",
        "InvalidVpcEndpointServiceId.NotFound",
        "InvalidVpcEndpointType",
        "InvalidVpcID.Malformed",
        "InvalidVpcID.NotFound",
        "InvalidVpcPeeringConnectionId.Malformed",
        "InvalidVpcPeeringConnectionID.NotFound",
        "InvalidVpcPeeringConnectionState.DnsHostnamesDisabled",
        "InvalidVpcRange",
        "InvalidVpcState",
        "InvalidVpnConnectionID",
        "InvalidVpnConnectionID.NotFound",
        "InvalidVpnConnection.InvalidState",
        "InvalidVpnConnection.InvalidType",
        "InvalidVpnGatewayAttachment.NotFound",
        "InvalidVpnGatewayID.NotFound",
        "InvalidVpnGatewayState",
        "InvalidZone.NotFound",
        "KeyPairLimitExceeded",
        "LegacySecurityGroup",
        "LimitPriceExceeded",
        "LogDestinationNotFoundException",
        "LogDestinationPermissionIssue",
        "MaxIOPSLimitExceeded",
        "MaxScheduledInstanceCapacityExceeded",
        "MaxSpotFleetRequestCountExceeded",
        "MaxSpotInstanceCountExceeded",
        "MaxTemplateLimitExceeded",
        "MaxTemplateVersionLimitExceeded",
        "MissingInput",
        "NatGatewayLimitExceeded",
        "NatGatewayMalformed",
        "NatGatewayNotFound",
        "NetworkAclEntryAlreadyExists",
        "NetworkAclEntryLimitExceeded",
        "NetworkAclLimitExceeded",
        "NetworkInterfaceLimitExceeded",
        "NonEBSInstance",
        "NoSuchVersion",
        "NotExportable",
        "OperationNotPermitted",
        "OutstandingVpcPeeringConnectionLimitExceeded",
        "PendingSnapshotLimitExceeded",
        "PendingVpcPeeringConnectionLimitExceeded",
        "PlacementGroupLimitExceeded",
        "PrivateIpAddressLimitExceeded",
        "RequestResourceCountExceeded",
        "ReservedInstancesCountExceeded",
        "ReservedInstancesLimitExceeded",
        "ReservedInstancesUnavailable",
        "Resource.AlreadyAssigned",
        "Resource.AlreadyAssociated",
        "ResourceCountExceeded",
        "ResourceCountLimitExceeded",
        "ResourceLimitExceeded",
        "RouteAlreadyExists",
        "RouteLimitExceeded",
        "RouteTableLimitExceeded",
        "RulesPerSecurityGroupLimitExceeded",
        "ScheduledInstanceLimitExceeded",
        "ScheduledInstanceParameterMismatch",
        "ScheduledInstanceSlotNotOpen",
        "ScheduledInstanceSlotUnavailable",
        "SecurityGroupLimitExceeded",
        "SecurityGroupsPerInstanceLimitExceeded",
        "SecurityGroupsPerInterfaceLimitExceeded",
        "SignatureDoesNotMatch",
        "SnapshotCopyUnsupported.InterRegion",
        "SnapshotCreationPerVolumeRateExceeded",
        "SnapshotLimitExceeded",
        "SubnetLimitExceeded",
        "TagLimitExceeded",
        "UnavailableHostRequirements",
        "UnknownPrincipalType.Unsupported",
        "UnknownVolumeType",
        "Unsupported",
        "UnsupportedHibernationConfiguration",
        "UnsupportedHostConfiguration",
        "UnsupportedInstanceTypeOnHost",
        "UnsupportedTenancy",
        "VolumeInUse",
        "VolumeIOPSLimit",
        "VolumeLimitExceeded",
        "VolumeTypeNotAvailableInZone",
        "VpcCidrConflict",
        "VPCIdNotSpecified",
        "VpcEndpointLimitExceeded",
        "VpcLimitExceeded",
        "VpcPeeringConnectionAlreadyExists",
        "VpcPeeringConnectionsPerVpcLimitExceeded",
        "VPCResourceNotSpecified",
        "VpnConnectionLimitExceeded",
        "VpnGatewayAttachmentLimitExceeded",
        "VpnGatewayLimitExceeded",
        "ZonesMismatched",
        "InsufficientAddressCapacity",
        "InsufficientCapacity",
        "InsufficientInstanceCapacity",
        "InsufficientHostCapacity",
        "InsufficientReservedInstanceCapacity",
        "InternalError",
        "InternalFailure",
        "RequestLimitExceeded",
        "ServiceUnavailable",
        "Unavailable"]

internal struct EC2Configuration {
    static let modelOverride = ModelOverride<NoModelTypeOverrides>(
        fieldRawTypeOverride: ["Long": CommonConfiguration.intOverride],
        additionalErrors: additionalErrors)
    
    static let httpClientConfiguration = HttpClientConfiguration(
        retryOnUnknownError: true,
        knownErrorsDefaultRetryBehavior: .fail,
        unretriableUnknownErrors: [],
        retriableUnknownErrors: [],
        clientDelegateParameters: ["outputListDecodingStrategy: .collapseListUsingItemTag(\"item\")",
             "inputQueryKeyEncodeTransformStrategy: .capitalizeFirstCharacter"])
    
    static let serviceModelDetails = ServiceModelDetails(
        serviceName: "ec2", serviceVersion: "2016-11-15",
        baseName: "ElasticComputeCloud", modelOverride: modelOverride,
        httpClientConfiguration: httpClientConfiguration,
        signAllHeaders: false)
}
