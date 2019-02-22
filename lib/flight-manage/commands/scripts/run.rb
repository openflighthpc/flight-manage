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
          out_file = find_node_info
          find_script.each do  |script|
            communicator = execute(script)
            output_execution_data(communicator, script, out_file)
          end
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

          return out_file
        end

        def find_script
          if not @options.stage and not @options.role
            script_loc = Utils.find_script_from_arg(@argv[0])
            return [script_loc]
          else
            matches = []
            scripts = Utils.find_all_flight_scripts
            scripts.each do |key, val|
              stages = val['stages'].nil? ? [nil] : val['stages'].split(',')
              roles = val['roles'].nil? ? [nil] : val['roles'].split(',')
              if stages.include?(@options.stage) and roles.include?(@options.role)
                matches << File.join(Config.scripts_dir, key)
              end
            end
            if matches.empty?
              role_str = @options.role ? "role '#{@options.role}'" : "no role"
              stage_str = @options.stage ? "stage '#{@options.stage}'" : "no stage"
              raise ArgumentError, <<-ERROR.chomp
No scripts found with #{role_str} and #{stage_str}
              ERROR
            end
            return matches
          end
        end

        def execute(script_loc)
          communicator = nil
          # use this block syntax to temporarily change the working dir
          Dir.chdir(File.dirname(script_loc)) do
          # need to switch to popen3 if we want to manipulate the thread
            stdout, stderr, process_status = Open3.capture3(script_loc)
            communicator = {
              stdout: stdout,
              stderr: stderr,
              process_status: process_status,
            }
          end
          return communicator
        end

        def output_execution_data(communicator, script_loc, out_file)
          script_name = Utils.get_name_from_script_location(script_loc)
          script_name = Utils.remove_bash_ext(script_name)

          time = DateTime.now.to_s
          stdout = communicator[:stdout].chomp
          stderr = communicator[:stderr].chomp
          exit_code = communicator[:process_status].exitstatus
          status = exit_code == 0 ? "OK" : "FAIL"

          data = Utils.get_data(out_file)

          data[script_name] = {
            "time" => time,
            "status" => status,
            "exit_code" => exit_code,
            "stdout" => stdout,
            "stderr" => stderr
          }

          data = Utils.order_scripts(data)

          File.open(out_file, 'w') { |f| f.write(data.to_yaml) }
          log(script_name, out_file, exit_code, time)
          puts "#{script_name} executed with exit code #{exit_code}"
        end

        def log(script_name, out_file, exit_code, time)
          FileUtils.mkdir_p(File.dirname(Config.log_file))
          node_name = File.basename(out_file)
          File.open(Config.log_file, 'a') do |f|
            f.write "#{time} - #{node_name} - #{script_name}: #{exit_code}\n"
          end
        end
      end
    end
  end
end
