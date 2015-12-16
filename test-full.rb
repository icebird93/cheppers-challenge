#!/usr/bin/ruby

# Load modules
require_relative 'cheppers/configuration.cheppers.rb'
require_relative 'cheppers/base.cheppers.rb'
require_relative 'cheppers/aws.cheppers.rb'

# Create new instance
cheppers = CheppersAws.new({verbose:true, debug:false, confirm:true})

# Load configuration
cheppers.load_configuration('config.yml')

# Enable all components
cheppers.component_set("create", true)
cheppers.component_set("environment", true)
cheppers.component_set("drupal", true)
cheppers.component_set("test", true)
cheppers.component_set("destroy", true)

# Run components
cheppers.components_execute