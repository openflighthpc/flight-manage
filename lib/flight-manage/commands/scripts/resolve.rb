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
require 'flight-manage/logger'
require 'flight-manage/utils'

require 'date'

module FlightManage
  module Commands
    module Scripts
      class Resolve < Command
        def run
          # finds the script's location as a form of validation
          script_loc = Utils.find_script_from_arg(@argv[0])
          script_name = Utils.get_name_from_script_loc_without_bash(script_loc)

          node_file = Utils.find_node_info
          data = Utils.get_data(node_file)

          unless data.dig(script_name, 'status') == 'FAIL'
            raise ArgumentError, <<-ERROR.chomp
Invalid command - #{script_name} has not failed on this node
            ERROR
          end

          data[script_name]['status'] = 'RESOLVED'
          log(node_file, script_name)
          File.open(node_file, 'w') { |f| f.write(data.to_yaml) }
          puts "#{script_name} has been marked as resolved"
        end

        def log(node_file, script_name)
          node = File.basename(node_file)
          time = DateTime.now.to_s
          Logger.new.log("#{time} - #{node} - #{script_name} - Resolved")
        end
      end
    end
  end
end
