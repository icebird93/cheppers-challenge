#!/usr/bin/ruby

require 'net/http/server'
require 'uri/query_params'

# Load modules
require_relative 'cheppers/configuration.cheppers.rb'
require_relative 'cheppers/base.cheppers.rb'
require_relative 'cheppers/aws.cheppers.rb'

# Start HTTP server on 8080 and listen
debug = true
puts "Starting HTTP listener on port 8080..."
loop do
	Net::HTTP::Server.run(:port => 8080) do |request,stream|
		puts "[INFO] Client connected"
		p request if debug

		# Create new instance
		cheppers = CheppersAws.new({verbose:false, debug:false, confirm:true})

		# Load configuration
		cheppers.load_configuration('config.yml')

		# Parse parameters
		begin
			query = request[:uri][:query] ? URI::QueryParams.parse(request[:uri][:query].str) : {}
		rescue Exception, message
			query = {}
		end
		p query if debug

		# Process parameters
		cheppers.instance_select(query["instance"]) if query["instance"]

		# Process request
		case request[:uri][:path]
			when "/", "/empty"
				# Nothing
				[200, {'Content-Type' => 'text/html'}, ["Empty REST call"]]
			when "/create"
				# Create VM
				begin
					instance = cheppers.component_create
					[200, {'Content-Type' => 'text/html'}, ["VM created: "+instance]]
				rescue Exception, message
					[500, {'Content-Type' => 'text/html'}, [message]]
				end
			when "/environment"
				# Prepare LAMP environment
				begin
					cheppers.component_instance
					cheppers.component_environment
					[200, {'Content-Type' => 'text/html'}, ['LAMP prepared']]
				rescue Exception, message
					[500, {'Content-Type' => 'text/html'}, [message]]
				end
			when "/drupal", "/portal"
				# Prepare Drupal environment
				begin
					cheppers.component_instance
					cheppers.component_drupal
					[200, {'Content-Type' => 'text/html'}, ['Drupal prepared']]
				rescue Exception, message
					[500, {'Content-Type' => 'text/html'}, [message]]
				end
			when "/test"
				# Run tests
				begin
					cheppers.component_instance
					success = cheppers.component_test
					[200, {'Content-Type' => 'text/html'}, [success ? 'All tests succeeded' : 'Some tests failed']]
				rescue Exception, message
					[500, {'Content-Type' => 'text/html'}, [message]]
				end
			when "/destroy"
				# Destroy VM
				begin
					cheppers.component_destroy
					[200, {'Content-Type' => 'text/html'}, ['VM destroyed']]
				rescue Exception, message
					[500, {'Content-Type' => 'text/html'}, [message]]
				end
			else
				# Fallback
				[400, {'Content-Type' => 'text/html'}, ['Unsupported call']]
		end		
	end
end