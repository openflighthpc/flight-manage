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

require 'flight-manage/command'

require 'lockfile'

module FlightManage
  module Commands
    module Scripts
      class ScriptCommand < Command
        def find_scripts(validate = false)
          if not @options.stage and not @options.role and not @argv[0]
            raise ArgumentError, <<-ERROR.chomp
Please provide either a script, a role, or a stage
            ERROR
          elsif not @options.stage and not @options.role
            script_loc = find_script_from_arg(@argv[0], validate)
            return [script_loc]
          else
            return find_scripts_with_role_and_stage
          end
        end

        def lock_state_file(state_file)
          begin
            Lockfile.new("#{state_file.path}.lock", retries: 0) do
              yield
            end
          rescue Lockfile::MaxTriesLockError
            raise FileSysError, <<-ERROR.chomp
The file for node #{state_file.node} is locked - aborting
            ERROR
          end
        end

        def find_script_from_arg(arg, validate = false)
          script_arg = Utils.remove_bash_ext(arg)
          script_loc = File.join(Config.scripts_dir, "#{script_arg}.bash")
          validate_script(script_loc) if validate
          return script_loc
        end

        def validate_script(script_loc)
          unless File.file?(script_loc) and File.readable?(script_loc)
            raise ArgumentError, <<-ERROR.chomp
Script at #{File.expand_path(script_loc)} is not reachable
            ERROR
          end
          unless Utils.is_flight_script?(script_loc)
            raise ArgumentError, <<-ERROR.chomp
Script at #{File.expand_path(script_loc)} is not a flight script
            ERROR
          end
        end

        def find_scripts_with_role_and_stage
          matches = []
          Utils.find_all_flight_scripts.each do |key, val|
            stages = val['stages'].nil? ? [nil] : val['stages'].split(',')
            roles = val['roles'].nil? ? [nil] : val['roles'].split(',')
            if stages.include?(@options.stage) and roles.include?(@options.role)
              matches << File.join(Config.scripts_dir, key)
            end
          end
          error_from_role_and_stage if matches.empty?
          return matches
        end

        def error_from_role_and_stage
          role_str = @options.role ? "role '#{@options.role}'" : "no role"
          stage_str = @options.stage ? "stage '#{@options.stage}'" : "no stage"
          raise ArgumentError, <<-ERROR.chomp
No scripts found with #{role_str} and #{stage_str}
          ERROR
        end
      end
    end
  end
end
