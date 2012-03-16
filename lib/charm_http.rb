require 'rubygems'
require 'net/http'
gem 'net-ssh', '~> 2.1.4'
require 'net/ssh'
require 'aws-sdk'

AWS.config(
  "access_key_id" => ENV["aws_access_key_id"],
  "secret_access_key" => ENV["aws_secret_access_key"])

EC2 = AWS::EC2.new.regions["us-east-1"]
IMAGE = EC2.images["ami-31814f58"]
KEY = EC2.key_pairs.create("charm_http")
GROUP = EC2.security_groups.create("charm_http")
GROUP.authorize_ingress(:tcp, 22, "0.0.0.0/0")

class CharmHttp
end

require 'charm_http/runner'
require 'charm_http/grapher'

