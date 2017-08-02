require 'name_helper'
include NameHelper

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  #skip_before_action :verify_authenticity_token, if: :json_request?
  skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  after_action :cors_set_access_control_headers
  
  before_action :crud_json_check
  
  def crud_json_check
     if Rails.env == "production"
       redirect_to "/500.html" unless (request.format == 'application/json' || request.format == 'application/xlsx')
     end
  end

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
    headers['Access-Control-Max-Age'] = "1728000"
    headers['Access-Control-Allow-Credentials'] = true
    headers['X-Frame-Options'] = "ALLOWALL"
  end


  def set_process_name_from_request
    $0 = request.path[0,16]
  end

  def unset_process_name_from_request
    $0 = request.path[0,15] + "*"
  end

  def error_log(msg)
    File.open("log/scm-error.log","a") {|f| f.puts msg.to_s}
  end

  around_action :exception_catch
  def exception_catch
    begin
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Credentials'] = true
      headers['Access-Control-Allow-Methods'] = 'POST, PUT, OPTIONS, GET'
      headers['X-Frame-Options'] = "ALLOWALL"
      yield
    rescue  Exception => err
      error_log "\nInternal Server Error: #{err.class.name}, #{Time.now}"
      error_log "#{request.path}  #{request.params}"
      err_str = err.to_s
      error_log err_str
      err.backtrace.each {|x| error_log x}
      if Rails.env == "production"
        if err.class == ActiveRecord::RecordInvalid
          render_error("#{request.path}出错了: #{err_str}")
        else
          render_error("#{request.path}出错了: #{err.class}")
        end
      else
        render_error("#{request.path}出错了: #{err_str}")
      end
    end
  end

  def render_error(error, error_msg=nil, hash2=nil)
    hash = {:error => error}
    hash.merge!({:error_msg => error_msg}) if error_msg
    hash.merge!(hash2) if hash2
    render :status => 400, :json => hash.to_json
  end
  
  before_action :set_search_params, only: [:index]
  
  def set_search_params
    default_page_count = 100
    default_page_count = 10 if params[:many]
    @page_count = params[:per] || default_page_count
    @page = params[:page].to_i
    @order = params[:order]
    if @page<0
      @page = -@page
      @order = "created_at asc" if @order.nil?
      @order = @order.split(",").map do |x|
        if x.match(" desc")
          x.sub!(" desc"," asc")
        elsif x.match(" asc")
          x.sub!(" asc"," desc")
        end
        x
      end.join(",")
    end
  end
  
  def check_rawsql_json
    raise "raw_sql needs json output" unless request.format == 'application/json'
  end
  
  def check_useless_params
    hash = to_hash(params)
    %w{controller action format count per page order many many_size index}.each{|x| hash.delete(x)}
    if hash["s"]
      %w{like date range in cmp exists full}.each{|x| hash["s"].delete(x)}
      hash["s"].each{|k,v| raise "查询参数s[#{k}]不支持" if v.class==Hash}
      hash.delete("s")
    end
    raise "不支持的未知查询条件#{hash}" unless hash.empty?
  end
  
  def jbuild2(*args, &block)
    Jbuilder.new(*args, &block).attributes!
  end
  
  def do_search
    check_useless_params if Rails.env != 'production'
    @list = @model_clazz.order(@order)
    @list = @list.use_index(params[:index]) if params[:index]
    if params[:s]
      check_search_param_exsit(to_hash(params[:s]), @model_clazz)
      like_search
      date_search
      range_search
      in_search
      cmp_search
      exists_search
      full_search
      equal_search
    end
    if params[:count]
      @count = @list.count
      if params[:count]=="2"
        render :json => {count: @count}.to_json
      end
    end
    @list = @list.page(@page).per(@page_count)
	  if params[:many] && params[:many].size>1
      @many = {}
	    params[:many].split(",").each do |x|
        raise "many查询#{x}必须是复数" if x.pluralize != x
        many_size = params[:many_size] || 100
        @many[x] = @model_clazz.many_caches(x, @list, many_size.to_i)
      end
    end
    @belong_names = @model_clazz.belong_names
    @belongs = @model_clazz.belongs_to_multi_get(@list)
    plural_table_name = @model_clazz.name.pluralize.underscore
    instance_variable_set("@#{plural_table_name}", @list)
    respond_to do |format|
      format.html
      format.json do
        result = jbuild2 do |json|
          def func(json)
          	json.array!(@list.each_with_index.to_a) do |(singular_table_name, i)|
          	  json.merge! singular_table_name.try(:filter_attributes)
          	  @belong_names.each do |name|
          	    json.set! name, @belongs[i][name].try(:filter_attributes)
          	  end
          	  @many.try(:each) do |x,value|
              	json.set! x do 
              		json.array!(value[i]) do |arr|
              		  json.merge! arr
              		end
              	end
          	  end
          	end
          end
          if params[:count]=="1"
          	json.count @count
          	json.data do
          	  func(json)
          	end
          else
          	func(json)
          end
        end
        render :json => result
      end
      format.xlsx do 
        workbook = @model_clazz.gen_workbook(@list)
        send_excel(workbook, "#{plural_table_name}.xlsx")
      end
    end
  end
  

  def equal_search
    return unless params[:s]
    query = to_hash simple_query(params[:s])
    @list = @list.where(query) 
    with_comma_query(params[:s]).each do |k,v|
      keys = k.split(",")
      t = @model_clazz.arel_table
      arel = nil
      keys.each_with_index  do |key, index|
        if  key.index(".")
          model, field = key.split(".")
          @list = @list.joins(model.to_sym)
          t2= get_table_class(table_name_fix(model)).arel_table
          if index==0
            arel = t2[field.to_sym].eq(v)
          else
            arel = arel.or(t2[field.to_sym].eq(v))
          end
        else
          if index==0
            arel = t[key.to_sym].eq(v)
          else
            arel = arel.or(t[key.to_sym].eq(v))
          end
        end
      end
      @list = @list.where(arel)
    end
    del_comma_query(params[:s])
    with_dot_query(params[:s]).each do |k,v|
      model, field = k.split(".")
      hash = {(table_name_fix(model)) => { field => v}}
      @list = @list.joins(model.to_sym).where(hash)
    end
  end

  def like_search
    return unless params[:s][:like]
    simple_query(params[:s][:like]).each {|k,v| @list = @list.where("#{k} like ?", like_value(v))}
    with_comma_query(params[:s][:like]).each do |k,v|
      keys = k.split(",")
      vv = like_value(v)
      t = @model_clazz.arel_table
      arel = nil
      keys.each_with_index  do |key, index|
        if  key.index(".")
          model, field = key.split(".")
          @list = @list.joins(model.to_sym)
          t2= get_table_class(table_name_fix(model)).arel_table
          if index==0
            arel = t2[field.to_sym].matches(vv)
          else
            arel = arel.or(t2[field.to_sym].matches(vv))
          end
        else
          if index==0
            arel = t[key.to_sym].matches(vv)
          else
            arel = arel.or(t[key.to_sym].matches(vv))
          end
        end
      end
      @list = @list.where(arel)
    end
    del_comma_query(params[:s][:like])
    with_dot_query(params[:s][:like]).each do |k,v|
      model, field = k.split(".")
      @list = @list.joins(model.to_sym)
      @list = @list.where("#{table_name_fix(model)}.#{field} like ?", like_value(v))
    end
    params[:s].delete(:like)
  end
  
  def like_value(v)
    return v if v.index("%") || v.index("_")
    "%#{v}%"
  end

  def date_search
    return unless params[:s][:date]
    simple_query(params[:s][:date]).each do |k,v|
      arr = v.split(",").delete_if{|x| x==''}
      if arr.size==1
        if v[0]==',' ||  v[-1]==','
          v1 = DateTime.parse(arr[0])
          operator = (v[0]==","?  "<=" : ">=")
          v1 = v1.end_of_day if v[0]==','
          @list = @list.where("#{k} #{operator} ?", v1)
        else
          day = DateTime.parse(arr[0])
          @list = @list.where(k => day.beginning_of_day..day.end_of_day)
        end
      elsif arr.size==2
        day1 = DateTime.parse(arr[0])
        day2 = DateTime.parse(arr[1])
        @list = @list.where(k => day1.beginning_of_day..day2.end_of_day)
      else
        logger.warn("date search 错误: #{k},#{v}")
      end
    end
    with_dot_query(params[:s][:date]).each do |k,v|
      model, field = k.split(".")
      @list = @list.joins(model.to_sym)
      arr = v.split(",").delete_if{|x| x==''}
      if arr.size==1
        if v[0]==',' ||  v[-1]==','
          logger.warn("date search 错误: #{k},#{v}. 外键字段暂不支持带,的单边日期查询")
        else
          day = DateTime.parse(arr[0])
          hash = {(table_name_fix(model)) => { field => day.beginning_of_day..day.end_of_day}}
          @list = @list.where(hash)
        end
      elsif arr.size==2
        day1 = DateTime.parse(arr[0])
        day2 = DateTime.parse(arr[1])
        hash = {(table_name_fix(model)) => { field => day1.beginning_of_day..day2.end_of_day}}
        @list = @list.where(hash)
       else
        logger.warn("date search 错误: #{k},#{v}")
      end
    end
    params[:s].delete(:date)
  end

  def range_search
    return unless params[:s][:range]
    simple_query(params[:s][:range]).each do |k,v|
      arr = v.split(",").delete_if{|x| x==''}
      if arr.size==1
        v1 = arr[0].to_f
        operator = (v[0]==","?  "<=" : ">=")
        @list = @list.where("#{k} #{operator} ?", v1)
      elsif arr.size==2
        v1 = arr[0].to_f
        v2 = arr[1].to_f
        @list = @list.where(k => v1..v2)
      else
        logger.warn("range search 错误: #{k},#{v}")
      end
    end
    with_dot_query(params[:s][:range]).each do |k,v|
      model, field = k.split(".")
      @list = @list.joins(model.to_sym)
      arr = v.split(",")
      if arr.size==1
        v1 = arr[0].to_f
        operator = (v[0]==","?  "<=" : ">=")
        @list = @list.where("#{table_name_fix(model)}.#{field} #{operator} ?", v1)
      elsif arr.size==2
        v1 = arr[0].to_f
        v2 = arr[1].to_f
        hash = {(table_name_fix(model)) => { field => v1..v2}}
        @list = @list.where(hash)
      else
        logger.warn("range search 错误: #{k},#{v}")
      end
    end
    params[:s].delete(:range)      
  end   

  def in_search
    return unless params[:s][:in]
    simple_query(params[:s][:in]).each do |k,v|
      arr = v.split(",")
      @list = @list.where("#{k} in (?)", arr)
    end
    with_dot_query(params[:s][:in]).each do |k,v|
      model, field = k.split(".")
      @list = @list.joins(model.to_sym)
      arr = v.split(",")
      @list = @list.where("#{table_name_fix(model)}.#{field} in (?)", arr)
    end
    params[:s].delete(:in)      
  end 

  def cmp_search
    return unless params[:s][:cmp]
    simple_query(params[:s][:cmp]).each do |key,v|
      found =false
      ["!=","<=",">=","=","<",">"].each do |op|
        if key.match(op)
          arr = key.split(op)
          next if arr.size != 2  #throw exception?
          found = true
          if arr[1]=="null"
            opv = case
            when op=='!='
              "is not"
            when op=='='
              "is"
            else
              raise "cmp查询对null值只允许等于和不等于操作：#{op}"
            end
            opv = op=="!="? "is not" : "is"
            @list = @list.where("#{arr[0]} #{opv} null")
          else
            @list = @list.where("#{arr[0]} #{op} #{arr[1]}")
          end
          break
        end
      end
      raise "不支持的cmp查询：是否没有正确转义，比如“=”需要转义为“%3D”" unless found
    end
    with_dot_query(params[:s][:cmp]).each do |k,v|
      model, field = k.split(".")
      @list = @list.joins(model.to_sym)
      found = false
      ["!=","<=",">=","=","<",">"].each do |op|
        if field.match(op)
          arr = field.split(op)
          next if arr.size != 2
          found = true
          if arr[1]=="null"
            opv = case
            when op=='!='
              "is not"
            when op=='='
              "is"
            else
              raise "cmp查询对null值只允许等于和不等于操作：#{op}"
            end
            opv = op=="!="? "is not" : "is"
            @list = @list.where("#{table_name_fix(model)}.#{arr[0]} #{opv} null")
          else
            @list = @list.where("#{table_name_fix(model)}.#{arr[0]} #{op} #{arr[1]}")
          end
          break
        end
      end
      raise "不支持的cmp查询：是否没有正确转义，比如“=”需要转义为“%3D”" unless found
    end
    params[:s].delete(:cmp)      
  end 
  
  def exists_search
    return unless params[:s][:exists]
    params[:s][:exists].each do |key,v|
      arel = @model_clazz.arel_table
      many_clazz = get_table_class(key)
      fid = many_clazz.get_belongs_fk(@model_clazz.table_name)
      sql = many_clazz.select(fid.to_sym).to_sql
      pkey = @model_clazz.primary_key.to_sym
      if v=="0"
        @list = @list.where(arel[pkey].not_in(Arel.sql(sql)))
      elsif v=="1"
        @list = @list.where(arel[pkey].in(Arel.sql(sql)))
      else
        raise "exists search only support 0/1 value"
      end
    end
    params[:s].delete(:exists)      
  end
  
  def full_search
    return unless params[:s][:full]
    params[:s][:full].each do |key,v|
      @list = @list.where("MATCH(#{key}) AGAINST('#{v}')")
    end
    params[:s].delete(:full)      
  end
    
  def with_dot_query(hash)
    hash.select{|k,v| k.index(".")}
  end
  
  def with_comma_query(hash)
    hash.select{|k,v| k.index(",")}
  end
  
  
  def del_comma_query(hash)
    hash.delete_if{|k,v| k.index(",")}
  end

  def simple_query(hash)
    hash.select{|k,v| !k.index(".") && !k.index(",")}
  end
  
  
  def check_search_param_exsit(hash,clazz)
    attrs = clazz.attribute_names
    %w{like date range in cmp exists full}.each do |op|
      next unless hash[op]
      hash[op].each do |k,v|
        if op == 'exists'
          check_many_relation(k)
        else
          check_keys_exist(k, attrs, clazz, op)
        end
      end
      hash.delete(op)
    end
    hash.each{|k,v| check_keys_exist(k, attrs, clazz)}
  end
  
  def check_keys_exist(keys, attrs, clazz, op=nil)
    if keys.index(",")
      keys.split(",").each do |x|
        if x.index(".")
          check_rel_keys_exist(x, attrs, clazz, op)
        else
          check_field_exist(x, attrs)
        end
      end
    elsif keys.index(".")
      check_rel_keys_exist(keys, attrs, clazz, op)
    else
      check_field_exist(keys, attrs, op)
    end
  end
  
  def check_rel_keys_exist(keys, attrs, clazz, op=nil)
    model, field = keys.split(".")
    field = split_field_for_cmp(field, op)
    if model.singularize == model
      # 关联主表 belongs关系
      check_field_exist(@model_clazz.get_belongs_fk(model), attrs)
      clazz_name = clazz.get_belongs_class_name(model)
      check_field_exist(field, Object.const_get(clazz_name).attribute_names)
    else
      check_many_relation(model)
      clazz_name = model.camelize.singularize
      check_field_exist(field, Object.const_get(clazz_name).attribute_names)
    end
    #TODO: 跨库的join查询，数据库不支持    
  end
  
  def split_field_for_cmp(field, op)
    if op == 'cmp'
      ["!=","<=",">=","=","<",">"].each{|x| field = field.split(x)[0]}
    end
    field
  end
  
  def check_field_exist(field, attrs, op=nil)
    field = split_field_for_cmp(field, op)
    find = attrs.find{|x| x==field}
    raise "field:#{field} doesn't exists." unless find
  end
  
  def check_many_relation(key)
    manys = $many[@model_clazz.table_name.singularize]
    unless manys.find{|x| x==key.singularize}
      raise "#{@model_clazz.table_name} and #{key} hasn't one-to-many relation."
    end
  end
  
  
  def batch_update
    raise "only support json input" unless request.format == 'application/json'
    input = params[self.controller_name.to_sym]
    clazz_name = self.controller_name.singularize.camelize
    clazz = Object.const_get clazz_name
    ret = []
    if input.class == Array
      ActiveRecord::Base.transaction do
        input.each do |hash|
          id = hash[:id]
          hash.delete(:id)
          ret << clazz.find(id).update_attributes!(hash.permit!)
        end
      end
    else
      raise 'batch_update no longer support hash input, use array instead.'
    end
    # clazz.update(hash.keys, hash.values)  #本update方法无法报告异常，所以弃用
    render :json => {count: ret.size, updated:true}.to_json
  end
  
  def do_show
    @many = {}
    if params[:many] && params[:many].size>1
      many_size = params[:many_size] || 100
      many_depth = params[:depth] || 1
      params[:many].split(",").each do |x|
        raise "many查询#{x}必须是复数" if x.pluralize != x
        @many[x] = @cache_obj.many_cache(x, many_size.to_i, many_depth.to_i)
      end
    end
    if params[:many]=="1" && Rails.env != "production"
      $many[singular_table_name(@model_clazz)].try(:each) do |x|
        x = x.pluralize
        @many[x] = @cache_obj.many_cache(x)
      end
    end
    respond_to do |format|
      format.html
      format.json do
        result = jbuild2 do |json|
          json.merge! @cache_obj.attributes
          @cache_obj.belongs_to_multi_get.each do |k,v|
            json.set! k, v.try(:filter_attributes)
          end
          @many.try(:each) do |x,value|
            	json.set! x do 
            		json.array!(value) do |arr|
            		  json.merge! arr
            		end
            	end
          end
        end
        render :json => result
      end
    end
  end
  
  def send_excel(workbook, filename, suffix='xlsx')
    send_data workbook.stream.string,
              filename: filename, disposition: 'attachment', type: "application/#{suffix}"
  end
  
  def to_hash(params)
    return params unless params.class==ActionController::Parameters
    hash = {}
    params.each_pair{|x,y| hash[x] = to_hash(y) }
    hash
  end
  
  
end
