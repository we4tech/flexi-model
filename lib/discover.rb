# Include plugins
require 'autotest/fsevent'
require 'autotest/growl'

Autotest.add_discovery { "rspec2" }

# Skip some paths
Autotest.add_hook :initialize do |autotest|
  %w{.idea .git .DS_Store ._* vendor}.each { |exception| autotest.add_exception(exception) }
  false
end
