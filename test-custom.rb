#!/usr/bin/ruby

require 'optparse'

# Load modules
require_relative 'cheppers/configuration.cheppers.rb'
require_relative 'cheppers/base.cheppers.rb'
require_relative 'cheppers/aws.cheppers.rb'

# Parse parameters
begin
	options = {:verbose => false, :debug => false, :confirm => false}
	OptionParser.new do |opts|
		opts.banner = "Usage: test-custom.rb [options]"
	
		opts.on('-y', '--yes', 'Preconfirm actions') { |v| options[:confirm] = !v }
		opts.on('-v', '--verbose', 'Verbose mode') { |v| options[:verbose] = v }
		opts.on('-d', '--debug', 'Debug mode') { |v| options[:debug] = v }
		opts.on('-h', '--help', 'Displays help') { puts opts; exit }

		opts.on('-i', '--instance id', 'Set instance ID') { |id| options[:instance] = id }
		
		opts.on('-C', '--create', 'Create instance automatically') { |v| options[:create] = v }
		opts.on('-E', '--environment', 'Prepare LAMP environment') { |v| options[:environment] = v }
		opts.on('-P', '--portal', 'Prepare Drupal environment') { |v| options[:drupal] = v }
		opts.on('-T', '--test', 'Run tests') { |v| options[:test] = v }
		opts.on('-D', '--destroy', 'Destroy instance on exit') { |v| options[:destroy] = v }
	end.parse!
rescue OptionParser::InvalidOption => error
	puts error
	exit
end

# Create new instance
cheppers = CheppersAws.new({verbose:options[:verbose], debug:options[:debug], confirm:options[:confirm]})

# Load configuration
cheppers.load_configuration('config.yml')

# Add configuration
cheppers.component_set("create", true) if options[:create]
cheppers.component_set("environment", true) if options[:environment]
cheppers.component_set("drupal", true) if options[:drupal]
cheppers.component_set("test", true) if options[:test]
cheppers.component_set("destroy", true) if options[:destroy]

# Select instance
cheppers.instance_select(options[:instance]) if options[:instance]

# Run components
cheppers.components_execute