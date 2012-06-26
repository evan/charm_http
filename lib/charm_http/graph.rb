
class CharmHttp
  class Graph
    def self.graph(filename)
      graph = Graph.new(filename)
      graph.make_data
      graph.make_chart
    end

    def initialize(filename)
      @filename = filename
      @data = eval(File.read(@filename))
      @headers = @data.keys
      @workers = @data[@headers.first].keys.first
      @x = @headers.map do |header|
        @data[header][@workers].keys
      end.flatten.uniq.sort
    end

    def make_data
      Dir.mkdir("tmp") rescue nil
      File.open("tmp/data.ssv", "w") do |ssv|
        ssv.puts "#{@filename} #{@headers.join(' ')}"
        @x.each do |x|
          ssv.write "#{@data[@headers.first][@workers][x].keys.first} "

          data = @headers.map do |header|
            hash = @data[header][@workers][x]
            hash = hash[hash.keys.first]

            max = 0
            hash.keys.each do |run|
              if hash[run]["hz"] > max
                max = hash[run]["hz"]
              end
            end
            max
          end

          ssv.puts data.join(' ')
        end
      end

      puts File.read("tmp/data.ssv")
    end

    def make_chart
      system("R --vanilla < #{LIB}/charm_http/graph.r")
    end
  end
end
