class SessionsController < ApplicationController  
	require "open-uri"
	require 'json'
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
		all_posts = Array.new
		

		# look at the efficiency in terms of the potential viewers based on the 
		# number of blogs your followers are following
		# this would also be a measurement of how influential you are
		# how many of the people that could possibly be affected by a post are actually
		# being influenced by a post (at least in terms of likes/reblogs)? 
		Blog.delete_all
		Post.delete_all
		for blog in blags
			likes = 0
			reblogs = 0
			puts "analyzing: " + blog["name"]
			b = Blog.create(name: blog["name"], following: "true")
			# if(blogs == "{ \n\"blogs\": [\n")
			# 	# for the first blog added
			# 	blogs << "{\"name\": \"" + blog["name"] + "\", \"following\": \"true\" }\n"
			# else
			# 	# for the rest of them
			# 	# we only want to add commas when we know there are blogs before the
			# 	# one we're about to add
			# 	blogs << ",{\"name\": \"" + blog["name"] + "\", \"following\": \"true\" }\n"
			# end	
			# Each of these should be started in 5 separate processes
			5.times do |i|
				sleep 0.1
				posts_array = client.posts(blog["name"], :offset => i*20, :reblog_info => true)
				posts_array = posts_array["posts"]
				for post in posts_array
					# posts << "short_url: " + post["short_url"] + ",\n"
					if post["reblogged_from_name"].to_s == ""
						source  =  blog['name']
					else
						source = post["reblogged_from_name"].to_s
					end
					Post.create(target: blog['name'], source: source, type_of_post: post['type'], tags: post['tags'].join(',').to_s)
					unless post["reblogged_from_name"].nil?
						Blog.create(name: post["reblogged_from_name"].to_s, following: "false")
					end
					doc = Nokogiri::HTML(open(post["short_url"]))
					doc.css("ol.notes").each do |node|
						node.css("li.like").each do |note|
							likes += 1
						end
						node.css("li.reblog").each do |note|
							if (reblogging = note.at_css("span .tumblelog"))
								reblogging = note.at_css("span .tumblelog").content
							end
							if (source = note.at_css("span .source_tumblelog"))
								source = note.at_css("span .source_tumblelog").content
							end
							if(source && reblogging)
								# puts "#{reblogging} reblogged from #{source}"
								# because this post is associated with a 
								# puts reblogging.to_s
								# puts source.to_s

								# Figure out how to load more links so that we get all the nodes and eventually the original poster.
								Blog.create(name: reblogging, following: "false")
								Blog.create(name: source, following: "false")
								Post.create(target: reblogging, source: source, type_of_post: post['type'], tags: post['tags'].join(',').to_s)
							end
							reblogs+=1
						end
					end
					# puts post["short_url"]
				end
			end
			b.update_attribute(:size, (reblogs + (likes/2)))
			b.save
		end	
    redirect_to root_url, :notice => "Signed in!"  

    puts "=============================================="
    f = File.open("blogs.json", "w+") 
    f.write ('{ "nodes": ')
    f.write(Blog.all.to_json(only: [:name, :following, :size]))
    f.write (', "links": ')
    f.write(Post.all.to_json(only: [:source, :target, :type_of_post]))
    f.write ("}")    
    f.close
    puts "=============================================="

  end 
end  