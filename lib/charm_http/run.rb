
class CharmHttp
  class Run
    def self.run(command = nil, *args)
      start_usage = "start number-of-instances [1]"
      benchmark_usage = "benchmark paths hostnames dyno_min [1] dyno_max [10] test_duration [120] timeout [60] buckets [1,5,10,50,100,500,1000]"
      graph_usage = "graph test-name [most recent]"
      stop_usage = "stop"

      case command
        when "start"
          Setup.start((args[0] || 1).to_i)
        when "stop"
          Setup.stop
        when "benchmark"
          puts "Usage: charm #{benchmark_usage}" and exit(1) if !args[1]
          Benchmark.run(args[0], args[1], (args[2] || 1).to_i, (args[3] || 10).to_i, (args[4] || 120).to_i, (args[6] || 60).to_i, args[6] || "1,5,10,50,100,500,1000")
        when "graph"
        else
          puts(
"""Usage: charm start|benchmark|graph|stop
  #{start_usage}
  #{benchmark_usage}
  #{graph_usage}
  #{stop_usage}
""")
      end
    end
  end
end
