require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Admin Module Test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @password = '123qweadmin'
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Bug #22555 User Acct Mgmt_Role viewing Search" do
    slmc.login("exist", @password)
    slmc.go_to_roles
    slmc.get_text("breadCrumbs").should == "View Roles › Search"
  end

  it "Bug #22460 User can't add Landing page with empty fields" do
    slmc.go_to_view_landing_pages
    slmc.add_landing_page(:add => true)
    slmc.get_text("displayLabel.errors").should == "Display label required."
  end

  it "Bug #22315 Error when creating a user without email " do
    slmc.go_to_healthcare_pages
    slmc.add_user(:user_name => "jglifonea", :password => @password, :confirm_password => @password, :acct_enabled => true, :add => true)
    slmc.get_text("errorMessages").should == "Email is a required field."
  end

  it "Do not accept invalid email format " do
    slmc.go_to_healthcare_pages
    slmc.add_user(:user_name => '431_user_999', :password => @password, :confirm_password => @password, :email => 'sampleemail', :acct_enabled => true, :add => true)
    slmc.get_text("errorMessages").should == "sampleemail is an invalid e-mail address."
  end

  it "Bug #22280 Admin > Roles - Unable to Add Open role, Add button missing" do
    slmc.go_to_roles
    slmc.add_new_role(:name => "", :description => "", :landing_page => "Nursing-General Units Landing Page", :user => "jglifonea")
    slmc.get_text("name.errors").should == "Role name is a required field.\nRoles are required to be prefixed by 'ROLE_'"
  end

  it "Add New Role" do
    slmc.go_to_roles
    slmc.add_new_role(:name => "ROLE_SELENIUM_TEST", :description => "Selenium Testing", :landing_page => "Nursing-General Units Landing Page", :user => "jglifonea").should be_true
  end

  it "Edit Newly Created Role" do
    slmc.go_to_roles
    slmc.edit_role(:name => "ROLE_SELENIUM_TEST").should be_true
  end

  it "Delete Role" do
    slmc.go_to_roles
    slmc.delete_role(:name => "ROLE_SELENIUM_TEST").should be_true
  end

  it "Bug #22262 [Manage Group]-User can't add Open group, Add button missing" do
    slmc.go_to_groups
    slmc.is_element_present("css=div.buttons_container").should be_true
  end

  it "Bug #22267 [Manage Group] - Cancel button not working" do
    slmc.go_to_groups
    slmc.click "//input[@type='button' and @value='Add']", :wait_for => :element, :element => "//input[@type='submit' and @value='Cancel']"
    slmc.click "//input[@type='submit' and @value='Cancel']", :wait_for => :page
    slmc.get_text("breadCrumbs").should == "View Groups › Search"
  end

  it "Add Groups - Do not accept null values when required" do
    slmc.go_to_groups
    slmc.add_group(:add => true)
    slmc.get_text("name.errors").should == "Group name is a required field."
  end

  it "Add New Group" do
    slmc.go_to_groups
    slmc.add_group(:add => true, :group_name => "Selenium Group Test", :description => "Selenium Test Description").should be_true
  end

  it "Edit Group" do
    slmc.go_to_groups
    slmc.edit_group(:edit => true, :group_name => "Selenium Group Test", :name => "Selenium Test", 
      :description => "Selenium Test", :role => "ROLE_ADMIN", :user => "jglifonea").should be_true
  end

  it "Delete Group" do
    slmc.go_to_groups
    slmc.edit_group(:group_name => "Selenium Test", :delete => true).should == "Group Selenium Test has been deleted successfully."
  end

  it "Bug #22286 User Accout Mgmt_Add Open user error" do
    @@new_user = slmc.add_new_user_with_roles(:all_roles => true, :osf_key => "0165").should be_true
    slmc.user_search(@@new_user).should be_true
  end

  it "Should be able to delete newly created user" do
    slmc.delete_user(@@new_user).should be_true
    slmc.is_text_present("Nothing found to display.").should be_true
  end

  it "Bug #22269 [User Management] -  System is not validating upon adding Open user" do
    slmc.go_to_healthcare_pages
    slmc.click "//input[@value='Add']", :wait_for => :page
    slmc.click "btnUserSubmit", :wait_for => :page
    slmc.get_text("errorMessages").should == "Username is a required field.\nPassword is a required field.\nPassword Confirmation is a required field.\nEmail is a required field.\nOrg Structure is a required field."
  end

  it "Bug #22316 [Manage Users] - Returns UserExistsException error, if user already exists upon adding " do
    slmc.go_to_healthcare_pages
    slmc.add_user(:user_name => "jglifonea", :confirm_password => @password, :password => @password, :email => "jglifonea@slmc.com", :acct_enabled => true, :add => true)
    slmc.get_text("css=div.warning").should match /User '.*' already exists!/
  end

  it "Verifies if ROLES of admin are on the Profile" do
    slmc.go_to_profile
    my_list = slmc.verify_availability_of_roles
    (my_list.include?("ROLE_FILE_MAINTENANCE")).should be_true
    (my_list.include?("ROLE_ADMIN")).should be_true
    (my_list.include?("ROLE_USER")).should be_true
  end

  it "Bug #24275 Healthcare Admin - Yikes in View User page" do
    slmc.go_to_healthcare_pages
    slmc.is_element_present("users").should be_true
  end

  it "Bug #22217 Search functionality in User Account Mgmt" do
    slmc.go_to_healthcare_pages
    slmc.user_search('ADMIN')
    slmc.is_element_present("css=tr:contains('admin')").should be_true
    slmc.user_search('cortez')
    slmc.is_element_present("css=tr:contains('CORTEZ')").should be_true
  end

  it "Bug #22219 User Acct Mgmt_Org Code/Description in search result" do
    slmc.go_to_healthcare_pages
    slmc.is_element_present("css=th:contains('Org Code')").should be_true
  end

  it "Bug #22221 User Acct Mgmt_Reset button should clear" do
    slmc.go_to_healthcare_pages
    slmc.user_search('wellness1')
    slmc.is_element_present("css=tr:contains('wellness1')").should be_true
    slmc.user_reset_search
    slmc.is_element_present("css=tr:contains('wellness1')").should be_false
  end

  it "Bug #22320 [Manage Users] - New user is still added even 'Confirm Password' field is blank" do
    slmc.go_to_healthcare_pages
    slmc.add_user(:user_name => "user_julius", :password => @password, :email => "user_julius@exist.com", :add => true).should == "Password Confirmation is a required field.\nThe password and confirmation password do not match."
  end

  it "Adding of null Permission name is not allowed in View Permission" do
    slmc.go_to_view_permissions
    slmc.click("//input[@value='Add']", :wait_for => :page)
    slmc.click("save", :wait_for => :page)
    slmc.get_text("name.errors").should == "Permission name required."
  end

  it "Verifies that other links in Healthcare pages is working" do
    slmc.go_to_current_users
    slmc.is_text_present("The following is a list of users that have logged in and their sessions have not expired.")
    slmc.go_to_flush_cache
    slmc.is_text_present("All caches successfully flushed, returning you to your previous page in 2 seconds.")
    slmc.go_to_scheduled_batch_run
    slmc.is_element_present("scheduledTask").should be_true
    slmc.go_to_printers
    slmc.is_element_present("printers").should be_true
    slmc.go_to_jms
    slmc.is_element_present("jms").should be_true
    slmc.go_to_constants
    slmc.is_element_present("const").should be_true
    slmc.go_to_project_logging
    slmc.is_element_present("xmlBean").should be_true
    slmc.go_to_server_logs
    slmc.is_element_present("log").should be_true
    slmc.go_to_performance_logs
    slmc.is_element_present("tblPerfLog").should be_true
    slmc.go_to_net_messaging
    slmc.is_element_present("btnBroadcast").should be_true
    slmc.go_to_audit_logs
    slmc.is_element_present("txtQuery").should be_true
