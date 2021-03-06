class ParticipationMailer < ActionMailer::Base

  helper :users

  def creation_notification(admin_or_modo, user, event, term, role)
    
    #organism_admin and organism_modo, send this emails
    setup_email(admin_or_modo,user, event, role)
    @subject    += I18n.t('participation_mailer.subject_participation_notification',:event => event.name)
    @body[:url_event]  = ENV['SITE_URL']+ url_for_even_polymorphic(term)
    @body[:url_user]  = "#{ENV['SITE_URL']}/users/#{user.id}"
    @body[:url_participants]  = "#{ENV['SITE_URL']}#{event_term_participations_path(:event_id =>event.id, :term_id => term.id, :role =>:sure)}"
  end

  def creation_notification_to_sys(admin_or_modo, user, event, term, role)

    #organism_admin and organism_modo, send this emails
    setup_email(admin_or_modo,user, event, role)
    @subject    += I18n.t('participation_mailer.subject_participation_notification',:event => event.name)
    @body[:url_event]  = "#{ENV['SITE_URL']}#{url_for_even_polymorphic(term)}"
    @body[:url_user]  = "#{ENV['SITE_URL']}/users/#{user.id}"
    @body[:url_participants]  = "#{ENV['SITE_URL']}#{event_term_participations_path(:event_id =>event.id, :term_id => term.id, :role =>:sure)}"
  end


  protected
  def setup_email(receiver, user, event, role)
    @recipients  = "#{receiver.email}"
    @from        = "#{ENV['ADMINEMAIL']}"
    @subject     = "#{ENV['APPNAME']} "
    @sent_on     = Time.now
    @body[:user] = user
    @body[:receiver] = receiver
    @body[:role] = role
    @body[:event] = event
    @content_type = "text/html"
  end

  private
  
  #polymorphic url to manage or not ?
  def url_for_even_polymorphic(object, options = {})
    if(object.get_parent_object)
      if object.get_parent_object.get_parent_object
        if object.get_parent_object.get_parent_object
          return polymorphic_path([object.get_parent_object.get_parent_object.get_parent_object, object.get_parent_object.get_parent_object, object.get_parent_object, object].flatten, options)
        else
          return polymorphic_path([object.get_parent_object.get_parent_object, object.get_parent_object, object].flatten, options)
        end
      else
        return polymorphic_path([object.get_parent_object, object].flatten, options)
      end
    else
      return polymorphic_path([object].flatten, options)
    end
  end
end
