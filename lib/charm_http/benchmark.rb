class CharmHttp
  class Benchmark
    class NoInstances < RuntimeError
    end

    class HstressError < RuntimeError
    end

    def self.run(paths, hostnames, dyno_min, dyno_max, test_duration, timeout, buckets)
      targets = paths.split(',').zip(hostnames.split(','))
      instances = CharmHttp.instances

      raise NoInstances if instances.empty?

      results = {}

      targets.each do |path, hostname|
        (dyno_min..dyno_max).each do |dynos|
          puts "Testing #{dynos} dynos..."
          scale(path, dynos)

          # Find optimal concurrency per dyno
          concurrency = 0
          step = 15
          prev_result = {}
          result = {}

          while result.empty? || prev_result.empty? || (result["hz"] > prev_result["hz"])
            concurrency += step
            prev_result = result
            reset(instances)
            print "Concurrency #{concurrency}"
            sleep timeout
            print ": "
            result = test(instances, hostname, (concurrency * dynos / instances.size).to_i, test_duration, buckets)
            puts "#{result["hz"] / dynos}hz per dyno"
          end

          reset(instances)

          results[hostname] ||= {}
          results[hostname][dynos] = prev_result
          puts "Final: #{prev_result["hz"] / dynos}hz per dyno"
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

    def self.scale(path, dynos)
      CharmHttp.run("cd #{path} && heroku restart && heroku ps:scale web=#{dynos}")
    end

  end
end
