<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :set_<%= singular_table_name %>, only: [:show, :edit, :update, :destroy]

  # GET <%= route_url %>
  def index
    @<%= plural_table_name %> = <%= class_name %>.page(params[:page]).per(params[:per]).order(params[:order])
    if params[:s]
      like_search
      date_search
      range_search
      in_search
      equal_search
    end
    @<%= plural_table_name %>
  end

  # GET <%= route_url %>/1
  def show
  end

  # GET <%= route_url %>/new
  def new
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
  end

  # GET <%= route_url %>/1/edit
  def edit
  end

  # POST <%= route_url %>
  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{singular_table_name}_params") %>

    if @<%= orm_instance.save %>
      if request.format == 'application/json'
        render :status => 200, :json => @<%= singular_table_name %>.to_json
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

  # DELETE <%= route_url %>/1
  def destroy
    @<%= orm_instance.destroy %>   #TODO: 删除报错如何处理？
    if request.format == 'application/json'
      render :status => 200, :json => {}.to_json
    else
      redirect_to <%= index_helper %>_url, notice: <%= "'#{human_name} was successfully destroyed.'" %>
    end
  end

  private

  def equal_search
    return unless params[:s]
    query = {}
    query.merge! params[:s]
    @<%= plural_table_name %> = @<%= plural_table_name %>.where(query) 
  end

  def like_search
    return unless params[:s][:like]
    params[:s][:like].each {|k,v| @<%= plural_table_name %> = @<%= plural_table_name %>.where("#{k} like ?",v)}
    params[:s].delete(:like)
  end

  def date_search
    return unless params[:s][:date]
    params[:s][:date].each do |k,v|
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
    params[:s].delete(:date)
  end

  def range_search
    return unless params[:s][:range]
    params[:s][:range].each do |k,v|
      arr = v.split(",")
      if arr.size==1
        v1 = arr[0].to_f
        operator = (v[0]==","?  "<=" : ">=")
        @<%= plural_table_name %> = @<%= plural_table_name %>.where("id #{operator} ?", v1)
      elsif arr.size==2
        v1 = arr[0].to_f
        v2 = arr[1].to_f
        @<%= plural_table_name %> = @<%= plural_table_name %>.where(k => v1..v2)
      else
        logger.warn("range search 错误: #{k},#{v}")
      end
    end
    params[:s].delete(:range)      
  end   

  def in_search
    return unless params[:s][:in]
    params[:s][:in].each do |k,v|
      arr = v.split(",")
      @<%= plural_table_name %> = @<%= plural_table_name %>.where("#{k} in (?)", arr)
    end
    params[:s].delete(:in)      
  end 
  
    # Use callbacks to share common setup or constraints between actions.
    def set_<%= singular_table_name %>
      @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
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
