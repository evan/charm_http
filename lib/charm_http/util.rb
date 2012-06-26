class CharmHttp
  class Util
      def self.combine(files)
      data = {}
      files.each do |filename|
        data.deep_merge!(eval(File.read(filename)))
      end
      pp data
    end
  end
end
