FIP_ID=`ibmcloud is floating-ips | grep modcluster-flip | awk ' { print $1 } '`
IST_ID=`ibmcloud is instances | grep modcluster | awk ' { print $1 } '`
SBN_ID=`ibmcloud is subnet modclustersubnet  | grep ^ID | awk '{ print $2 }'`
GWY_ID=`ibmcloud is public-gateway modclustergateway | grep ^ID | awk '{ print $2 }'`
VPC_ID=`ibmcloud is vpc modclustervpc | grep ^ID | awk '{ print $2 }'`
# release the floating-ip. (NO we reuse it for ever...)
#ibmcloud is floating-ip-release $FIP_ID --force
# delete the instance
ibmcloud is instance-delete $IST_ID --force
# wait until it is deleted
while true
do
  ibmcloud is instance $IST_ID
  if [ $? -ne 0 ]; then
    break;
  fi
  sleep 10
done
# delete the subnet
ibmcloud is subnet-delete $SBN_ID --force
# delete the public gateway
ibmcloud is public-gateway-delete $GWY_ID --force
# wait until it is deleted
while true
do
  ibmcloud is public-gateway $GWY_ID
  if [ $? -ne 0 ]; then
    break;
  fi
  sleep 10
done
# delete the vpc
ibmcloud is vpc-delete $VPC_ID --force
