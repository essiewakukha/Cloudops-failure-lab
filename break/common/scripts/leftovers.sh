#!/usr/bin/env bash
# Run after eks-destroy. Everything should be empty.
R=${1:-us-east-1}
echo "== EKS clusters";   aws eks list-clusters --region "$R" --query 'clusters' --output text
echo "== Load balancers"; aws elbv2 describe-load-balancers --region "$R" --query 'LoadBalancers[].LoadBalancerName' --output text
echo "== NAT gateways";   aws ec2 describe-nat-gateways --region "$R" --filter Name=state,Values=available,pending --query 'NatGateways[].NatGatewayId' --output text
echo "== Elastic IPs";    aws ec2 describe-addresses --region "$R" --query 'Addresses[].PublicIp' --output text
echo "== EC2 instances";  aws ec2 describe-instances --region "$R" --filters Name=instance-state-name,Values=running,pending --query 'Reservations[].Instances[].InstanceId' --output text
echo "Blank lines above = nothing expensive left. (S3/ECR from core are fine to keep.)"