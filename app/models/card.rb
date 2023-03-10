class Card < ActiveRecord::Base
  @@card_status = { active: 0, archived: 1, finished: 2}

  def self.card_status
    @@card_status
  end

  def self.create_card(uid, title, source, description)
    new_card = create(uid: uid, title: title, source: source, description: description, schedule_time: nil, status: 0,
                      stars: 0, used_time: 0, create_time: Time.now, update_time: Time.now)
    new_card.cid
  end

  def self.view_card(uid, status, page_size, offset, sort_by, sort_type)
    @cards = Card.where(uid: uid)
    @cards = @cards.where(status: status) unless status == 3

    if !sort_by.nil? && sort_type == 'asc'
      @cards = @cards.order(sort_by => :asc)
    end
    if !sort_by.nil? && sort_type == 'desc'
      @cards = @cards.order(sort_by => :desc)
    end

    total_size = @cards.count

    @cards = @cards.limit(page_size).offset(offset * page_size)

    total_page = total_size / page_size
    if total_size % page_size != 0
      total_page += 1
    end
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


  def self.view_card_detail(cid, uid)
    if Card.find_by_uid(uid).nil?
      nil
    else
      Card.find_by(uid: uid, cid: cid)
    end
  end

  def self.get_card_statistics(uid, status, period)
    case period
    when 'month'
      cur_date = Date.today - Date.today.mday
      prev_date = cur_date << 1
    when 'week'
      cur_date = Date.today - Date.today.wday
      prev_date = cur_date - 7
    else
      cur_date = Date.today
      prev_date = cur_date - 1
    end

    if status == 2 # today, this week, this month finished cards
      cur_period_cards = Card.where(status: @@card_status[:finished], uid: uid)
                             .where('update_time >= ?', cur_date.to_time)
      prev_period_cards = Card.where(status: @@card_status[:finished], uid: uid)
                              .where('update_time >= ?', prev_date.to_time)
                              .where('update_time < ?', cur_date.to_time)
    else # today created cards
      cur_period_cards = Card.where(uid: uid).where('create_time >= ?', cur_date.to_time)
      prev_period_cards = Card.where(uid: uid).where('create_time >= ?', prev_date.to_time)
                              .where('create_time < ?', cur_date.to_time)
    end

    if prev_period_cards.count.zero?
      [cur_period_cards.count, 'New', 'text-success', 'icon-box-success', 'mdi-arrow-top-right']
    else
      percent = "#{((cur_period_cards.count - prev_period_cards.count).to_d / prev_period_cards.count * 100).to_i}%"
      if cur_period_cards.count >= prev_period_cards.count
        [cur_period_cards.count, "+#{percent}", 'text-success', 'icon-box-success', 'mdi-arrow-top-right']
      else
        [cur_period_cards.count, percent, 'text-danger', 'icon-box-danger', 'mdi-arrow-bottom-left']
      end
    end
  end
end
