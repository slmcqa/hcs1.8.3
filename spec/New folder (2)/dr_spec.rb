require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Delivery Room Scenarios and Samples" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @dr_user = "sel_dr7"
    @pba_user = "sel_pba19"
    @password = "123qweuser"
    @dr_user1 = "sel_dr10" #with role nursing manager
    @adm_user = "sel_adm9"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Create DR patient" do
    slmc.login(@dr_user, @password).should be_true
    @@dr_pin = slmc.or_create_patient_record(Admission.generate_data.merge!(:admit => true, :org_code => "0170", :gender => 'F')).gsub(' ', '')
  end

  # Feature 45374
  it "Verify that Frequency is automatically set to STAT-NOW" do
    slmc.occupancy_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@dr_pin)
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
    slmc.er_submit_added_order(:validate => true, :username => "sel_dr_validator").should be_true
    slmc.get_text("css=#drugOrderCartDetails>tbody>tr>td:nth-child(14)").should == "STAT - NOW"
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Verify that STAT and Frequency settings are retained in Order Cart Page and reflected in Order List" do
    slmc.occupancy_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Order List", @@dr_pin)
    slmc.click("//a[@class='display_more']/img", :wait_for => :visible, :element => "//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[3]")
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[3]").should == "STAT - NOW"
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[4]").should == "REMARKS"
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[5]").should == @dr_user
  end

  it "Verify that “Reprint Discharge Notice Slip” is available upon clinical discharge" do
    slmc.login(@dr_user, @password).should be_true
    slmc.occupancy_pin_search(:pin => @@dr_pin)
    slmc.get_select_options("userAction#{@@dr_pin}").include?("Reprint Discharge Notice Slip").should be_false
    slmc.clinically_discharge_patient(:pin => @@dr_pin, :outpatient => true, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.occupancy_pin_search(:pin => @@dr_pin)
    slmc.get_select_options("userAction#{@@dr_pin}").include?("Reprint Discharge Notice Slip").should be_true
  end

  # Feature 45876
  it "Verify that “Reprint Discharge Notice Slip” is not available upon billing discharge" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no2 = slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
    slmc.login(@dr_user, @password).should be_true
    slmc.occupancy_pin_search(:pin => @@dr_pin)
    slmc.get_select_options("userAction#{@@dr_pin}").include?("Reprint Discharge Notice Slip").should be_false
  end

  it "Verify that “Reprint Gate Pass” is available upon physical discharge when ROLE_LATE_TRANSACTION is added" do
    slmc.or_print_gatepass(:pin => @@dr_pin, :visit_no => @@visit_no2)
    slmc.occupancy_pin_search(:pin => @@dr_pin, :discharged => true)
    slmc.get_text("css=#occupancyList>tbody>tr>td:nth-child(8)").should == "DISCHARGED"
    slmc.get_select_options("userAction#{@@dr_pin}").include?("Reprint Gate Pass").should be_true
  end

  it "Verify that “Reprint Discharge Notice Slip” is not available when clinical discharge is deferred" do
    @@dr_pin2 = slmc.or_nb_create_patient_record(Admission.generate_data.merge(:admit => true, :org_code => "0170", :gender => 'F')).gsub(' ', '')
    slmc.occupancy_pin_search(:pin => @@dr_pin2)
    slmc.clinically_discharge_patient(:pin => @@dr_pin2, :outpatient => true, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.occupancy_pin_search(:pin => @@dr_pin2)
    slmc.defer_clinical_discharge(:pin => @@dr_pin2, :outpatient => true).should be_true
    slmc.occupancy_pin_search(:pin => @@dr_pin2)
    slmc.get_select_options("userAction#{@@dr_pin2}").include?("Reprint Discharge Notice Slip").should be_false
  end

  it "Feature #46170 - Verify that Validation pop-up is displayed upon Checklist Order Adjustment when user does not have ROLE_SPU_NURSING_MANAGER" do
    slmc.login(@dr_user, @password).should be_true
    @@dr_pin1 = slmc.or_create_patient_record(Admission.generate_data.merge!(:admit => true, :org_code => "0170")).gsub(' ', '')

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin1)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin1)
    @@item_code = slmc.search_service(:procedure => true, :description => "APPENDECTOMY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "APPENDECTOMY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "5979")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items(:username => "sel_0170_validator").should be_true

    slmc.search_soa_checklist_order(:pin => @@dr_pin1)
    slmc.adjust_checklist_order

    slmc.type("oif_entity_finder_key", "LIPOSUCTION")
    slmc.click("search")
    sleep 2
    slmc.click(Locators::NursingSpecialUnits.order_adjustment_searched_service_code)
    slmc.click("_addButton")
    sleep 2
    slmc.click('_submitForm')
    slmc.is_element_present("userEntryPopup").should be_true
  end

  it "Feature #46170 - Verify that invalid or incorrect comibination of username and password is not accepted" do
    slmc.type("usernameInputBox", "@@@@@@@")
    slmc.type("passwordInputBox", "123qweuser")
    slmc.click("//html/body/div[8]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "Invalid username/password."
  end

  it "Feature #46170 - Verify that username and password with no ROLE_SPU_NURSING_MANAGER is not accepted" do
    slmc.type("usernameInputBox", "adm1")
    slmc.type("passwordInputBox", "123qweuser")
    slmc.click("//html/body/div[8]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "User adm1 is not allowed to validate."
  end

  it "Feature #46170 - Verify that username and password with ROLE_SPU_NURSING_MANAGER but different Org Code is not accepted" do
    slmc.type("usernameInputBox", "sel_0165_validator")
    slmc.type("passwordInputBox", "123qweuser")
    slmc.click("//html/body/div[8]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "User sel_0165_validator is not allowed to validate."
  end

  it "Feature #46170 - Verify that username and password with ROLE_SPU_NURSING_MANAGER and the same Org Code is accepted" do
    slmc.type("usernameInputBox", "sel_0170_validator")
    slmc.type("passwordInputBox", "123qweuser")
    slmc.click("//html/body/div[8]/div[11]/div/button[2]", :wait_for => :page)
  end

  it "Feature #46170 - Verify that Validation pop-up is displayed upon Checklist Order Cancellation when user does not have ROLE_SPU_NURSING_MANAGER" do
    slmc.search_soa_checklist_order(:pin => @@dr_pin1)
    slmc.click("link=Cancel")
    sleep 2
    slmc.is_element_present("userEntryPopup").should be_true
  end

  it "Feature #46170 - Verify that invalid or incorrect comibination of username and password is not accepted" do
    slmc.type("usernameInputBox", "@@@@@@@")
    slmc.type("passwordInputBox", "123qweuser")
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "Invalid username/password."
  end

  it "Feature #46170 - Verify that username and password with no ROLE_SPU_NURSING_MANAGER is not accepted" do
    slmc.type"usernameInputBox", "adm1"
    slmc.type"passwordInputBox", "123qweuser"
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "User adm1 is not allowed to validate."
  end

  it "Feature #46170 - Verify that username and password with ROLE_SPU_NURSING_MANAGER but different Org Code is not accepted" do
    slmc.type("usernameInputBox", "sel_0165_validator")
    slmc.type("passwordInputBox", "123qweuser")
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "User sel_0165_validator is not allowed to validate."
  end

  it "Feature #46170 - Verify that username and password with ROLE_SPU_NURSING_MANAGER and the same Org Code is accepted" do
    slmc.type("usernameInputBox", "sel_0170_validator")
    slmc.type("passwordInputBox", "123qweuser")
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 2
    (slmc.is_element_present"orderCancelForm").should be_true

    slmc.select("reason", "CANCELLATION - ORDER")
    slmc.click("btnOK", :wait_for => :page)
  end

  it "Feature #46170 - Verify that Validation is not required upon Checklist Order Adjustment when user has ROLE_SPU_NURSING_MANAGER" do
    slmc.login(@dr_user1, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin1)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@dr_pin1)

    @@item_code = slmc.search_service(:procedure => true, :description => "TRANSVAGINAL ULTRASOUND")
    slmc.add_returned_service(:item_code => @@item_code, :description => "TRANSVAGINAL ULTRASOUND")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "5979")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.search_soa_checklist_order(:pin => @@dr_pin1)
    slmc.adjust_checklist_order
    slmc.type("oif_entity_finder_key", "TRANSRECTAL ULTRASOUND")
    slmc.click("search")
    sleep 2
    slmc.click(Locators::NursingSpecialUnits.order_adjustment_searched_service_code)
    slmc.click("_addButton")
    sleep 2
    slmc.click('_submitForm', :wait_for => :page) #no validation popup
  end

  it "Feature #46170 - Verify that Validation is not required upon Checklist Order Cancellation when user has ROLE_SPU_NURSING_MANAGER" do
    slmc.search_soa_checklist_order(:pin => @@dr_pin1)
    slmc.click("link=Cancel")
    sleep 2
    slmc.is_element_present("orderCancelForm").should be_true   #no validation popup

    slmc.select("reason", "CANCELLATION - ORDER")
    slmc.click("btnOK", :wait_for => :page)
  end

  it "Feature #46665 - Validate if the system allows printing of PDS after Clinically Discharge" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin1)
    @@dr_visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@dr_pin1, :pf_amount => '1000', :no_pending_order => true, :save => true)
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin1)
    slmc.go_to_su_page_for_a_given_pin("Print Label Sticker",@@dr_pin1)

    slmc.med_reprinting_page(:patient_data_sheet => true, :successful => true).should be_true
  end

  it "Feature #46665 - Validate if the system allows printing of PDS after Printing of Gatepass" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@dr_visit_no)
    slmc.select_discharge_patient_type(:type => "DAS").should be_true

    slmc.login(@dr_user1, @password).should be_true
    slmc.or_print_gatepass(:pin => @@dr_pin1, :visit_no => @@dr_visit_no)

    slmc.login(@adm_user, @password).should be_true
    slmc.reprinting_from_admission_page(:pin => @@dr_pin1, :patient_data_sheet => true).should be_true
  end

  it "Feature #46665 - Validate if the system reprints correct PDS after re admitting patient with the same PIN with different visit number" do
    slmc.login(@dr_user1, @password).should be_true
    slmc.or_register_patient(:pin => @@dr_pin1, :org_code => "0170")

    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin1)
    @@dr_visit_no1 = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@dr_pin1, :pf_amount => '1000', :no_pending_order => true, :save => true)

    @@dr_visit_no.should_not == @@dr_visit_no1
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin1)
    slmc.go_to_su_page_for_a_given_pin("Print Label Sticker",@@dr_pin1)
    (slmc.get_text"banner.visitNo").should == @@dr_visit_no1
    slmc.med_reprinting_page(:patient_data_sheet => true, :successful => true).should be_true
  end

  it "Feature #46665 - Validate if the system reprints correct PDS after re admitting patient with the same PIN with different visit number and printing its gatepass" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@dr_visit_no1)
    slmc.select_discharge_patient_type(:type => "DAS").should be_true

    slmc.login(@dr_user1, @password).should be_true
    slmc.or_print_gatepass(:pin => @@dr_pin1, :visit_no => @@dr_visit_no1)

    slmc.login(@adm_user, @password).should be_true
    slmc.reprinting_from_admission_page(:pin => @@dr_pin1, :patient_data_sheet => true).should be_true
    slmc.get_text("banner.visitNo").should == @@dr_visit_no1
  end

  it "Feature #32308 - Create patient" do
     slmc.login(@dr_user, @password).should be_true
    @@dr_pin3 = slmc.or_create_patient_record(Admission.generate_data.merge!(:admit => true, :org_code => "0170", :gender => 'F')).gsub(' ', '')
  end

  it "Feature #32308 - Entered patient's diet should be saved in database" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin3)
    slmc.go_to_su_page_for_a_given_pin("Clinical Diet",@@dr_pin3)
    slmc.add_clinical_diet(:save => true).should == "Patient diet COMPUTED DIET successfully created."

    @@visit_no = slmc.get_text"banner.visitNo"
    @@diet_no = slmc.access_from_database(:what => "DIET_NO", :table => "TXN_OM_PAT_DIET", :column1 => "VISIT_NO", :condition1 => @@visit_no)
    slmc.access_from_database(:what => "DESCRIPTION", :table => "TXN_OM_PAT_FOOD_ALLERGY", :column1 => "PIN", :condition1 => @@dr_pin3).should == "SELENIUM TEST FOOD ALLERGY DESCRIPTION"
    slmc.access_from_database(:what => "PREFERENCE", :table => "TXN_OM_PAT_FOOD_PREF", :column1 => "VISIT_NO", :condition1 => @@visit_no).should == "SELENIUM TEST FOOD PREFERENCE"
    slmc.access_from_database(:what => "DIET_ID", :table => "TXN_OM_PAT_DIET_ALLERGY ", :column1 => "DIET_ID", :condition1 => @@diet_no).should == @@diet_no
  end

  it "Feature #32308 - Click View Diet History button" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin3)
    slmc.go_to_su_page_for_a_given_pin("Clinical Diet",@@dr_pin3)
    slmc.click("//input[@type='button' and @value='View Diet History']", :wait_for => :page)
    contents = slmc.get_text"dataTable"
    #(contents.include?"Updated Datetime").should be_true
    (contents.include?"Allergies").should be_true
    (contents.include?"Food Preference").should be_true
    (contents.include?"Additional Instructions").should be_true
    (contents.include?"Diet Type").should be_true
    (contents.include?"Diet Group").should be_true
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet - Diet Type then save" do
    slmc.count_diet_history(:pin => @@dr_pin3, :visit_no => @@visit_no, :back => true).should == 2
    slmc.add_clinical_diet(:diet => "CLEAR LIQUID", :update => true).should == "Patient diet CLEAR LIQUID successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@dr_pin3, :visit_no => @@visit_no, :back => true).should == 3
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet - Addiitonal Instructions then save" do
    slmc.add_clinical_diet(:additional_instruction => "SELENIUM ADDITIONAL INSTRUCTIONS", :update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@dr_pin3, :visit_no => @@visit_no, :back => true).should == 4
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet -Allergies then save" do
    slmc.add_clinical_diet(:description => "ALLERGIES FOR COUNTING", :update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@dr_pin3, :visit_no => @@visit_no, :back => true).should == 5
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet -Patient Food Preference then save" do
    slmc.add_clinical_diet(:food_preferences => "TEST FOOD PREFERENCES FOR COUNTING", :update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@dr_pin3, :visit_no => @@visit_no, :back => true).should == 6
  end

  it "Feature #32308 - Click View Diet History button - Diet Type" do
    slmc.click("//input[@type='button' and @value='View Diet History']", :wait_for => :page)
    count = slmc.get_css_count("css=#dataTable>tbody>tr")
    count -=1
    rows = 1
    @@arr = []
    count.times do
    @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)>a")
      count-=1
      rows+=1
    end

    (@@arr.to_s).include?("CLEAR LIQUID").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Addiitonal Instructions" do
    count = slmc.get_css_count("css=#dataTable>tbody>tr")
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(6)>a")
      count-=1
      rows+=1
    end

    (@@arr.to_s).include?("SELENIUM ADDITIONAL INSTRUCTIONS").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Allergies" do
    count = slmc.get_css_count("css=#dataTable>tbody>tr")
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(4)>a")
      count-=1
      rows+=1
    end

    (@@arr.to_s).include?("ALLERGIES FOR COUNTING").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Patient Food Preference" do
    count = slmc.get_css_count("css=#dataTable>tbody>tr")
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(5)>a")
      count-=1
      rows+=1
    end

    (@@arr.to_s).include?("TEST FOOD PREFERENCES FOR COUNTING").should be_true
  end

  it "Feature #32308 - Click patient diet details link" do
    slmc.click"link=CLEAR LIQUID"
    sleep 4
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{count})>th")
      count-=1
    end

    (@@arr.to_s).should == "Additional Instructions :Disposable Tray :Interpretation :BMI :Weight :Height :Food Allergies :Food Preference :Patient Diet Type :Patient Diet Group :"
    slmc.click("//html/body/div/div[2]/div[2]/div[7]/div[2]/div/a/input")
  end

  it "Feature #41781 - DR - AFTER A DAY - ONE ITEM - CANCEL" do
    slmc.login(@dr_user, @password).should be_true
    @@dr_pin2 = slmc.or_create_patient_record(Admission.generate_data.merge!(:admit => true, :org_code => "0170")).gsub(' ', '')

    slmc.or_add_checklist_order(:pin => @@dr_pin2, :procedure => "APPENDECTOMY", :doctor => "ABAD")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items(:username => "sel_0170_validator").should be_true
    
    @@days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 3).strftime("%d-%b-%y").upcase).to_s
    @@visit_no = slmc.get_visit_number_using_pin(@@dr_pin2)
    slmc.adjust_admission_date(:days_to_adjust => 3, :pin => @@dr_pin2, :visit_no => @@visit_no)

    slmc.update_from_database(:what => "ORDR_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "VISIT_NO", :condition1 => @@visit_no)
    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "VISIT_NO", :condition1 => @@visit_no)
    @@order_grp_no = slmc.access_from_database(:what => "ORDER_GRP_NO", :table => "TXN_OM_ORDER_GRP", :column1 => "VISIT_NO", :condition1 => @@visit_no)

    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "VALIDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "UPDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)

    slmc.search_soa_checklist_order(:pin => @@dr_pin2, :date_today => "", :date2 => "", :soa_number => Time.now.strftime("%m")).should be_true
    slmc.cancel_checklist_order(:soa_number => slmc.get_text("//table[@id='results']/tbody/tr/td[3]"), :username => "sel_0170_validator").should be_true
  end

  it "Feature #41781 - DR - AFTER A DAY - TWO ITEM - CANCEL" do
    slmc.or_add_checklist_order(:pin => @@dr_pin2, :procedure => "APPENDECTOMY", :doctor => "ABAD")
    slmc.add_checklist_order(:procedure => "LAPAROSCOPY CHOLECYSTECTOMY", :doctor => "ABAD")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items(:username => "sel_0170_validator").should be_true

    slmc.search_soa_checklist_order(:pin => @@dr_pin2, :date_today => "", :date2 => "", :soa_number => Time.now.strftime("%m")).should be_true
    @@soa_number2 = slmc.get_text("//table[@id='results']/tbody/tr/td[3]")
    @@days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 3).strftime("%d-%b-%y").upcase).to_s

    slmc.update_from_database(:what => "ORDR_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number2)
    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number2)
    @@order_grp_no = slmc.access_from_database(:what => "ORDER_GRP_NO", :table => "TXN_OM_ORDER_GRP", :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number2)

    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "VALIDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "UPDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)

    slmc.search_soa_checklist_order(:pin => @@dr_pin2, :date_today => "", :date2 => "", :soa_number => @@soa_number2).should be_true
    slmc.cancel_checklist_order(:soa_number => slmc.get_text("//table[@id='results']/tbody/tr/td[3]"), :username => "sel_0170_validator").should be_true
  end

  it "Feature #41781 - DR - AFTER A DAY - ONE ITEM - ADJUST" do
    @@dr_pin3 = slmc.or_create_patient_record(Admission.generate_data.merge!(:admit => true, :org_code => "0170")).gsub(' ', '')
    slmc.or_add_checklist_order(:pin => @@dr_pin3, :supplies_equipment => "ALCOHOL SWAB", :a_quantity => "5", :s_quantity => "5", :doctor => "ABAD")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:non_procedures => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items(:username => "sel_0170_validator").should be_true

    slmc.search_soa_checklist_order(:pin => @@dr_pin3, :date_today => "", :date2 => "", :soa_number => Time.now.strftime("%m")).should be_true
    @@soa_number3 = slmc.get_text("//table[@id='results']/tbody/tr/td[3]")
    @@days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 3).strftime("%d-%b-%y").upcase).to_s
    @@visit_no2 = slmc.get_visit_number_using_pin(@@dr_pin3)
    slmc.adjust_admission_date(:days_to_adjust => 3, :pin => @@dr_pin3, :visit_no => @@visit_no2)

    slmc.update_from_database(:what => "ORDR_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number3)
    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number3)
    @@order_grp_no = slmc.access_from_database(:what => "ORDER_GRP_NO", :table => "TXN_OM_ORDER_GRP", :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number3)

    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "VALIDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "UPDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)

    slmc.search_soa_checklist_order(:pin => @@dr_pin3, :date_today => "", :date2 => "", :soa_number => @@soa_number3).should be_true
    slmc.adjust_checklist_order
    slmc.checklist_order_adjustment(:edit => true, :username => "sel_0170_validator").should be_true
  end

  it "Feature #41781 - DR - AFTER A DAY - TWO ITEM - ADJUST" do
    slmc.or_add_checklist_order(:pin => @@dr_pin3, :supplies_equipment => "ALCOHOL SWAB", :a_quantity => "5", :s_quantity => "5", :doctor => "ABAD")
    slmc.add_checklist_order(:supplies_equipment => "ALCOHOL 70% ISOPROPHYL 250ML", :a_quantity => "5", :s_quantity => "5", :doctor => "ABAD")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:non_procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items(:username => "sel_0170_validator").should be_true

    slmc.search_soa_checklist_order(:pin => @@dr_pin3, :date_today => "", :date2 => "", :soa_number => Time.now.strftime("%m")).should be_true
    @@soa_number4 = slmc.get_text("//table[@id='results']/tbody/tr/td[3]")
    @@days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 3).strftime("%d-%b-%y").upcase).to_s

    slmc.update_from_database(:what => "ORDR_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number4)
    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number4)
    @@order_grp_no = slmc.access_from_database(:what => "ORDER_GRP_NO", :table => "TXN_OM_ORDER_GRP", :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number4)

    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "VALIDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "UPDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)

    slmc.search_soa_checklist_order(:pin => @@dr_pin3, :date_today => "", :date2 => "", :soa_number => @@soa_number4).should be_true
    slmc.adjust_checklist_order
    slmc.checklist_order_adjustment(:edit => true, :username => "sel_0170_validator").should be_true
  end

end