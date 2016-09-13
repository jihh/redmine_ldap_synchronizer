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

      result = self.auth_source.get_attributes self.login, mapping.values.uniq
      case
        when result.nil?
        when result.empty?
          self.status = User::STATUS_LOCKED if Setting.plugin_redmine_ldap_synchronizer['inactive'] == '1'
        else
          self.custom_field_values = mapping.inject({}) do |hash, pair|
            hash[pair.first] = result[pair.last]
            hash
          end
      end
    end
  end
end

if User.included_modules.exclude? RedmineLdapSynchronizer::UserPatch
  User.send :include, RedmineLdapSynchronizer::UserPatch
end