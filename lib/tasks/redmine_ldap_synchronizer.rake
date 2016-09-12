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

namespace :redmine do
  namespace :ldap do
    desc 'Synchronize user information from LDAP'
    task :synchronize => :environment do
      User.active.joins(:auth_source).
          where("#{AuthSourceLdap.table_name}.type" => 'AuthSourceLdap').
          find_each(&:save)
    end
  end
end
