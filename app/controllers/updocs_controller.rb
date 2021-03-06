class UpdocsController < ApplicationController
   def index
      @updocs = Updoc.all
   end
   
   def new
      @updoc = Updoc.new
   end
   
   def create
      @updoc = Updoc.new(updoc_params)
      if user_signed_in?
         @updoc.user_id = current_user.id
      elsif admin_signed_in?
         @updoc.user_id = params[:id]
      end
      if @updoc.save
         redirect_to updocs_path, notice: "The #{@updoc.name} file has been uploaded."
      else
         render "new"
      end
      
   end
   
   def destroy
      @updoc = Updoc.find(params[:doc_id])
      @updoc.destroy
      redirect_to updocs_path, notice:  "The #{@updoc.name} has been deleted."
   end
   
   private
      def updoc_params
         params.require(:updoc).permit(:name, :attachment)
      end
   
end
