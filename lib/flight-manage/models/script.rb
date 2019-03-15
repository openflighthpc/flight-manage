# ==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Manage.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Manage is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Manage. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Manage, please visit:
# https://github.com/openflighthpc/flight-manage
# ==============================================================================

require 'flight-manage/config'
require 'flight-manage/exceptions'

module FlightManage
  module Models
    class Script
      attr_reader :name, :dir, :path

      class << self
        def glob_all_scripts
          # will be ordered first by script directory (as defined in the config)
          # then by the order defined below in `sort_scripts`
          scripts = []
          Config.script_dirs.each do |dir|
            scripts = scripts + glob_scripts(dir)
          end
          return scripts
        end

        def glob_scripts(dir)
          paths = Dir.glob(File.join(dir, '**/*.bash'))
          scripts = paths.map { |p| Script.new({'path' => p}) }
          scripts = scripts.select { |s| s.is_flight_script? }
          scripts = sort_scripts(scripts)
        end

        # sort for higher level scripts first then alphanumerically
        def sort_scripts(scripts)
          scripts = scripts.sort_by do |s|
            [s.name.split('/').length, s.name]
          end
        end
      end

      def initialize(args)
        if args['name']
          @name = sanitise_name(args['name'])
          @dir = find_dir
          @path = File.join(@dir, "#{name}.bash")
        elsif args['path']
          @path = args['path']
          @dir, @name = split_path
          @name = sanitise_name
        else
          raise ManageError, <<-ERROR.chomp
Error using script
          ERROR
        end
      end

      def roles
        @roles ||= flight_vars['roles']&.split(',') || [nil]
      end

      def stages
        @stages ||= flight_vars['stages']&.split(',') || [nil]
      end

      def description
        @description ||= flight_vars['description']
      end

      def rerunnable
        @rerunnable ||= flight_vars['rerunnable'] || flight_vars['rerunable']
      end

      def validate
        unless File.file?(path) and File.readable?(path)
          raise ArgumentError, <<-ERROR.chomp
Script at #{path} is not reachable
          ERROR
        end
        unless is_flight_script?
          raise ArgumentError, <<-ERROR.chomp
Script at #{path} is not a flight script
          ERROR
        end
      end

      def is_flight_script?
        #NB: File.read & File.readlines both load the entire file into mem
        flight = false
        read_for_variables { |line| flight = true if line =~ /^#FLIGHT/ }
        return flight
      end

      def flight_vars
        vars = {}
        read_for_variables do |line|
          if line =~ /^#FLIGHT/
            match = line.match(/^#FLIGHT(\S*): (.*)$/)
            if match&.captures
              key, val = match.captures
              vars[key] = val
            end
          end
        end
        return vars
      end

      private

      def sanitise_name(str = @name)
        str = str.gsub(/\.bash$/, '')
        str = str.gsub(/^\//, '')
      end

      def find_dir(name = @name)
        Config.script_dirs.each do |dir|
          return dir if File.file?(File.join(dir, "#{name}.bash"))
        end
        raise ArgumentError, <<-ERROR.chomp
No script by name '#{name}' reachable
        ERROR
      end

      # NB: this method will act strangly in the case of nested script directories
      # Don't do that - that is dumb
      def split_path(path = @path)
        Config.script_dirs.each do |dir|
          return dir, path.gsub(/^#{dir}/, '') if path =~ /^#{dir}/
        end
        raise ManageError, <<-ERROR.chomp
Invalid path '#{path}'
        ERROR
      end

      def read_for_variables
        IO.foreach(path) do |line|
          break unless (line =~ /^#/ or line =~ /^$/)
          yield(line)
        end
      end
    end
  end
end
