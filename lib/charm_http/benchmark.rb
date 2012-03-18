class CharmHttp
  class Benchmark
    class NoInstances < RuntimeError
    end

    class HstressError < RuntimeError
    end

    def self.run(paths, hostnames, dyno_min, dyno_max, buckets)
      targets = paths.split(',').zip(hostnames.split(','))
      instances = CharmHttp.instances

      raise NoInstances if instances.empty?
      reset(instances)

      results = {}

      targets.each do |path, hostname|
        (dyno_min..dyno_max).each do |dynos|
          puts "Testing #{dynos} dynos..."
          scale(path, dynos)

          # Find optimal concurrency per dyno
          concurrency, prev_hz, hz = 10, 0, 1
          step = 10

          while hz > prev_hz
            concurrency += step
            prev_hz = hz
            hz = test(instances, hostname, (concurrency * dynos / instances.size).to_i, 10, buckets)["hz"]
            puts "Concurrency #{concurrency}: #{hz}hz"
          end
          concurrency -= step

          # Measure
          results[hostname] ||= {}
          results[hostname][dynos] = test(instances, hostname, (concurrency * dynos / instances.size).to_i, 90, buckets)
          puts "Results:"
          pp results[hostname][dynos]
        end

        File.write("#{hostname}.data", results.inspect)

        reset(instances)
        scale(path, 1)
      end
    end

    def self.reset(instances)
      CharmHttp.parallel_ssh(instances, "killall hstress || true")
    end

    def self.test(instance, hostname, concurrency, seconds, buckets)
      results = Hash.new(0)
      CharmHttp.parallel_ssh(instance, "hummingbird/hstress -c #{concurrency} -b #{buckets} -i 1 #{hostname} 80", seconds).each do |value|
        if value =~ /(Assertion.*?failed)/
          raise HstressError, $1
        end
        values = value[/(conn_successes.*)/m, 1].split('#')
        values.map! {|v| v.split(/\s+/)}
        values.each {|v| v.reject!(&:empty?) }
        values.each {|k, v, p| results[k] += v.to_i}
      end
      results
    end

    def self.scale(path, dynos)
      CharmHttp.run("cd #{path} && heroku restart && heroku ps:scale web=#{dynos}")
    end

  end
end
