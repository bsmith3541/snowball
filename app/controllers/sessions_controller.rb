class SessionsController < ApplicationController  
	require 'open-uri'
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
		user.following = blogs
		user.save

		# TODO: Figure out how to get the first 100 posts
			# right now, we're only grabbing 20 posts
		# Figure out how to save the data for each blog so that
		# some library can read it later for the visualization
		f = File.open("blogs.net", 'w+') 
		all_posts = Array.new
		

		# look at the efficiency in terms of the potential viewers based on the 
		# number of blogs your followers are following
		# this would also be a measurement of how influential you are
		# how many of the people that could possibly be affected by a post are actually
		# being influenced by a post (at least in terms of likes/reblogs)? 
		for blog in user.following
			likes = 0
			reblogs = 0
			puts "analyzing: " + blog["name"]
			f.write(blog["name"] + "\n")
			5.times do |i|
				posts = client.posts(blog["name"], :limit => 20, :offset => i*20)
				posts = posts["posts"]
				for post in posts
					doc = Nokogiri::HTML(open(post["short_url"]))
					doc.css('ol.notes').each do |node|
						node.css('li.like').each do |note|
							likes+=1
						end
						node.css('li.reblog').each do |note|
							reblogger = note.get_attribute("class")
							matches = reblogger.match("/tumblelog_(\S*)/")
							# index 0 is the whole pattern that was matched
							puts reblogger
							if(matches)
								first = matches[1] # this is the first () group
								puts "#{first}"
							end
							reblogs+=1
						end
					end
					f.write("\t"+ post["short_url"] + "\n")
				end
			end
			puts " #{blog["name"]} has #{likes} likes and #{reblogs} reblogs"
		end
		f.close
	
    redirect_to root_url, :notice => "Signed in!"  
  end  
end  