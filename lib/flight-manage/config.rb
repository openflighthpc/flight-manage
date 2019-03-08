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

module FlightManage
  # Contains configuration logic based on etc/manage.conf config file
  class Config
    class << self
      def instance
        @instance ||= Config.new
      end

      def method_missing(s, *_a, &_b)
        raise unless instance.respond_to?(s)
        instance.send(s)
      end

      def respond_to_missing?(s)
        instance.respond_to?(s)
      end
    end

    attr_reader :data_dir, :scripts_dir, :log_file

    def initialize
      @root_dir = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
      @conf_file = File.join(@root_dir, 'etc/manage.conf')
      conf = if File.readable?(@conf_file)
               File.open(@conf_file) { |f| YAML.safe_load(f) }
             else
               {}
             end
      @data_dir = get_path_from_conf(conf, 'data_dir')
      @data_dir ||= '/opt/service/flight/managedata/'

      @scripts_dir = get_path_from_conf(conf, 'scripts_dir')
      @scripts_dir ||= '/opt/service/scripts/'

      @log_file = get_path_from_conf(conf, 'log_file')
      @log_file ||= File.join(@root_dir, 'var/log/manage.log')
    end

    def get_path_from_conf(conf, key)
      unless conf.key?(key)
        return nil
      end
      # check if absolute path
      if conf[key].start_with?('/')
        return conf[key]
      else
        return File.join(@root_dir, conf[key])
      end
    end
  end
end
