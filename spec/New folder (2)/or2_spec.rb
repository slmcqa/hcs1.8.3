require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Stluke's OR test case" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @or_patient = Admission.generate_data
    @password = "123qweuser"
    @soa_month = Time.now.strftime("%m")
    @dr_user = "sel_dr6"
    @pba_user = "sel_pba19"
    @or_user = "sel_or10" #with role spu manager
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates patient for OR" do
    slmc.login("or23", @password).should be_true
    @@slmc_or_pin = slmc.or_create_patient_record(@or_patient.merge(:admit => true, :gender => 'F')).gsub(' ','').should be_true
  end

  it "Patient Search parameters" do
    slmc.su_patient_search.should be_true
  end

  it "Displays error message when search criteria is not filled out" do
    slmc.display_error_message.should be_true
  end

  it "Displays patient banner in Order List page" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Order List", :pin => @@slmc_or_pin)
    slmc.check_patient_banner.should be_true
  end

  # Feature 45374
  it "Verify that Frequency is automatically set to STAT-NOW" do
    slmc.occupancy_pin_search(:pin => @@slmc_or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@slmc_or_pin)
    slmc.search_order(:description => "040004334", :drugs => true).should be_true
    slmc.add_returned_order(:drugs => true, :stat => true, :description => "040004334", :doctor => "6726")
    slmc.get_value("priorityCode").should == "on"
    slmc.get_selected_label("frequencyCode").should == "STAT - NOW"
  end

  it "Verify that Frequency is automatically set to default value when STAT checkbox is not checked" do
    slmc.click("priorityCode")
    slmc.get_selected_label("frequencyCode").should == ""
  end

  it "Verify that STAT checkbox is automatically checked" do
    slmc.select("frequencyCode", "STAT - NOW")
    slmc.get_value("priorityCode").should == "on"
  end

  it "Verify that STAT checkbox is automatically unchecked" do
    slmc.select("frequencyCode", "EVERY OTHER DAY")
    slmc.get_value("priorityCode").should == "off"
  end

  it "Verify that STAT and Frequency settings are retained in Edit Order Page" do
    slmc.add_returned_order(:drugs => true, :stat => true, :description => "040004334", :add => true, :doctor => "6726").should be_true
    slmc.click_order("*BABYHALER")
    slmc.get_value("priorityCode").should == "on"
    slmc.get_selected_label("frequencyCode").should == "STAT - NOW"
    slmc.click("//input[@value='Save']", :wait_for => :page)
    slmc.submit_added_order(:validate => true)
    slmc.get_text("css=#drugOrderCartDetails>tbody>tr>td:nth-child(14)").should == "STAT - NOW"
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Verify that STAT and Frequency settings are retained in Order Cart Page and reflected in Order List" do
    slmc.occupancy_pin_search(:pin => @@slmc_or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order List", @@slmc_or_pin)
    slmc.click("//a[@class='display_more']/img", :wait_for => :visible, :element => "//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[3]")
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[3]").should == "STAT - NOW"
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[4]").should == "REMARKS"
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[5]").should == "or23"
  end

  it "Should not add special purchase without description" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@slmc_or_pin)
    slmc.search_order(:special => true)
    slmc.add_returned_order(:special => true, :special_description => " ", :add => true).should == "Description is a required field."
  end

  it "Displays confirmation message after saving ordered item" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@slmc_or_pin)
    slmc.search_order(:special => true)
    slmc.add_returned_order(:special => true, :special_description => "SPECIAL ITEM", :add => true)
    slmc.er_submit_added_order.should be_true
    slmc.validate_item("SPECIAL ITEM").should be_true
    slmc.check_confirmation_message_after_validation.should be_true
  end

  it "Should display error message when required fields are not filled out when adding item - ITEM DESCRIPTION" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@slmc_or_pin)
    slmc.search_order(:special => true)
    slmc.add_returned_order(:special => true, :special_description => " ", :add => true)
    slmc.get_error_message.should be_true
 end

  it "Displays Clinical Diet fields/parameters" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.check_clinical_diet_fields.should be_true
  end

  it "Clinical Diet buttons are available" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.is_element_present("//input[@value='Add']").should be_true
    slmc.is_element_present("//input[@value='Delete Row']").should be_true
    slmc.is_element_present("//input[@value='Save']").should be_true
    slmc.is_element_present("//input[@value='View Diet History']").should be_false
    slmc.is_element_present("//input[@value='Cancel']").should be_true
  end

  it "User should be able to select/unselect the check box for allergy description " do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.add_food_allergy
    slmc.click("actual-chk-0")
    slmc.get_value("actual-chk-0").should == "on"
    slmc.click("actual-chk-0")
    slmc.get_value("actual-chk-0").should == "off"
  end

  it "Delete allergy from grid" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.add_food_allergy
    desc = slmc.get_text("actual-description-0")
    slmc.click("actual-chk-0")
    slmc.click("//input[@value='Delete Row']", :wait_for => :ajax)
    sleep 2
    slmc.is_text_present(desc).should be_false
  end

  it "System should allow to select and unselect check box for Disposable Tray" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.select_unselect_disposable_tray.should be_true
  end

