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
require 'flight-manage/utils'

module FlightManage
  module Commands
    module Scripts
      class Show < Command
        def run
          # finds the script's location as a form of validation
          script_loc = Utils.find_script_from_arg(@argv[0])
          script_name = Utils.get_name_from_script_location(script_loc)
          script_name = Utils.remove_bash_ext(script_name)

          data_locs = Dir.glob(File.join(Config.data_dir, '*'))
          data = {}
          data_locs.each do |path|
            data[File.basename(path)] = Utils.get_data(path)
          end
          out = ''
          data.each do |node, data_hash|
            if data_hash.key?(script_name)
              out << "#{node}: #{data_hash[script_name]['status']}\n"
            end
          end

          if out.empty?
            puts "No execution data found for #{script_name}"
          else
            puts "Showing current state of script: #{script_name}\n\n"
            puts out
          end
        end
      end
    end
  end
end
