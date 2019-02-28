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
require 'flight-manage/logger'
require 'flight-manage/models/state_file'
require 'flight-manage/utils'

require 'date'
require 'open3'

module FlightManage
  module Commands
    module Scripts
      class Run < ScriptCommand
        def run
          node = Utils.get_host_name
          data = Models::StateFile.read_or_new(node).__data__.to_h
          scripts = find_scripts(validate = true)
          scripts.each do |script|
            error_if_re_run(script, data)
          end
          scripts.each do |script|
            exec_values = execute(script)
            output_execution_data(exec_values, script, node)
          end
        end

        def error_if_re_run(script_loc, data)
          flight_vars = Utils.find_flight_vars(script_loc)
          rerunable = flight_vars['re-runable'] == 'true'

          script_name = Utils.get_name_from_script_loc_without_bash(script_loc)
          been_run = data.key?(script_name)

          if not rerunable and been_run
            raise ManageError, <<-ERROR.chomp
Script #{script_name} has been ran and cannot be re-ran
            ERROR
          end
        end

        def execute(script_loc)
          exec_values = nil
          # use this block syntax to temporarily change the working dir
          Dir.chdir(File.dirname(script_loc)) do
          # need to switch to popen3 if we want to manipulate the thread
            stdout, stderr, process_status = Open3.capture3(script_loc)
            exit_code = process_status.exitstatus
            status = exit_code == 0 ? "OK" : "FAIL"
            exec_values = {
              'time' => DateTime.now.to_s,
              'status' => status,
              'exit_code' => exit_code,
              'stdout' => stdout.chomp,
              'stderr' => stderr.chomp
            }
          end
          return exec_values
        end

        def output_execution_data(exec_values, script_loc, node)
          script_name = Utils.get_name_from_script_loc_without_bash(script_loc)
          exit_code = exec_values['exit_code']

          # maybe order the script names in the yaml
          Models::StateFile.create_or_update(node) do |sf|
            sf.set_script_values(script_name, exec_values)
          end

          log(script_name, node, exit_code, exec_values['time'])
          puts "#{script_name} executed with exit code #{exit_code}"
        end

        def log(script_name, node, exit_code, time)
          Logger.new.log(time, node, "#{script_name}: #{exit_code}")
        end
      end
    end
  end
end
