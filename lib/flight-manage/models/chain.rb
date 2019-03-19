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

require 'flight-manage/models/script'
require 'flight-manage/utils'

module FlightManage
  module Models
    class Chain
      def initialize(path, role = nil)
        unless File.file?(path) and File.readable?(path)
          raise ArgumentError, <<-ERROR.chomp
No chain file founnd at #{path}
          ERROR
        end
        @path = path
        @role = role
      end

      def data
        data = Utils.read_yaml(@path)
        unless data.is_a?(Array)
          raise ManageError, <<-ERROR.chomp
Invalid chain at #{@path} - not a yaml list
          ERROR
        end
        return data
      end

      def scripts
        scripts = []
        data.each do |line|
          if line.is_a?(Hash) and line.key?('stage')
            stage = line['stage']
            stage_scripts = Script.find_scripts_with_role_and_stage(@role, stage)
            scripts.concat(stage_scripts)
          elsif line.is_a?(String) and not line =~ /\s/
            script = Script.new({'name' => line})
            script.validate
            scripts << script
          else
            raise ManageError, <<-ERROR.chomp
Error with chain - invlid line #{line}
            ERROR
          end
        end
        return scripts
      end
    end
  end
end
