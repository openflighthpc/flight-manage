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

require 'fileutils'
require 'zip'

module FlightManage
  module Commands
    module Scripts
      # Class of the script import command, creates scripts from a .zip
      class Import < Command
        CHAR = /[\w\.\-]/
        FILENAME = /#{CHAR}+/
        PATH = /(#{FILENAME})\/node\/(#{FILENAME})\/core\/plugins\/(.*)/

        def run
          destination = @argv[1]
          platform = @argv[2]
          zip_path = find_zip()

          Zip::File.open(zip_path) do |zip_file|
            changed = false
            zip_file.each do |entry|
              m = PATH.match(entry.name)
              if m and m[1] == platform
                node, name = m[2, 3]
                path = File.join(destination,
                                 "#{node}scripts",
                                 name)
                FileUtils.mkdir_p(File.dirname(path))
                entry.extract(path) { :continue_on_exists_proc }
                puts "Extracting '#{name}' for node '#{node}' to '#{path}'"
                changed = true
              end
            end
            unless changed
              puts "No files found in #{zip_path} for platform #{platform}"
            end
          end
        end

        def find_zip
          if File.file?(@argv[0]) and File.extname(@argv[0]) == '.zip'
            return @argv[0]
          else
            rel_path = File.join(Config.root_dir, @argv[0])
            if File.file?(rel_path) and File.extname(rel_path) == '.zip'
              return rel_path
            else
              raise ArgumentError, <<-ERROR.chomp
No .zip script file found at #{@argv[0]}
              ERROR
            end
          end
        end
      end
    end
  end
end
