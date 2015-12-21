class ConfirmationsController < ApplicationController


def index


  @user = current_user
  if logged_in? && !current_user.admin? && !current_user.bankcontact? && !current_user.clientcontact?

# clients is an array - you cannot call a method on an array - you build another confirmations array by iterating through client  
   @confirmations = @user.confirmations
   @banks = Bank.all
   @clients = Client.all
    render 'confirmations/indexuser'

  elsif logged_in? && current_user.admin?

  #@confirmation = Confirmations.all
    if params[:search]
      @confirmations = Confirmation.search(params[:search]).page([:page]).per_page(5)
    else
      @confirmations = Confirmation.paginate(:page => params[:page], :per_page => 5)
    end
  render 'confirmations/indexadmin'

  elsif logged_in? && current_user.bankcontact?

  email = current_user.email
  bankcontact = Bankcontact.find_by(email: email)
  @id = bankcontact.bank_id
  @banks = Bank.all
  @clients = Client.all
  @bank = bankcontact.bank.name
  # @attachedRequestFiles = AttachedFile.where("bankaccount_id = ? AND is_audit = ?", params[:id], true)
  # @confirmations = Confirmation.where("bank_id = ?", @id).where.not(status: "Terminée")
  @confirmations = Confirmation.where("bank_id = ?", @id)
  @confirmations_pagination = @confirmations.paginate(:page => 1, per_page: 5)
  render 'confirmations/indexbank'


  else

  render 'static_pages/home'

  end

end

# --- New Confirmation ---
# Handle here the access attached file
def new

  @confirmation= Confirmation.new
    
end
  

def create
  @user = current_user
  client_id = params[:client_id]
  bank_id = params[:bank_id]
  
  @confirmation = @user.confirmations.create(confirmation_params)
  id1 = @confirmation.id.to_s
  id2 = rand(1000..2000).to_s
  @id3 = "C"+id1+"0V0"+id2+"Y15"
  @confirmation.update_attribute(:reference, @id3) 
 
  redirect_to root_url
 
end

def todo_when_attachedfile_is_empty
    # This point has not yet been tested
  	flash[:danger]="Veuillez attacher au moins un scan"
  	redirect_to '/confirmations/new'
end

# --- CHECK BY AUDITOR --------------------------------------------------------------
def check_by_auditor
  @confirmation = Confirmation.find(params[:id])
  @client = @confirmation.client
  @clientcontact = Clientcontact.find_by(client: @client)
  @bankcontact = Bankcontact.find_by(bank: @bank)
  @user = current_user
  @cac = @client.user
  @id = @confirmation.id
  

  render '/confirmations/check_by_auditor/'
end


# --- CHECK BY BANK --------------------------------------------------------------
def check_by_bank
  @confirmation = Confirmation.find(params[:id])
  @client = @confirmation.client
  @clientcontact = Clientcontact.find_by(client: @client)
  @bankcontact = Bankcontact.find_by(bank: @bank)
  @user = current_user
  @cac = @client.user
  @id = @confirmation.id
  
  # Must add the files here
  # --- We retrieve attached file to the account here ---
  @attachedRequestFiles = AttachedFile.where("confirmation_id = ? AND is_audit = ?", params[:id], true)
  
  
  
  
  
  
  # --- START: Retrieve last attached file ---
  # TODO Please avoid duplication on this !!!
  # The big question is where are we come from ? If we have just attached a new file
  # Then we need to retrieve all our attached files. If not, then we are freshly new
  # Remember: session is unsafe, you must not store any sensitive data here
  
  # Retrieve the attached file from session
  # If this file exists, we need to attached it
  if !session[:last_attachedfile].nil?
    attachedfileSaved = YAML.load(session[:last_attachedfile])
    # Here in the check by bank we must update the confirmation id has we know it.
    attachedfileSaved.confirmation_id = @id
    attachedfileSaved.save
    
    
    if !session[:involved_attachedfiles].nil?
      # Retrieve here all session attached files
      @attachedAnswerFiles = YAML.load(session[:involved_attachedfiles])
      
      
    
    
      @attachedAnswerFiles.push(attachedfileSaved)
      # Save in session
      session[:involved_attachedfiles] = @attachedAnswerFiles.to_yaml
      else
        @attachedAnswerFiles = AttachedFile.where("confirmation_id = ? AND is_bank = ?", params[:id], true)
    end
    
    # After that we flush the data
    # When we arrive first on index
    # Fresh start we need an empty attached file
    session.delete(:last_attachedfile)
    
    puts "attachedfileSaved: " + attachedfileSaved.to_s
    
    
    
  else
    # We are freshly new
    puts "attachedfileSaved is nil"
    session.delete(:last_attachedfile)
    session.delete(:involved_attachedfiles)
    
    # Must add the files here
    @attachedAnswerFiles = AttachedFile.where("confirmation_id = ? AND is_bank = ?", params[:id], true)
    
    # Save in session
    session[:involved_attachedfiles] = @attachedAnswerFiles.to_yaml
    
    
  end
  
  # --- END: Retrieve last attached file ---

  

  render '/confirmations/check_by_bank/'
end

# --- ANSWER --------------------------------------------------------------
def answer
  @confirmation = Confirmation.find(params[:id])
  
  # --- We need to update all attached file now ---
  # TODO Please avoid duplicated code
  if !session[:involved_attachedfiles].nil?
	  # Retrieve here all session attached files
	  @attachedAnswerFiles = YAML.load(session[:involved_attachedfiles])
  	  
  	  puts 'Size @attachedAnswerFiles: ' + @attachedAnswerFiles.size.to_s
  	  
  	  if @attachedAnswerFiles.size > 0
  	  	  @confirmation.attached_files << @attachedAnswerFiles
		  
		  if @confirmation.save and @confirmation.update_attribute(:status, "Terminée")
			flash[:info]="Votre réponse a été communiquée au commissaire aux comptes."
			session.delete(:last_attachedfile)
			session.delete(:involved_attachedfiles)
		
		
			redirect_to confirmations_url
		  else
		  	flash[:info]="Une erreur est survenue. Veuillez nous contacter."
			redirect_to confirmations_url
		  end
  	  else
		todo_when_attachedfile_is_empty
  	  end
  
  else
	todo_when_attachedfile_is_empty
  end
  
end

def destroy
  #have to change the line below down the road by modifying the way data are structured
  @confirmation = Confirmation.find(params[:id])
  @confirmation.destroy
  flash[:success] = "Confirmation supprimée."
  redirect_to root_url   
end


private

def confirmation_params
  params.require(:confirmation).permit(:client_id, :bank_id, :status, :reference, :file)
end


end
