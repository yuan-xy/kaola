class SqlController < ApplicationController
  
  before_action :check_rawsql_json
  
  def search
    info = TsSqlInfo.find(params[:id])
    sql = info.sql_value
    num = info.param_num
    arr = [sql]
    if num>0
      (1..num).each{|x| arr << params[x.to_s]}
    end
    r = ActiveRecord::Base.send(:sanitize_sql_array, arr)
    ret = ActiveRecord::Base.connection.select_all r    
    render :json => ret.to_json
  end

  def exec
    #ActiveRecord::Base.connection.execute("call SP_name (#{param1}, #{param2}, ... )")
  end
  
  def heartbeat
    render :json => {status:"alive"}.to_json
  end
  
end
