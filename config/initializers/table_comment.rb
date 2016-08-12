require 'rails/generators'
require_relative '../../extra_databases'

module Rails
  module Generators
    class NamedBase < Base

      protected
      
        def find_database(clazz)
           $extra_databases.each do |extra|
             ActiveRecord::Base.establish_connection("#{extra}_#{Rails.env}".to_sym)
             return if clazz.table_exists?
           end
        end
        
        def human_table_name
          clazz = Object.const_get(singular_table_name.camelize)
          find_database(clazz) unless clazz.table_exists?
          str = clazz.connection.retrieve_table_comment(plural_table_name)
          return human_name unless str
          str.force_encoding('ASCII-8BIT')
        end
        
        def human_column_name(col)
          clazz = Object.const_get(singular_table_name.camelize)
          find_database(clazz) unless clazz.table_exists?
          hash = clazz.connection.retrieve_column_comments(plural_table_name)
          return col if hash.nil? || hash[col.to_sym].nil?
          hash[col.to_sym].split(" ")[0].force_encoding('ASCII-8BIT')
        end
    end
  end
end
