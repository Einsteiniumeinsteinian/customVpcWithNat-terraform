# STEPS TO CREATING VPC with Private, Public Subnets with NAT
- Create a VPC with a size /16 IPv4 CIDR block eg: (172.31.0.0/16). This provides up to 65,536 private IPv4 addresses.
- Create a size /20 default public and private subnet in each Availability Zone. This provides up to 4,096 addresses per subnet, a few of which are reserved for our use.
- Create an internet gateway and connect it to your default VPC.
- Create an nat gateway and connect it to your default VPC.
- Add a route to the public route table that points all traffic (0.0.0.0/0) to the internet gateway.
- Add a route to the private route table that points all traffic (0.0.0.0/0) to the nat gateway.
- Create a default security group and associate it with your default VPC.
**Default DHCP and NACL config is used here.**