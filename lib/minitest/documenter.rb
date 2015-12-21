gem "minitest"
require 'minitest/autorun'
require 'ansi/code'

module Minitest
  module Documenter
    require "minitest/documenter/version"

    class Documenter < AbstractReporter
      include ANSI::Code

      attr_reader :io, :options, :results
      attr_accessor :start_time, :total_time, :failures, :errors, :skips, :count, :results

      def initialize(options = {})
        @io = io
        @options = options
        self.results = []
        self.errors = 0
        self.skips = 0
        self.count = 0
        self.failures = 0
      end

      def start
        puts
        self.start_time = Time.now
      end

      def record(result)
        puts_header(result)
        puts format_result(result)
        unless result.passed?
          puts
          puts failure_info(result)
        end

        update_statistics(result)
      end


      def report
        super

        aggregate = self.results.group_by { |r| r.failure.class }
        aggregate.default = [] # dumb. group_by should provide this

        self.failures   = aggregate[Assertion].size
        self.errors     = aggregate[UnexpectedError].size
        self.skips      = aggregate[Skip].size

        puts
        puts format_tests_run_count(count, total_time)
        puts statistics
        puts
      end

      private

      def failure_info(result)
        if result.error?
          puts pad(format_error_info(result))
          puts
        elsif result.failure
          result.failure.to_s.each_line {|l| puts pad(l)}
          puts
        end
      end

      def update_statistics(result)
        self.count += 1
        self.results << result unless result.passed? || result.skipped?
      end

      def statistics
        "#{format_result_type('Errors', errors, :red)} #{format_divider}" + \
          "#{format_result_type('Failures', failures, :red)} #{format_divider}" + \
          "#{format_result_type('Skips', skips, :yellow)}"
      end

      def total_time
        Time.now - start_time
      end

      #formatters
      def pad(str, amount = 2)
        " " * amount + str
      end

      def format_error_info(result)
        e = result.failure.exception
        bt = Minitest.filter_backtrace e.backtrace
        ANSI.bold {e.class.to_s} + "\n" + pad(e.message.to_s) + "\n" + \
            format_backtrace(bt)
      end

      def format_backtrace(bt)
        output = ""
        bt.each {|l| output << pad(l)}
        output
      end

      def format_result(result)
        output = ""
        name = format_test_description result

        if result.passed?
          output =  ANSI.green {name}
        else
          output = ANSI.red {name}
        end

        pad output
      end

      def format_test_description(result)
        verb = result.name.split[0].split("_").last
        phrase = result.name.split[1..-1].join " "
        "#{verb} #{phrase}"
      end

      def puts_header(result)
        current_header = header(result)
        if @prevous_header != current_header
          @prevous_header = current_header
          puts
          puts format_header(current_header)
        end
      end

      def format_header(header)
        header.gsub!('::.', '.')
        header.gsub!('::#', '#')
        header.gsub!('::(', ' (')
        header.gsub!(/\:\:([a-z])/, ' \1')
        klass, method = header.split(/(?=\.|\#)/, 2)
        ANSI.bold(header)
        ANSI.bold(klass) + ANSI.white(method)
      end

      def header(result)
        result.class.to_s
      end

      def format_tests_run_count(count, total_time)
        time = ANSI.bold total_time.to_s
        "#{count} tests run in #{time} seconds."
      end

      def format_result_type(type, count, colour)
        summary = "#{type}: #{count}"

        if count.zero?
          return ANSI.ansi(summary, :white, :bold)
        else
          return ANSI.ansi(summary, colour, :bold)
        end
      end

      def format_divider(divider = '|')
        ANSI.white + ANSI.bold + " #{divider} "
      end
    end
  end
end