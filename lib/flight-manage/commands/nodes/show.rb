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

module FlightManage
  module Commands
    module Nodes
      class Show < Command
        def run
          host = @argv[0]
          unless host
            host = Utils.get_host_name
          end
          data_loc = File.join(Config.data_dir, host)

          unless File.readable?(data_loc)
            raise ArgumentError, <<-ERROR.chomp
No data found for #{host}
            ERROR
          end

          data = Utils.get_data(data_loc)

          puts "Showing current state of hostname: #{host}\n\n"
          data.each do |key, vals|
            puts "#{key}: #{vals['status']}"
          end
        end
      end
    end
  end
end
