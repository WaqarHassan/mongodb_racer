class Racer 
	include ActiveModel::Model
	attr_accessor :id, :number , :first_name , :last_name , :gender , :group , 	:secs
	def initialize(params={})
		@id=params[:_id].nil? ? params[:id] : params[:_id].to_s
		@number=params[:number].to_i
		@first_name=params[:first_name]
		@last_name=params[:last_name]
		@gender=params[:gender]
		@group=params[:group]
		@secs=params[:secs].to_i
	end

	def self.mongo_client
		Mongoid::Clients.default #('mongodb://localhost:27017')
	end
	def self.collection
		self.mongo_client['racers']
	end
	def self.all(prototype={}, sort={:number => 1}, skip=0, limit=nil)
		result = collection.find(prototype).sort(sort).skip(skip)
		result = result.limit(limit) if !limit.nil?
		return result
	end
	def self.find  id 
		Rails.logger.debug {"Getting Racer #{id}"}
		id = BSON::ObjectId(id) if id.is_a?(String)
		doc = collection.find(:_id=>id).first
		return doc.nil? ? nil : Racer.new(doc)
	end
	def save
		result=self.class.collection.insert_one(_id:@id, number:@number, first_name:@first_name, last_name:@last_name, gender:@gender , group: @group, secs: @secs)
		@id=result.inserted_id.to_s #store just the string form of the _id
	end
	def update(params)
		@number=params[:number].to_i
		@first_name=params[:first_name]
		@last_name=params[:last_name]
		@gender = params[:gender]
		@group = params[:group]
		@secs=params[:secs].to_i
		params.slice!(:number, :first_name, :last_name, :gender, :group, :secs)
		self.class.collection
              .find(_id:BSON::ObjectId(@id))
              .update_one(:$set=> {number: @number, first_name: @first_name , last_name: @last_name , gender: @gender , group: @group , secs: @secs})
	end
	def destroy
		self.class.collection.find(_id:BSON::ObjectId(@id)).delete_one()
	
	end
	def created_at
		Date.today
	end
	def updated_at
		Date.today
	end
	def persisted?
	!@id.nil?
	end
	def self.paginate(params)
		page=(params[:page] || 1).to_i
		limit=(params[:per_page] || 30).to_i
		skip=(page-1)*limit
		sort = params[:sort] ||= {}
		racers=[]
		all({}, sort, skip, limit).each do |doc|
      racers << Racer.new(doc)
    end
		total= all({}, sort , 0 , 1).count

		WillPaginate::Collection.create(page, limit, total) do |pager|
			pager.replace(racers)
		end
	end

end