
module test_cockroach {
  source = "../../modules/cockroachdb"
  vpc_id = "vpc-865c80fb"
  nlb_subnet_ids = ["subnet-d82d7e95","subnet-62e36f3d","subnet-0d23a36b"]
  vpc_cidr_block= ["172.31.0.0/16"]
  fqdn = "test@tester.com"
  ca_crt_path="/tmp/ca.crt"
  ca_key_path="/tmp/ca.key"
}