#    slmc.go_to_project_environment # Bug 51694 - removed system info 02/23/2012
#    slmc.is_element_present("systemInfo").should be_true
    slmc.go_to_clinical_applications
    slmc.is_element_present("clinicalAppList").should be_true
  end

  it "Bug #25408 Admin Healthcare - Yikes encountered in editing printer" do
    slmc.login("exist", @password)
    slmc.go_to_printers
    slmc.click("link=Edit", :wait_for => :page)
    slmc.click("//input[@type='submit' and @value='Save' and @name='save']", :wait_for => :page)
    slmc.is_text_present("Printers › Search").should be_true
  end

  it "Bug #25603 - file maintenace error in saving price batch" do
    slmc.click Locators::LandingPage.services_and_rates, :wait_for => :page
    slmc.get_text("breadCrumbs").should == "File Maintenance › Service"
  end

  it "Bug #26338 [Admission] View/Print Room Transfer History" do
    slmc.login("sel_adm3", "123qweuser")
    slmc.go_to_admission_page
    slmc.click "link=View/Print Room Transfer History", :wait_for => :element, :element => "//img[@alt='...']"
    slmc.type("transactionDate", "13/13/13")
    slmc.get_text("viewRoomTransferTransactionHistoryError").should == "Invalid date."
  end

