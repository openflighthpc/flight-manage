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

require 'flight-manage/command'
require 'flight-manage/config'
require 'flight-manage/exceptions'
require 'flight-manage/utils'

require 'date'
require 'open3'
require 'yaml'

module FlightManage
  module Commands
    module Scripts
      class Run < Command
        def run
          script_name, script_loc = find_script
          node_name, out_file = find_node_info

          # need to switch to popen3 & block syntax if want to manipulate the thread
          stdout, stderr, process_status = Open3.capture3(script_loc)
          time = DateTime.now.to_s
          stdout.chomp!
          stderr.chomp!
          exit_code = process_status.exitstatus
          status = exit_code == 0 ? "OK" : "FAIL"

          data = Utils.get_data(out_file)

          data[script_name] = {
            "time" => time,
            "status" => status,
            "exit_code" => exit_code,
            "stdout" => stdout,
            "stderr" => stderr
          }

          File.open(out_file, 'w') { |f| f.write(data.to_yaml) }
        end

        def find_script
          script_arg = @argv[0]
          #TODO let users specify the .bash themselves & not care?
          script_loc = File.join(Config.scripts_dir, "#{script_arg}.bash")
=begin
#TODO finish this
          glob_str = File.join(
            FlightManage::Config.scripts_dir,
            #still doesn't work for multilvl systems
            "#{script_arg}**/*.bash"
          )
          found = Dir.glob(glob_str)

          if found.empty?
            raise ArgumentError, <<-ERROR.chomp
No files found for #{script_arg}
            ERROR
          elsif found.length == 1
            script_loc = found[0]
          else
            file_names = found.map { |p| File.basename(p, File.extname(p)) }
            # if the results include just the search val, return that path
            if file_names.include?(script_arg)
              script_loc = found.select { |p| p =~ /#{script_arg}\.bash$/ }[0]
            else
              $stderr.puts "Ambiguous search term '#{script_arg}'"\
              " - possible results are:"
              file_names.each_slice(3).each { |p| $stderr.puts p.join("  ") }
              raise ArgumentError, <<-ERROR.chomp
  Please refine your search.
              ERROR
            end
          end
=end

          unless File.file?(script_loc) and File.readable?(script_loc)
            raise ArgumentError, <<-ERROR.chomp
Script at #{script_loc} is not reachable
            ERROR
          end

          return script_arg, script_loc
        end

        def find_node_info
          node_name = Utils.get_host_name

          out_file = File.join(FlightManage::Config.data_dir, node_name)

          #if out_file doesn't exist, create it
          unless File.file?(out_file)
            File.open(out_file, 'w') {}
          end

          unless File.writable?(out_file)
            raise ArgumentError, <<-ERROR.chomp
Output file at #{out_file} is not reachable - check permissions and try again
            ERROR
          end

          return node_name, out_file
        end
      end
    end
  end
end
