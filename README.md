# Redmine LDAP Synchronizer

Features:
* Synchronize user information from LDAP
* Rake task for update all user
* Filters for custom field of issue's user type custom field

## Installation

1. Copy your plugin directory into #{RAILS_ROOT}/plugins. If you are downloading the plugin directly from GitHub, you can do so by changing into your plugin directory and issuing a command like `git clone git://github.com/jihh/redmine_ldap_synchronizer.git`
2. Restart redmine.

You should now be able to see the plugin list in Administration -> Plugins and configure the newly installed plugin.

## Usage

1. [Create some string type custom fields for User.](http://www.redmine.org/projects/redmine/wiki/RedmineCustomFields) Plugin will store the attributes to those custom fields.
2. [Declaring the LDAP.](http://www.redmine.org/projects/redmine/wiki/RedmineLDAP#Declaring-the-LDAP)
3. Set user's authentication mode to LDAP.

After that, when user be updated, plugin will get attributes from LDAP, and put them in custom fields.

### Update all user
> rake redmine:ldap:synchronize

## License
This plugin is released under the [GNU GPLv3](http://www.gnu.org/licenses/).