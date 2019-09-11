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

require 'flight-manage/exceptions'
require 'flight-manage/utils'

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

    attr_reader :root_dir, :data_dir, :script_dirs, :log_file, :remote_exec

    def initialize
      @root_dir = File.expand_path(File.join(File.dirname(__FILE__), '../..'))
      @conf_file = File.join(@root_dir, 'etc/manage.conf')
      conf = if File.readable?(@conf_file)
               File.open(@conf_file) { |f| YAML.safe_load(f) }
             else
               {}
             end
      @data_dir = get_val_from_conf(conf, 'data_dir')
      @data_dir ||= '/opt/service/flight/managedata/'

      @script_dirs = get_val_from_conf(conf, 'script_dirs')
      @script_dirs ||= ['/opt/service/scripts']
      @script_dirs.map! { |p| p.gsub('{nodename}', Utils.get_host_name) }
      #check if any script directories are nested
      @script_dirs.each do |dir1|
        @script_dirs.each do |dir2|
          if dir1 =~ /^#{dir2}.*\//
            raise ConfigError, <<-ERROR.chomp
Error in config file: Nested script directories #{dir1} and #{dir2} not valid
            ERROR
          end
        end
      end

      @remote_exec = get_val_from_conf(conf, 'remote_dir')
      @remote_exec ||= '/opt/flight/bin/flight/manage'

      @log_file = get_val_from_conf(conf, 'log_file')
      @log_file ||= File.join(@root_dir, 'var/log/manage.log')
    end

    def get_val_from_conf(conf, key)
      unless conf.respond_to?(:key?) and conf.key?(key)
        return nil
      end
      # check if absolute path
      if conf[key].is_a?(Array)
        return conf[key]
      elsif not conf[key].is_a?(String)
        return nil
      elsif conf[key].start_with?('/')
        return conf[key]
      else
        return File.join(@root_dir, conf[key])
      end
    end
  end
end
