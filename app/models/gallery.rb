class Gallery < ActiveRecord::Base
  include SharedMethods
  before_validation :remove_whitespace_from_name

  has_friendly_id :name, :use_slug => true, :strip_diacritics => true , :reserved => ["edit_pics", "add_pics"]

  has_many :pictures, :as => :parent, :dependent => :destroy, :conditions => "pictures.state = 'active'", :order => "pictures.position_active"

  #has_many :galleries_pictures
  #has_many :pictures, :through => :galleries_pictures, :conditions => "pictures.state = 'active'", :order => "position"

  validates_presence_of :name

  #validates_presence_of :parent_id
  validates_presence_of :parent_type
  validates_presence_of :creator_id

  acts_as_commentable

  acts_as_rateable

   include AASM
  aasm_column :state
  aasm_initial_state :initial => :passive
  aasm_state :passive
  aasm_state :active,  :enter => :do_activate
  aasm_state :suspended, :enter => :do_suspend
  aasm_state :archive,  :enter => :do_activate


  aasm_event :activate do
    transitions :from => :passive, :to => :active
  end

  aasm_event :suspend do
    transitions :from => [:passive, :active, :edited], :to => :suspended
  end

  aasm_event :unsuspend do
    transitions :from => :suspended, :to => :active
    transitions :from => :suspended, :to => :passive
  end

  def recently_activated?
    @activated
  end

  def recently_suspended?
    @suspended
  end

  def do_suspend
    @suspended = true
    self.suspended_at = Time.now.utc
  end

  def do_activate
    set_activated
    self.activated_at = Time.now.utc
  end

  def set_activated
    @activated = true
  end


  def self.search(search, page, state = 'active')
    paginate :per_page => ENV['PER_PAGE'], :page => page,
      :conditions => ['name like ? and state = ?', "%#{search}%", state],
      :order => 'id DESC'
  end

  # Helper class method to look up a commentable object
  # given the commentable class name and id
  def self.find_parent(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

  def picture_attributes=(picture_attributes)
    picture_attributes.each do |attributes|
      #pictures.build(attributes)
      picture = Picture.new(attributes)
      if attributes[:state] == 'active'
        picture.activated_at = Time.now
        picture.set_activated
        #raise attributes[:creator_id].inspect
        picture.activated_by = attributes[:creator_id]
      end
      pictures << picture
      #raise picture.errors.full_messages.inspect
    end
  end

  def self.find_parent(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

  def get_parent_object
    parent_type.constantize.find(parent_id)
  end

  def get_picture_root_path
    get_parent_object.get_picture_root_path + '/galleries/'+id.to_s
  end
  

  def is_user_moderator?(user)
    get_parent_object.is_user_moderator?(user)
	end

  def is_user_parents_member?(user)
    get_parent_object.is_user_member?(user)
	end

  def is_user_allowed_add_picture(user)
    result = false
    if add_picture_right=="members"
      if is_user_parents_member?(user)
        result=true
      end
    end
    if add_picture_right=="all"
      result=true
    end
    return result
  end

  def get_moderators_list
    get_parent_object.get_moderators_list
  end

#  def get_last_order_value
#    if pictures.first(:order => "position ASC").inspect
#    return (pictures.first(:order => "position ASC")).position
#  end

  def cover
    pictures.find_by_cover(true) or pictures.first
  end

  def defined_cover
    pictures.find_by_cover(true)
  end

  def get_rand_pics_not_cover(number)
    pictures.find_all_by_cover(false, :limit => number, :order => "RAND()")
  end

end
