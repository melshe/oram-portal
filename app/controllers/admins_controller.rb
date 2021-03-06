class AdminsController < ApplicationController

	include AdminsHelper
	before_filter :authenticate_admin!

	def show_referrers
		@curr_admin = current_admin
		#@referrers = User.where(role: User.roles[:referrer]).where.not(invitation_accepted_at: nil)
		if @curr_admin.role == "central"
			@referrers = User.where(role: 0).where.not(:first_name => nil).all.order(:last_name)
		elsif @curr_admin.role == "employee"
			@referrers = User.where(role:0).where(status: "Approved").all
			if params[:status] and params[:status] != 'Status'
				@referrers = @referrers.where(status: params[:status]).where.not(:first_name => nil)
			end
			@status = params[:status]
		end
		render :show_referrers
	end

	def show_clients
		@curr_admin = current_admin
		if @curr_admin.role == "central"
			@clients = User.where(role: 1).where.not(:first_name => nil).all.order(:last_name)
		elsif @curr_admin.role == "employee"
			@clients = @curr_admin.users
			#@clients = Form.where(form_type: 3).order("created_at DESC")
			if params[:status] and params[:status] != 'Status'
				@clients = @clients.where(status: params[:status]).where.not(:first_name => nil).all
			end
			@status = params[:status]
		end

		render :show_clients
	end

	def show_referrals
		@curr_admin = current_admin
		@forms = Form.where(:form_type => 2)
		render :show_referrals
	end

	def mark_referrer_status
		@referrer = User.find_by_id(params[:id])
		#form_type for referrers is number 1
		mark_status(@referrer, params[:status], 1)
		
		redirect_to referrers_path
	end

	def mark_client_status
		@client = User.find_by_id(params[:id])
		#form_type for client questionnaires is number 3
		mark_status(@client, params[:status], 3)
		
		redirect_to clients_path
	end

	def mark_form_status
		status = params[:status]
		@form = Form.find(params[:id])
		@form.status = status
		@form.save
		message = "Referral #{@form.first_name} #{@form.last_name} has been marked as #{@form.status.downcase} by admin #{current_admin.full_name}"

		e = Admin.find_by_id(current_admin.id).events.build(:admin_id => current_admin.id, :message => message)
		e.save
		if status == "Approved"
			flash[:notice] = "#{@form.first_name} #{@form.last_name} has been marked as #{@form.status.downcase}, next step is to invite as client."
			redirect_to new_user_invitation_path
			return
		else
			flash[:notice] = message
		end
		redirect_to admin_referrals_path
	end
	
	def change_client_phase
		@client = User.find_by_id(params[:id])
		prev_phase = @client.phase
		@client.phase = params[:edit_client]["changed_phase"]
		@client.save
		message = "#{@client.first_name} #{@client.last_name} has been moved from #{prev_phase} to #{@client.phase}"
		@client.events.build(:user_id => :id, :message => message)
		@client.save
		flash[:notice] = message
		redirect_to client_path
	end
	
	def assign_caseworker
		@client = User.find_by_id(params[:id])
		caseworker_id, caseworker_name = params[:edit_client]["assign_caseworker"].split(",")
		if !@client.ownerships.where(user_id: params[:id]).empty? && !@client.ownerships.where(user_id: params[:id]).where(admin_id: caseworker_id).empty?
			#means that this ownership already exists!
			flash[:warning] = "#{@client.full_name} has already been assigned to caseworker #{caseworker_name}!"
		else
			@client.ownerships.build(:user_id => params[:id], :admin_id => caseworker_id)
			message = "#{@client.first_name} #{@client.last_name} has been assigned to caseworker #{caseworker_name}"
			@client.events.build(:user_id => params[:id], :message => message)
			@client.save
			flash[:notice] = message
		end
		redirect_to client_path
	end
	
	def delete_caseworker
		@client = User.find_by_id(params[:id])
		caseworker = params[:caseworker]
		caseworker_id = caseworker
		caseworker_name = Admin.find_by_id(caseworker_id.to_i).full_name
		if !@client.ownerships.where(admin_id: caseworker_id).empty?
			@client.ownerships.where(admin_id: caseworker_id).destroy_all
			message = "Admin #{current_admin.full_name} deleted caseworker #{caseworker_name} from client #{@client.full_name}"
			flash[:notice] = message
			@client.events.build(:user_id => @client.id, :admin_id => current_admin.id, :message => message)
			@client.save
		end
		redirect_to client_path
	end


	def show_all
		@curr_admin = current_admin
		if @curr_admin != nil && @curr_admin.role == 'employee'
			flash[:error] = "You must be a central admin to do that!"
			redirect_to root_path and return
		# elsif @curr_admin.role == 'employee'
		# 	flash[:warning] = "You must be central admin to do that!"
		# 	redirect_to root_path and return
		else
			@admins = Admin.all
		end
	end
	
	def show_my_profile
		@curr_admin = current_admin
		@admin = Admin.find_by_id(params[:id])
		render :show_my_profile
	end
	
	def show
		@curr_admin = current_admin
		@admin = Admin.find_by_id(params[:id])
		@client_names = []
		if !@admin.ownerships.empty?
			@admin.ownerships.each do |ownership|
				client_id = ownership.user_id
				@client_names.append(User.find_by_id(client_id).full_name)
			end
		else
			@client_names.append('This caseworker has no clients.')
		end
		render :admin_profile
	end
	
	def admin_settings_edit
		@curr_admin = current_admin
		@admin = Admin.find_by_id(params[:id])
		render :admin_edit_profile
	end
    
	def admin_setting
		@curr_admin = current_admin
		@admin = Admin.find_by_id(params[:id])
		render :admin_setting
	end
    
	def admin_edit_save
		@curr_admin = current_admin
		Admin.update(params[:id], 
		{:first_name => params["admin"]["first_name"], 
		:last_name => params["admin"]["last_name"], 
		:email => params["admin"]["email"], 
		:phone => params["admin"]["phone"], 
		:address => params["admin"]["address"],
		:skype => params["admin"]["skype"]})
		redirect_to :admin_setting
	end
    
	def admin_destroy
		@admin = Admin.find_by_id(params[:id])
		@admin.destroy
		if @admin.id == current_admin.id
			message = "Admin #{current_admin.full_name} deleted their own account."
			redirect_to destroy_user_session_path
		else
			message = "Admin #{current_admin.full_name} deleted account of Admin #{@admin.full_name}."
			redirect_to admins_path
		end
		@admin.events.build(:admin_id => @admin.id, :message => message)
	end
	
	def admin_pass_change
		@curr_admin = current_admin
		@admin = Admin.find_by_id(params[:id])
		render :admin_pass_change
	end 
	
	def admin_pass_save
		@curr_admin = current_admin
		curr = params["admin"]["encrypted_password"]
		if (@curr_admin.valid_password?(curr))
			pass1 = params["admin"]["pass_reset1"]
			pass2 = params["admin"]["pass_reset2"]
			if (pass1 == pass2)
				if (pass1.length > 5)
					new_pass = Admin.create(:password => pass1).encrypted_password
					@curr_admin.encrypted_password = new_pass
					@curr_admin.save
				else 
					flash[:alert] = "Your new password must be longer than 5 characters long."
				end
			else
				flash[:alert] = "Your new password and confirmation password do not match. Please try again."
			end
		else
			flash[:alert] = "Your old password is incorrect. Please try again."
		end
		redirect_to :admin_setting
	end
    
    def show_pending
    	@pending = User.where(:first_name => nil)
    	render :show_pending
    end
end
