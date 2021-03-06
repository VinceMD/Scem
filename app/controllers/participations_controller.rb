class ParticipationsController < ApplicationController

  # store the current location in case of an atempt to login, for redirecting back
  before_filter :store_location, :only => [:index, :accept]

  before_filter :is_logged?, :except => [:index]

  before_filter :ensure_term_or_event_or_user_parameter?, :only => [:index]
  before_filter :ensure_term_parameter?, :except => [:index]
  before_filter :ensure_participation_role_parameter, :only  => [:create_or_update]
  before_filter :ensure_role_parameter, :only  => [:index]
  # before_filter :ensure_user_parameter?, :only => [:destroy_relation]


  # GET /terms
  # GET /terms.xml
  def index
    if !params[:event_id].nil?
      @event = Event.find(params[:event_id])
      @partial_path = 'index_terms'
    end

    if !params[:term_id].nil?
      @term = Term.find(params[:term_id])
      @event = @term.event
      @users = @term.search_participants(params[:role],params[:search], params[:page])
      @partial_path = 'index_term_users'
    end
    
    if params[:event_id].nil? && params[:term_id].nil?
      @user = User.find(params[:user_id])
      if params[:period] == "past"
        @terms = @user.search_participate_in_past(params[:search], params[:page], ENV['PER_PAGE'])
      else
        @terms = @user.search_participate_in_futur(params[:search], params[:page], ENV['PER_PAGE'])
      end
      @partial_path = 'index_user_terms'
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @users }
      format.js {
        render :update do |page|
          page.replace_html 'results', :partial => @partial_path
        end
      }
    end
  end

  def create_or_update

    proceed_rendering = true

    term = Term.find(params[:term_id])
    participation = term.participations.find_by_user_id(self.current_user.id)

    if(participation.nil?)
      participation = Participation.new
      participation.term_id=params[:term_id]
      participation.user_id=current_user.id
    end

    participation.role=params[:participation][:role]

    #update the participation on Facebook
    begin
    if facebook_session && term.facebook_eid
      if facebook_session.user.has_permission?('rsvp_event')
        if params[:participation][:role] == 'sure'
          status = 'attending'
        elsif params[:participation][:role] == 'maybe'
          status = 'unsure'
        elsif params[:participation][:role] == 'not'
          status = 'declined'
        end
        
        if status
          facebook_session.user.rsvp_event(term.facebook_eid, status)
        end
      else
        proceed_rendering = false
        redirect_to url_for(:controller => 'facebook', :action => 'ask_events_permissions_rsvp', :id => term.id)
      end
    end
    rescue
      flash[:error] = I18n.t('participations.controller.Error_status_update')
    end

    if proceed_rendering
      respond_to do |format|
        if participation.save
          flash[:notice] = I18n.t('participations.controller.Successfully_updated')
          format.html { redirect_to(url_for_even_polymorphic(term)) }
          format.xml  { head :ok }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => participation.errors, :status => :unprocessable_entity }
        end
      end
    end
  end


  #  def destroy
  #
  #    term = Term.find(params[:term_id])
  #    participation = term.participations.find_by_user_id(self.current_user.id)
  #
  #    participation.destroy unless(participation.nil?)
  #
  #    respond_to do |format|
  #      format.html { redirect_back_or_default('/') }
  #      format.xml  { head :ok }
  #    end
  #  end


  protected

  def ensure_term_parameter?
    param_uncorrect_redirection unless !params[:term_id].nil? and Term.find(params[:term_id])
  end


  def ensure_user_parameter?
    param_uncorrect_redirection unless !params[:user_id].nil? and User.find(params[:user_id])
  end

  def ensure_term_or_event_or_user_parameter?
    param_uncorrect_redirection unless (!params[:event_id].nil? and Event.find(params[:event_id])) or (!params[:term_id].nil? and Term.find(params[:term_id])) or (!params[:user_id].nil? and User.find(params[:user_id]))
  end


  def ensure_participation_role_parameter
    if params[:participation]
      params[:participation][:role]="maybe" unless (params[:participation][:role]=="sure" or params[:participation][:role]=="maybe" or params[:participation][:role]=="not")
    else
      params[:participation] = Hash.new
      params[:participation][:role]="maybe"
    end
  end

  def ensure_role_parameter
    params[:role]="maybe" unless (params[:role]=="sure" or params[:role]=="maybe" or params[:role]=="not")
  end

  def param_uncorrect_redirection
    flash[:error] = I18n.t('organisms.controller.Missing_parameters')
    redirect_to root_path
  end


end
