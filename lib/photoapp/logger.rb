module PhotoApp
  module Logger

    module LogLevels
      DEBUG = 1
      INFO = 2
      WARN = 3
      ERROR = 4
      FATAL = 5
    end

    class StdoutLogger
      def initialize(level = "debug")
        STDOUT.sync = true
        @level = eval "LogLevels::#{level.upcase}"
      end

      %w(debug info warn error fatal).each do |l|
        define_method(l) do |line|
          requested_level = eval "Logger::LogLevels::#{l.upcase}"
          if requested_level >= @level
            STDOUT.puts "#{l.upcase} - #{line}"
          end
        end
      end

    end
  end
end