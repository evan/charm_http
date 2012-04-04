class CharmHttp
  class Benchmark
    class NoInstances < RuntimeError
    end

    class HstressError < RuntimeError
    end

    KEEPALIVE = 25

    def self.run(appnames, hostnames, dyno_min, dyno_max, test_duration, timeout, concurrency, runs, buckets)
      targets = appnames.split(',').zip(hostnames.split(','))
      instances = CharmHttp.instances

      raise NoInstances if instances.empty?
      reset(instances)
      results = {}

      targets.each do |appname, hostname|
        (dyno_min..dyno_max).each do |dynos|
          puts "Testing #{dynos} dynos with #{instances.size} instances at concurrency:#{concurrency}, duration:#{test_duration}, timeout:#{timeout}..."
          scale(appname, dynos)

          runs.times do |run|
            total_concurrency = concurrency * dynos
            result = {hostname =>
              {instances.size =>
                {total_concurrency =>
                  {dynos =>
                    {run => test(instances, hostname, total_concurrency, test_duration, buckets)}}}}}
            pp result
            results.deep_merge!(result)

            # Overwrite the file everytime so we never lose data
            File.write("#{hostname}.data", results.inspect)

            reset(instances)
            sleep(timeout)
          end
        end


        reset(instances)
        scale(appname, 1)
      end
    end

    def self.reset(instances)
      CharmHttp.parallel_ssh(instances, "killall hstress || true")
    end

    def self.test(instances, hostname, concurrency, seconds, buckets)
      results = Hash.new(0)
      CharmHttp.parallel_ssh(instances, "hummingbird/hstress -c #{concurrency / instances.size} -r #{KEEPALIVE} -b #{buckets} -i 1 #{hostname} 80", seconds).each do |value|
        if value =~ /(Assertion.*?failed)/
          raise HstressError, $1
        end
        values = value[/# (hz.*)/m, 1].split('#')
        values.map! {|v| v.split(/\s+/)}
        values.each {|v| v.reject!(&:empty?) }
        values.each {|k, v, p| results[k] += v.to_i}
      end
      results
    rescue Benchmark::HstressError
      print "."
      retry
    end

    def self.scale(appname, dynos)
      CharmHttp.run("heroku restart --app #{appname} && heroku ps:scale web=#{dynos} --app #{appname}")
    end

  end
end
