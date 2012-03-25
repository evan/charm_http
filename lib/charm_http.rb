require 'rubygems'
require 'ruby-debug' if ENV['DEBUG']
require 'pp'
require 'aws-sdk'
require 'active_support/core_ext/hash'

STDOUT.sync = true

AWS.config(
  "access_key_id" => ENV["AWS_ACCESS_KEY_ID"],
  "secret_access_key" => ENV["AWS_SECRET_ACCESS_KEY"])

class CharmHttp
  class SshError < RuntimeError
  end
  class LocalError < RuntimeError
  end

  LOG = File.open("/tmp/charm_http.log", "w")
  LOG.sync = true

  C = {
    :version => 1,
    :ec2 => AWS::EC2.new.regions["us-east-1"]
  }

  name = "charm_http#{C[:version]}"
  C[:key_file] = ENV['HOME'] + "/.ssh/#{name}"

  if key_pair = C[:ec2].key_pairs.find {|n| n.name == name}
    key_pair.delete and exit if !File.exist?(C[:key_file])
 else
    key_pair = C[:ec2].key_pairs.create(name)
    File.write(C[:key_file], key_pair.private_key)
    system("chmod 600 #{C[:key_file]}")
  end
  C[:key_pair] = key_pair

  if !group = C[:ec2].security_groups.find {|n| n.name == name}
    group = C[:ec2].security_groups.create(name)
    group.authorize_ingress(:tcp, 22, "0.0.0.0/0")
  end
  C[:security_groups] = group

  C[:image] = C[:ec2].images["ami-1a837773"]
  C[:instance_type] = "m1.small"

  def self.run(command)
    LOG.puts "localhost: #{command}"
    value = `#{command} 2>&1`
    LOG.puts value
    raise LocalError if $? != 0
    value
  end

  def self.parallel_ssh(instances, *args)
    threads = []
    response = []
    instances.each do |instance|
      threads << Thread.new do
        response << ssh(instance, *args)
      end
    end
    threads.each(&:join)
    response
  end

  def self.ssh(instance, original_command, timeout = nil)
    command = original_command
    command = "timeout -s INT #{timeout} #{command} || true" if timeout
    command = "ssh -i #{C[:key_file]} -o 'StrictHostKeyChecking no' ubuntu@#{instance.public_dns_name} '#{command}' 2>&1"
    LOG.puts "#{instance.public_dns_name}: #{command}"
    response = `#{command}`
    LOG.puts response
    raise SshError if $? != 0
    response
  rescue SshError
    sleep 1
    retry
  end

  def self.instances
    instances = C[:ec2].instances.select do |instance|
      instance.security_groups.first == C[:security_groups] and instance.status == :running
    end
    puts "Found #{instances.size} instances"
    instances
  end
end

require 'charm_http/run'
require 'charm_http/setup'
require 'charm_http/benchmark'
require 'charm_http/graph'

