class SessionsController < ApplicationController  
  def create  
    auth = request.env["omniauth.auth"]  
    user = User.find_by_provider_and_uid(auth["provider"], auth["uid"]) || User.create_with_omniauth(auth)  
    session[:user_id] = user.id  

    Tumblr.configure do |config|
		  config.consumer_key = "zGwB3KqWwxJ1ZFUDxxA6yV9jQmA3aVZR3KatMyFltgg7QaCJyz"
		  config.consumer_secret = "KyjlTSaMyEVWfzV55DfErmk6v80sSCow4g9SSgYYIkAM3U92j2"
		  config.oauth_token = auth["extra"]["access_token"].token
		  config.oauth_token_secret = auth["extra"]["access_token"].secret
		end

		client = Tumblr::Client.new
		# displaying user data
		# puts client.info		
		# puts client.following

		# Mechanize code

		agent = Mechanize.new
		agent.user_agent_alias = "Mac Safari"
		agent.follow_meta_refresh = true

		blogs = client.following["blogs"]
		user.following = client.following["blogs"]
		user.save
		puts user.following.to_yaml

		# TODO: Figure out how to get the first 100 posts
		# Figure out how to save the data for each blog so that
		# some library can read it later for the visualization

		for blog in user.following
			puts client.posts(blog["name"]).to_yaml
		end

    redirect_to root_url, :notice => "Signed in!"  
  end  
end  