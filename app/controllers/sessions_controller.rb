class SessionsController < ApplicationController  
	require "open-uri"
	def create  
		auth = request.env["omniauth.auth"]  
		user = User.find_by_provider_and_uid(auth["provider"], auth["uid"]) || User.create_with_omniauth(auth)  
		session[:user_id] = user.id  

		logger.info(user.id)
		Tumblr.configure do |config|
			config.consumer_key = "zGwB3KqWwxJ1ZFUDxxA6yV9jQmA3aVZR3KatMyFltgg7QaCJyz"
			config.consumer_secret = "KyjlTSaMyEVWfzV55DfErmk6v80sSCow4g9SSgYYIkAM3U92j2"
			config.oauth_token = auth["extra"]["access_token"].token
			config.oauth_token_secret = auth["extra"]["access_token"].secret
		end

		client = Tumblr::Client.new
		# displaying user data
		puts client.info		
		# puts client.following

		# Mechanize code

		agent = Mechanize.new
		agent.user_agent_alias = "Mac Safari"
		agent.follow_meta_refresh = true

		# Find total number of blogs the user is following. If its more 
		# than 20, it find 20 blogs at a time and appends the list to 
		# the blogs variable
		numFollowing = client.info["user"]["following"]
		blags = []
		((numFollowing/20.0).ceil).times do |i|
			x = client.following(:offset => i*20)["blogs"]
			blags.concat x
		end
		user.following = blags
		user.save

		# TODO: Figure out how to get the first 100 posts
		# right now, we"re only grabbing 20 posts. DONE
		# Figure out how to save the data for each blog so that
		# some library can read it later for the visualization
		# TODO: From here (to line 76) should go into a separate thread.
		f = File.open("blogs.net", "w+") 
		all_posts = Array.new
		

		# look at the efficiency in terms of the potential viewers based on the 
		# number of blogs your followers are following
		# this would also be a measurement of how influential you are
		# how many of the people that could possibly be affected by a post are actually
		# being influenced by a post (at least in terms of likes/reblogs)? 
		blogs = ""
		posts = ""
		blogs << "{ \n\"blogs\": [\n"
		posts << "\n\"posts\": [\n"
		blag = blags[0, 2]

		for blog in blag
			likes = 0
			reblogs = 0
			puts "analyzing: " + blog["name"]
			blogs << "{ \"blog_name\": \"" + blog["name"] + "\", \"following\": \"true\" },\n"
			# Each of these should be started in 5 separate processes
			5.times do |i|
				sleep 0.5
				posts_array = client.posts(blog["name"], :offset => i*20, :reblog_info => true, :limit => 5)
				posts_array = posts_array["posts"]
				for post in posts_array
					# posts << "short_url: " + post["short_url"] + ",\n"
					posts << "{ \"reblogging\": \""+ blog["name"] + "\", \"source\": \"" + (post["reblogged_from_name"].to_s || "") + "\"},\n"
					if !post["reblogged_from_name"].nil?
						blogs << "{ \"blog_name\": \"" + post["reblogged_from_name"].to_s + "\", \"following\": \"false\"},\n"
					end
					doc = Nokogiri::HTML(open(post["short_url"]))
					doc.css("ol.notes").each do |node|
						node.css("li.like").each do |note|
							likes+=1
						end
						node.css("li.reblog").each do |note|
							reblogging = note.at_css("span .tumblelog")
							source = note.at_css("span .source_tumblelog")
							if(source && reblogging)
								# puts "#{reblogging} reblogged from #{source}"
								posts << "{ \"reblogging\": \"" + reblogging + "\", \"source\": \"" + source + "\"},\n"
							end
							reblogs+=1
						end
					end
					puts post["short_url"]
				end
			end
			#puts " #{blog["name"]} has #{likes} likes and #{reblogs} reblogs"
		end
		blogs << "],"
		posts << "]}"
		f.write(blogs + posts)
		f.close
	
    redirect_to root_url, :notice => "Signed in!"  
  end 
end  