#  it "Checks if MasterServiceAOP Active/Inactive is working" do
#    slmc.login("exist", "123qweadmin")
#    slmc.go_to_medicines
#    slmc.click("link=MasterServiceAOP", :wait_for => :page)
#    slmc.type("txtQuery", "Test")
#    slmc.click("//input[@type='submit' and @value='Search']", :wait_for => :page)
#    slmc.edit_master_service_aop(:master_services => true, :status => "Inactive", :master_service => "BONE IMAGING", :edit => true).should be_true
#    slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/div[6]/div/table/tbody/tr/td[4]").should == "Inactive"
#    slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/div[6]/div/table/tbody/tr/td[2]").should == "BONE IMAGING"
#    slmc.edit_master_service_aop(:units_measures => true, :status => "Active", :master_service => "BONE IMAGING", :units_measure => "BOTTLE", :edit => true).should be_true
#    slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/div[6]/div/table/tbody/tr/td[4]").should == "Active"
#    slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/div[6]/div/table/tbody/tr/td[3]").should == "BOTTLE"
#    slmc.edit_master_service_aop(:master_services => true, :master_service => "ALDOSTERONE", :units_measures => true, :units_measure => "AMPULES", :status => "Active", :edit => true).should be_true
#  end

  it "Bug #40543 [User Management] Exception error, upon accessing the roles to add a user" do
    #Expected: It should open a page wherein user can add/Remove user to the role
    slmc.login("exist", "123qweadmin")
    slmc.go_to_roles
    slmc.edit_role(:name => "ROLE_ADMIN", :user => "chriz_arms").should be_true
    slmc.type("criteria", "ROLE_ADMIN")
    slmc.click("//input[@type='submit' and @value='Search']", :wait_for => :page)
    sleep 5
    slmc.click("css=#role>tbody>tr:nth-child(1)>td:nth-child(2)", :wait_for => :page)
    slmc.add_selection("id=selCurrentUsers", "label=chriz_arms")
    slmc.click("id=btnMoveLeft")
    slmc.click "save", :wait_for => :page #after adding a user to the role
    slmc.is_text_present("Role ROLE_ADMIN has been updated successfully.").should be_true
  end

  it "Added constant property should be save in Database" do
    slmc.go_to_constants
    slmc.click("link=Last »", :wait_for => :page)
    slmc.click("link=‹ Prev", :wait_for => :page)
    slmc.click("link=Selenium Constant", :wait_for => :page)

    current_key = slmc.get_value("propertyKey")
    current_value = slmc.get_value("propertyValue")
    current_value.should == slmc.access_from_database(
      :what => "CONST_VALUE",
      :table => "CTRL_CONSTANTS",
      :column1 => "CONST_KEY",
      :condition1 => current_key)

    new_value = "Test"
    slmc.type("propertyValue", "#{new_value}")
    slmc.click("//input[@value='Save']", :wait_for => :page)
    new_value.should == slmc.access_from_database(
      :what => "CONST_VALUE",
      :table => "CTRL_CONSTANTS",
      :column1 => "CONST_KEY",
      :condition1 => current_key)
  end

  it "Admission history will show only 2 confinement history per page" do # CRITICAL PART, return the value to 5 if this fails
    slmc.go_to_constants
    slmc.click("link=5", :wait_for => :page)
    slmc.is_text_present("code.admission.confinementHistory.resultsPerPage").should be_true
    slmc.is_element_present("link=code.admission.confinementHistory.resultsPerPage").should be_true
    slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/table/tbody/tr[16]/td[2]").should == "5"

    slmc.click("link=code.admission.confinementHistory.resultsPerPage", :wait_for => :page)
    slmc.type("propertyValue", "2")
    slmc.click("//input[@value='Save']", :wait_for => :page)

    slmc.login("sel_adm3", "123qweuser")
    slmc.admission_search(:pin => "1108008820") # TAN, Kate Venice Go
    slmc.click("link=View Confinement History")
    sleep 5
    (slmc.get_css_count("css=#confinementHistoryRows>tr").to_i).should == (2 + 1) # +1 for the empty <tr> field before the actual list

    slmc.login("exist", "123qweadmin")
    slmc.go_to_constants
    slmc.click "link=5", :wait_for => :page
    slmc.click("link=code.admission.confinementHistory.resultsPerPage", :wait_for => :page)
    slmc.type("propertyValue", "5")
    slmc.click("//input[@value='Save']", :wait_for => :page)

    slmc.login("sel_adm3", "123qweuser")
    slmc.admission_search(:pin => "1108008820") # TAN, Kate Venice Go
    slmc.click("link=View Confinement History")
    sleep 5
    (slmc.get_css_count("css=#confinementHistoryRows>tr").to_i).should == (5 + 1) # +1 for the empty <tr> field before the actual list
  end

end