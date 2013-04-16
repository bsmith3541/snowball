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
		# puts client.info		
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
		blags = client.following["blogs"];
		puts blags
		user.following = blags
		user.save

		# TODO: Figure out how to get the first 100 posts
		# right now, we"re only grabbing 20 posts. DONE
		# Figure out how to save the data for each blog so that
		# some library can read it later for the visualization
		# TODO: From here (to line 76) should go into a separate thread.
		f = File.open("blogs.json", "w+") 
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

		for blog in blags
			likes = 0
			reblogs = 0
			puts "analyzing: " + blog["name"]
			if(blogs == "{ \n\"blogs\": [\n")
				# for the first blog added
				blogs << "{\"blog_name\": \"" + blog["name"] + "\", \"following\": \"true\" }"
			else
				# for the rest of them
				# we only want to add commas when we know there are blogs before the
				# one we're about to add
				blogs << ",{\"blog_name\": \"" + blog["name"] + "\", \"following\": \"true\" }"
			end	
			# Each of these should be started in 5 separate processes
			5.times do |i|
				sleep 0.5
				posts_array = client.posts(blog["name"], :offset => i*20, :reblog_info => true)
				posts_array = posts_array["posts"]
				for post in posts_array
					# posts << "short_url: " + post["short_url"] + ",\n"
					if(posts == "\n\"posts\": [\n")
						# for the first post added
						posts << "{ \"reblogging\": \""+ blog["name"] + "\", \"source\": \"" + (post["reblogged_from_name"].to_s || "") + "\"}\n"
					else
						# we only want to add commas when we know there are posts before the
						# one we're about to add
						posts << ",{ \"reblogging\": \""+ blog["name"] + "\", \"source\": \"" + (post["reblogged_from_name"].to_s || "") + "\"}\n"
					end
					if !post["reblogged_from_name"].nil?
						# we only want to add commas when we know there are blogs before the
						# one we're about to add
						# because this blog belongs to a post within a blog, we know that
						# there are blogs before the one we're about to add
						blogs << ",{ \"blog_name\": \"" + post["reblogged_from_name"].to_s + "\", \"following\": \"false\"}\n"
					end
					doc = Nokogiri::HTML(open(post["short_url"]))
					doc.css("ol.notes").each do |node|
						node.css("li.like").each do |note|
							likes+=1
						end
						node.css("li.reblog").each do |note|
							reblogging = note.at_css("span .tumblelog").content
							source = note.at_css("span .source_tumblelog").content
							if(source && reblogging)
								# puts "#{reblogging} reblogged from #{source}"
								# because this post is associated with a 
								if(posts == "\n\"posts\": [\n")
									# this is the first post
									posts << "{ \"reblogging\": \"" + reblogging + "\", \"source\": \"" + source + "\"}\n"
								else
									puts reblogging.to_s
									puts source.to_s
									dup_reblog = blogs.match("\"blog_name\": \"#{reblogging}\"")
									dup_source = blogs.match("\"blog_name\": \"#{source}\"")
									if (dup_reblog == nil)
										puts "============================="
										puts "the reblogger: #{reblogging} is NOT a duplicate!"
										puts "============================="
										blogs << ",{\"blog_name\": \"" + reblogging + "\", \"following\": \"false\" }"
									elsif(dup_source == nil)
										puts "============================="
										puts "the source: #{source} is NOT a duplicate!"
										puts "============================="
										blogs << ",{\"blog_name\": \"" + source + "\", \"following\": \"false\" }"
									end
									# there are posts before this one
									posts << ",{ \"reblogging\": \"" + reblogging + "\", \"source\": \"" + source + "\"}\n"
								end
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