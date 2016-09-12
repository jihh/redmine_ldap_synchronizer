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
  module UserPatch
    extend ActiveSupport::Concern
    included do
      before_save :synchronize_ldap_information
    end

    def synchronize_ldap_information
      return unless self.auth_source.is_a?(AuthSourceLdap)
      mapping = Setting.plugin_redmine_ldap_synchronizer['mapping'].select { |k, v| v.present? }
      return if mapping.empty?

      search_filter = Net::LDAP::Filter.eq 'objectClass', '*'
      search_filter &= Net::LDAP::Filter.construct self.auth_source.filter if self.auth_source.filter.present?
      search_filter &= Net::LDAP::Filter.eq self.auth_source.attr_login, self.login

      search_attrs = (['dn'] + mapping.values).uniq

      options = {:host => self.auth_source.host,
                 :port => self.auth_source.port,
                 :encryption => (self.auth_source.tls ? :simple_tls : nil)}
      if self.auth_source.account.present? or self.auth_source.account_password.present?
        options[:auth] = {:method => :simple,
                          :username => self.auth_source.account,
                          :password => self.auth_source.account_password}
      end
      ldap_connection = Net::LDAP.new options
      result_set = ldap_connection.search :base => self.auth_source.base_dn,
                                          :filter => search_filter,
                                          :attributes => search_attrs,
                                          :size => 1
      if result_set.empty?
        # Not Found
        false
      else
        entry = result_set.first
        self.custom_field_values = mapping.inject({}) do |hash, pair|
          hash[pair.first] = AuthSourceLdap.get_attr entry, pair.last
          hash
        end
        true
      end
    rescue Exception => e
      false
    end

  end
end

if User.included_modules.exclude? RedmineLdapSynchronizer::UserPatch
  User.send :include, RedmineLdapSynchronizer::UserPatch
end