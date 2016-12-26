<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :set_<%= singular_table_name %>, only: [:show, :edit, :update]

  # GET <%= route_url %>
  def index
    @model_clazz = <%= class_name %>
    @<%= plural_table_name %> = do_search
    @<%= plural_table_name %>
  end

  # GET <%= route_url %>/1
  def show
    @many = {}
    if params[:many] && params[:many].size>1
      params[:many].split(",").each do |x|
        @many[x] = @<%= singular_table_name %>.many_cache(x)
      end
    end
    if params[:many]=="1" && Rails.env != "production"
      $many['<%= singular_table_name %>'].try(:each) do |x|
        x = x.pluralize
        @many[x] = @<%= singular_table_name %>.many_cache(x)
      end
    end
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
    
    # Use callbacks to share common setup or constraints between actions.
    def set_<%= singular_table_name %>
      cache = <%= class_name %>.memcache_load(params[:id])
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
