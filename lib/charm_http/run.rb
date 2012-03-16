
class CharmHttp
  class Run
    def self.run(command = nil, *args)
      case command
        when "start"
          instances = (args[0] || 1).to_i
          Setup.start(instances)
        when "stop"
          Setup.stop
        when "benchmark"
          paths = args[0]
          hostnames = args[1]
          dyno_min = (args[2] || 1).to_i
          dyno_max = (args[3] || 10).to_i
          buckets = args[4] || "1,10,100,250,500"
          requests_per_connection = (args[5] || 10).to_i
          if !hostnames
            puts "Usage: charm benchmark paths hostnames dyno_min [1] dyno_max [10] buckets [1,10,100,250,500] requests-per-connection [10]"
            exit(1)
          end
          Benchmark.run(paths, hostnames, dyno_min, dyno_max, buckets, requests_per_connection)
        when "graph"
        else
          puts(
"""Usage: charm start|benchmark|graph|stop|all
  start number-of-instances [1]
  benchmark paths hostnames dyno_min [1] dyno_max [10] buckets [1,10,100,250,500] requests-per-connection [10]
  stop
  graph test-name [most recent]
""")
      end
    end
  end
end
