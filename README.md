# Cheppers Challenge
This package provides classes for the following Amazon AWS operations using your CLI:
- Create instance
- Prepare an LAMP environment (Apache 2, PHP 5, MySQL)
- Deploy a Drupal portal
- Run some tests
 - Online status: is a website accessible at the targeted IP address?
 - Apache status: is it served by the installed Apache configuration?
 - Drupal status: is the website a Drupal instance?
- Stop instance automatically

Also you can do these in a single script, meaning that you create, prepare an instance, run the tests and stop the VM when everything is finished.

##Tests included:
- 2 "hard-coded" tests (example for class calls, installations using single script)
- Custom, parametrized (for CLI)
- REST API (simple HTTP call triggered calls)
