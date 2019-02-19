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

require 'flight-manage/command'
require 'flight-manage/config'
require 'flight-manage/exceptions'
require 'flight-manage/utils'

require 'date'
require 'open3'
require 'yaml'

module FlightManage
  module Commands
    module Scripts
      class Run < Command
        def run
          script_name, script_loc = find_script
          node_name, out_file = find_node_info

          script = ""
          File.open(script_loc) { |file| script = file.read }

          # need to switch to popen3 & block syntax if want to manipulate the thread
          stdout, stderr, process_status = Open3.capture3(script)
          time = DateTime.now.to_s
          stdout.chomp!
          stderr.chomp!
          exit_code = process_status.exitstatus
          status = exit_code == 0 ? "OK" : "FAIL"

          data = Utils.get_data(out_file)

          data[script_name] = {
            "time" => time,
            "status" => status,
            "exit_code" => exit_code,
            "stdout" => stdout,
            "stderr" => stderr
          }

          File.open(out_file, 'w') { |f| f.write(data.to_yaml) }
        end

        def find_script
          script_name = @argv[0]
          script_loc = File.join(FlightManage::Config.scripts_dir, script_name)

          #TODO probs replace this with glob so can leave off extensions/give disambiguation
          unless File.file?(script_loc) and File.readable?(script_loc)
            raise ArgumentError, <<-ERROR.chomp
Script at #{script_loc} is not reachable
            ERROR
          end

          return script_name, script_loc
        end

        def find_node_info
          node_name = Utils.get_host_name

          out_file = File.join(FlightManage::Config.data_dir, node_name)

          #if out_file doesn't exist, create it
          unless File.file?(out_file)
            File.open(out_file, 'w') {}
          end

          unless File.writable?(out_file)
            raise ArgumentError, <<-ERROR.chomp
Output file at #{out_file} is not reachable - check permissions and try again
            ERROR
          end

          return node_name, out_file
        end
      end
    end
  end
end
