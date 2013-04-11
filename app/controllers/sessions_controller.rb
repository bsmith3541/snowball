class SessionsController < ApplicationController  
  def create  
    auth = request.env["omniauth.auth"]  
    user = User.find_by_provider_and_uid(auth["provider"], auth["uid"]) || User.create_with_omniauth(auth)  
    session[:user_id] = user.id  

    Tumblr.configure do |config|
		  config.consumer_key = "zGwB3KqWwxJ1ZFUDxxA6yV9jQmA3aVZR3KatMyFltgg7QaCJyz"
		  config.consumer_secret = "KyjlTSaMyEVWfzV55DfErmk6v80sSCow4g9SSgYYIkAM3U92j2"
		  puts "HELLOOOOOOOOOOOOOOOOOO"
		  config.oauth_token = auth["extra"]["access_token"].token
		  config.oauth_token_secret = auth["extra"]["access_token"].secret
		  puts config.oauth_token
		  puts config.oauth_token_secret
		end

    redirect_to root_url, :notice => "Signed in!"  
  end  
end  