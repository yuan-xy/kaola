<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :set_<%= singular_table_name %>, only: [:show, :edit, :update]

  # GET <%= route_url %>
  def index
    @<%= plural_table_name %> = <%= class_name %>.order(@order)
    if params[:s]
      like_search
      date_search
      range_search
      in_search
      cmp_search
      equal_search
    end
    @count = @<%= plural_table_name %>.count if params[:count]=="1"
    @<%= plural_table_name %> = @<%= plural_table_name %>.page(@page).per(@page_count)
    @<%= plural_table_name %>
  end

  # GET <%= route_url %>/1
  def show
  end

  # GET <%= route_url %>/new
  def new
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
    if request.format == 'application/json'
      render :json => @<%= singular_table_name %>.to_json
    else
      render :new
    end
  end

  # GET <%= route_url %>/1/edit
  def edit
  end

  # POST <%= route_url %>
  def create
    unless params[:<%= singular_table_name %>].empty?
      @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{singular_table_name}_params") %>
    else
      @<%= singular_table_name %> = <%= singular_table_name.camelize %>.new
    end
    arr = @<%= singular_table_name %>.nested_save(params)
    if arr
      if request.format == 'application/json'
        render :status => 200, :json => arr.to_json
      else
        redirect_to @<%= singular_table_name %>, notice: <%= "'#{human_name} was successfully created.'" %>
      end
    else
      if request.format == 'application/json'
        render :status => 400, :json => {:error => @<%= singular_table_name %>.errors.full_messages.join("\n")}.to_json
      else
        render :new
      end
    end
  end

  # PATCH/PUT <%= route_url %>/1
  def update
    if @<%= orm_instance.update("#{singular_table_name}_params") %>
      if request.format == 'application/json'
              render :status => 200, :json => @<%= singular_table_name %>.to_json
            else
              redirect_to @<%= singular_table_name %>, notice: <%= "'#{human_name} was successfully updated.'" %>
      end
    else
      if request.format == 'application/json'
        render :status => 400, :json => {:error => @<%= singular_table_name %>.errors.full_messages.join("\n")}.to_json
      else
        render :edit
      end
    end
  end

  def batch_update
    raise "only support json input" unless request.format == 'application/json'
    input = params[:<%= plural_table_name %>]
    if input.class == Array
      ActiveRecord::Base.transaction do
        input.each do |hash|
          id = hash[:id]
          hash.delete(:id)
          <%= class_name %>.find(id).update_attributes!(hash.permit!)
        end
      end
    elsif input.class == Hash
      hash = input
      ActiveRecord::Base.transaction do
        hash.keys.each do |id|
          <%= class_name %>.find(id).update_attributes!(hash[id].permit!)
        end
      end
    end
    # <%= class_name %>.update(hash.keys, hash.values)  #本update方法无法报告异常，所以弃用
    render :json => hash.to_json
  end
  
  # DELETE <%= route_url %>/1
  def destroy
    ids = params[:id].split(",")
    ActiveRecord::Base.transaction do
      ids.each do |id|
        to_be_del = <%= class_name %>.find(id)
        if params[:many] && params[:many].size>1
          params[:many].split(",").each do |many|
            to_be_del.send(many).try(:each){|y| y.destroy}
          end
        end
        to_be_del.destroy
      end
    end
    if request.format == 'application/json'
      render :status => 200, :json => {id:ids, deleted:true}.to_json
    else
      redirect_to <%= index_helper %>_url, notice: <%= "'#{human_name} was successfully destroyed.'" %>
    end
  end

  private

  def equal_search
    return unless params[:s]
    query = {}
    query.merge!(simple_query(params[:s]))
    @<%= plural_table_name %> = @<%= plural_table_name %>.where(query) 
    with_dot_query(params[:s]).each do |k,v|
      model_field = k.split(".")
      hash = {(model_field[0].pluralize) => { model_field[1] => v}}
      @<%= plural_table_name %> = @<%= plural_table_name %>.joins(model_field[0].to_sym).where(hash)
    end
    with_comma_query(params[:s]).each do |k,v|
      keys = k.split(",")
      t = <%= class_name %>.arel_table
      arel = t[keys[0].to_sym].eq(v)
      keys[1..-1].each{|key| arel = arel.or(t[key.to_sym].eq(v))}
      @<%= plural_table_name %> = @<%= plural_table_name %>.where(arel)
    end
  end

  def like_search
    return unless params[:s][:like]
    simple_query(params[:s][:like]).each {|k,v| @<%= plural_table_name %> = @<%= plural_table_name %>.where("#{k} like ?", like_value(v))}
    with_dot_query(params[:s][:like]).each do |k,v|
      model_field = k.split(".")
      @<%= plural_table_name %> = @<%= plural_table_name %>.joins(model_field[0].to_sym)
      @<%= plural_table_name %> = @<%= plural_table_name %>.where("#{model_field[0].pluralize}.#{model_field[1]} like ?", like_value(v))
    end
    with_comma_query(params[:s][:like]).each do |k,v|
      keys = k.split(",")
      vv = like_value(v)
      t = <%= class_name %>.arel_table
      arel = t[keys[0].to_sym].matches(vv)
      keys[1..-1].each{|key| arel = arel.or(t[key.to_sym].matches(vv))}
      @<%= plural_table_name %> = @<%= plural_table_name %>.where(arel)
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
      arr = v.split(",")
      if arr.size==1
        day = DateTime.parse(arr[0])
        @<%= plural_table_name %> = @<%= plural_table_name %>.where(k => day.beginning_of_day..day.end_of_day)
      elsif arr.size==2
        day1 = DateTime.parse(arr[0])
        day2 = DateTime.parse(arr[1])
        @<%= plural_table_name %> = @<%= plural_table_name %>.where(k => day1.beginning_of_day..day2.end_of_day)
      else
        logger.warn("date search 错误: #{k},#{v}")
      end
    end
    with_dot_query(params[:s][:date]).each do |k,v|
      model_field = k.split(".")
      @<%= plural_table_name %> = @<%= plural_table_name %>.joins(model_field[0].to_sym)
      arr = v.split(",")
      if arr.size==1
        day = DateTime.parse(arr[0])
        hash = {(model_field[0].pluralize) => { model_field[1] => day.beginning_of_day..day.end_of_day}}
        @<%= plural_table_name %> = @<%= plural_table_name %>.where(hash)
      elsif arr.size==2
        day1 = DateTime.parse(arr[0])
        day2 = DateTime.parse(arr[1])
        hash = {(model_field[0].pluralize) => { model_field[1] => day1.beginning_of_day..day2.end_of_day}}
        @<%= plural_table_name %> = @<%= plural_table_name %>.where(hash)
       else
        logger.warn("date search 错误: #{k},#{v}")
      end
    end
    params[:s].delete(:date)
  end

  def range_search
    return unless params[:s][:range]
    simple_query(params[:s][:range]).each do |k,v|
      arr = v.split(",")
      if arr.size==1
        v1 = arr[0].to_f
        operator = (v[0]==","?  "<=" : ">=")
        @<%= plural_table_name %> = @<%= plural_table_name %>.where("#{k} #{operator} ?", v1)
      elsif arr.size==2
        v1 = arr[0].to_f
        v2 = arr[1].to_f
        @<%= plural_table_name %> = @<%= plural_table_name %>.where(k => v1..v2)
      else
        logger.warn("range search 错误: #{k},#{v}")
      end
    end
    with_dot_query(params[:s][:range]).each do |k,v|
      model_field = k.split(".")
      @<%= plural_table_name %> = @<%= plural_table_name %>.joins(model_field[0].to_sym)
      arr = v.split(",")
      if arr.size==1
        v1 = arr[0].to_f
        operator = (v[0]==","?  "<=" : ">=")
        @<%= plural_table_name %> = @<%= plural_table_name %>.where("#{model_field[0].pluralize}.#{model_field[1]} #{operator} ?", v1)
      elsif arr.size==2
        v1 = arr[0].to_f
        v2 = arr[1].to_f
        hash = {(model_field[0].pluralize) => { model_field[1] => v1..v2}}
        @<%= plural_table_name %> = @<%= plural_table_name %>.where(hash)
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
      @<%= plural_table_name %> = @<%= plural_table_name %>.where("#{k} in (?)", arr)
    end
    with_dot_query(params[:s][:in]).each do |k,v|
      model_field = k.split(".")
      @<%= plural_table_name %> = @<%= plural_table_name %>.joins(model_field[0].to_sym)
      arr = v.split(",")
      @<%= plural_table_name %> = @<%= plural_table_name %>.where("#{model_field[0].pluralize}.#{model_field[1]} in (?)", arr)
    end
    params[:s].delete(:in)      
  end 

  def cmp_search
    return unless params[:s][:cmp]
    simple_query(params[:s][:cmp]).each do |key,v|
      ["!=","<=",">=","=","<",">"].each do |op|
        if key.match(op)
          arr = key.split(op)
          next if arr.size != 2
          @<%= plural_table_name %> = @<%= plural_table_name %>.where("#{arr[0]} #{op} #{arr[1]}")
          break
        end
      end
    end
    params[:s].delete(:cmp)      
  end 
  
  def with_dot_query(hash)
    hash.select{|k,v| k.index(".")}
  end
  
  def with_comma_query(hash)
    hash.select{|k,v| k.index(",")}
  end

  def simple_query(hash)
    hash.select{|k,v| !k.index(".") && !k.index(",")}
  end
    
    # Use callbacks to share common setup or constraints between actions.
    def set_<%= singular_table_name %>
      cache = <%= class_name %>.new.memcache_load(<%= class_name %>, params[:id])
      @<%= singular_table_name %> = cache
    end

    # Only allow a trusted parameter "white list" through.
    def <%= "#{singular_table_name}_params" %>
      <%- if attributes_names.empty? -%>
      params[:<%= singular_table_name %>]
      <%- else -%>
      params.require(:<%= singular_table_name %>).permit!
      <%- end -%>
    end
end
<% end -%>
