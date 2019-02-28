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
      class Resolve < ScriptCommand
        def run
          scripts = find_scripts
          Models::StateFile.update(Utils.get_host_name) do |sf|
            scripts.each { |s| resolve(s, sf) }
          end
        end

        def resolve(script_path, state_file)
          script_name = Utils.get_name_from_script_loc_without_bash(script_path)
          data = state_file.__data__.to_h

          unless data.dig(script_name, 'status') == 'FAIL'
            puts "#{script_name} has not failed on this node - skipping"
          else
            script_data = data[script_name]
            script_data['status'] = 'RESOLVED'
            state_file.set_script_values(script_name, script_data)
            log(state_file.node, script_name)
            puts "#{script_name} has been marked as resolved"
          end
        end

        def log(node, script_name)
          time = DateTime.now.to_s
          Logger.new.log(time, node, script_name, 'Resolved')
        end
      end
    end
  end
end
