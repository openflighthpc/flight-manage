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

require 'socket'

module FlightManage
  module Utils
    def self.get_host_name
      Socket.gethostname.split('.')[0]
    end

    def self.remove_bash_ext(str)
      str.gsub(/\.bash$/, '')
    end

    def self.get_name_from_script_location(loc)
      loc.gsub(/^#{Config.scripts_dir}/,'')
    end

    def self.get_name_from_script_loc_without_bash(loc)
      remove_bash_ext(get_name_from_script_location(loc))
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
        if find_flight_vars(script)
          script_name = get_name_from_script_location(script)
          flight_scripts[script_name] = find_flight_vars(script)
        end
      end
      return order_scripts(flight_scripts)
    end

    def self.find_flight_vars(script)
      script_info = nil
      IO.foreach(script) do |line|
        break unless (line =~ /^#/ or line =~ /^$/)
        if line =~ /^#FLIGHT/
          script_info ||= {}
          match = line.match(/^#FLIGHT(\S*): (.*)$/)
          if match&.captures
            key, val = match.captures
            script_info[key] = val
          end
        end
      end
      return script_info
    end

    # sort the keys of a hash in breadth-first alphanumeric order
    def self.order_scripts(scripts_hash)
      scripts_hash = scripts_hash.sort_by do |key, _|
        [key.split('/').length, key]
      end
      #calling sort on a hash converts it to an array which must be reverted
      scripts_hash.to_h
    end
  end
end
