module EventsHelper

  def get_mini_height
    "36px"
  end

  def get_mini_width
    "36px"
  end

  def display_event_cover(event, style)
    if event.picture.nil?
      link_to(get_default_event_picture(style), event)
    else
      if style == "mini"
        link_to(image_tag(event.picture.attached.url(:small), :height => get_mini_height), event)
      elsif style == "mini_width"
        link_to(image_tag(event.picture.attached.url(:small), :width => get_mini_height), event)
      else
        link_to(image_tag(event.picture.attached.url(style)), event)
      end
    end
  end



  def display_term_cover(term, style)
    if term.event.picture.nil?
      link_to(get_default_event_picture(style), url_for_even_polymorphic(term))
    else
      if style == "mini"
        link_to(image_tag(term.event.picture.attached.url(:small), :height => get_mini_height), url_for_even_polymorphic(term))
      elsif style == "mini_width"
        link_to(image_tag(term.event.picture.attached.url(:small), :width => get_mini_height), url_for_even_polymorphic(term))
      else
        link_to(image_tag(term.event.picture.attached.url(style)), url_for_even_polymorphic(term))
      end
    end
  end

  def get_default_event_picture(style)
    if style == "mini"
      image_tag("default/event/small/1.jpg", :height => get_mini_height)
    elsif style == "mini_width"
      image_tag("default/event/small/1.jpg", :width => get_mini_width)
    else
      image_tag("default/event/#{style}/1.jpg")
    end
  end

  def get_list_organism_rights_user(user)
    #if user.has_system_role('moderator')
    # Organism.find_all_by_state('active', :order =>'name')
    #else
    user.is_admin_or_moderator_of
    #end
  end

  def display_event_action
    case controller_name
    when 'events'
      result = 'profil'
    when 'galleries'
      result = 'galleries'
    when 'participants'
      result = 'participants'
    end
    return result
  end

  def is_event_moderator?(event)
    if current_user && event.is_granted_to_edit?(current_user)
      return true
    else
      return false
    end
  end

  def displayable_categories_links(event)
    result = ""
    event.categories.each do |category|
      if category.to_display
        result += link_to(category.name, url_for(category_path(category))) + "&nbsp";
      end
    end
    if result == ""
      result = t("events.no_categories")
    end
    return result
  end

  def fields_for_term(term, &block)
    prefix = term.new_record? ? 'new' : 'existing'
    fields_for("event[#{prefix}_term_attributes][]", term, &block)
  end

  def add_term_link(name)
    link_to_function name do |page|
      page.insert_html :bottom, :terms, :partial => 'term', :object => Term.new
    end
  end

  def get_event_location(event)
    if event.places.size > 0
      if !event.places.first.name.blank?
        location = event.places.first.name
      end
    end
    if !event.location.blank?
      location =event.location
    end
    return location
  end

  def get_event_street(event)
    if event.places.size > 0
      if !event.places.first.street.blank?
        street = event.places.first.street
      end
    end
    if !event.street.blank?
      street = event.street
    end
    return street
  end

  def get_event_city(event)
    if event.places.size > 0
      if !event.places.first.city.blank?
        city = event.places.first.city
      end
    end
    if !event.city.blank?
      city = event.city
    end
    return city 
  end

  def get_event_description_long_or_term_description
    if @term
      if !@term.description.blank?
        return @term.description
      end
    end
    if @event
      if !@event.description_long.blank?
        return @event.description_long
      end
    end
  end

  def get_event_description_short_or_term_description
    if @term
      if !@term.description.blank?
        return @term.description
      end
    end
    if @event
      if !@event.description_short.blank?
        return @event.description_short
      end
    end
  end

  def get_event_if_term_url(term)
    event = term.event
    if event.terms.size == 0
      return url_for(event)
    elsif event.terms.size == 1
      return url_for(event)
    else
      return url_for_even_polymorphic(term)
    end
  end

  def get_event_place_as_string(event)
    result = ""
    if get_event_location(event) && get_event_street(event) && get_event_city(event)
      result = get_event_location(event) + ", " + get_event_street(event) + ", " + get_event_city(event)
    elsif get_event_street(event) && get_event_city(event)
      result = get_event_street(event) + ", " + get_event_city(event)
    elsif get_event_street(event)
      result = get_event_street(event)
    elsif get_event_city(event)
      result = get_event_city(event)
    end
    return result
  end
end
