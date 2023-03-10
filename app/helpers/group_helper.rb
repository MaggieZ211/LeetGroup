# require 'instances/user_view'
module GroupHelper
  def self.create_group(uid, name, description, status = GroupInfo.group_status[:private])
    return nil if status != GroupInfo.group_status[:private] && status != GroupInfo.group_status[:public]

    group = GroupInfo.create(name: name, description: description, create_time: Time.now, status: status)
    return nil if group.nil?

    GroupToUser.create(gid: group.gid, uid: uid, role: GroupToUser.role_status[:owner])
    group
  end

  def self.delete_group(gid, uid)
    user = GroupToUser.find_by(gid: gid, uid: uid)
    return false if user.nil? || user.role != GroupToUser.role_status[:owner]

    # delete all the members firstly
    GroupToUser.delete_by(gid: gid)
    # delete all the cards secondly
    GroupToCard.delete_by(gid: gid)
    # delete the group info
    GroupInfo.delete_by(gid: gid)
    true
  end

  def self.get_group_info(gid)
    GroupInfo.where(gid: gid).first
  end

  def self.get_group_detail(group)
    info = GroupView.new
    info.group = group
    info.count = GroupHelper.get_total_users_number group.gid
    role = GroupToUser.where(gid: group.gid, role: GroupToUser.role_status[:owner]).first
    return info if role.nil?

    info.user = UserProfile.where(uid: role.uid).first
    info
  end

  def self.get_total_users_number(gid)
    GroupToUser.where(gid: gid).count
  end

  def self.get_total_cards_number(gid)
    GroupToCard.where(gid: gid).count
  end

  def self.get_group_owner_info(gid)
    group_owner = GroupToUser.find_by(gid: gid, role: GroupToUser.role_status[:owner])
    UserProfile.find_by(uid: group_owner.uid)
  end

  def self.generate_private_invite_code(gid, username, expiration_date = nil)
    user = UserLogInfo.find_by(username: username)
    return nil if user.nil?

    code = CodeGenerator.generate
    welcome_code = GroupWelcomeCode.create(code: code, gid: gid, uid: user.uid, status: GroupWelcomeCode.welcome_type[:private], expiration_date: expiration_date)
    while welcome_code.nil?
      code = CodeGenerator.generate
      welcome_code = GroupWelcomeCode.create(code: code, gid: gid, uid: user.uid, status: GroupWelcomeCode.welcome_type[:private], expiration_date: expiration_date)
    end
    code
  end

  def self.generate_public_invite_code(gid, expiration_date)
    code = CodeGenerator.generate
    welcome_code = GroupWelcomeCode.create(code: code, gid: gid, expiration_date: expiration_date, status: GroupWelcomeCode.welcome_type[:public])
    while welcome_code.nil?
      code = CodeGenerator.generate
      welcome_code = GroupWelcomeCode.create(code: code, gid: gid, expiration_date: expiration_date, status: GroupWelcomeCode.welcome_type[:public])
    end
    code
  end

  def self.join_group(uid, code)
    # valid the code
    welcome = GroupWelcomeCode.find_by(code: code)
    if welcome.nil?
      return -1 # doesn't have such welcome code
    end

    delete_code = false
    if welcome.status == GroupWelcomeCode.welcome_type[:private] # private
      if welcome.uid != uid
        return -2 # didn't invite to such user
      end

      delete_code = true
    end
    if !welcome.expiration_date.nil? && Time.now.to_i > welcome.expiration_date.to_time.to_i # has been expired
      GroupWelcomeCode.delete_by(code: code)
      return -3 # the welcome has expired
    end
    exist = GroupToUser.find_by(gid: welcome.gid, uid: uid)
    unless exist.nil?
      return -4 # the user already in this group
    end
    GroupToUser.create(gid: welcome.gid, uid: uid, role: GroupToUser.role_status[:member])
    GroupWelcomeCode.delete_by(code: code) if delete_code
    1 # success
  end

  def self.remove_user_from_group(gid, operator, uid)
    unless GroupInfo.exists? gid
      return -1 # group doesn't exist
    end

    permission_role = GroupToUser.find_by(gid: gid, uid: operator)
    if permission_role.nil?
      return -2 # operator doesn't exist
    end

    if operator == uid # leave the group
      GroupToUser.delete_by(gid: gid, uid: uid)
      return 1 # successfully leave the group
    end
    if GroupToUser.find_by(gid: gid, uid: uid).nil?
      return -4 # doesn't have target user
    end

    if permission_role.role != GroupToUser.role_status[:owner] && permission_role.role != GroupToUser.role_status[:manager]
      return -3 # no permission to do
    end

    GroupToUser.delete_by(gid: gid, uid: uid)
    1 # remove successfully
  end

  def self.assign_role_to_user(gid, operator, uid, role)
    unless GroupInfo.exists? gid
      return -1 # group doesn't exist
    end

    permission_role = GroupToUser.find_by(gid: gid, uid: operator)
    if permission_role.nil?
      return -2 # doesn't have this person
    end

    if permission_role.role != GroupToUser.role_status[:owner]
      return -3 # doesn't have right to do this
    end

    target_user = GroupToUser.find_by(gid: gid, uid: uid)
    if target_user.nil?
      return -4 # doesn't have target user
    end

    if role == GroupToUser.role_status[:owner] # transfer the ownership
      permission_role.role = GroupToUser.role_status[:member]
      permission_role.save
    end
    target_user.role = role
    target_user.save
    1 # success
  end

  def self.get_group_users(gid, size = nil, page = nil)
    unless GroupInfo.exists? gid
      return UserResult.new nil, nil # group doesn't exist
    end

    total_num = GroupToUser.where(gid: gid).count
    page = 1 if page.nil?
    size = total_num if size.nil?
    uids = GroupToUser.where(gid: gid).offset(size * (page - 1)).limit(size)
    current_num = uids.count
    result = []
    uids.each do |u|
      user = UserProfile.find_by(uid: u.uid)
      if user.nil?
        GroupToUser.delete_by(gid: gid, uid: u.uid)
      else
        result.append(UserView.new(user, u.role))
      end
    end
    page_info = PageInfo.new((total_num.to_f / size).ceil, total_num, page, current_num)
    UserResult.new result, page_info
  end

  def self.get_user_groups(uid)
    groups = GroupToUser.where(uid: uid)
    result = []
    groups.each do |g|
      group = GroupInfo.find_by(gid: g.gid)
      next if group.nil?

      result.append group
    end
    result
  end

  def self.view_card(gid, status, page_size, offset, sort_by, sort_type)
    @card_list = GroupToCard.where(gid: gid)
    cid_list = []
    @card_list.each do |onecard|
      cid_list.append onecard.cid
    end

    @cards = Card.where(cid: cid_list)
    @cards = @cards.where(status: status) unless status == 3

    @cards = @cards.order(sort_by => :asc) if !sort_by.nil? && sort_type == 'asc'
    @cards = @cards.order(sort_by => :desc) if !sort_by.nil? && sort_type == 'desc'

    total_size = @cards.count

    @cards = @cards.limit(page_size).offset(offset * page_size)

    total_page = total_size / page_size
    total_page += 1 if total_size % page_size != 0
    current_size = if total_size.zero?
                     0
                   elsif offset == total_page - 1
                     total_size - (total_page - 1) * page_size
                   else
                     page_size
                   end

    page_info = PageInfo.new(total_page, total_size, offset, current_size)
    CardView.new(page_info, @cards)
  end

  def self.view_card_detail(gid, cid)
    Card.find_by(cid: cid)
  end

  def self.check_permission(gid, uid, cid)
    permission_role = GroupToUser.find_by(gid: gid, uid: uid)
    card_owner = Card.find_by(cid: cid)

    # have no permission
    return -1 if permission_role.role != GroupToUser.role_status[:owner] && card_owner.uid != uid.to_i

    return 1
  end

  def self.delete_card(gid, cid)
    prev_card = GroupToCard.find_by(gid: gid, cid: cid)
    return false if prev_card.nil?

    prev_card.delete
    true
  end
end
