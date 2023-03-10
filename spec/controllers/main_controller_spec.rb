require 'rails_helper'

describe MainController do
  describe 'User want to goto the main page' do
    before(:each) do
      @group = GroupInfo.create(gid: 1)
      GroupToUser.create(gid: 1, uid: 2, role: 0)
      UserProfile.create(uid: 2, username: 'Maggie', avatar: '/avatar/1.jpg')
    end
    it 'user goto the register page if not login' do
      # get :user_index_path, :type => 'register'
      get :dashboard
      expect(response).to redirect_to('/user/index/login')
    end

    it 'user goto the main page if login' do
      session[:uid] = 2
      session[:profile] = 2
      session[:email] = 2
      session[:groups] = []
      get :dashboard
      expect(response).to render_template('main/dashboard')
    end
  end

  describe 'User want to goto the group page' do
    before(:each) do
      GroupToUser.create(gid: 1, uid: 1)
      UserProfile.delete_all
      UserProfile.create(uid: 1, username: 'MaggieZ')
      GroupInfo.delete_all
      GroupInfo.create(gid: 1, name: 'ColumbiaStudent', description: 'Columbia students practicing group')
    end

    it "redirect to dashboard if user hasn't joined a group" do
      session[:uid] = 2
      session[:profile] = 2
      session[:email] = 2
      session[:groups] = []
      get :group, params: {
        gid: 1
      }
      expect(response).to redirect_to('/main/dashboard')
    end

    it 'should show all the groups the user joined' do
      session[:uid] = 1
      session[:profile] = 1
      session[:email] = 1
      session[:groups] = []
      get :group, params: {
        gid: 1
      }
      expect(response).to render_template('main/group')
    end
  end
end
