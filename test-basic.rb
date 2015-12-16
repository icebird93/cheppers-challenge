#!/usr/bin/ruby

# Load modules
require_relative 'cheppers/configuration.cheppers.rb'
require_relative 'cheppers/base.cheppers.rb'
require_relative 'cheppers/aws.cheppers.rb'

# Create new instance
cheppers = CheppersAws.new({verbose:true, debug:false, confirm:true})

# Load configuration
cheppers.load_configuration('config.yml')

# Run components
cheppers.components_execute