require 'yaml'

# Configuration submodule
# @description Used to preconfigure Cheppers classes and add configuration functions
module CheppersConfiguration

	# Load configuration file
	def load_configuration(file)
		raise ArgumentError, "Invalid file argument in load_configuration" unless file

		# Try to load file as YAML
		begin
			puts "Reading configuration..."
			@configuration = YAML.load_file(file)
			p @configuration if @debug

			# Parse values
			@components = @configuration["components"]
			p @components if @debug

			# Prepare SSH config
			@ssh = @configuration["instance"]["ssh"]
			if (!@ssh["username"]) or (!@ssh["password"])
				# Select username and password, based on instance OS
				case @configuration["instance"]["os"]
					when "debian"
						@ssh["username"]="admin"
					else
						raise "Unsupported instance OS"
				end
			end
			p @ssh if @debug

			# Prepare MySQL config
			@sql = @configuration["instance"]["sql"]
			if (!@sql["username"]) or (!@sql["password"]) or (!@sql["database"])
				@sql = { "root" => { "username" => "root", "password" => "admin" }, "username" => "drupal", "password" => "drupal", "database" => "drupal" }
				puts "[INFO] Using default MySQL credentials and database" if @verbose
			end			
			p @sql if @debug

			# Drush config
			@drush = @configuration["drush"]
			if (!@drush["version"])
				@drush = { "version" => "7.1.0" }
				puts "[INFO] Using default Drush settings" if @verbose
			end
			p @drush if @debug

			# Drupal config
			@drupal = @configuration["drupal"]
			if (!@drupal["version"])
				@drupal = { "version" => "7.41", "email" => "", "password" => false }
				puts "[INFO] Using default Drupal settings" if @verbose
			end
			p @drupal if @debug

			# Check configuration
			raise "SSH key file does not exist or is not a valid file" if (File.exist?(@ssh["key"])) || (File.file?(@ssh["key"]))

			puts "[OK] Configuration loaded" if @verbose
		rescue Exception => message
			puts message if @verbose
			puts "[ERROR] Configuration could not be loaded"
		end
	end

	# Enable/Disable component
	def component_set(component, status)
		raise ArgumentError, "Invalid component" unless ["create","environment","drupal","test","destroy"].include?(component)
		raise ArgumentError, "Invalid component" unless !!status==status
		@components[component] = status
	end

	# Select target instance
	def instance_select(instance)
		@instance = instance
	end

	# Accessors
	attr_reader :configuration, :components
	attr_accessor :verbose, :debug

	###################
	# Private methods #
	###################
	private

	# Initialize default values (called from constructors)
	def _init_configuration
		# Set defaults
		@info = {}
		@components = { "create" => false, "environment" => false, "drupal" => false, "test" => true, "destroy" => false }
		@configuration = false
		@ssh = false
	end

end