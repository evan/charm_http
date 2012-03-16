
class CharmHttp
  class Setup
    def self.start(n)
      CharmHttp.instances.each do |instance|
        puts "#{instance.public_dns_name} terminated"
        instance.delete
      end

      instances = []
      n.times do
        instance = C[:image].run_instance(C.slice(:key_pair, :security_groups))
        puts "Booted new instance"
        instances << instance
      end
      sleep 1 while instances.any? {|i| i.status == :pending}

      instances.each do |instance|
        puts "#{instance.public_dns_name} running"
      end

      instances.each do |instance|
        [
        "yes | sudo apt-get install make gcc git libevent-dev",
        "git clone https://github.com/evan/hummingbird.git",
        "cd hummingbird && make hstress hplay"
        ].each do |command|
          CharmHttp.ssh(instance, command)
        end
      end
      debugger
      1
    end

    def self.stop
      CharmHttp.instances.each(&:delete)
      C[:key_pair].delete
      begin
        C[:security_groups].delete
      rescue AWS::EC2::Errors::InvalidGroup::InUse
        sleep 2
        retry
      end
    end
  end
end
