# ==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Manage.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-software.com.
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

require 'socket'

module FlightManage
  module Utils
    def self.get_host_name
      Socket.gethostname.split('.')[0]
    end

    def self.get_data(location)
      data = nil
      begin
        File.open(location) do |f|
          data = YAML.safe_load(f)
        end
      rescue Psych::SyntaxError
        raise ParseError, <<-ERROR.chomp
Error parsing yaml in #{location} - aborting
        ERROR
      end
      data = {} if data.nil?
      data
    end

    def self.get_name_from_script_location(loc)
        loc.gsub(/^#{Config.scripts_dir}/,'')
    end

    def self.find_script_from_arg(arg)
      script_arg = arg
      script_arg = script_arg.gsub(/\.bash$/, '')
      script_loc = File.join(Config.scripts_dir, "#{script_arg}.bash")

      unless File.file?(script_loc) and File.readable?(script_loc)
        raise ArgumentError, <<-ERROR.chomp
Script at #{script_loc} is not reachable
        ERROR
      end
      unless is_flight_script?(script_loc)
        raise ArgumentError, <<-ERROR.chomp
Script at #{script_loc} is not a flight script
        ERROR
      end
      return script_loc
=begin
#TODO finish this
          glob_str = File.join(
            FlightManage::Config.scripts_dir,
            #still doesn't work for multilvl systems
            "#{script_arg}**/*.bash"
          )
          found = Dir.glob(glob_str)

          if found.empty?
            raise ArgumentError, <<-ERROR.chomp
No files found for #{script_arg}
            ERROR
          elsif found.length == 1
            script_loc = found[0]
          else
            file_names = found.map { |p| File.basename(p, File.extname(p)) }
            # if the results include just the search val, return that path
            if file_names.include?(script_arg)
              script_loc = found.select { |p| p =~ /#{script_arg}\.bash$/ }[0]
            else
              $stderr.puts "Ambiguous search term '#{script_arg}'"\
              " - possible results are:"
              file_names.each_slice(3).each { |p| $stderr.puts p.join("  ") }
              raise ArgumentError, <<-ERROR.chomp
  Please refine your search.
              ERROR
            end
          end
=end
    end

    def self.is_flight_script?(script)
      #NB: File.read & File.readlines both load the entire file into mem
      flight = false
      IO.foreach(script) do |line|
        flight = true if line =~ /^#FLIGHT/
        break unless (line =~ /^#/ or line =~ /^$/)
      end
      return flight
    end

    # returns a hash of hashes
    # { script1 => { FLIGHTvar => value, ... }, script2 => {...}, ... }
    def self.find_all_flight_scripts
      found = Dir.glob(File.join(Config.scripts_dir, '**/*.bash'))
      flight_scripts = {}
      found.each do |script|
        script_name = get_name_from_script_location(script)
        IO.foreach(script) do |line|
          if line =~ /^#FLIGHT/
            flight_scripts[script_name] = {} unless flight_scripts[script_name]
            match = line.match(/^#FLIGHT(\w*): (.*)$/)
            if match&.captures
              key, val = match.captures
              flight_scripts[script_name][key] = val
            end
          end
        end
      end
      return flight_scripts
    end
  end
end
