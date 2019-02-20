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
        script_name = script.gsub(/^#{Config.scripts_dir}/,'')
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
