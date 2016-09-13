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

# -- encoding: utf-8 --
module RedmineLdapSynchronizer
  module IssueQueryPatch
    extend ActiveSupport::Concern
    included do
      alias_method_chain :initialize_available_filters, :ldap_sync
      alias_method_chain :statement, :ldap_sync
    end

    def initialize_available_filters_with_ldap_sync
      initialize_available_filters_without_ldap_sync
      # 用户的可过滤自定义属性
      user_custom_fields = UserCustomField.where(:is_filter => true).all
      # 问题的用户类型自定义属性
      issue_custom_fields = project ? project.all_issue_custom_fields.select { |c| c.field_format == 'user' } :
          IssueCustomField.sorted.where(:field_format => 'user', :is_for_all => true).to_a
      unless user_custom_fields.empty? or issue_custom_fields.empty?
        issue_custom_fields.each do |issue_custom_field|
          user_custom_fields.each do |user_custom_field|
            add_nest_custom_field_filter issue_custom_field, user_custom_field
          end
        end
      end
    end

    def statement_with_ldap_sync
      filters.each_key do |field|
        if field =~ /^custom_field_(\d+)_of_(\d+)$/
          src = <<-END_SRC
          def sql_for_#{field}_field(field, operator, value)
            sql_for_nest_custom_field(field, operator, value)
          end
          END_SRC
          instance_eval src, __FILE__, __LINE__
        end
      end
      statement_without_ldap_sync
    end


    private
    def sql_for_nest_custom_field(field, operator, value)
      filter = @available_filters[field]
      return nil unless filter
      if filter[:field].format.target_class && filter[:field].format.target_class <= User
        if value.delete('me')
          value.push User.current.id.to_s
        end
      end
      not_in = nil
      if operator == '!'
        operator = '='
        not_in = 'NOT'
      end
      where = sql_for_field field, operator, value, 'cv2', 'value', true
      if operator =~ /[<>]/
        where = "(#{where}) AND cv2.value <> ''"
      end
      "#{Issue.table_name}.id #{not_in} IN (" +
          "SELECT #{Issue.table_name}.id FROM #{Issue.table_name}" +
          " LEFT OUTER JOIN #{CustomValue.table_name} cv1 ON cv1.customized_id = #{Issue.table_name}.id AND cv1.custom_field_id = #{filter[:owner].id} AND cv1.customized_type = 'Issue'" +
          " LEFT OUTER JOIN #{CustomValue.table_name} cv2 ON cv2.customized_id = cv1.value AND cv2.custom_field_id = #{filter[:field].id} AND cv2.customized_type = 'Principal'" +
          " WHERE #{where} )"
    end

    def add_nest_custom_field_filter(owner, field)
      field_id = "custom_field_#{field.id}_of_#{owner.id}"
      options = field.query_filter_options(self)
      options[:name] = "#{owner.name} #{field.name}"
      options[:owner] = owner
      options[:field] = field
      add_available_filter field_id, options
    end
  end
end


if IssueQuery.included_modules.exclude? RedmineLdapSynchronizer::IssueQueryPatch
  IssueQuery.send :include, RedmineLdapSynchronizer::IssueQueryPatch
end