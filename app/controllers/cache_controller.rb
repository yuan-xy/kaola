class CacheController < ApplicationController
  def expire
    table = params[:table]
    if $tables.find{|x| x==table}
      clear_cache(table)
    else
      raise "table #{table} doesn't exsits."
    end
    render :json => {status:"ok"}.to_json
  end

  def expire_all
    $tables.each do |table|
      clear_cache(table)
    end
    render :json => {status:"ok"}.to_json
  end
  
  private
  
  def clear_cache(table)
    clazz_name = table.singularize.camelize
    clazz = Object.const_get(clazz_name)
    clazz.inc_prefix
  end
  
end
