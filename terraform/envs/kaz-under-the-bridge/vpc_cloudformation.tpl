AWSTemplateFormatVersion: "2010-09-09"
Description: UTBSandbox01

Parameters:
  VpcCIDR:
    Type: String
    Default: "10.0.0.0/16"
    Description: "CIDR block for the VPC"
  SubnetPubACIDR:
    Type: String
    Default: "10.0.0.0/24"
    Description: "CIDR block for the public subnet A"
  SubnetPubCCIDR:
    Type: String
    Default: "10.0.1.0/24"
    Description: "CIDR block for the public subnet C"
  SubnetProACIDR:
    Type: String
    Default: "10.0.10.0/24"
    Description: "CIDR block for the protected subnet A"
  SubnetProCCIDR:
    Type: String
    Default: "10.0.11.0/24"
    Description: "CIDR block for the protected subnet C"
  SubnetPriACIDR:
    Type: String
    Default: "10.0.20.0/24"
    Description: "CIDR block for the private subnet A"
  SubnetPriCCIDR:
    Type: String
    Default: "10.0.21.0/24"
    Description: "CIDR block for the private subnet C"

Resources:
  VpcUTBSandbox01:
    Type: "AWS::EC2::VPC"
    DeletionPolicy: Delete
    Properties:
      CidrBlock: !Ref VpcCIDR
      EnableDnsHostnames: "true"
      EnableDnsSupport: "true"
      Tags:
        - Key: Name
          Value: vpc-UTBSandbox01
  FlowLogsRole:
    Type: "AWS::IAM::Role"
    DeletionPolicy: Delete
    Properties:
      RoleName: fl-vpc-UTBSandbox01
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - vpc-flow-logs.amazonaws.com
            Action:
              - "sts:AssumeRole"
      Path: /
  FlowLogsPolicy:
    Type: "AWS::IAM::Policy"
    DeletionPolicy: Delete
    Properties:
      PolicyName: FlowLogsPolicy
      PolicyDocument:
        Version: 2012-10-17
        Statement:
          - Action:
              - "logs:CreateLogGroup"
              - "logs:CreateLogStream"
              - "logs:PutLogEvents"
              - "logs:DescribeLogGroups"
              - "logs:DescribeLogStreams"
            Effect: Allow
            Resource: "*"
      Roles:
        - !Ref FlowLogsRole
  VPCFlowLog:
    Type: "AWS::EC2::FlowLog"
    DeletionPolicy: Delete
    Properties:
      DeliverLogsPermissionArn: !GetAtt
        - FlowLogsRole
        - Arn
      LogGroupName: vpc-UTBSandbox01
      ResourceId: !Ref VpcUTBSandbox01
      ResourceType: VPC
      Tags:
        - Key: Name
          Value: vpc-UTBSandbox01
      TrafficType: ALL
  CloudWatchLogGroup0:
    Type: "AWS::Logs::LogGroup"
    DeletionPolicy: Delete
    Properties:
      LogGroupName: vpc-UTBSandbox01
      RetentionInDays: "7"
      Tags:
        - Key: Name
          Value: vpc-UTBSandbox01
        - Key: Application
          Value: UTBSandbox01
  SubnetUTBSandbox01PublicA:
    Type: "AWS::EC2::Subnet"
    DeletionPolicy: Delete
    Properties:
      VpcId: !Ref VpcUTBSandbox01
      AvailabilityZone: ap-northeast-1a
      CidrBlock: !Ref SubnetPubACIDR
      MapPublicIpOnLaunch: "false"
      Tags:
        - Key: Name
          Value: subnet-UTBSandbox01-public-a
  SubnetUTBSandbox01PublicC:
    Type: "AWS::EC2::Subnet"
    DeletionPolicy: Delete
    Properties:
      VpcId: !Ref VpcUTBSandbox01
      AvailabilityZone: ap-northeast-1c
      CidrBlock: !Ref SubnetPubCCIDR
      MapPublicIpOnLaunch: "false"
      Tags:
        - Key: Name
          Value: subnet-UTBSandbox01-public-c
  SubnetUTBSandbox01ProtectedA:
    Type: "AWS::EC2::Subnet"
    DeletionPolicy: Delete
    Properties:
      VpcId: !Ref VpcUTBSandbox01
      AvailabilityZone: ap-northeast-1a
      CidrBlock: !Ref SubnetProACIDR
      MapPublicIpOnLaunch: "false"
      Tags:
        - Key: Name
          Value: subnet-UTBSandbox01-protected-a
  SubnetUTBSandbox01ProtectedC:
    Type: "AWS::EC2::Subnet"
    DeletionPolicy: Delete
    Properties:
      VpcId: !Ref VpcUTBSandbox01
      AvailabilityZone: ap-northeast-1c
      CidrBlock: !Ref SubnetProCCIDR
      MapPublicIpOnLaunch: "false"
      Tags:
        - Key: Name
          Value: subnet-UTBSandbox01-protected-c
  SubnetUTBSandbox01PrivateA:
    Type: "AWS::EC2::Subnet"
    DeletionPolicy: Delete
    Properties:
      VpcId: !Ref VpcUTBSandbox01
      AvailabilityZone: ap-northeast-1a
      CidrBlock: !Ref SubnetPriACIDR
      MapPublicIpOnLaunch: "false"
      Tags:
        - Key: Name
          Value: subnet-UTBSandbox01-private-a
  SubnetUTBSandbox01PrivateC:
    Type: "AWS::EC2::Subnet"
    DeletionPolicy: Delete
    Properties:
      VpcId: !Ref VpcUTBSandbox01
      AvailabilityZone: ap-northeast-1c
      CidrBlock: !Ref SubnetPriCCIDR
      MapPublicIpOnLaunch: "false"
      Tags:
        - Key: Name
          Value: subnet-UTBSandbox01-private-c
  DbsubnetUTBSandbox01:
    Type: "AWS::RDS::DBSubnetGroup"
    DeletionPolicy: Delete
    Properties:
      DBSubnetGroupDescription: "for subnet-UTBSandbox01-private-a, subnet-UTBSandbox01-private-c"
      DBSubnetGroupName: dbsubnet-UTBSandbox01
      SubnetIds:
        - !Ref SubnetUTBSandbox01PrivateA
        - !Ref SubnetUTBSandbox01PrivateC
      Tags:
        - Key: Name
          Value: dbsubnet-UTBSandbox01
  IgwUTBSandbox01:
    Type: "AWS::EC2::InternetGateway"
    DeletionPolicy: Delete
    Properties:
      Tags:
        - Key: Name
          Value: igw-UTBSandbox01
  IgwUTBSandbox01Attach:
    Type: "AWS::EC2::VPCGatewayAttachment"
    DeletionPolicy: Delete
    Properties:
      VpcId: !Ref VpcUTBSandbox01
      InternetGatewayId: !Ref IgwUTBSandbox01
  NgwUTBSandbox01A:
    Type: "AWS::EC2::NatGateway"
    DeletionPolicy: Delete
    Properties:
      AllocationId: !GetAtt
        - EipNgwUTBSandbox01A
        - AllocationId
      SubnetId: !Ref SubnetUTBSandbox01PublicA
      Tags:
        - Key: Name
          Value: ngw-UTBSandbox01-a
        - Key: Application
          Value: UTBSandbox01
  EipNgwUTBSandbox01A:
    Type: "AWS::EC2::EIP"
    DeletionPolicy: Delete
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: eip-ngw-UTBSandbox01-a
        - Key: Application
          Value: UTBSandbox01
  NgwUTBSandbox01C:
    Type: "AWS::EC2::NatGateway"
    DeletionPolicy: Delete
    Properties:
      AllocationId: !GetAtt
        - EipNgwUTBSandbox01C
        - AllocationId
      SubnetId: !Ref SubnetUTBSandbox01PublicC
      Tags:
        - Key: Name
          Value: ngw-UTBSandbox01-c
        - Key: Application
          Value: UTBSandbox01
  EipNgwUTBSandbox01C:
    Type: "AWS::EC2::EIP"
    DeletionPolicy: Delete
    Properties:
      Domain: vpc
      Tags:
        - Key: Name
          Value: eip-ngw-UTBSandbox01-c
        - Key: Application
          Value: UTBSandbox01
  RtbUTBSandbox01Public:
    Type: "AWS::EC2::RouteTable"
    DeletionPolicy: Delete
    Properties:
      VpcId: !Ref VpcUTBSandbox01
      Tags:
        - Key: Name
          Value: rtb-UTBSandbox01-public
  RtbUTBSandbox01PublicRoute0:
    Type: "AWS::EC2::Route"
    DependsOn: IgwUTBSandbox01Attach
    DeletionPolicy: Delete
    Properties:
      RouteTableId: !Ref RtbUTBSandbox01Public
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref IgwUTBSandbox01
  RtbUTBSandbox01Private:
    Type: "AWS::EC2::RouteTable"
    DeletionPolicy: Delete
    Properties:
      VpcId: !Ref VpcUTBSandbox01
      Tags:
        - Key: Name
          Value: rtb-UTBSandbox01-private
  RtbUTBSandbox01ProtectedA:
    Type: "AWS::EC2::RouteTable"
    DeletionPolicy: Delete
    Properties:
      VpcId: !Ref VpcUTBSandbox01
      Tags:
        - Key: Name
          Value: rtb-UTBSandbox01-protected-a
  RtbUTBSandbox01ProtectedARoute0:
    Type: "AWS::EC2::Route"
    DeletionPolicy: Delete
    Properties:
      RouteTableId: !Ref RtbUTBSandbox01ProtectedA
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NgwUTBSandbox01A
  RtbUTBSandbox01ProtectedC:
    Type: "AWS::EC2::RouteTable"
    DeletionPolicy: Delete
    Properties:
      VpcId: !Ref VpcUTBSandbox01
      Tags:
        - Key: Name
          Value: rtb-UTBSandbox01-protected-c
  RtbUTBSandbox01ProtectedCRoute0:
    Type: "AWS::EC2::Route"
    DeletionPolicy: Delete
    Properties:
      RouteTableId: !Ref RtbUTBSandbox01ProtectedC
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NgwUTBSandbox01C
  SubnetRouteTableAssociationSubnetUTBSandbox01PublicA:
    Type: "AWS::EC2::SubnetRouteTableAssociation"
    DeletionPolicy: Delete
    Properties:
      SubnetId: !Ref SubnetUTBSandbox01PublicA
      RouteTableId: !Ref RtbUTBSandbox01Public
  SubnetRouteTableAssociationSubnetUTBSandbox01PublicC:
    Type: "AWS::EC2::SubnetRouteTableAssociation"
    DeletionPolicy: Delete
    Properties:
      SubnetId: !Ref SubnetUTBSandbox01PublicC
      RouteTableId: !Ref RtbUTBSandbox01Public
  SubnetRouteTableAssociationSubnetUTBSandbox01ProtectedA:
    Type: "AWS::EC2::SubnetRouteTableAssociation"
    DeletionPolicy: Delete
    Properties:
      SubnetId: !Ref SubnetUTBSandbox01ProtectedA
      RouteTableId: !Ref RtbUTBSandbox01ProtectedA
  SubnetRouteTableAssociationSubnetUTBSandbox01ProtectedC:
    Type: "AWS::EC2::SubnetRouteTableAssociation"
    DeletionPolicy: Delete
    Properties:
      SubnetId: !Ref SubnetUTBSandbox01ProtectedC
      RouteTableId: !Ref RtbUTBSandbox01ProtectedC
  SubnetRouteTableAssociationSubnetUTBSandbox01PrivateA:
    Type: "AWS::EC2::SubnetRouteTableAssociation"
    DeletionPolicy: Delete
    Properties:
      SubnetId: !Ref SubnetUTBSandbox01PrivateA
      RouteTableId: !Ref RtbUTBSandbox01Private
  SubnetRouteTableAssociationSubnetUTBSandbox01PrivateC:
    Type: "AWS::EC2::SubnetRouteTableAssociation"
    DeletionPolicy: Delete
    Properties:
      SubnetId: !Ref SubnetUTBSandbox01PrivateC
      RouteTableId: !Ref RtbUTBSandbox01Private
  EndpointUTBSandbox01S3Endpoint:
    Type: AWS::EC2::VPCEndpoint
    Properties:
      PolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Principal: "*"
            Action:
              - s3:*
            Resource: "*"
      RouteTableIds:
        - !Ref RtbUTBSandbox01ProtectedA
        - !Ref RtbUTBSandbox01ProtectedC
      ServiceName: !Sub com.amazonaws.${AWS::Region}.s3
      VpcId: !Ref VpcUTBSandbox01
