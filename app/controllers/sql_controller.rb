class SqlController < ApplicationController
  
  before_action :check_rawsql_json
  
  def search
    info = TsSqlInfo.find(params[:id])
    arr = [info.sql_value]
    if info.param_types
      info.param_types.split(",").each_with_index do |type, i|
        i +=1
        str = params[i.to_s]
        arr << type_cast(str, type)
      end
    end
    r = ActiveRecord::Base.send(:sanitize_sql_array, arr)
    ret = ActiveRecord::Base.connection.select_all(r).to_a
    ret = ret[0,1000] if ret.size>1000
    render :json => ret.to_json
  end

  def exec
    #ActiveRecord::Base.connection.execute("call SP_name (#{param1}, #{param2}, ... )")
  end
  
  def heartbeat
    render :json => {status:"alive"}.to_json
  end
  
  private 
  def type_cast(str, type)
    case type
    when "s"
      str.to_s
    when 'i'
      str.to_i
    when 'f'
      str.to_f
    when 'd'
      DateTime.parse(str)
    else
      str
    end
  end
  
end
