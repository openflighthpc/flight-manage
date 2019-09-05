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
          # get names of all nodes
          names = get_names
          # puts names

          # create list of StateFile objects
          nodes = load_nodes(names)
          # puts nodes

          # get names of all scripts
          scripts = get_scripts(nodes)
          # puts scripts

          # output table
          print_table(names,nodes,scripts)
        end

        def get_names
          names = Dir[File.join(Config.data_dir,'*')]
          names.map! { |f| File.basename(f,'.*')}
          names
        end

        def load_nodes(names)
          nodes = Array.new
          names.each {|name| nodes.push(Models::StateFile.new(name))}
          nodes
        end

        def get_scripts(nodes)
          scripts = Array.new
          nodes.each { |node| scripts.push(node.data.keys)}
          scripts.flatten.uniq
        end

        def print_table(names,nodes,scripts)
          table = Terminal::Table.new do |t|
            t.headings = scripts.unshift('Node')
            rows = Array.new
            (0..names.length-1).each do |i|
              rows.push([names[i]])
              (0..scripts.length-2).each do |j|
                if nodes[i].data.values[j] == nil
                  scriptval = "N/A"
                else
                  scriptval = nodes[i].data.values[j]["status"]
                end
                rows[i].push(scriptval)
              end
            end
            rows.each do |r|
              t.add_row r
            end
          end
          puts table
        end        
      end
    end
  end
end