require 'rubycritic/configuration'
require 'rubycritic/source_control_systems/base'
require 'rubycritic/analysers_runner'

module QualityControl
  # Rubycritic Plugin
  module Rubycritic
    class << self
      attr_writer :rating_threshold, :score_threshold, :directories

      # Directories attr_reader with default value
      #
      # @return [Array] The array of directories to run rubocop.
      def directories
        @directories ||= []
      end

      # The threshold for faliure.
      #
      # @return [String] The threshold A-F
      def rating_threshold
        @rating_threshold ||= 'B'
      end

      # The threshold for faliure.
      #
      # @return [Integer] The threshold
      def score_threshold
        @score_threshold ||= 100
      end
    end
  end
end

namespace :rubycritic do
  desc 'Generates Rubycritic report'
  task :generate do
    verbose false
    sh "rubycritic #{QualityControl::Rubycritic.directories.join ' '}"
  end

  desc 'Check Rubycritic coverage'
  task :coverage do
    Rubycritic::Config.set(mode: :ci)
    Rubycritic::Config.source_control_system = Rubycritic::SourceControlSystem::Base.create
    analysed_files = ::Rubycritic::AnalysersRunner.new(QualityControl::Rubycritic.directories).run
    rating = analysed_files.map { |file| file.rating.to_s }.max
    score = analysed_files.reduce([]) { |memo, file|  memo + file.smells }.map { |smell| smell.score || 0 }.max
    puts "Maximum score: #{score}, Minimum rating: #{rating}"
    fail if score > QualityControl::Rubycritic.score_threshold
    fail if rating > QualityControl::Rubycritic.rating_threshold
  end
end
