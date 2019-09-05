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

require 'socket'
require 'yaml'
require 'terminal-table'

module FlightManage
  module Utils
    def self.get_host_name
      Socket.gethostname.split('.')[0]
    end

    # Use lockfile library to prevent simultaneous access
    def self.lock_state_file(state_file)
      Lockfile.new("#{state_file.path}.lock", retries: 0) do
        yield
      end
    rescue Lockfile::MaxTriesLockError
      raise FileSysError, <<-ERROR.chomp
The file for node #{state_file.node} is locked - aborting
      ERROR
    end

    def self.read_yaml(path)
      data = nil
      begin
        File.open(path) do |f|
          data = YAML.safe_load(f)
        end
      rescue Psych::SyntaxError
        raise ManageError, <<-ERROR.chomp
Error parsing yaml in #{path} - aborting
        ERROR
      end
      data ||= {}
      data
    end
  end
end
