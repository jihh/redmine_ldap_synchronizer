# Redmine LDAP Synchronizer - synchronize user information from LDAP
# Copyright (C) 2016 Haihan Ji
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module RedmineLdapSynchronizer
  module AuthSourceLdapPatch
    extend ActiveSupport::Concern

    def get_attributes(login, attributes=[])
      result = {}
      search_filter = base_filter & Net::LDAP::Filter.eq(self.attr_login, login)
      ldap_connection = initialize_ldap_con(self.account, self.account_password)
      ldap_connection.search :base => self.base_dn,
                             :filter => search_filter,
                             :attributes => attributes,
                             :size => 1 do |entry|
        attributes.each do |attr_name|
          result[attr_name] = AuthSourceLdap.get_attr entry, attr_name
        end
      end
      result
    rescue *NETWORK_EXCEPTIONS => e
      logger.error e.message
      nil
    end
  end
end

if AuthSourceLdap.included_modules.exclude? RedmineLdapSynchronizer::AuthSourceLdapPatch
  AuthSourceLdap.send :include, RedmineLdapSynchronizer::AuthSourceLdapPatch
end