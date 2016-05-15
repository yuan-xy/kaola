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
      if params[:s][:like]
        params[:s][:like].each {|k,v| @<%= plural_table_name %> = @<%= plural_table_name %>.where("#{k} like ?",v)}
      end
      params[:s].delete(:like)
      if params[:s][:date]
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
      end
      params[:s].delete(:date) 
      if params[:s]
        query = {}
        query.merge! params[:s]
        @<%= plural_table_name %> = @<%= plural_table_name %>.where(query) 
      end
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
      redirect_to @<%= singular_table_name %>, notice: <%= "'#{human_name} was successfully created.'" %>
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
      redirect_to @<%= singular_table_name %>, notice: <%= "'#{human_name} was successfully updated.'" %>
    else
      render :edit
    end
  end

  # DELETE <%= route_url %>/1
  def destroy
    @<%= orm_instance.destroy %>
    redirect_to <%= index_helper %>_url, notice: <%= "'#{human_name} was successfully destroyed.'" %>
  end

  private
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
