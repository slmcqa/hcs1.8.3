require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Regression of Issues for ER" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @er_patient2 = Admission.generate_data
    @password = "123qweuser"
    @er_user = "sel_er2"
    @er_user1 = "sel_er12"    #without spu_nursing_manager
    @ss_user = "sel_ss2"
    @user = "billing_spec_user8"

    @ancillary = {"010000317" => 1,"010000212" => 2}
    @drugs = {"042820145" => 5,"042820004" => 6}
    @supplies = {"080100021" => 10}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Bug #41503 - ER: Two Back buttons are available in New Patient Information" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_page
    slmc.er_patient_search(:pin => "test")
    slmc.click_create_patient_record
    slmc.get_fields_and_labels_by_type("button").should == ["Back", "DISMISS", "OK", "Save"] #OK button is hidden element
  end

  it "Bug #42306 - Room/Bed Area Shoud be a mandatory field during outpatient registration" do
    slmc.go_to_er_page
    slmc.er_patient_search(:pin => "test")
    slmc.er_outpatient_registration(Admission.generate_data)
    slmc.select "accountClass", "INDIVIDUAL"
    slmc.doctor_finder(:doctor => "ABAD")
    slmc.click "previewAction", :wait_for => :page
    slmc.get_text("admission.errors").should == "Room is a required field.\nBed is a required field."
    slmc.is_element_present("previewAction").should be_true
  end

  it "Bug #42942 - ER: Behavior of Frequency, Dose and Route in Add Cart UI is inconsistent" do
    @@er_pin = slmc.er_create_patient_record(Admission.generate_data(:not_senior => true)).gsub(' ','').should be_true
    slmc.admit_er_patient(:account_class => "SOCIAL SERVICE", :esc_no => "345", :dept_code => "OBSTETRICS AND GYNECOLOGY")
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin)
    slmc.search_order(:description => "042820145", :drugs => true).should be_true
    @frequency = slmc.get_selected_label("frequencyCode")
    @route = slmc.get_selected_label("routeCode")
    @dose = slmc.get_value("dose")
    sleep 2
    frequency = "TWICE A WEEK"
    slmc.select "frequencyCode", "label=#{frequency}"
    slmc.select("routeCode","NASAL")
    slmc.type("dose","3")
    (slmc.get_selected_label("frequencyCode")).should_not == @frequency
    (slmc.get_selected_label("routeCode")).should_not == @route
    (slmc.get_value("dose")).should_not == @dose
  end

  it "Bug #40867 - ER - Order Page - Duplicate view of the ordered items to be validated" do
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.search_order(:ancillary => true, :description => "010000212").should be_true
    slmc.add_returned_order(:ancillary => true,:description => "010000212", :add => true ).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.click "validate"
    sleep 2
    (slmc.get_text"css=#orderPrinter2>thead").should == "Description Requesting Unit Request Prooflist"
    (slmc.get_text"css=#orderPrinter>thead").should == "Performing Unit Request Slip"
    slmc.click '//input[@type="button" and @value="Cancel"]'
    slmc.is_text_present"TRANSVAGINAL ULTRASOUND".should be_true
    sleep 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Bug #41032 - [SS-ER] Unable to un-tag patient that is for express discharge" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.pba_search_1(:all_patients => true, :pin => @@er_pin)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    slmc.add_recommendation_entry(:express_discharge => true)

    slmc.go_to_social_services_landing_page
    slmc.pba_search_1(:all_patients => true, :pin => @@er_pin)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    slmc.click("expressDischarge1")
    slmc.click("//input[@type='submit' and @value='Submit']", :wait_for => :page)
    slmc.is_text_present("Social Service Home").should be_true
  end

  it "Bug #40689 - ER Billing Landing Page" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin)
    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
    slmc.go_to_er_billing_page
    slmc.pba_search_1(:all_patients => true, :pin => @@er_pin)
    ((slmc.get_text("css=#results>tbody>tr.even>td:nth-child(8)")).include?("View Confinement History")).should be_true
  end

  it "Bug #42184 - ADMISSION - Patient Type of patient undergo room transfer from GU to ER still Inpatient" do
    @@er_pin2 = slmc.er_create_patient_record(@er_patient2.merge(:admit => true)).gsub(' ','')
    slmc.go_to_er_landing_page
    slmc.click("link=Patient Search", :wait_for => :page)
    slmc.outpatient_to_inpatient(@er_patient2.merge(:pin => @@er_pin2, :username => 'sel_adm1', :password => @password, :room_label => "REGULAR PRIVATE", :rch_code => "RCH08", :diagnosis => "CHOLERA", :org_code => "0287", :mobility_status => "WHEELCHAIR BORNE")).should be_true

    slmc.login(@user, @password).should be_true
    slmc.request_for_room_transfer(:pin => @@er_pin2, :remarks => "Room transfer remarks", :first => true)
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@er_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "For Room Transfer")
    slmc.go_to_general_units_page
    slmc.search_patient_for_room_transfer(:pin => @@er_pin2)
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "Physically Transferred").should be_true
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@er_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Transfer Room Location", :transfer_type => "NURSING UNIT TRANSFER", :room_charge => "SPECIAL UNITS", :room => true, :org_code => "0173", :close => true).should == "Room location updated."

    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_landing_page
    slmc.click("link=Patient Search", :wait_for => :page)
    slmc.patient_pin_search(:pin => @@er_pin2)
    slmc.get_text("css=#results>tbody>tr>td:nth-child(3)").should == slmc.return_original_pin(@@er_pin2)
    slmc.access_from_database(:what => "PATIENT_TYPE", :table => "TXN_ADM_ENCOUNTER", :column1 => "PIN", :condition1 => @@er_pin2).should == "O" # Outpatient
  end

  it "Feature #46170 - Verify that Validation pop-up is displayed upon Checklist Order Adjustment when user does not have ROLE_SPU_NURSING_MANAGER" do
    slmc.login(@er_user1, @password).should be_true
    @@er_pin1 = slmc.er_create_patient_record(Admission.generate_data.merge(:admit => true)).gsub(' ','')

    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin1)
    slmc.go_to_gu_page_for_a_given_pin("Checklist Order", @@er_pin1)

    @@item_code = slmc.search_service(:procedure => true, :description => "CAST REMOVAL")
    slmc.add_returned_service(:item_code => @@item_code, :description => "CAST REMOVAL")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "5979")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_er_patient_search
    slmc.er_search_checklist_order(:pin => @@er_pin1)
    slmc.adjust_checklist_order

    slmc.type "oif_entity_finder_key","GASTRIC LAVAGE"
    slmc.click "search"
    sleep 2
    slmc.click Locators::NursingSpecialUnits.order_adjustment_searched_service_code
    slmc.type"sQuantity","1"
    slmc.click "_addButton"
    sleep 2
    slmc.click '_submitForm'
    (slmc.is_element_present"userEntryPopup").should be_true
  end

  it "Feature #46170 - Verify that invalid or incorrect comibination of username and password is not accepted" do
    slmc.type"usernameInputBox","@@@@@@@"
    slmc.type"passwordInputBox","123qweuser"
    slmc.click("//html/body/div[8]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "Invalid username/password."
  end

  it "Feature #46170 - Verify that username and password with no ROLE_SPU_NURSING_MANAGER is not accepted" do
    slmc.type"usernameInputBox","adm1"
    slmc.type"passwordInputBox","123qweuser"
    slmc.click("//html/body/div[8]/div[11]/div/button[2]")
    sleep 5
    (slmc.get_text"userValidationErr").should == "User adm1 is not allowed to validate."
  end

  it "Feature #46170 - Verify that username and password with ROLE_SPU_NURSING_MANAGER but different Org Code is not accepted" do
    slmc.type"usernameInputBox","sel_0165_validator"
    slmc.type"passwordInputBox","123qweuser"
    slmc.click("//html/body/div[8]/div[11]/div/button[2]")
    sleep 5
    (slmc.get_text"userValidationErr").should == "User sel_0165_validator is not allowed to validate."
  end

  it "Feature #46170 - Verify that username and password with ROLE_SPU_NURSING_MANAGER and the same Org Code is accepted" do
    slmc.type"usernameInputBox","sel_0173_validator"
    slmc.type"passwordInputBox","123qweuser"
    slmc.click("//html/body/div[8]/div[11]/div/button[2]", :wait_for => :page)
  end

  it "Feature #46170 - Verify that Validation pop-up is displayed upon Checklist Order Cancellation when user does not have ROLE_SPU_NURSING_MANAGER" do
    slmc.go_to_er_patient_search
    slmc.er_search_checklist_order(:pin => @@er_pin1)
    slmc.click "link=Cancel"
    sleep 2
    (slmc.is_element_present"userEntryPopup").should be_true
  end

  it "Feature #46170 - Verify that invalid or incorrect comibination of username and password is not accepted" do
    slmc.type"usernameInputBox","@@@@@@@"
    slmc.type"passwordInputBox","123qweuser"
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "Invalid username/password."
  end

  it "Feature #46170 - Verify that username and password with no ROLE_SPU_NURSING_MANAGER is not accepted" do
    slmc.type"usernameInputBox","adm1"
    slmc.type"passwordInputBox","123qweuser"
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "User adm1 is not allowed to validate."
  end

  it "Feature #46170 - Verify that username and password with ROLE_SPU_NURSING_MANAGER but different Org Code is not accepted" do
    slmc.type"usernameInputBox","sel_0165_validator"
    slmc.type"passwordInputBox","123qweuser"
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 2
    (slmc.get_text"userValidationErr").should == "User sel_0165_validator is not allowed to validate."
  end

  it "Feature #46170 - Verify that username and password with ROLE_SPU_NURSING_MANAGER and the same Org Code is accepted" do
    slmc.type"usernameInputBox","sel_0173_validator"
    slmc.type"passwordInputBox","123qweuser"
    slmc.click("//html/body/div[7]/div[11]/div/button[2]")
    sleep 2
    (slmc.is_element_present"orderCancelForm").should be_true

    slmc.select"reason","CANCELLATION - ORDER"
    slmc.click"btnOK", :wait_for => :page
  end

  it "Feature #46170 - Verify that Validation is not required upon Checklist Order Adjustment when user has ROLE_SPU_NURSING_MANAGER" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin1)
    slmc.go_to_gu_page_for_a_given_pin("Checklist Order", @@er_pin1)

    @@item_code = slmc.search_service(:procedure => true, :description => "BURN DRESSING")
    slmc.add_returned_service(:item_code => @@item_code, :description => "BURN DRESSING")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "5979")
    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_er_patient_search
    slmc.er_search_checklist_order(:pin => @@er_pin1)
    slmc.adjust_checklist_order

    slmc.type "oif_entity_finder_key","CARDIAC ARREST"
    slmc.click "search"
    sleep 2
    slmc.click Locators::NursingSpecialUnits.order_adjustment_searched_service_code
    slmc.type"sQuantity","1"
    slmc.click "_addButton"
    sleep 2
    slmc.click '_submitForm', :wait_for => :page #no validation popup
  end

  it "Feature #46170 - Verify that Validation is not required upon Checklist Order Cancellation when user has ROLE_SPU_NURSING_MANAGER" do
    slmc.go_to_er_patient_search
    slmc.er_search_checklist_order(:pin => @@er_pin1)
    slmc.click "link=Cancel"
    sleep 2
    (slmc.is_element_present"orderCancelForm").should be_true   #no validation popup

    slmc.select"reason","CANCELLATION - ORDER"
    slmc.click"btnOK", :wait_for => :page
  end

  it "Feature #32308 - Entered patient's diet should be saved in database" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin1)
    slmc.go_to_gu_page_for_a_given_pin("Diet", @@er_pin1)
    slmc.add_clinical_diet(:save => true).should == "Patient diet COMPUTED DIET successfully created."

    @@visit_no = slmc.get_text"banner.visitNo"
    @@diet_no = slmc.access_from_database(:what => "DIET_NO", :table => "TXN_OM_PAT_DIET", :column1 => "VISIT_NO", :condition1 => @@visit_no)
    slmc.access_from_database(:what => "DESCRIPTION", :table => "TXN_OM_PAT_FOOD_ALLERGY", :column1 => "PIN", :condition1 => @@er_pin1).should == "SELENIUM TEST FOOD ALLERGY DESCRIPTION"
    slmc.access_from_database(:what => "PREFERENCE", :table => "TXN_OM_PAT_FOOD_PREF", :column1 => "VISIT_NO", :condition1 => @@visit_no).should == "SELENIUM TEST FOOD PREFERENCE"
    slmc.access_from_database(:what => "DIET_ID", :table => "TXN_OM_PAT_DIET_ALLERGY ", :column1 => "DIET_ID", :condition1 => @@diet_no).should == @@diet_no
  end

  it "Feature #32308 - Click View Diet History button" do
    slmc.click("//input[@type='button' and @value='View Diet History']", :wait_for => :page)
    contents = slmc.get_text"dataTable"
    #(contents.include?"Updated Datetime").should be_true #task51185.
    (contents.include?"Allergies").should be_true
    (contents.include?"Food Preference").should be_true
    (contents.include?"Additional Instructions").should be_true
    (contents.include?"Diet Type").should be_true
    (contents.include?"Diet Group").should be_true
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet - Diet Type then save" do
    slmc.count_diet_history(:pin => @@er_pin1, :visit_no => @@visit_no, :back => true).should == 2
    slmc.add_clinical_diet(:diet => "CLEAR LIQUID",:update => true).should == "Patient diet CLEAR LIQUID successfully created."
    slmc.count_diet_history(:view_diet_history => true,:pin => @@er_pin1, :visit_no => @@visit_no,:back => true).should == 3
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet - Addiitonal Instructions then save" do
    slmc.add_clinical_diet(:additional_instruction => "SELENIUM ADDITIONAL INSTRUCTIONS",:update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true,:pin => @@er_pin1, :visit_no => @@visit_no,:back => true).should == 4
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet -Allergies then save" do
    slmc.add_clinical_diet(:description => "ALLERGIES FOR COUNTING",:update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true,:pin => @@er_pin1, :visit_no => @@visit_no,:back => true).should == 5
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet -Patient Food Preference then save" do
    slmc.add_clinical_diet(:food_preferences => "TEST FOOD PREFERENCES FOR COUNTING",:update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true,:pin => @@er_pin1, :visit_no => @@visit_no,:back => true).should == 6
  end

  it "Feature #32308 - Click View Diet History button - Diet Type" do
    slmc.click"//input[@type='button' and @value='View Diet History']", :wait_for => :page
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)>a")
      count-=1
      rows+=1
    end

    ((@@arr.to_s).include?"CLEAR LIQUID").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Addiitonal Instructions" do
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(6)>a")
      count-=1
      rows+=1
    end

    ((@@arr.to_s).include?"SELENIUM ADDITIONAL INSTRUCTIONS").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Allergies" do
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(4)>a")
      count-=1
      rows+=1
    end

    ((@@arr.to_s).include?"ALLERGIES FOR COUNTING").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Patient Food Preference" do
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(5)>a")
      count-=1
      rows+=1
    end

    ((@@arr.to_s).include?"TEST FOOD PREFERENCES FOR COUNTING").should be_true
  end

  it "Feature #32308 - Click patient diet details link" do
    slmc.click"link=CLEAR LIQUID", :wait_for => :page
    #sleep 4
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{count})>th")
      count-=1
    end

    (@@arr.to_s).should == "Additional Instructions :Disposable Tray :Interpretation :BMI :Weight :Height :Food Allergies :Food Preference :Patient Diet Type :Patient Diet Group :"
    slmc.click"//html/body/div/div[2]/div[2]/div[7]/div[2]/div/a/input"
    sleep 2
  end

  it "Feature #41781 - ER - AFTER A DAY - ONE ITEM - CANCEL" do
    slmc.login(@er_user, @password).should be_true
    @@er_pin3 = slmc.er_create_patient_record(Admission.generate_data.merge(:admit => true)).gsub(' ','')
    
    slmc.er_add_checklist_order(:pin => @@er_pin3, :procedure => "BURN DRESSING", :doctor => "ABAD")
    slmc.confirm_order(:surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true

    @@days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 3).strftime("%d-%b-%y").upcase).to_s
    @@visit_no = slmc.get_visit_number_using_pin(@@er_pin3)
    slmc.adjust_admission_date(:days_to_adjust => 3, :pin => @@er_pin3, :visit_no => @@visit_no)

    slmc.update_from_database(:what => "ORDR_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "VISIT_NO", :condition1 => @@visit_no)
    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "VISIT_NO", :condition1 => @@visit_no)
    @@order_grp_no = slmc.access_from_database(:what => "ORDER_GRP_NO", :table => "TXN_OM_ORDER_GRP", :column1 => "VISIT_NO", :condition1 => @@visit_no)

    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "VALIDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "UPDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)

    slmc.search_soa_checklist_order(:er => true, :pin => @@er_pin3, :date_today => "", :date2 => "", :soa_number => Time.now.strftime("%m")).should be_true
    slmc.cancel_checklist_order(:er => true, :soa_number => slmc.get_text("//table[@id='results']/tbody/tr/td[3]")).should be_true
    slmc.search_soa_checklist_order(:er => true, :pin => @@er_pin3, :date_today => "", :date2 => "", :soa_number => Time.now.strftime("%m")).should be_true
    slmc.get_text("//div[@class='boxedLink']").should == "CANCELLED"
  end

  it "Feature #41781 - ER - AFTER A DAY - TWO ITEM - CANCEL" do
    slmc.er_add_checklist_order(:pin => @@er_pin3, :procedure => "BURN DRESSING", :doctor => "ABAD")
    slmc.add_checklist_order(:procedure => "CAST REMOVAL", :doctor => "ABAD")
    slmc.confirm_order(:surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true

    slmc.search_soa_checklist_order(:er => true, :pin => @@er_pin3, :date_today => "", :date2 => "", :soa_number => Time.now.strftime("%m")).should be_true
    @@soa_number2 = slmc.get_text("//table[@id='results']/tbody/tr/td[3]")
    @@days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 3).strftime("%d-%b-%y").upcase).to_s

    slmc.update_from_database(:what => "ORDR_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number2)
    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number2)
    @@order_grp_no = slmc.access_from_database(:what => "ORDER_GRP_NO", :table => "TXN_OM_ORDER_GRP", :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number2)

    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "VALIDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "UPDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)

    slmc.search_soa_checklist_order(:er => true, :pin => @@er_pin3, :date_today => "", :date2 => "", :soa_number => @@soa_number2).should be_true
    slmc.cancel_checklist_order(:er => true, :soa_number => slmc.get_text("//table[@id='results']/tbody/tr/td[3]")).should be_true
    slmc.is_text_present("has been cancelled.").should be_true
  end

  it "Feature #41781 - ER - AFTER A DAY - ONE ITEM - ADJUST" do
    slmc.login(@er_user, @password).should be_true
    @@er_pin4 = slmc.er_create_patient_record(Admission.generate_data.merge(:admit => true)).gsub(' ','')
    slmc.er_add_checklist_order(:pin => @@er_pin4, :supplies_equipment => "ADHESIVE STRAPPING", :a_quantity => "5", :s_quantity => "5", :doctor => "ABAD")
    slmc.confirm_order(:surgeon_code => "6726")
    slmc.validate_orders(:non_procedures => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.search_soa_checklist_order(:er => true, :pin => @@er_pin4, :date_today => "", :date2 => "", :soa_number => Time.now.strftime("%m")).should be_true
    @@soa_number3 = slmc.get_text("//table[@id='results']/tbody/tr/td[3]")
    @@days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 3).strftime("%d-%b-%y").upcase).to_s
    @@visit_no2 = slmc.get_visit_number_using_pin(@@er_pin4)
    slmc.adjust_admission_date(:days_to_adjust => 3, :pin => @@er_pin4, :visit_no => @@visit_no2)

    slmc.update_from_database(:what => "ORDR_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number3)
    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number3)
    @@order_grp_no = slmc.access_from_database(:what => "ORDER_GRP_NO", :table => "TXN_OM_ORDER_GRP", :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number3)

    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "VALIDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "UPDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)

    slmc.search_soa_checklist_order(:er => true, :pin => @@er_pin4, :date_today => "", :date2 => "", :soa_number => @@soa_number3).should be_true
    slmc.adjust_checklist_order
    slmc.checklist_order_adjustment(:edit => true).should be_true
  end

  it "Feature #41781 - ER - AFTER A DAY - TWO ITEM - ADJUST" do
    slmc.er_add_checklist_order(:pin => @@er_pin4, :supplies_equipment => "ARM SLING LARGE", :a_quantity => "5", :s_quantity => "5", :doctor => "ABAD")
    slmc.add_checklist_order(:supplies_equipment => "BLOOD SET LANCET", :a_quantity => "5", :s_quantity => "5", :doctor => "ABAD")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:non_procedures => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true

    slmc.search_soa_checklist_order(:er => true, :pin => @@er_pin4, :date_today => "", :date2 => "", :soa_number => Time.now.strftime("%m")).should be_true
    @@soa_number4 = slmc.get_text("//table[@id='results']/tbody/tr/td[3]")
    @@days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 3).strftime("%d-%b-%y").upcase).to_s

    slmc.update_from_database(:what => "ORDR_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number4)
    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_GRP", :set1 => @@days_before, :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number4)
    @@order_grp_no = slmc.access_from_database(:what => "ORDER_GRP_NO", :table => "TXN_OM_ORDER_GRP", :column1 => "CHECKLIST_SOA_NO", :condition1 => @@soa_number4)

    slmc.update_from_database(:what => "CREATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "VALIDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)
    slmc.update_from_database(:what => "UPDATED_DATETIME", :table => "TXN_OM_ORDER_DTL", :set1 => @@days_before, :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no)

    slmc.search_soa_checklist_order(:er => true, :pin => @@er_pin4, :date_today => "", :date2 => "", :soa_number => @@soa_number4).should be_true
    slmc.adjust_checklist_order
    slmc.checklist_order_adjustment(:edit => true).should be_true
  end

end

