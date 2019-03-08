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

require 'yaml'

module FlightManage
  module Models
    class StateFile
      attr_reader :node

      def initialize(node)
        @node = node
      end

      def data
        # create file if it doesn't exist
        File.open(path, 'w') {} unless File.file?(path)

        data = nil
        begin
          File.open(path) do |f|
            data = YAML.safe_load(f)
          end
        rescue Psych::SyntaxError
          raise ParseError, <<-ERROR.chomp
Error parsing yaml in #{location} - aborting
          ERROR
        end
        data ||= {}
        data
      end

      def path
        File.join(Config.data_dir, node + '.yaml')
      end

      def set_script_values(script_name, values)
        new_data = data
        new_data[script_name] = values
        save_data(new_data)
      end

      def save_data(new_data)
        File.open(path, 'w') { |f| f.write(new_data.to_yaml) }
      end
    end
  end
end
