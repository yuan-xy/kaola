class SqlController < ApplicationController
  
  before_action :check_rawsql_json
  
  def search
    arr = ActiveRecord::Base.connection.select_all($raw_sqls[params[:id].to_i])
    render :json => arr.to_json
  end

  def exec
    #ActiveRecord::Base.connection.execute("call SP_name (#{param1}, #{param2}, ... )")
  end
  
  def heartbeat
    render :json => {status:"alive"}.to_json
  end
  
end
