#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class ApplicationController < ActionController::Base
  has_mobile_fu
  protect_from_forgery :except => :receive

  #before_filter :mobile_except_ipad
  before_filter :set_contacts_notifications_and_status, :except => [:create, :update]
  before_filter :count_requests
  before_filter :set_invites
  before_filter :set_locale

  def set_contacts_notifications_and_status
    if user_signed_in?
      @aspect = nil
      @object_aspect_ids = []
      @all_aspects = current_user.aspects.includes(:aspect_memberships)
      @aspects_dropdown_array = @all_aspects.collect{|x| [x.to_s, x.id]}
      @notification_count = Notification.for(current_user, :unread =>true).count
    end
  end

  def mobile_except_ipad
    if is_mobile_device?
      if request.env["HTTP_USER_AGENT"].include? "iPad"
        session[:mobile_view] = false
      else
        session[:mobile_view] = true
      end
    end
  end

  def count_requests
    @request_count = Request.where(:recipient_id => current_user.person.id).count if current_user
  end

  def set_invites
    if user_signed_in?
      @invites = current_user.invites
    end
  end

  def set_locale
    if user_signed_in?
      I18n.locale = current_user.language
    else
      I18n.locale = request.compatible_language_from AVAILABLE_LANGUAGE_CODES
    end
  end

  def similar_people contact, opts={}
    opts[:limit] ||= 5
    aspect_ids = contact.aspects.map{|a| a.id}
    count = Contact.joins(:aspect_memberships).where(
      :user_id => current_user.id).where(
      "contacts.person_id != #{contact.person_id}").where(
      :aspect_memberships => {:aspect_id => aspect_ids}).count
    if count > opts[:limit]
      offset = rand(count-opts[:limit])
    else
      offset = 0
    end

    contacts = Contact.joins(:aspect_memberships).includes(:person).where(
      :user_id => current_user.id).where(
      "contacts.person_id != #{contact.person_id}").where(
      :aspect_memberships => {:aspect_id => aspect_ids}).all(
      :offset => offset,
      :limit => opts[:limit])
    contacts.collect!{ |contact| contact.person }
  end
end
