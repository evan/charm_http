class CharmHttp
  class Benchmark
    def self.run(paths, hostnames, dyno_min, dyno_max, concurrency, seconds, buckets, procs, requests_per_connection)
      targets = paths.split(',').zip(hostnames.split(','))
      instances = CharmHttp.instances

      results = {}

      targets.each do |path, hostname|
        (dyno_min..dyno_max).each do |dynos|
          scale(path, dynos)
          instances.each do |instance|
            value = CharmHttp.ssh(instance, "hummingbird/hstress -c #{concurrency} -b #{buckets} -p #{procs} -r #{requests_per_connection} -i #{1} #{hostname} 80", seconds)
            values = value[/(successes.*)/m, 1].split('#')
            values.map! {|v| v.split(/\s+/)}
            values.each {|v| v.reject!(&:empty?) }
            values.each do |key, value, percentage|
              if results[key]
                results[key] += value.to_i
              else
                results[key] = value.to_i
              end
            end
          end
        end

        pp results

        scale(path, 1)
      end

      instances.each do |instance|
        CharmHttp.ssh(instance, "killall hstress || true")
      end
    end

    def self.scale(path, dynos)
      CharmHttp.run("cd #{path} && heroku restart && heroku ps:scale web=#{dynos}")
      sleep 5
    end

  end
end
