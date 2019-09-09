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
require 'flight-manage/models/chain'
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
          if @options.chain
            #return find_scripts_from_workflow
            Models::Chain.new(@options.chain, @options.role).scripts
          elsif @options.role or @options.stage
            return Models::Script.find_scripts_with_role_and_stage(
              @options.role,
              @options.stage
            )
          elsif @argv[0]
            script = Models::Script.new({'name' => @argv[0]})
            script.validate if validate
            return [script]
          else
            raise ArgumentError, <<-ERROR.chomp
Please provide either a script, a role, a stage, or a chain
            ERROR
          end
        end
      end
    end
  end
end
