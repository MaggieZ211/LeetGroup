require 'rails_helper'

describe CardToCommentHelper do
  describe 'show comments' do
    before(:each) do
      UserProfile.delete_all
      UserProfile.create(username: 'MaggieZ', avatar: '/avatar/1..jpg', status: 0, uid: 1)
      UserProfile.create(username: 'Zll211', avatar: '/avatar/2..jpg', status: 0, uid: 2)
      CardToComment.create(cid: 1, uid: 1, comment_id: 1, content: 'This problem appears in Google OA', create_time: '2022-10-31T04:26:02.000Z')
      CardToComment.create(cid: 2, uid: 2, comment_id: 2, content: 'should use binary search', create_time: '2022-10-31T05:26:02.000Z')
      CardToComment.create(cid: 1, uid: 2, comment_id: 3, content: 'should use binary search', create_time: '2022-10-31T06:26:02.000Z')
    end

    it 'should return all comments correctly and ordered by create_time' do
      comments = CardToCommentHelper.show_comment(1)
      expect(comments.size).to eq 2
      comment1 = comments[0]
      comment2 = comments[1]
      expect_comment1 = {
        username: 'MaggieZ',
        avatar: '/avatar/1..jpg',
        content: 'This problem appears in Google OA',
        create_time: '2022-10-31'
      }
      expect_comment2 = {
        username: 'Zll211',
        avatar: '/avatar/2..jpg',
        content: 'should use binary search',
        create_time: '2022-10-31'
      }
      expect(comment1).to eq expect_comment1.to_json
      expect(comment2).to eq expect_comment2.to_json
    end

    it 'should set username as user_not_existed if the user is not existed' do
      UserProfile.delete_by(uid: 2)
      comments = CardToCommentHelper.show_comment(2)
      expect(comments.size).to eq 1
      comment = comments[0]
      expect_comment = {
        username: 'user_not_existed',
        avatar: nil,
        content: 'should use binary search',
        create_time: '2022-10-31'
      }
      expect(comment).to eq expect_comment.to_json
    end
  end
end
