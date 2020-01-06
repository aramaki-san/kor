Feature: User administration
  In order to limit access to certain users
  As a user admin
  I should be able to administer users
  

  @javascript
  Scenario: Delete a user
    Given I am logged in as "admin"
    And the user "john"
    When I go to the users page
    And I follow the delete link within the row for "user" "john"
    Then there should be no "user" named "john"
    Then I should be on the users page
    

  @javascript
  Scenario: Delete a user which has shared user groups
    Given I am logged in as "admin"
    And the user "john"
    And "john" has a shared user group "My Group"
    When I go to the users page
    And I follow the delete link within the row for "user" "john"
    Then there should be no "UserGroup" named "My Group"
    
    
  Scenario: Have a sorted list of credentials within the user form
    Given I am logged in as "admin"
    And the credential "AAAs"
    When I go to the users page
    And I follow "Plus"
    Then I should see "AAAs" before "admins"


  @javascript
  Scenario: Show the user's API key
    Given I am logged in as "admin"
    And the user "jdoe"
    And I go to the users page
    And I follow "Pen" within the row for "user" "jdoe"
    Then I should see "jdoe"'s API Key


  @javascript
  Scenario: Accept terms of use
    Given the user "jdoe"
    Given the user "jdoe" has not accepted the terms of use
    And I am logged in as "jdoe"
    Then I should see "Terms of use"
    When I follow "accept terms"
    Then I should see "You have accepted the terms of use"
