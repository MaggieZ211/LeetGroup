# frozen_string_literal: true

# Description
# Used to redirect to the main page of the website
class MainController < ApplicationController
  layout 'dashboard'
  before_action :auth_check
  def auth_check
    unless MainHelper.check_session session
      MainHelper.clean_session session
      flash[:l_notice] = 'Pleases Login Account'
      redirect_to user_index_path type: 'login'
    end
  end

  def dashboard
    uid = session[:uid]
    # finish status
    @day_finished = Card.get_card_statistics(uid, Card.card_status[:finished], 'day')
    @week_finished = Card.get_card_statistics(uid, Card.card_status[:finished], 'week')
    @month_finished = Card.get_card_statistics(uid, Card.card_status[:finished], 'month')

    # create status
    @day_created = Card.get_card_statistics(uid, Card.card_status[:active], 'day')
    groups = GroupHelper.get_user_groups uid
    @group_info = []
    groups.each do |each|
      @group_info.append GroupHelper.get_group_detail each
    end
  end
  def profile; end
  def password; end

  def group
    @gid = params[:gid]
    uid = session[:uid]
    if GroupToUser.find_by(gid: @gid, uid: uid).nil?
      flash[:main_notice] = 'You haven\'t join this group'
      session[:groups] = GroupHelper.get_user_groups uid
      redirect_to main_dashboard_path
      return
    end

    @group_info = GroupHelper.get_group_info @gid
    member_result = GroupHelper.get_group_users @gid
    @members = member_result.result
    @member = @members.find { |m| m.uid == uid }
    flash[:tab] = params[:tab] unless params[:tab].nil?
  end
end
