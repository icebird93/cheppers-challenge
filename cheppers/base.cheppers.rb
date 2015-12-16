require 'io/console'

# Cheppers Challenge class
# @description AWS Challenge solution
# @created 2015
# @requirements ruby(v2), gems(mysql2)
module CheppersBase

	# Include Configurator
	include CheppersConfiguration

	# Initializate, welcome user
	# @parameters {params}
	# @params verbose=false,debug=false
	def initialize(params=false)
		# Set debug options (can be overriden with custom config)
		if params
			@verbose = params[:verbose]
			@debug = params[:debug]
			@confirm = params[:confirm]
		else
			@verbose = false
			@debug = false
			@confirm = false
		end

		# Initialize configuration
		_init_configuration

		puts "[OK] Cheppers base initizalized"
	end

	def components_execute()
		# Check configuration
		raise "Components not initialized" if !@components

		# Confirmation
		if !@confirm
			# Display selected actions
			puts "Following actions will be performed:"
			puts "- Create" if @components["create"]
			puts "- Prepare LAMP environment" if @components["environment"]
			puts "- Prepare Drupal" if @components["drupal"]
			puts "- Tests" if @components["test"]
			puts "- Destroy" if @components["destroy"]

			# Accept/Deny
			print "Continue? [y/N] "
			response = STDIN.getch
			puts ""
			if !(response == 'y' || response == 'Y')
				puts "[INFO] Aborted by user"
				exit
			end
		end		

		# Run components one-by-one
		begin
			component_create if @components["create"]
			component_instance
			component_environment if @components["environment"]
			component_drupal if @components["drupal"]
			component_test if @components["test"]
			component_destroy if @components["destroy"]
		rescue Exception => message
			_log(message)
			puts message if @verbose
			puts "[ERROR] Component execution failed"
		end
	end

	##################
	# Helper methods #
	##################

	# Sends command to VM instance for execution
	def command_send(command)
		raise "Configuration not loaded or no VM is running" if (!@ssh) or (!@ip)
		ssh = `ssh -oStrictHostKeyChecking=no -i #{@ssh["key"]} -t #{@ssh["username"]}@#{@ip} "#{command}" #{@debug ? "" : "2>/dev/null"}`
		return ssh
	end

	# Sends file to VM using predefined credientals
	def file_send(source, destination)
		raise "Configuration not loaded or no VM is running" if (!@ssh) or (!@ip)
		scp = `scp -oStrictHostKeyChecking=no -i #{@ssh["key"]} #{source} #{@ssh["username"]}@#{@ip}:#{destination} #{@debug ? "" : "2>/dev/null"}`
		return scp
	end

	####################
	# Abstract methods #
	####################

	# Creates and checks VM
	def component_create
		raise NotImplementedError, "component_create is not implemented"
	end

	# Starts VM
	def component_instance
		raise NotImplementedError, "component_instance is not implemented"
	end

	# Prepares LAMP environment
	def component_environment
		raise NotImplementedError, "component_environment is not implemented"
	end

	# Prepares Drupal environment
	def component_drupal
		raise NotImplementedError, "component_drupal is not implemented"
	end

	# Does tests
	def component_test
		raise NotImplementedError, "component_drupal is not implemented"
	end

	# Destroys VM
	def component_destroy
		raise NotImplementedError, "component_drupal is not implemented"
	end

	###################
	# Private methods #
	###################
	private

	# Log a custom text
	def _log(text)
		open('cheppers.log', 'a') { |f| f.puts(text+"\n") } if text.is_a?(String)
	end

end