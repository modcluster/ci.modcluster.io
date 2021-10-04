# setup script to create the jenkins in ibmcloud
# you need to log in before.
# create vpc
ibmcloud is target --gen 2
ibmcloud is vpc-create modclustervpc
VPC_ID=`ibmcloud is vpc modclustervpc | grep ^ID | awk '{ print $2 }'`
# create gateway
ibmcloud is public-gateway-create modclustergateway $VPC_ID eu-de-1
GWY_ID=`ibmcloud is public-gateway modclustergateway | grep ^ID | awk '{ print $2 }'`
# create a subnet (why 256 :D)
ibmcloud is subnet-create modclustersubnet $VPC_ID --zone eu-de-1 --ipv4-address-count 256
# --public-gateway-id $GWY_ID
SBN_ID=`ibmcloud is subnet modclustersubnet  | grep ^ID | awk '{ print $2 }'`
# attach the gateway to the subnet
ibmcloud is subnet-update $SBN_ID --public-gateway-id $GWY_ID
# create the SSH keys
ibmcloud is key karm >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
  ibmcloud is key-create karm @karm.key 
fi
  ibmcloud is key jfclere >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
  ibmcloud is key-create jfclere @jfclere.key
fi
# create the instance 
# x2-2x8         amd64          balanced           2       8             4000              1000 (enough)
#    --placement-group <PLACEMENT_GROUP_NAME>
# find the image: ibmcloud is images | grep available (here ibm-debian-10-8-minimal-amd64-1)
#IMG_ID=r010-6095acf1-5165-4745-98ae-c51d2c7980ea
# find the image: ibmcloud is images | grep available (here ibm-redhat-7-9-minimal-amd64-3)
IMG_ID=r010-7e2107f3-d581-46f5-ac06-479b90bcdc3b
# list the keys
KEYS=""
for key in `ibmcloud is keys | grep ^r010- | awk ' { print $1 } '`
do
  echo $key
  if [ -z $KEYS ]; then
    KEYS=$key
  else
    KEYS="$KEYS,$key"
  fi
done
echo $KEYS
# create the instance.
ibmcloud is instance-create \
    modcluster \
    $VPC_ID \
    eu-de-1 \
    bx2-2x8 \
    $SBN_ID \
    --image-id $IMG_ID \
    --key-ids $KEYS \
    --volume-attach @modclustervol.json \
    --resource-group-name Default
# create the address to access it.
IST_ID=`ibmcloud is instances | grep modcluster | awk ' { print $1 } '`
NIC_ID=`ibmcloud is instance $IST_ID | grep Primary | awk ' { print $3 } '`
ibmcloud is floating-ip modcluster-flip >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
  # Not existing let's create it.
  ibmcloud is floating-ip-reserve modcluster-flip --zone=eu-de-1
fi
# 20210930 try (failed)
#ibmcloud is floating-ip-reserve \
#    my-floatingip \
#    --nic-id $NIC_ID
# Allow port 22 and 80,443 to the security group
SCG_ID=`ibmcloud is vpc-sg modclustervpc | grep ^ID | grep r010- | awk ' { print $2 } '`
ibmcloud is sg-rulec $SCG_ID inbound tcp --port-min=22 --port-max=22
ibmcloud is sg-rulec $SCG_ID inbound tcp --port-min=80 --port-max=80
ibmcloud is sg-rulec $SCG_ID inbound tcp --port-min=443 --port-max=443
ibmcloud is sg-rulec $SCG_ID inbound tcp --port-min=64387 --port-max=64387 --remote 66.187.232.0/24
ibmcloud is sg-rulec $SCG_ID inbound tcp --port-min=64387 --port-max=64387 --remote 213.175.37.0/24
ibmcloud is sg-rulec $SCG_ID inbound tcp --port-min=64387 --port-max=64387 --remote 66.187.233.0/24
ibmcloud is sg-rulec $SCG_ID inbound icmp --icmp-type 8 --icmp-code 0
# get the instance address
FIP_ID=`ibmcloud is floating-ips | grep modcluster-flip | awk ' { print $1 } '`
ibmcloud is floating-ip-update $FIP_ID --nic-id $NIC_ID

#ibmcloud is instance-network-interfaces $IST_ID --json
# we need to figure out how to get the floating_ips piece...
#ibmcloud is ip r010-754b4b66-ae99-45df-81dc-d3e9367f0917

