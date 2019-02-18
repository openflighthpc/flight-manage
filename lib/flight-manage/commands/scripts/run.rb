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

require 'open3'

module FlightManage
  module Commands
    module Scripts
      class Run < Command
        def run
          script_name = @argv[0]
          script_loc = File.join(FlightManage::Config.scripts_dir, script_name)

          #TODO probs replace this with glob so can leave off extensions/give disambiguation
          unless File.file?(script_loc) and File.readable?(script_loc)
            raise ArgumentError, <<-ERROR.chomp
Script at #{script_loc} is not reachable
            ERROR
          end

          script = ""

          File.open(script_loc) { |file| script = file.read }

          stdout, stderr, exit_code = Open3.capture3(script)
        end
      end
    end
  end
end
