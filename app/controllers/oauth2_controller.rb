require 'oauth2'

class Oauth2Controller < ApplicationController
  
  $OAUTH = YAML.load_file(Rails.root.join('config/oauth.yml'))[Rails.env]
  
  def sso_client
    client = OAuth2::Client.new($OAUTH["key"], $OAUTH["secret"], :site => $OAUTH["authorize_url"] )    
    client.options[:authorize_url] = $OAUTH["authorize_url"] 
    client.options[:token_url] = $OAUTH["token_url"] 
    client
  end

  def login
    @@client ||= sso_client
    redirect_to @@client.auth_code.authorize_url(:redirect_uri => "http://#{request.host}:#{request.port}/oauth2/callback")
  end

  #使用oauth2认证时的回调页
  def callback
    if params[:code].nil?
      render :json => params.to_json
      return
    end
    @@client ||= sso_client
    auth = Base64.encode64("#{$OAUTH['key']}:#{$OAUTH['secret']}")
    token = @@client.auth_code.get_token(params[:code], :redirect_uri => "http://#{request.host}:#{request.port}/oauth2/callback", :headers => {'Authorization' => "Basic #{auth}"} )
    filepath = Rails.root.join("config/jwt.public.key")
    File.open(filepath) do |file|
      key = OpenSSL::PKey.read(file)
      decoded_token = JWT.decode(token.token, key, true, { :algorithm => 'RS256' })
      session[:user_id] = decoded_token[0]["user_name"]
      return render :json => decoded_token.to_json
    end
    render :json => token.merge!({error:"error"}).to_json
  end
  
  def test_login
    return if ENV["RAILS_ENV"] != "test"
    session[:user_id] = User.find_by_id(params[:id]).id
    render :json => {}
  end
  
end
