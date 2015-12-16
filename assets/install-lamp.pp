# Update
exec { 'apt-update':
  command => '/usr/bin/apt-get update'
}

# Install curl 
package { 'curl':
  require => Exec['apt-update'],
  ensure => installed
}

# Install apache2 package (requires update)
package { 'apache2':
  require => Exec['apt-update'],
  ensure => installed
}

# Ensure apache2 service is running
service { 'apache2':
  require => Package['apache2'],
  ensure => running
}

# Install mysql-server package (requires update)
package { 'mysql-server':
  require => Exec['apt-update'],
  ensure => installed
}

# Ensure mysql service is running
service { 'mysql':
  require => Package['mysql-server'],
  ensure => running
}

# Ensure MySQL root password
exec { 'set-mysql-password':
  unless => 'mysqladmin -u{mysql_root_username} -p{mysql_root_password} status',
  path => ['/bin', '/usr/bin'],
  command => 'mysqladmin -u{mysql_root_username} password {mysql_root_password}',
  require => Service['mysql']
}

# Ensure MySQL database
exec { 'create-mysql-database':
  unless => '/usr/bin/mysql -u{mysql_username} -p{mysql_password} {mysql_database}',
  command => '/usr/bin/mysql -u{mysql_root_username} -p{mysql_root_password} -e "create database if not exists {mysql_database}; grant all on {mysql_database}.* to {mysql_username}@localhost identified by \'{mysql_password}\';"',
  require => Exec['set-mysql-password']
}

# Install php5 package (requires update)
package { 'php5':
  require => Exec['apt-update'],
  ensure => installed
}

# Install gd (required for Drupal) 
package { 'php5-gd':
  require => Package['php5'],
  ensure => installed
}

# Install database support
package { 'php5-mysql':
  require => [ Package['php5'], Package['mysql-server'] ],
  ensure => installed
}
exec { 'apache2-restart':
  require => Package['php5-mysql'],
  command => '/etc/init.d/apache2 restart'
}