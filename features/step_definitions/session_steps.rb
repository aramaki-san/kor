Given /^the user "([^\"]*)"$/ do |user|
  unless User.exists? :name => user
    FactoryGirl.create :user, :name => user, :password => user, :email => "#{user}@example.com"
  end
end

Given /^the user "([^\"]*)" is a "([^\"]*)"$/ do |user, role|
  step "the user \"#{user}\""
  user = User.find_by_name(user)
  user.send("#{role}=".to_sym, true)
  user.save
end

Given /^the user "([^\"]*)" has password "([^\"]*)"$/ do |user, password|
  user = User.find_by_name(user)
  user.update_attributes :password => password, :make_personal => user.personal?, :terms_accepted => true
end

Given /^the user "([^\"]*)" with credential "([^\"]*)"$/ do |user, credential|
  step "the credential \"#{credential}\""
  step "the user \"#{user}\""
  user = User.find_by_name(user)
  credential = Credential.find_by_name(credential)
  user.groups << credential
  user.save
end

Given /^I am logged in as "([^\"]*)"/ do |user|
  step "the user \"#{user}\""
  
  step "I go to the login page"
  step "I fill in \"username\" with \"#{user}\""
  step "I fill in \"password\" with \"#{user}\""
  step "I press \"Login\""
  sleep 1
end

Given /^I re\-login as "([^"]*)"$/ do |user|
  step "I log out"
  step "I am logged in as \"#{user}\""
end

Given /^I log out$/ do
  step "I click element \"a[href='/logout']\""
end

When /^"([^\"]*)" is selected as current entity$/ do |name|
  step "I mark \"#{name}\" as current entity"
end

When /^I mark "([^\"]*)" as current entity$/ do |name|
  step "I am on the entity page for \"#{name}\""
  step "I should see \"#{name}\""
  find("a[kor-to-current]").click
  step "I should see \"has been marked as current entity\""
end

When(/^I put "(.*?)" into the clipboard$/) do |name|
  step "I am on the entity page for \"#{name}\""
  step "I should see \"#{name}\""
  sleep 1
  find("a[kor-to-clipboard]").click
  step "I should see \"has been copied to the clipboard\""
end

Given /^the session has expired$/ do
  allow_any_instance_of(ApplicationController).to receive(:session_expired?).and_return(true)
end

Given /^the session is not forcibly expired anymore$/ do
  allow_any_instance_of(ApplicationController).to receive(:session_expired?).and_call_original
end

Given /^"([^\"]*)" is expanded$/ do |folded_menu_name|
  case folded_menu_name
  when "Administration" 
    click_link "Administration"
  when "Groups"
    click_link "Groups"
  end
end

Given /^all entities of kind "([^\"]*)" are in the clipboard$/ do |kind|
  Kind.find_by_name(kind.split("/").first).entities.each do |entity|
    if entity.is_medium?
      step "I go to the entity page for medium \"#{entity.id}\""
    else
      step "I go to the entity page for \"#{entity.name}\""
    end
    step "I should see \"#{entity.name}\""
    sleep 2
    find("a[kor-to-clipboard]").click
    step "I should see \"has been copied to the clipboard\""
  end
end

When(/^I save a screenshot$/) do
  page.save_screenshot "screenshot.png"
end

When(/^I call the inspector$/) do
  page.driver.debug
end
