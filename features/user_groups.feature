Feature: usergroups

  Scenario: User Groups (no groups, list)
    Given I am logged in as "admin"
    When I go to the credentials page
    Then I should see "User groups"
    And I should see no user groups


  Scenario: create user group
    Given I am logged in as "admin"
    When I go to the new user group page
    And I fill in "user_group[name]" with "Leonardo"
    And I press "Create"
    Then I should see "Leonardo has been created"
    And I should see "Leonardo"
    When I go to the user group "Leonardo"
    Then I should see "Leonardo"
    And I should see "Personal group"
    And I should see "no entities"


  Scenario: rename user group
    Given I am logged in as "admin"
    And the user group "Leonardo"
    When I go to the user groups page
    And I follow "Pen"
    And I fill in "user_group[name]" with "Raffael"
    And I press "Save"
    Then I should see "Raffael"
    And I should not see "Leonardo"

  @javascript
  Scenario: delete user group
    Given I am logged in as "admin"
    And the user group "Leonardo"
    When I go to the user groups page
    And I follow the delete link within "tr.user_group"
    Then I should be on the user groups page
    Then I should not see "Leonardo"


  Scenario: share usergroup
    Given I am logged in as "admin"
    And the user group "Leonardo"
    When I go to the user groups page
    And I follow "Private"
    Then I should see "Leonardo has been shared"
    When I go to the shared user groups page
    Then I should see "Leonardo"


  Scenario: unshare usergroup
    Given I am logged in as "admin"
    And the shared user group "Leonardo"
    When I go to the user groups page
    And I follow "Public"
    Then I should be on the user groups page
    Then I should see "Leonardo is not shared anymore"
    When I go to the shared user groups page
    Then I should not see "Leonardo"


  Scenario: publish usergroup
    Given I am logged in as "admin"
    And the user group "Leonardo"
    When I go to the publishments page
    And I follow "Plus"
    And I fill in "publishment[name]" with "Leoforall"
    And I select "Leonardo" from "publishment[user_group_id]"
    And I press "Create"
    Then I should see "Leoforall"
    And I should see "pub" within "table.kor_table"

  
  @javascript
  Scenario: unpublish usergroup
    Given I am logged in as "admin"
    And the user group "Leonardo" published as "Leoforall"
    When I go to the publishments page
    And I follow the delete link within "table.kor_table tr:nth-child(2)"
    Then I should see "no published groups found"
    
    
  Scenario: Renew a published usergroup
    Given I am logged in as "admin"
    And the user group "Leonardo" published as "Leonforall"
    And the entity "Mona Lisa" of kind "Werk/Werke"
    When I go to the entity page for "Mona Lisa"
    And I go to the publishments page
    And I follow "Stop watch" within the row for "publishment" "Leonforall"
    Then I should be on the publishments page
    
    
  @javascript
  Scenario: Transfer a shared group to the clipboard
    Given I am logged in as "admin"
    And Leonardo, Mona Lisa and a medium as correctly related entities
    And "admin" has a shared user group "MyStuff"
    And the first medium is inside user group "MyStuff"
    And user "john" is allowed to "view/edit" collection "Default" through credential "Freelancers"
    And I re-login as "john"
    And I am on the shared user groups page
    When I follow "MyStuff"
    Then I should see "Leonardo da Vinci"
    When I follow "Target"
    And I go to the clipboard
    Then I should see element "img" within ".canvas"
    

  @javascript
  Scenario: Add an authority group's entities to the clipboard as a normal user
    Given user "jdoe" is allowed to "view" collection "default" through credential "users"
    And I am logged in as "jdoe"
    And the entity "Mona Lisa" of kind "artwork/artworks"
    And the entity "Leonardo" of kind "person/people"
    And the authority group "some"
    And the entity "Leonardo" is in authority group "some"
    And the entity "Mona Lisa" is in authority group "some"
    When I go to the authority group page for "some"
    And I click element "[data-name=target]" within ".section_panel .header"
    Then I should see "entities have been copied to the clipboard"
    When I go to the clipboard
    Then I should see "Mona Lisa"
    And I should see "Leonardo"
    
  @javascript
  Scenario: show a user group without permissions
    Given the user "mrossi"
    And "mrossi" has a user group "My selection"
    And I am logged in as "jdoe"
    When I go to the user group page for "My selection"
    Then I should see "Access denied"