class Blog < ActiveRecord::Base

	validates :name, :uniqueness => true
	attr_accessible :name, :following, :size
end  

