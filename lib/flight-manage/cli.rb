#require 'inventoryware/commands'

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
  end
end
