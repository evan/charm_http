
class CharmHttp
  class Run
    def self.run(command = nil, *args)
      start_usage = "start number-of-instances [1]"
      benchmark_usage = "benchmark appnames hostnames dyno_min [1] dyno_max [10] test_duration [180] timeout [60] concurrency_per_dyno [100] runs [3] buckets [1,5,10,50,100,500,1000]"
      graph_usage = "graph test-name [most recent]"
      stop_usage = "stop"

      case command
        when "start"
          Setup.start((args[0] || 1).to_i)
        when "stop"
          Setup.stop
        when "benchmark"
          puts "Usage: charm #{benchmark_usage}" and exit(1) if !args[1]
          Benchmark.run(args[0], args[1], (args[2] || 1).to_i, (args[3] || 10).to_i, (args[4] || 180).to_i, (args[6] || 60).to_i, (args[7] || 100).to_i, (args[8] || 3).to_i, args[9] || "1,5,10,50,100,500,1000")
        when "graph"
          Graph.graph(args[0] || Dir["*.data"].max_by {|f| File.mtime(f)})
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