#  it "Reset button - clears all data entered by the user" do # removed reset button as per venz 1.5.1 iter2
#    slmc.go_to_occupancy_list_page
#    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
#    slmc.reset_input_diet.should be_true
#  end

  it "Add and save clinical diet" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.add_clinical_diet(:save => true).should == "Patient diet COMPUTED DIET successfully created."
  end

  it "Upon adding diet, View Diet History button should be on page" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.is_element_present("//input[@value='Update']").should be_true
    slmc.is_element_present("//input[@value='Delete Row']").should be_true
    slmc.is_element_present("//input[@value='Save']").should be_false
    slmc.is_element_present("//input[@value='View Diet History']").should be_true
    slmc.is_element_present("//input[@value='Cancel']").should be_true
  end

  it "Update Diet" do
    slmc.add_clinical_diet(:diet => "COMPUTED DIET", :food_preference => "Preference Sample", :height => "161", :weight => "57", :update => true).should be_true
  end

  it "Displays patient diet history" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.view_diet_history.should be_true
  end

  it "Items displayed in the grid are links to Patient Diet Details page" do
    slmc.check_links.should be_true
  end

  it "Click Back button - system should redirect to clinical diet page" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.view_diet_history
    slmc.click_back_button.should be_true
  end

  it "Displays patient diet details" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.view_diet_history
    slmc.display_patient_diet_details.should be_true
  end

  it "Directs to Clinical Diet Page when Close button is clicked from Patient Diet Details page" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.view_diet_history
    slmc.display_patient_diet_details
    slmc.click_close_button.should be_true
  end

  it "Directs to Occupancy List page when Cancel button is clicked from Clinical Diet page" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@slmc_or_pin)
    slmc.click_cancel_button.should be_true
  end

  it "Encoded Food Allergies can be viewed from FND" do
    slmc.login("sel_fnb2", @password).should be_true
    slmc.go_to_fnb_landing_page
    slmc.go_to_fnb(:page => "Patient Diet History", :pin => @@slmc_or_pin)
    slmc.diet_history_in_fnb.should be_true
  end

  it "Login to OR from FNB" do
    slmc.login("or23", @password).should be_true
  end

  it "Displays patient banner in Order Page" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Order Page", :pin => @@slmc_or_pin)
    slmc.check_patient_banner.should be_true
  end

  it "Clinical Order page contains: Patient Banner, Item Search, Input fields for Order details, and Order Cart" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Order Page", :pin => @@slmc_or_pin)
    slmc.check_clinical_order_page_fields.should be_true
  end

  it "Clinical Discharge patient" do
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@slmc_or_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
  end

  it "Display window for defer" do
    slmc.occupancy_pin_search(:pin => @@slmc_or_pin)
    slmc.is_visible("deferPopupDiv").should be_false
    slmc.select("userAction#{@@slmc_or_pin}", "Defer Discharge")
    slmc.click Locators::NursingSpecialUnits.submit_button_spu
    slmc.is_visible("deferPopupDiv").should be_true
  end

  it "Submit defer" do
    slmc.occupancy_pin_search(:pin => @@slmc_or_pin)
    slmc.defer_clinical_discharge(:outpatient => true, :pin => @@slmc_or_pin).should be_true
  end

  it "Display available action buttons in occupancy list" do
    slmc.get_select_options("userAction#{@@slmc_or_pin}").should == ["Update Patient Info", "Update Registration", "Doctor and PF Amount", "Order Page", "Order List", "Clinical Diet", "Discharge Instructions\302\240", "Checklist Order", "Patient Results", "Notice of Death", "Print Label Sticker"]
  end

  it "Select & go to patient's notice of death" do # Create Notice of Death in Outpatient Patient
    slmc.go_to_su_page_for_a_given_pin("Notice of Death", @@slmc_or_pin)
    slmc.notice_of_death(:save => true, :print => true).should == "Notice of Death succesfully saved (patient pin: #{@@slmc_or_pin})"
    slmc.is_element_present("criteria").should be_true
    slmc.or_notice_of_death(:pin => @@slmc_or_pin).should be_true
  end

  it "Verify that “Reprint Discharge Notice Slip” is available upon clinical discharge" do
    slmc.login(@dr_user, @password).should be_true # ROLE_LATE_TRANSACTION
    @@dr_pin = slmc.or_nb_create_patient_record(Admission.generate_data.merge(:admit => true, :org_code => "0170", :gender => 'F')).gsub(' ', '')
    slmc.occupancy_pin_search(:pin => @@dr_pin)
    slmc.get_select_options("userAction#{@@dr_pin}").include?("Reprint Discharge Notice Slip").should be_false
    @@visit_no2 = slmc.clinically_discharge_patient(:pin => @@dr_pin, :outpatient => true, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.occupancy_pin_search(:pin => @@dr_pin)
    slmc.get_select_options("userAction#{@@dr_pin}").include?("Reprint Discharge Notice Slip").should be_true
  end

  it "Verify that “Reprint Discharge Notice Slip” is not available upon billing discharge" do
    slmc.login("sel_pba7", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS").should be_true
    slmc.login(@dr_user, @password).should be_true
    slmc.occupancy_pin_search(:pin => @@dr_pin)
    slmc.get_select_options("userAction#{@@dr_pin}").include?("Reprint Discharge Notice Slip").should be_false
  end

  it "Verify that “Reprint Gate Pass” is available upon physical discharge when ROLE_LATE_TRANSACTION is added" do
    slmc.login(@dr_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@dr_pin, :visit_no => @@visit_no2)
    slmc.occupancy_pin_search(:pin => @@dr_pin, :discharged => true)
    slmc.get_text("css=#occupancyList>tbody>tr>td:nth-child(8)").should == "DISCHARGED"
    slmc.get_select_options("userAction#{@@dr_pin}").include?("Reprint Gate Pass").should be_true
  end

  it "Verify that “Reprint Gate Pass” is available upon physical discharge when ROLE_LATE_TRANSACTION is not available" do
    slmc.login("sel_or1", @password).should be_true # sel_or1 does not have ROLE_LATE_TRANSACTION
    slmc.occupancy_pin_search(:pin => @@dr_pin, :discharged => true)
    slmc.get_select_options("userAction#{@@dr_pin}").include?("Reprint Gate Pass").should be_true
  end

  it "Verify that “Reprint Discharge Notice Slip” is not available when clinical discharge is deferred" do
    slmc.login(@dr_user, @password).should be_true
    @@dr_pin = slmc.or_nb_create_patient_record(Admission.generate_data.merge(:admit => true, :gender => 'F', :org_code => "0170")).gsub(' ', '')
    slmc.occupancy_pin_search(:pin => @@dr_pin)
    slmc.clinically_discharge_patient(:pin => @@dr_pin, :outpatient => true, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.occupancy_pin_search(:pin => @@dr_pin)
    slmc.defer_clinical_discharge(:pin => @@dr_pin, :outpatient => true).should be_true
    slmc.occupancy_pin_search(:pin => @@dr_pin)
    slmc.get_select_options("userAction#{@@dr_pin}").include?("Reprint Discharge Notice Slip").should be_false
  end

  it "Feature #46170 - Verify that Validation pop-up is displayed upon Checklist Order Adjustment when user does not have ROLE_SPU_NURSING_MANAGER" do
    slmc.login("or23", @password).should be_true
    @@or_pin = slmc.or_create_patient_record(Admission.generate_data.merge(:admit => true)).gsub(' ','').should be_true

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "5979")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.search_soa_checklist_order(:pin => @@or_pin)
    slmc.adjust_checklist_order

    slmc.type "oif_entity_finder_key","POWER BONE SHAVING"
    slmc.click "search"
    sleep 2
    slmc.click Locators::NursingSpecialUnits.order_adjustment_searched_service_code
    slmc.click "_addButton"
    sleep 2
    slmc.click '_submitForm'
    (slmc.is_element_present"userEntryPopup").should be_true
  end

  it "Feature #46170 - Verify that invalid or incorrect comibination of username and password is not accepted" do
    slmc.type"usernameInputBox","sel_0164_validator"
    slmc.type"passwordInputBox","@@@@@@@"
    slmc.click("//html/body/div[8]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "Invalid username/password."
  end

  it "Feature #46170 - Verify that username and password with no ROLE_SPU_NURSING_MANAGER is not accepted" do
    slmc.type"usernameInputBox","adm1"
    slmc.type"passwordInputBox","123qweuser"
    slmc.click("//html/body/div[8]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "User adm1 is not allowed to validate."
  end

  it "Feature #46170 - Verify that username and password with ROLE_SPU_NURSING_MANAGER but different Org Code is not accepted" do
    slmc.type "usernameInputBox", "sel_0165_validator"
    slmc.type "passwordInputBox", "123qweuser"
    slmc.click("//html/body/div[8]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "User sel_0165_validator is not allowed to validate."
  end

  it "Feature #46170 - Verify that username and password with ROLE_SPU_NURSING_MANAGER and the same Org Code is accepted" do
    slmc.type"usernameInputBox","sel_0164_validator"
    slmc.type"passwordInputBox","123qweuser"
    slmc.click("//html/body/div[8]/div[11]/div/button[2]", :wait_for => :page)
  end

  it "Feature #46170 - Verify that Validation pop-up is displayed upon Checklist Order Cancellation when user does not have ROLE_SPU_NURSING_MANAGER" do
    slmc.search_soa_checklist_order(:pin => @@or_pin)
    slmc.click "link=Cancel"
    sleep 5
    (slmc.is_element_present"userEntryPopup").should be_true
  end

  it "Feature #46170 - Verify that invalid or incorrect comibination of username and password is not accepted" do
    slmc.type "usernameInputBox", "@@@@@@@"
    slmc.type "passwordInputBox", "123qweuser"
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "Invalid username/password."
  end

  it "Feature #46170 - Verify that username and password with no ROLE_SPU_NURSING_MANAGER is not accepted" do
    slmc.type "usernameInputBox", "adm1"
    slmc.type "passwordInputBox", "123qweuser"
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 5
    slmc.get_text("userValidationErr").should == "User adm1 is not allowed to validate."
  end

  it "Feature  #46170 -Verify that username and password with ROLE_SPU_NURSING_MANAGER but different Org Code is not accepted" do
    slmc.type "usernameInputBox", "sel_0165_validator"
    slmc.type "passwordInputBox", "123qweuser"
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "User sel_0165_validator is not allowed to validate."
  end

  it "Feature #46170 - Verify that username and password with ROLE_SPU_NURSING_MANAGER and the same Org Code is accepted" do
    slmc.type "usernameInputBox", "sel_0164_validator"
    slmc.type "passwordInputBox", "123qweuser"
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 2
    (slmc.is_element_present"orderCancelForm").should be_true

    slmc.select"reason","CANCELLATION - ORDER"
    slmc.click"btnOK", :wait_for => :page
  end

  it "Feature #46170 - Verify that Validation is not required upon Checklist Order Adjustment when user has ROLE_SPU_NURSING_MANAGER" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)

    @@item_code = slmc.search_service(:procedure => true, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.add_returned_service(:item_code => @@item_code, :description => "USE OF ANESTHESIA MACHINE WITH VENTILATOR")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "5979")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.search_soa_checklist_order(:pin => @@or_pin)
    slmc.adjust_checklist_order
    slmc.type "oif_entity_finder_key","APPENDECTOMY"
    slmc.click "search"
    sleep 2
    slmc.click Locators::NursingSpecialUnits.order_adjustment_searched_service_code
    slmc.click "_addButton"
    sleep 2
    slmc.click '_submitForm', :wait_for => :page #no validation popup
  end

  it "Feature #46170 - Verify that Validation is not required upon Checklist Order Cancellation when user has ROLE_SPU_NURSING_MANAGER" do
    slmc.search_soa_checklist_order(:pin => @@or_pin)
    slmc.click "link=Cancel"
    sleep 2
    (slmc.is_element_present"orderCancelForm").should be_true   #no validation popup

    slmc.select"reason","CANCELLATION - ORDER"
    slmc.click"btnOK", :wait_for => :page
  end

end