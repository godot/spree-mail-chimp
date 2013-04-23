# -*- coding: utf-8 -*-
class Spree::SubscriptionsController < Spree::BaseController

  def hominid
    @hominid ||= Hominid::API.new(Spree::Config.get(:mailchimp_api_key))
  end

  def create
    @errors = []

    if params[:email].blank?
      @errors << t('missing_email')
    elsif params[:email] !~ /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}/i
      @errors << t('invalid_email_address')
    else
      begin
        @mc_member = hominid.list_member_info(mailchimp_list_id, [params[:email]])
      rescue Hominid::APIError => e
          Rails.logger.error e.to_s
      end

      if @mc_member['errors'] == 0
        @errors << t('that_address_is_already_subscribed')
      else
        begin
          hominid.list_subscribe(mailchimp_list_id, params[:email], mailchimp_merge_vars)
        rescue
          @errors << t('invalid_email_address')
        end
      end
    end

    respond_to do |wants|
      wants.js
    end
  end

  private
  def mailchimp_list_id
    @mailchimp_list_id ||= mailchimp_list_id_from_env || Spree::Config.get(:mailchimp_list_id)
  end

  def mailchimp_list_id_from_env
    ENV["MAILCHIMP_LIST_ID_#{I18n.locale.to_s.upcase}"]
  rescue
    nil
  end

  def mailchimp_merge_vars
    merge_vars = {}
    merge_vars[:GROUPINGS] = [{ "name"=>"Language", groups: group_name_from_locale }]
    merge_vars
  end

  def group_name_from_locale
    if I18n.locale == :fr
      'Newsletter en français'
    else
      'Newsletter in english'
    end
  end


end
