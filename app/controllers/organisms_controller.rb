class OrganismsController < ApplicationController

  # logged in mandatory to create an organism
  before_filter :is_logged?, :only => [:new, :create]
  
  # store the current location in case of an atempt to login, for redirecting back
  before_filter :store_location, :only => [:show, :index]

  # Protect these actions behind an admin login
  before_filter :is_organism_admin?, :only => [:update, :edit, :destroy, :purge, :suspend, :unsuspend]

  def list
    @organisms = Organism.find(:all, :limit => 10, :conditions => ['name like ? and in_directory = ? and state = ?', "%#{params[:search]}%", true, "active"])
  end

  # GET /organisms
  # GET /organisms.xml
  def index
    @organisms = Organism.search(params[:search], params[:page])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @organisms }
      format.js {
        render :update do |page|
          page.replace_html 'results', :partial => 'organisms_list'
        end
      }
    end
  end

  # GET /organisms/1
  # GET /organisms/1.xml
  def show
    @current_object = @organism = Organism.find(params[:id])
    @comments = @organism.search_comments('', 1, 3)

    #the object comment is needed for displaying the form of new comment
    initialize_new_comment(@organism)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @organism }
    end
  end

  # GET /organisms/new
  # GET /organisms/new.xml
  def new
    @organism = Organism.new
    set_session_parent_pictures_root_path(@organism)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organism }
    end
  end

  # GET /organisms/1/edit
  def edit
    @organism = Organism.find(params[:id])
    set_session_parent_pictures_root_path(@organism)
  end

  # POST /organisms
  # POST /organisms.xml
  def create
    @organism = Organism.new(params[:organism])
    @organism.created_by = current_user.id
    #raise @organism.terms_of_service.inspect
    
    #set the creator as an admin
    organism_user = OrganismsUser.new
    organism_user.user_id = current_user.id
    organism_user.role = 'admin'
    organism_user.activated_at = Time.now
    organism_user.state = 'active'

    
    set_session_parent_pictures_root_path(@organism)

    respond_to do |format|
      @organism.register! if @organism && @organism.valid?
      success = @organism && @organism.valid?
      
      if success && @organism.errors.empty?

        # save the current user as an admin of the organism
        if organism_user.valid?
          organism_user.organism_id = @organism.id
          organism_user.save 
        end

        flash[:notice] = I18n.t('organisms.controller.Successfully_created')
        format.html { redirect_to(edit_organism_path(@organism, :only_details => true)) }
        format.xml  { render :xml => @organism, :status => :created, :location => @organism }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /organisms/1
  # PUT /organisms/1.xml
  def update
    @organism = Organism.find(params[:id])
    @organism.edited_by = current_user.id


    set_session_parent_pictures_root_path(@organism)

    #hack: do not consider categories id made of hash ['_all'] => id. Problem comes from Swapselect
    if params[:organism][:activity_ids]
      activity_ids = Array.new
      params[:organism][:activity_ids].each do |id|
        if !id.include?("_all") && !id.include?("_selected")
          activity_ids << id
        end
      end
      params[:organism][:activity_ids] = activity_ids
    end
    
    respond_to do |format|
      if @organism.update_attributes(params[:organism])

        flash[:notice] = I18n.t('organisms.controller.Successfully_updated')
        format.html { redirect_to(@organism) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /organisms/1
  # DELETE /organisms/1.xml
  def destroy
    organism = Organism.find(params[:id])

    destroyable = true

    if(organism.galleries.size>0)
      destroyable = false
    end

    if organism.comments.size>0
      destroyable = false
    end


    if destroyable
      #destroy in cascade
      organism.destroy
      flash[:notice] = I18n.t('organisms.controller.Successfully_destroyed')
      respond_to do |format|
        format.html { redirect_to(root_path) }
        format.xml  { head :ok }
      end
    else

      organism.suspend!
      flash[:notice] = I18n.t('organisms.controller.Successfully_suspended')
      respond_to do |format|
        format.html { redirect_to(root_path) }
        format.xml  { head :ok }
      end
    end
  end

  def activate
    organism = Organism.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && organism && !organism.active?
      organism.activate!
      flash[:notice] = I18n.t('organisms.controller.Activated')
      redirect_to(organism)
    when params[:activation_code].blank?
      flash[:error] = I18n.t('organisms.controller.Activation_code_missing')
      redirect_back_or_default('/')
    else
      flash[:error]  = I18n.t('organisms.controller.Cant_find_organism_activation')
      redirect_back_or_default('/')
    end
  end

#  # PUT /users/1/suspend
#  def suspend
#    @organism = Organism.find(params[:id])
#    @organism.suspend!
#    redirect_to(organisms_url)
#  end
#
#  # PUT /users/1/unsuspend
#  def unsuspend
#    @organism = Organism.find(params[:id])
#    @organism.unsuspend!
#    redirect_to(organisms_url)
#  end
#
#  # DELETE /users/1
#  def destroy
#    @organism = Organism.find(params[:id])
#    @organism.delete!
#    redirect_to(organisms_url)
#  end
#
#  # DELETE /users/1/purge
#  def purge
#    @organism = Organism.find(params[:id])
#    @organism.destroy
#    redirect_to(organisms_url)
#  end

  # Check if logged in user has organism_admin or organism_moderator rights
  #
  # will return true if the logged in user is equal as the controlled user (or admin or moderator)
	def organism_admin_or_moderator?
    return true
    #TODO: implement organism_moderator and organism_admin
    #no_permission_redirection unless self.current_user && (self.current_user.id==find_user.id || self.current_user.has_system_role('moderator'))
  end

  def is_organism_moderator?
    organism = Organism.find(params[:id])
    not_granted_redirection unless current_user && organism.is_user_moderator?(current_user)
  end

  def is_organism_admin?
    organism = Organism.find(params[:id])
    not_granted_redirection unless current_user && organism.is_user_admin?(current_user)
  end

  def not_granted_redirection
    flash[:error] = I18n.t('organisms.controller.Not_allowed_to_do_this')
    redirect_to root_path
  end

end
