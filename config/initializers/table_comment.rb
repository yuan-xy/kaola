require 'rails/generators'

module Rails
  module Generators
    class NamedBase < Base

      protected
        
        def human_table_name
          str = Object.const_get(singular_table_name.camelize).connection.retrieve_table_comment(plural_table_name)
          return human_name unless str
          str.force_encoding('ASCII-8BIT')
        end
        
        def human_column_name(col)
          hash = Object.const_get(singular_table_name.camelize).connection.retrieve_column_comments(plural_table_name)
          return col if hash.nil? || hash[col.to_sym].nil?
          hash[col.to_sym].split(" ")[0].force_encoding('ASCII-8BIT')
        end
    end
  end
end
