class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  #skip_before_action :verify_authenticity_token, if: :json_request?
  skip_before_filter :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  #before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
    headers['Access-Control-Max-Age'] = "1728000"
    headers['Access-Control-Allow-Credentials'] = true
    headers['X-Frame-Options'] = "ALLOWALL"
  end

  def cors_preflight_check
    if request.method == 'OPTIONS'
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token'
      headers['Access-Control-Max-Age'] = '1728000'

      render :text => '', :content_type => 'text/plain'
    end
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

  around_filter :exception_catch if true || ENV["RAILS_ENV"] == "production"
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
      render_error("#{request.path}出错了: #{err_str}")
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
    @page_count = params[:per] || 100
    @page = params[:page].to_i
    @order = params[:order]
    if @page<0
      @page = -@page
      @order = @order.split(",").map do |x|
        if x.match(" desc")
          x.sub!("desc","asc")
        elsif x.match(" asc")
          x.sub!("asc","desc")
        end
        x
      end.join(",")
    end
  end
  

  
end
