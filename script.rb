require 'json'
filename = "blogs.json"
x = ""
File.open( filename, "r" ) do |f|
    x = JSON.load( f )
end

x["nodes"].each do |blob|
	blob["match"] = 1.0
	blob["id"] = blob["name"].downcase.tr(' ', '_')
	# if blob["following"] == "true"
	# 	blob["playcount"] = 100
	# else
	# 	blob["playcount"] = 5
	# end
	blob["playcount"] = blob["size"]
	blob["artist"] = "Me"
end

sel = ''
i=0
x["links"].each do |blob|
	i+=1
	if i%100==0
		puts i
	end
	sel = x["nodes"].select { |i| i["name"] == blob["target"] }
	if blob["target"]
		if sel.empty?
			x["nodes"] << ({ "match" => "1.0",
								"id" => blob['target'].downcase.tr(' ', '_'),
								"playcount" => 5,
								"artist" => "New",
								"name" => blob['target'],
								"following" => "false"})
		end
	end
	if blob["target"]
		sel = x["nodes"].select { |i| i["name"] == blob["source"] }
		if sel.empty?
			x["nodes"] << ({ "match" => "1.0",
								"id" => blob['source'].downcase.tr(' ', '_'),
								"playcount" => 5,
								"artist" => "New",
								"name" => blob['source'],
								"following" => "false"})
		end
	end
end


f = File.open('b.json', 'w+')
f.write x.to_json
f.close