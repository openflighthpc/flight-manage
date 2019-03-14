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
require 'flight-manage/models/script'

require 'lockfile'

module FlightManage
  module Commands
    module Scripts
      # Super class containing script selection methods
      class ScriptCommand < Command
        # Locate scripts from argv and stage & role options
        # Can be used in commands without these options as they'll
        # evaluate to nil
        def find_scripts(validate = false)
          if not @options.stage and not @options.role and not @argv[0]
            raise ArgumentError, <<-ERROR.chomp
Please provide either a script, a role, or a stage
            ERROR
          elsif not @options.stage and not @options.role
            script = Models::Script.new({'name' => @argv[0]})
            script.validate if validate
            return [script]
          else
            return find_scripts_with_role_and_stage
          end
        end

        #TODO more this to utils
        # Use lockfile library to prevent simultaneous access
        def lock_state_file(state_file)
          Lockfile.new("#{state_file.path}.lock", retries: 0) do
            yield
          end
        rescue Lockfile::MaxTriesLockError
          raise FileSysError, <<-ERROR.chomp
The file for node #{state_file.node} is locked - aborting
          ERROR
        end

        # resolve role & stage options to find scripts
        def find_scripts_with_role_and_stage
          matches = []
          Models::Script.glob_all_scripts.each do |script|
            if script.stages.include?(@options.stage)
              if script.roles.include?(@options.role)
                matches << script
              end
            end
          end
          error_from_role_and_stage if matches.empty?
          return matches
        end

        # print error if no scripts are found
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
