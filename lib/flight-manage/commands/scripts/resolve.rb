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

require 'flight-manage/logger'
require 'flight-manage/models/state_file'
require 'flight-manage/utils'

require 'date'

module FlightManage
  module Commands
    module Scripts
      # Class of the script resolve command
      # Marks a script as executed successfully elsewhere
      class Resolve < ScriptCommand
        def run
          state_file = Models::StateFile.new(Utils.get_host_name)
          scripts = find_scripts
          lock_state_file(state_file) do
            scripts.each { |s| resolve(s, state_file) }
          end
        end

        def resolve(script, state_file)
          data = state_file.data

          unless data.dig(script.name, 'status') == 'FAIL'
            puts "#{script.name} has not failed on this node - skipping"
          else
            script_data = data[script.name]
            script_data['status'] = 'RESOLVED'
            state_file.set_script_values(script.name, script_data)
            log(state_file.node, script)
            puts "#{script.name} has been marked as resolved"
          end
        end

        def log(node, script)
          time = DateTime.now.to_s
          Logger.new.log(time, node, script.dir, script.name, 'Resolved')
        end
      end
    end
  end
end
