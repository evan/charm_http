class CharmHttp
  class Benchmark
    class NoInstances < RuntimeError
    end

    class HstressError < RuntimeError
    end

    CONCURRENCIES = [20, 40, 60, 80, 100, 120]

    def self.run(paths, hostnames, dyno_min, dyno_max, test_duration, timeout, buckets)
      targets = paths.split(',').zip(hostnames.split(','))
      instances = CharmHttp.instances

      raise NoInstances if instances.empty?

      results = {}

      targets.each do |path, hostname|
        results[hostname] ||= {}

        (dyno_min..dyno_max).each do |dynos|
          results[hostname][dynos] ||={}

          puts "Testing #{dynos} dynos..."
          scale(path, dynos)

          CONCURRENCIES.each do |concurrency|
            concurrency = concurrency * dynos
            result = test(instances, hostname, concurrency, test_duration, buckets)
            pp({hostname => {dynos => {concurrency => result}}})
            results[hostname][dynos][concurrency] = result
            sleep(timeout)
            reset(instances)
          end
        end

        File.write("#{hostname}.data", results.inspect)

        reset(instances)
        scale(path, 1)
      end
    end

    def self.reset(instances)
      CharmHttp.parallel_ssh(instances, "killall hstress || true")
    end

    def self.test(instances, hostname, concurrency, seconds, buckets)
      results = Hash.new(0)
      CharmHttp.parallel_ssh(instances, "hummingbird/hstress -c #{concurrency / instances.size} -r 25 -b #{buckets} -i 1 #{hostname} 80", seconds).each do |value|
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
