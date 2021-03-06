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
require 'flight-manage/exceptions'
require 'flight-manage/models/state_file'
require 'flight-manage/utils'

module FlightManage
  module Commands
    module Report
      # Class of report command, prints table report on all node/script status
      class Show < Command
        def run
          # import nodes
          nodes = Utils.import_node_statefiles

          # list of node names
          names = nodes.map { |node| node.node }
          
          # get names of all scripts
          scripts = get_scripts(names)

          # output table
          table = print_table(nodes,names,scripts)
          puts table
        end

        def get_scripts(names)
          scripts = Array.new
          if @options.role or @options.stage
            filtered_scripts = Models::Script.find_scripts_with_role_and_stage(
              @options.role,
              @options.stage
            )
            filtered_scripts.each do |script|
              scripts.push(script.name)
            end
          else
            Config.script_dirs.each do |dir|
              Models::Script.glob_scripts(dir).each do |script|
                scripts.push(script.name)
              end
            end
          end
          names.each do |name|
            node = Utils.read_yaml(File.join(Config.data_dir,"#{name}.yaml"))
            scripts.push(node.keys)
          end
          scripts.flatten.uniq
        end        

        def print_table(nodes,names,scripts)
          table = Terminal::Table.new do |t|
            t.headings = ['Node','Script','Status']
            (0..names.length-1).each do |i|
              t.add_row [names[i],'','']
              rows = Array.new
              (0..scripts.length-1).each do |j|
                if nodes[i].data[scripts[j]] == nil
                  scriptval = "N/A"
                else
                  scriptval = nodes[i].data[scripts[j]]["status"]
                end
                rows.push(['',scripts[j],scriptval])
              end
              rows.each { |row| t.add_row row}
            end
          end
          table
        end        
      end
    end
  end
end
