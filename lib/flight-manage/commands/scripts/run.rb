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
      # Class of the script run command, executes a script
      class Run < ScriptCommand
        def run
          state_file = Models::StateFile.new(Utils.get_host_name)
          scripts = find_scripts(validate = true)
          scripts.each do |script|
            error_if_re_run(script, state_file.data)
          end
          Utils.lock_state_file(state_file) do
            scripts.each do |script|
              exec_values = execute(script)
              output_execution_data(exec_values, script, state_file)
            end
          end
        end

        # Checks if a script is valid to be ran
        def error_if_re_run(script, data)

          rerunable = (script.rerunnable == 'true')
          # don't allow re-running of failed scripts
          rerunable = false if data.dig(script.name, 'status') == 'FAIL'

          been_run = data.key?(script.name)

          if not rerunable and been_run
            raise ManageError, <<-ERROR.chomp
Script #{script.name} cannot be re-ran or has failed on this node
            ERROR
          end
        end

        # execute a script
        def execute(script)
          exec_values = nil
          # use this block syntax to temporarily change the working dir
          Dir.chdir(File.dirname(script.path)) do
            # need to switch to popen3 if we want to manipulate the thread
            stdout, stderr, process_status = Open3.capture3("bash #{script.path}")
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

        # print output, log & update the node's statefile
        def output_execution_data(exec_values, script, sf)
          exit_code = exec_values['exit_code']

          # maybe order the script names in the yaml
          sf.set_script_values(script.name, exec_values)

          log(script, sf.node, exit_code, exec_values['time'])
          puts "#{script.name} executed with exit code #{exit_code}"
        end

        def log(script, node, exit_code, time)
          Logger.new.log(time, node, script.dir, "#{script.name}: #{exit_code}")
        end
      end
    end
  end
end
