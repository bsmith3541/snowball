class SessionsController < ApplicationController  
	require 'open-uri'
	def create  
		auth = request.env["omniauth.auth"]  
		user = User.find_by_provider_and_uid(auth["provider"], auth["uid"]) || User.create_with_omniauth(auth)  
		session[:user_id] = user.id  

		Tumblr.configure do |config|
			config.consumer_key = "zGwB3KqWwxJ1ZFUDxxA6yV9jQmA3aVZR3KatMyFltgg7QaCJyz"
			config.consumer_secret = "KyjlTSaMyEVWfzV55DfErmk6v80sSCow4g9SSgYYIkAM3U92j2"
			puts config.oauth_token = auth["extra"]["access_token"].token
			puts config.oauth_token_secret = auth["extra"]["access_token"].secret
		end

		client = Tumblr::Client.new

		logger.info client.info
		# displaying user data
		# puts client.info		
		# puts client.following

		# Mechanize code

		agent = Mechanize.new
		agent.user_agent_alias = "Mac Safari"
		agent.follow_meta_refresh = true

		# Find total number of blogs the user is following. If its more 
		# than 20, it find 20 blogs at a time and appends the list to 
		# the blogs variable
		numFollowing = client.info["following"]
		blogs = []
		((numFollowing/20.0).ceil).times do |i|
			blogs << client.following({"offset" => i*20})["blogs"]
		end
		user.following = blogs
		user.save

		# TODO: Figure out how to get the first 100 posts
		# right now, we're only grabbing 20 posts. DONE
		# Figure out how to save the data for each blog so that
		# some library can read it later for the visualization
		# TODO: From here (to line 76) should go into a separate thread.
		f = File.open("blogs.net", 'w+') 
		all_posts = Array.new
		

		# look at the efficiency in terms of the potential viewers based on the 
		# number of blogs your followers are following
		# this would also be a measurement of how influential you are
		# how many of the people that could possibly be affected by a post are actually
		# being influenced by a post (at least in terms of likes/reblogs)? 
		for blog in user.following
			puts "analyzing: " + blog["name"]
			f.write(blog["name"] + "\n")
			5.times do |i|
				posts = client.posts(blog["name"], { :limit => 20, :offset => i*20,
									 "reblog_info" => "true", "notes_info" => "true"})
				posts = posts["posts"]
				for post in posts
					for note in post["notes"]
						if note["type"] == "reblog"
							# increse size by 1
							# link blog to note["blog_url"]
						elsif note["type"] == "like"
							#increase size by 0.5
							
						# doc = Nokogiri::HTML(open(post["short_url"]))
						#puts doc.css('div#post_notes').to_yaml
						#puts doc.to_html
						#puts post["notes_info"]
						#all_posts.push("\t"+ post["short_url"] + "\n")
						# f.write("\t"+ post["short_url"] + "\n")
					end
				end
			#f.write(all_posts)
			#all_posts = Array.new
		end
		f.close


		redirect_to root_url, :notice => "Signed in!"  
	end  
end  