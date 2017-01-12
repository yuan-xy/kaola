require 'rails/generators'
require 'byebug'
require_relative '../../extra_databases'

module MigrationComments::ActiveRecord::ConnectionAdapters
  module Mysql2Adapter


    def table_comments_sql
      <<SQL
SELECT table_name,table_comment FROM INFORMATION_SCHEMA.TABLES
  WHERE table_schema = '#{database_name}'
SQL
    end

  def retrieve_table_comments
    result = select_rows(table_comments_sql) || []
    Hash[result.map{|row| [row[0], row[1].presence]}]
  end
  
  def retrieve_views
    sql = "SELECT table_name FROM INFORMATION_SCHEMA.VIEWS WHERE table_schema = '#{database_name}'"
    result = select_rows(sql)
    result.flatten! if result
    result
  end

end
end

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
          with_cache($cached_table_names,singular_table_name) do
            clazz = Object.const_get(class_name) #部分表名如jhc_sport_calories，singular_table_name!=singular_name
            find_database(clazz) unless clazz.table_exists?
            str = clazz.connection.retrieve_table_comment(plural_table_name)
            return human_name unless str
            str.force_encoding('ASCII-8BIT')
          end
        end
        
        def human_column_name(col)
          with_cache($cached_column_names, singular_table_name+col) do
            clazz = Object.const_get(class_name)
            find_database(clazz) unless clazz.table_exists?
            hash = with_cache($cached_column_hash,plural_table_name) do
              clazz.connection.retrieve_column_comments(plural_table_name)
            end
            return col if hash.nil? || hash[col.to_sym].nil?
            hash[col.to_sym].split(" ")[0].force_encoding('ASCII-8BIT')
          end
        end
        
        def with_cache(hash,key)
          value = hash[key]
          return value if value
          value = yield
          hash[key]=value
          value
        end
        
        $cached_table_names = {}  # table_name -> 中文表名
#        $cached_table_hash = {}   # database_name -> {table_name -> 中文表名}
        $cached_column_names = {} # column_name -> 中文字段名
        $cached_column_hash = {}  # table_name -> {column_name -> 中文字段名}
        
    end
  end
end
