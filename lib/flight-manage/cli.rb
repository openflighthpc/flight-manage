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

require 'flight-manage/commands'

require 'commander'

module FlightManage
  module CLI
    # TODO confirm with mark about the name stuff
    PROGRAM_NAME = ENV.fetch('FLIGHT_PROGRAM_NAME', 'manage')

    extend Commander::Delegates
    program :name, PROGRAM_NAME
    program :version, '0.0.0'
    program :description, 'Remote executor of shared scripts.'
    program :help_paging, false

    ARGV.push '--help' if ARGV.empty?

    #silent_trace!

    class << self
      def action(command, klass)
        command.action do |args, options|
          klass.new(args, options).run!
        end
      end

      def cli_syntax(command, args_str = nil)
        command.syntax = [
          PROGRAM_NAME,
          command.name,
          args_str
        ].compact.join(' ')
      end
    end

    command :node do |c|
      cli_syntax(c, 'SUBCOMMAND')
      c.description = "Manage nodes"
      c.configure_sub_command(self)
    end

    command :'node show' do |c|
      cli_syntax(c, '[NODE]')
      c.description = "Show exectution history on a node"
      c.hidden = true
      action(c, nil)
    end

    command :script do |c|
      cli_syntax(c, 'SUBCOMMAND')
      c.description = "Manage scripts"
      c.configure_sub_command(self)
    end

    command :'script list' do |c|
      cli_syntax(c)
      c.description = "List available scripts"
      c.hidden = true
      action(c, nil)
    end

    command :'script show' do |c|
      cli_syntax(c, 'SCRIPT')
      c.description = "Show execution history of a script"
      c.hidden = true
      action(c, nil)
    end

    command :'script run' do |c|
      cli_syntax(c, '[SCRIPT]')
      c.description = "Execute scripts"
      c.hidden = true
      c.option '-r', '--role ROLE',
        "Run all scripts with ROLE (and no STAGE unless --stage is passed)"
      c.option '-s', '--stage',
        "Run all scripts with STAGE (and no ROLE unless --role is passed)"
      action(c, nil)
    end
  end
end
