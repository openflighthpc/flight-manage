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
require 'flight-manage/config'
require 'flight-manage/exceptions'
require 'flight-manage/models/state_file'
require 'flight-manage/utils'

module FlightManage
  module Commands
    module Nodes
      # Class of the show node command, displays execution on a node
      class Show < Command
        def run
          node = @argv[0]
          verbose = @options['verbose']
          errors = @options['error']
          node ||= Utils.get_host_name
          state_file = Models::StateFile.new(node)

          unless File.file?(state_file.path)
            raise ArgumentError, <<-ERROR.chomp
No data found for node '#{node}'
            ERROR
          end

          data = state_file.data

          if data.empty?
            puts "No data found for node '#{node}'"
          else
            puts "Showing current state of hostname: #{node}\n\n"
            data.each do |key, vals|
              puts "#{key}: #{vals['status']}"
              if verbose
                print_verbose(vals)
              elsif errors
                print_stderr(vals)
              end
            end
          end
        end

        def print_stderr(vals)
          puts "stderr:\n  #{vals['stdout']}"
        end

        def print_verbose(vals)
          puts "stdout:\n  #{vals['stdout']}"
          print_stderr(vals)
        end
      end
    end
  end
end
