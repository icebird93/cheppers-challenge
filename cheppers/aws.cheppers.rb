require 'securerandom'
require 'net/http'
require 'uri'

# AWS specific class extender
class CheppersAws

	# Include base class (Cheppers)
	include CheppersBase

	# Initializate class
	def initialize(params)
		# Load baseclass' constructor
		super(params)

		# Initialize AWS specific variables
		_init_aws

		puts "[OK] AWS initialized"
	end

	# Load configuration
	def load_configuration(file)
		# Load baseclass' loader
		super(file)

		# Load AWS specific configuration
		@aws = @configuration["aws"]

		# Check configuration
		raise "No instance type specified" if !@aws["type"]
		raise "No AMI specified" if !@aws["ami"]
		raise "No AWS keypair specified" if !@aws["key"]
	end

	# Creates VM if needed
	def component_create
		puts "Checking if instance is created..."
		_log("[component_create]")

		# Check instance
		if (!@aws["instance"]) || (_instance_terminated(@aws["instance"])) || (_instance_status(@aws["instance"]).eql? "")
			# Instance not running or specified
			puts "[INFO] Instance not running or specified" if @verbose
			puts "Creating instance..."
			@instance = _instance_create(@aws["ami"], @aws["type"], @aws["key"], @aws["security"])
			@info["created"] = true
			puts "[OK] Created instance #{@instance}"
		else
			# Valid instance specified
			@instance = @aws["instance"]
		end
		return @instance
	end

	# Starts VM if needed
	def component_instance
		if !@info["instance"]
			# Checking instance
			@instance = @aws["instance"] if !@instance
			status = _instance_status(@instance)

			# Start instance
			if !(status.eql? "running")
				puts "Waiting for instance #{@instance}..."
				_log("[component_instance]")
				raise "Instance cannot be started" if !_instance_start(@instance)

				# Safety sleep (to be ready for sure)
				puts "Waiting 120 more seconds for safety..."
				sleep(120)
			end

			# Get IP
			puts "Getting public IP of instance..."
			@ip = _instance_ip(@instance)
			_log("Instance accessible at #{@ip}")
			@info["instance"] = true
			puts "[INFO] #{@instance} is accessible at #{@ip}" if @verbose
		end

		puts "[OK] Instance is ready"
		return @ip
	end

	# Prepares LAMP environment
	def component_environment
		puts "Preparing LAMP environment..."
		puts "[INFO] This might take a few minutes"
		_log("[component_environment]")

		# Upload Puppet installer and run
		file_send("assets/#{@configuration["instance"]["os"]}/install-puppet.sh", "~/install-puppet.sh")
		debug = command_send("cd; sudo chmod u+x install-puppet.sh; sudo ./install-puppet.sh; rm install-puppet.sh;")
		_log(debug)
		puts debug if @debug

		# Wait until it reboots
		retries = 10
		sleep(10)
		until (retries == 0) || (_instance_status(@instance).eql? "running") do
			retries -= 1
			sleep(10)
		end

		# Prepare manifest
		manifest = File.read("assets/install-lamp.pp")
		manifest.gsub!('{mysql_root_username}', @sql["root"]["username"])
		manifest.gsub!('{mysql_root_password}', @sql["root"]["password"])
		manifest.gsub!('{mysql_username}', @sql["username"])
		manifest.gsub!('{mysql_password}', @sql["password"])
		manifest.gsub!('{mysql_database}', @sql["database"])
		File.open("install-lamp.pp.tmp", "w"){ |f| f.write(manifest) }

		# Upload Puppet manifest and apply
		file_send("install-lamp.pp.tmp", "~/install-lamp.pp")
		debug = command_send("cd; sudo puppet apply install-lamp.pp; rm install-lamp.pp;")
		File.delete("install-lamp.pp.tmp")
		_log(debug)
		puts debug if @debug

		puts "[OK] LAMP is ready"
	end

	# Prepares Drupal environment
	def component_drupal
		puts "Preparing Drupal environment..."
		puts "[INFO] This might take a few minutes"
		_log("[component_drupal]")

		# Install Drush
		puts "Installing Drush..." if @verbose
		debug = command_send("/usr/bin/curl -sS https://getcomposer.org/installer | sudo /usr/bin/php -- --install-dir=/usr/local/bin --filename=composer; composer global require drush/drush:#{@drush["version"]};")
		_log(debug)
		puts debug if @debug

		# Generate admin password if needed
		@drupal["password"] = SecureRandom.hex(4) if !@drupal["password"]

		# Install Drupal
		puts "Installing Drupal..." if @verbose
		debug = command_send("cd /var/www/; sudo rm -rf drupal; sudo ~/.composer/vendor/bin/drush dl drupal-#{@drupal["version"]} --destination=/var/www --drupal-project-rename=drupal; cd drupal; sudo ~/.composer/vendor/bin/drush site-install standard -y --account-name=admin --account-pass=#{@drupal["password"]} --account-mail=#{@drupal["email"]} --db-url=mysql://#{@sql["username"]}:#{@sql["password"]}@localhost/#{@sql["database"]} --site-name='#{@drupal["title"]}' --locale=en;")
		_log(debug)
		puts debug if @debug

		# Upload prepared vhost file and make it active, also enable required modules (rewrite, headers)
		file_send("assets/vhost", "~/vhost")
		debug = command_send("cd; sudo mv vhost /etc/apache2/sites-available/000-drupal; sudo ln -s /etc/apache2/sites-available/000-drupal /etc/apache2/sites-enabled/000-drupal.conf; sudo unlink /etc/apache2/sites-enabled/000-default.conf; sudo ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load; sudo ln -s /etc/apache2/mods-available/headers.load /etc/apache2/mods-enabled/headers.load; sudo service apache2 restart;")
		_log(debug)
		puts debug if @debug

		# Drupal post-install
		command_send("sudo chmod 0777 /var/www/drupal/sites/default")

		puts "[INFO] Drupal credentials: admin/#{@drupal["password"]}"
		puts "[OK] Drupal is ready on http://#{@ip}"
	end

	# Does tests
	def component_test
		puts "Running tests..."
		_log("[component_test]")

		# 1-2 test: HTTP status code and header validation
		test = []
		uri = URI.parse("http://#{@ip}")
		http = Net::HTTP.new(uri.host, uri.port)
		request = Net::HTTP::Get.new("/")
		response = http.request(request)
		_log(response.body)
		p response.body if @debug

		# Evaluate first tests
		test[1] = response.code=="200"
		puts "[INFO] Status code is #{response.code}" if @verbose
		puts "["+(test[1] ? "OK" : "FAIL")+"] First check: status code"
		test[2] = response["X-Cheppers"]=="Challenge"
		puts "[INFO] X-Cheppers header is #{response["X-Cheppers"]}" if @verbose
		puts "["+(test[2] ? "OK" : "FAIL")+"] Second check: header validation"

		# 3 test: Check HTML content
		match = /Welcome to (.*?)\s{2,}<\/h1>/.match(response.body)
		test[3] = match[1]==@drupal["title"]
		puts "[INFO] <h1> Welcome to #{match[1]}</h1>" if @verbose
		puts "["+(test[3] ? "OK" : "FAIL")+"] Third check: H1 title validation"

		puts "["+((test[1] && test[2] && test[3]) ? "OK" : "FAIL")+"] All checks completed"
		return (test[1] && test[2] && test[3])
	end

	# Destroys VM
	def component_destroy
		puts "Stopping instances..."
		_log("[component_destroy]")

		# Stop running instance
		_instance_stop(@instance)

		puts "[OK] All instances stopped"
	end

	###################
	# Private methods #
	###################
	private

	# Initialize AWS variables
	def _init_aws
		# Set defaults
		@aws = { "type" => "t2.micro" }
	end

	# Check if instance was terminated
	def _instance_terminated(instance)
		status = `aws ec2 describe-instance-status --instance-ids #{instance} --query "InstanceStatuses[0]" --output text 2>/dev/null`
		return status.strip.eql? "None"
	end

	# Check instance status
	def _instance_status(instance)
		status = `aws ec2 describe-instance-status --instance-ids #{instance} --query "InstanceStatuses[0].InstanceState.Name" --output text 2>/dev/null`
		return status.strip
	end

	# Create instance in AWS
	def _instance_create(ami, type, keypair, security_group)
		instance = `aws ec2 run-instances --image-id ami-#{ami} --instance-type #{type} --key-name #{keypair} --security-group-ids #{security_group} --count 1 --query 'Instances[0].InstanceId' --output text 2>/dev/null`
		return instance.strip
	end

	# Start instance if not already started
	def _instance_start(instance)
		if !(_instance_status(instance).eql? "running")
			# Start instance
			`aws ec2 start-instances --instance-ids #{instance} 2>/dev/null`

			# Wait until it boots (or 10 attempts)
			retries = 10
			until (retries == 0) || (_instance_status(instance).eql? "running") do
				puts "[INFO] Instance is not yet running, waiting..." if @verbose
				sleep(10)
				retries -= 1
			end
			return false if retries==0
		end
		return true
	end

	# Get public IP of instance	
	def _instance_ip(instance)
		ip = `aws ec2 describe-instances --instance-ids #{instance} --query "Reservations[0].Instances[0].PublicIpAddress" --output text 2>/dev/null`
		return ip.strip
	end

	# Stop instance
	def _instance_stop(instance)
		`aws ec2 stop-instances --instance-ids #{instance}` if _instance_status(instance).eql? "running"
	end

end