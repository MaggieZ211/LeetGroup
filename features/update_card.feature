Feature: User update card detail
  As a user
  I want to update my cards
  so that I can change and edit the card contents


Background: users in database
  Given the following users exist:
    | username  | password   | email       | uid |
    | Zzx135246 | !Zzx135246 | 123@123.com | 1   |
    | Alien     | !G1535     | zzx@163.com | 2   |

  Given the following cards exist:
    | cid | uid | title           | source   | description | status | used_time | stars | create_time              | update_time              | schedule_time |
    | 1   | 1   | Two Sum         | LeetCode | easy        | 0      | 0         | 0     | 2022-10-31T04:26:02.000Z | 2022-10-31T04:26:02.000Z | nil           |
    | 2   | 1   | Reverse Integer | LeetCode | medium      | 1      | 30        | 5     | 2022-10-31T04:36:02.000Z | 2022-10-31T06:36:02.000Z | nil           |
    | 3   | 1   | Tree Traversal  | LeetCode | hard        | 2      | 40        | 10    | 2022-10-31T03:26:02.000Z | 2022-10-31T04:16:02.000Z | nil           |

  @javascript
  Scenario: change card detail
    Given I log in with "Zzx135246" and "!Zzx135246"
    When I click the element with id "nav-card"
    And I click the element with id "nav-sub-all-cards"
    Then I should see "Two Sum"
    When I click the element with id "card-detail-btn-1"
    And I fill in "card-view-source" with "Three Sum"
    Then I click the element with id "edit-save-btn"
    Then I should see "Three Sum"

    @javascript
    Scenario: delete card detail
      Given I log in with "Zzx135246" and "!Zzx135246"
      When I click the element with id "nav-card"
      And I click the element with id "nav-sub-all-cards"
      Then I should see "Two Sum"
      When I click the element with id "card-detail-btn-1"
      And I click the element with id "delete-save-btn"
      And I click the element with id "delete-card-btn"
      Then I should not see "Two Sum"
