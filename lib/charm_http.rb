require 'rubygems'
require 'ruby-debug'
require 'net/http'
gem 'net-ssh', '~> 2.1.4'
require 'net/ssh'
require 'aws-sdk'
require 'active_support/core_ext/hash'

AWS.config(
  "access_key_id" => ENV["AWS_ACCESS_KEY_ID"],
  "secret_access_key" => ENV["AWS_SECRET_ACCESS_KEY"])

class CharmHttp
  C = {
    :version => 1,
    :ec2 => AWS::EC2.new.regions["us-east-1"]
  }

  name = "charm_http#{C[:version]}"
  key_file = ENV['HOME'] + "/.ssh/#{name}"

  if key_pair = C[:ec2].key_pairs.find {|n| n.name == name}
    key_pair.delete and exit if !File.exist?(key_file)
 else
    key_pair = C[:ec2].key_pairs.create(name)
    File.write(key_file, key_pair.private_key)
  end

  C[:key_pair] = key_pair
  C[:key_data] = [File.read(key_file)]

  if !group = C[:ec2].security_groups.find {|n| n.name == name}
    group = C[:ec2].security_groups.create(name)
    group.authorize_ingress(:tcp, 22, "0.0.0.0/0")
  end
  C[:security_groups] = group

  C[:image] = C[:ec2].images["ami-1a837773"]

  def self.ssh(instance, command)
    value = nil
    puts "#{instance.public_dns_name}: #{command}"
    Net::SSH.start(instance.public_dns_name, "ubuntu", :key_data => C[:key_data]) { |ssh| value = ssh.exec!(command)}
    value
  rescue Errno::ECONNREFUSED
    sleep 2
    retry
  end

  def self.instances
    C[:ec2].instances.select do |instance|
      instance.security_groups.first == C[:security_groups] and instance.status != :terminated
    end
  end
end

require 'charm_http/run'
require 'charm_http/setup'
require 'charm_http/benchmark'
require 'charm_http/graph'

