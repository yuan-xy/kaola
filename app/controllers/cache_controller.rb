class CacheController < ApplicationController
  def expire
    table = params[:tables]
    raise "table doesn't exsits." unless table
    table.split(',').each do |t|
      if $tables.find{|x| x==t}
        clear_cache(t)
      else
        raise "table #{table} doesn't exsits."
      end
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
