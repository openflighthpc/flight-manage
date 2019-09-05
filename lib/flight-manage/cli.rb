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

require 'flight-manage/commands'

require 'commander'
require 'paint'

module FlightManage
  module CLI
    PROGRAM_NAME = ENV.fetch('FLIGHT_PROGRAM_NAME', 'manage')

    extend Commander::Delegates
    program :name, PROGRAM_NAME
    program :version, '0.0.0'
    program :description, 'Remote executor of shared scripts.'
    program :help_paging, false

    ARGV.push '--help' if ARGV.empty?

    error_handler do |e|
      $stderr.puts "#{Paint[PROGRAM_NAME, '#2794d8']}: #{Paint[e.to_s, :red]}"
      case e
      when OptionParser::InvalidOption,
           Commander::Runner::InvalidCommandError,
           Commander::Patches::CommandUsageError
        $stderr.puts "\nUsage:\n\n"
        args = ARGV.reject { |o| o[0] == '-' }
        if command(topic = args[0..1].join(' '))
          command('help').run(topic)
        elsif command(args[0])
          command('help').run(args[0])
        else
          command('help').run
        end
      end
      exit(1)
    end

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

      def add_role_and_stage_options(command)
        command.option '-r', '--role ROLE',
          'Select all scripts with ROLE (and no STAGE unless --stage is passed)'
        command.option '-s', '--stage STAGE',
          'Select all scripts with STAGE (and no ROLE unless --role is passed)'
        command.option '-c', '--chain CHAIN',
          'Select all the scripts in the specified file'
      end

      def output_verbosity(command)
        command.option '-v', '--verbose',
          'Print stderr and stdout of a script'
        command.option '-e', '--error',
          'Print just stderr'
      end
    end

    command :node do |c|
      cli_syntax(c, 'SUBCOMMAND')
      c.description = 'Manage nodes'
      c.configure_sub_command(self)
    end

    command :'node show' do |c|
      cli_syntax(c, '[NODE]')
      c.description = 'Show history of execution on a node'\
                      ' (defaults to this node)'
      output_verbosity(c)
      c.hidden = true      
      action(c, Commands::Nodes::Show)
    end

    command :script do |c|
      cli_syntax(c, 'SUBCOMMAND')
      c.description = 'Manage scripts'
      c.configure_sub_command(self)
    end

    command :'script import' do |c|
      cli_syntax(c, 'SOURCE DESTINATION PLATFORM')
      c.description = 'Import scripts from an openflightHPC Architect .zip'
      c.hidden = true
      action(c, Commands::Scripts::Import)
    end

    command :'script list' do |c|
      cli_syntax(c)
      c.description = 'List available scripts'
      c.hidden = true
      action(c, Commands::Scripts::List)
    end

    command :'script show' do |c|
      cli_syntax(c, 'SCRIPT')
      c.description = 'Show execution history of a script'
      c.hidden = true
      action(c, Commands::Scripts::Show)
    end

    command :'script run' do |c|
      cli_syntax(c, '[SCRIPT]')
      c.description = 'Execute scripts'
      add_role_and_stage_options(c)
      c.hidden = true
      action(c, Commands::Scripts::Run)
    end

    command :'script resolve' do |c|
      cli_syntax(c, '[SCRIPT]')
      c.description = 'Mark a script as having been completed externally'
      add_role_and_stage_options(c)
      c.hidden = true
      action(c, Commands::Scripts::Resolve)
    end

    command :report do |c|
      cli_syntax(c)
      c.description = 'Show table report of node status for all scripts'
      action(c, Commands::Report::Show)
    end
  end
end
