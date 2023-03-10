module CardHelper
  def self.check_title_empty(title)
    !title.empty?
  end

  def self.check_title_length(title)
    title.size <= 50
  end

  def self.check_source_length(source)
    source.size <= 100
  end

  def self.check_description_length(description)
    description.size <= 300
  end

  def self.create_card(uid, title, source, description)
    cid = Card.create_card(uid, title, source, description)
    UserToCard.create(uid: uid, cid:cid)
    true
  end

  def self.update_card(card)
    prev_card = Card.find_by(uid: card.uid, cid: card.cid)
    return false if prev_card.nil?

    Card.columns.each do |c|
      type = c.name
      val = card.method(type).call
      prev_card.method("#{type}=").call val unless val.nil?
    end
    prev_card.save
    true
  end

  def self.delete_card(uid, cid)
    prev_card = Card.find_by(uid: uid, cid: cid)
    return false if prev_card.nil?

    prev_card.delete
    true
  end

  def self.share_card(gid, cid)
    if GroupToCard.exists?(gid: gid, cid: cid)
      return false
    else
      GroupToCard.create(cid: cid, gid: gid)
    end
    true
  end

  def self.copy_card(copyTo, cid)
    this_card = Card.find_by(cid: cid)
    return false if this_card.nil?
    self.create_card(copyTo, this_card.title, this_card.source, this_card.description)
    true
  end

  def self.change_status(uid, cid, status)
    this_card = Card.find_by(uid: uid, cid: cid)
    return false if this_card.nil?
    this_card.status = status
    this_card.save
    true
  end

  def self.star(cid)
    this_card = Card.find_by(cid: cid)
    return -1 if this_card.nil?
    this_card.stars += 1
    this_card.save
    return this_card.stars
  end
end
