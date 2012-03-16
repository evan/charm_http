
class CharmHttp
  class Run
    def self.run(command = nil, *args)
      case command
        when "start"
          instances = args[0] || 1
          Setup.start(instances)
        when "stop"
          Setup.stop
        when "benchmark"
          host = args[0]
          rps_low = args[1] || 1000
          rps_high = args[2] || 5000
          increments = args[3] || 5
          seconds = args[4] || 30
          if !host
            puts "Usage: charm benchmark hostname lower-rps-limit higher-rps-limit number-of-increments seconds-per-test"
            exit(1)
          end

        when "graph"
        else
          puts(
"""Usage: charm start|benchmark|graph|stop|all
  start number-of-instances [1]
  benchmark hostname lower-rps-limit [1000] higher-rps-limit [5000] number-of-increments [5] seconds-per-test [30]
  stop
  graph test-name [most recent]
""")
      end
    end
  end
end
