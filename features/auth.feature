Feature: Authentication and Authorization
  In order to have different responsabilities
  As a User
  I should have to authenticate and be authorized accordingly
  
  
  Scenario: Reset password with wrong email address
    When I go to the login page
    And I follow "forgot your password?"
    And I fill in "email" with "does@not.exist"
    And I press "reset"
    Then I should see "could not be found"


  Scenario: Reset password with correct email address
    Given the user "jdoe"
    When I go to the login page
    And I follow "forgot your password?"
    And I fill in "email" with "jdoe@example.com"
    And I press "reset"
    Then I should see "A new passowrd has been created and sent to the entered email address"
    
    
  Scenario: Reset admin password
    When I go to the login page
    And I follow "forgot your password?"
    And I fill in "email" with "admin@coneda.net"
    And I press "reset"
    Then I should see "could not be found"
  

  @javascript  
  Scenario: Login after a session timeout
    Given I am logged in as "admin"
    And the entity "Mona Lisa" of kind "Werk/Werke"
    And the session has expired
    When I go to the entity page for "Mona Lisa"
    Then I should not see "Mona Lisa"
    And I should see "Access denied"
    When I follow "login"
    Given the session is not forcibly expired anymore
    When I fill in "username" with "admin"
    And I fill in "password" with "admin"
    And I press "Login"
    And I should see "Mona Lisa"
    Then I should be on the entity page for "Mona Lisa"

  
  Scenario: see credentials without authorization
    Given I am logged in as "john"
    When I go to the credentials page
    Then I should see "Access denied"


  Scenario: delete credential without authorization	
    Given I am logged in as "john"
    And the credential "Freaks" described by "The KOR-Freaks"
    When I go to the edit page for "credential" "Freaks"
    Then I should see "Access denied"

    
  @javascript
  Scenario: Don't show group menu when not logged in
    Given the user "guest"
    And I am on the root page
    Then I should not see "Groups"

