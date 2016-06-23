#edit test
require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: ARMS Module Test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
#    @selenium_driver.evaluate_rooms_for_admission('0295', 'RCH08')
    @gu_patient = Admission.generate_data
    @patient = Admission.generate_data(:not_senior => true)
    @patient2 = Admission.generate_data
    @or_patient = Admission.generate_data

    @user = 'arms_spec_user'
    @password = "123qweuser"
    @items = {"010001047" => {:desc => "URINE HEMOSIDERIN QUALITATIVE", :code => "0062"},
              "010001664" => {:desc => "2D ECHO W/ DOPPLER", :code => "0083"}}
    @items1 = {"010002376" => {:desc => "TRANSVAGINAL ULTRASOUND", :code => "0135"}}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates new general unit patient" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_admission_page
    slmc.admission_search(:pin => "test").should be_true
    @@gu_pin = slmc.create_new_patient(@gu_patient.merge(:gender => 'M')).gsub(' ','')
    @@gu_pin.should be_true
    slmc.admission_search(:pin => @@gu_pin).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0295', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Test if input field for Search accepts either description or item code" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.search_order(:drugs => true, :description =>  "040004334").should be_true
    slmc.search_order(:supplies => true, :description => "080200000").should be_true
    slmc.search_order(:ancillary => true, :description => "010000003").should be_true
    slmc.search_order(:others => true, :description => "050000009").should be_true
    slmc.search_order(:drugs => true, :description => "SOLUSET").should be_true
    slmc.search_order(:supplies => true, :description => "NASO-TRACHEAL TUBE IVORY S7").should be_true
    slmc.search_order(:ancillary => true, :description => "BONE IMAGING - THREE PHASE STUDY").should be_true
    slmc.search_order(:others => true, :description => "BLOOD WARMER - SUCCEDING HOUR").should be_true
  end

  it "Performs clinical ordering - ANCILLARY (ADSORPTION TEST)" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.search_order(:ancillary => true, :description => "010001047").should be_true
    slmc.add_returned_order(:ancillary => true, :description => @items["010001047"][:desc], :add => true).should be_true
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Sets the arms user to same org code of ancillary" do
    slmc.login('chriss',"chriss").should be_true
    slmc.modify_user_credentials(:user_name => "sel_armsdastech", :org_code => @items["010001047"][:code]).should be_true
  end

  it "Encodes the test result and assign signatories in ARMS" do
    slmc.login("sel_armsdastech", @password).should be_true
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    @@ci_number = slmc.get_text(Locators::ARMS.ci_number_list)
    slmc.click_results_data_entry
    slmc.assign_signatory(:one => true, :code1 => "0209139")
  end

  it "Saves the document and marks it as CREATED" do
    slmc.save_signatories.should be_true
  end

  it "Updates status of CREATED document in the Order list" do
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    slmc.verify_document_status.should == 'CREATED'
    slmc.click_results_data_entry
  end

  it "Updates document from created to queued for validation" do
    slmc.queue_for_validation
  end

  it "Updates status of QUEUED document in the Order list" do
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    slmc.verify_document_status.should == 'QUEUED'
    slmc.click_results_data_entry
  end

  it "2nd signatory should NOT be able to update the status to VALIDATED" do#1st signatory should be empty
    (slmc.is_element_present'//input[@type="Button" and @name="a_validate2"]').should be_false
#    slmc.validate_document.should be_true
#    slmc.validate_credentials(:username => "dcvillanueva", :password => "dcvillanueva", :allowed => false).should == "User is not allowed for this action."
#    slmc.cancel_credentials
  end

  it "1st signatory should be able to update document status to VALIDATED " do
    slmc.click'//input[@type="Button" and @onclick="clearSignatures()"]'
    sleep 5
    slmc.assign_signatory(:one => true, :code1 => "0209139")
    slmc.assign_signatory(:two => true, :code2 => "7099")
    sleep 2
    slmc.click'//input[@type="Button" and @name="a_update2"]', :wait_for => :element, :element => '//input[@type="Button" and @name="a_validate2"]'
    sleep 10
    slmc.validate_document.should be_true
    slmc.validate_credentials(:username => "dasdoc5", :password => @password, :allowed => true).should == "VALIDATED"
  end

  it "Updates status of VALIDATED document in the Order list" do
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    slmc.verify_document_status.should == 'VALIDATED'
    slmc.click_results_data_entry
  end

  it "1st signatory should NOT be able to update the status to OFFICIAL" do
    slmc.click'//input[@type="Button" and @onclick="clearSignatures()"]'
    sleep 2
    slmc.assign_signatory(:one => true, :code1 => "0209139")
    slmc.click'//input[@type="Button" and @name="a_official2"]'
    slmc.get_alert.should == "Please assign a signatory 2 first."
#    slmc.tag_as_official.should be_true
#    slmc.official_credentials(:username => "sel_adm1", :password => @password, :allowed => false).should == "User is not allowed for this action."
#    slmc.cancel_credentials
  end

  it "2nd signatory should be able to update document status to OFFICIAL" do
    sleep 2
    slmc.assign_signatory(:two => true, :code2 => "7099")
    slmc.click'//input[@type="Button" and @name="a_update2"]'
    sleep 10
    if slmc.is_element_present'//input[@type="Button" and @name="a_validate2"]'
      slmc.click'//input[@type="Button" and @name="a_validate2"]'
      slmc.validate_credentials(:username => "dasdoc5", :password => @password, :allowed => true).should == "VALIDATED"
    end
    sleep 10
    slmc.tag_as_official.should be_true
    sleep 5
    slmc.official_credentials(:username => "dcvillanueva", :password => "dcvillanueva", :allowed => true).should == "OFFICIAL"
  end

  it "Updates status of OFFICIAL document in the Order list" do
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    slmc.verify_document_status.should == 'OFFICIAL'
  end

  it "Displays the results of an official document" do
    slmc.results_retrieval.should be_true
  end

  it "Allows dasdoc user to view ancillary document" do
#    slmc.login("dasdoc5",@password).should be_true
    slmc.login("dcvillanueva","dcvillanueva").should be_true
    slmc.go_to_doctor_ancillary
    slmc.patient_pin_search(:pin => @@gu_pin).should be_true
    slmc.is_text_present(@@gu_pin).should be_true
    slmc.verify_document_action.should == 'Results Retrieval'
  end
  
  it "Patient Results - Search by Exam date" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@gu_pin)
    slmc.go_to_gu_page_for_a_given_pin("Patient Results", @@gu_pin)
    slmc.result_list_search(:start_date => Time.now.strftime("%m/%d/%Y"), :end_date => Time.now.strftime("%m/%d/%Y"), :search => true).should be_true
  end

  it "Patient Results - Search by Request date" do
    slmc.result_list_search(:start_request => Time.now.strftime("%m/%d/%Y"), :end_request => Time.now.strftime("%m/%d/%Y"), :search => true).should be_true
  end

  it "Patient Results - Search & select Test Procedure" do
    slmc.result_list_search(:test_procedure => "003600000000006", :search => true).should be_false #ALDOSTERONE
    slmc.result_list_search(:test_procedure => "006200000000115", :search => true).should be_true #Urine Hemosiderin Test
  end

  it "Patient Results - Search & Select Performing Unit" do
    slmc.result_list_search(:performing_unit => "PHARMACY", :search => true).should be_false
    slmc.result_list_search(:performing_unit => "CLINICAL MICROSCOPY", :search => true).should be_true
  end

  it "Patient Admission History - Search by Admission date" do
    slmc.click_patient_admission_history.should be_true
    slmc.search_patient_admission_history(:start_admission => Time.now.strftime("%m/%d/%Y"), :end_admission => Time.now.strftime("%m/%d/%Y")).should be_true
  end

  it "Patient Admission History - Search by Discharge date" do
    slmc.search_patient_admission_history(:start_discharge => Time.now.strftime("%m/%d/%Y"), :end_discharge => Time.now.strftime("%m/%d/%Y")).should == "No Visit History Found."
  end

   it "Patient Admission History - Search by Patient type" do
     slmc.search_patient_admission_history(:outpatient => true).should == "No Visit History Found."
     slmc.search_patient_admission_history(:inpatient => true).should be_true
  end

  it "Allows medical user to view ancillary document" do
    slmc.login('medical1',@password).should be_true
    slmc.go_to_medical_records
    slmc.medical_search_patient(@@gu_pin)
    slmc.click_medical_fullname
    slmc.verify_medical_record(@@ci_number).should be_true
  end

  ## scenarios below are based on Test Cases
  it "ARMS Das Technologist : Should return patient matching the search criteria" do
    slmc.login("sel_oss1", @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test").should be_true
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@patient)
    @@oss_pin = @@oss_pin.gsub(' ', '')
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin).should be_true
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:guarantor_type => "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true).should be_true
    slmc.oss_order(:order_add => true, :item_code => "010002376", :quantity => 1, :doctor => "0126", :filter => "WOMENS HEALTH CARE").should be_true
    @amount = slmc.get_total_amount_due.to_s + '00'
    slmc.oss_add_payment(:type => "CASH", :amount => @amount.to_s).should be_true
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    slmc.login('chriss',"chriss").should be_true
    slmc.modify_user_credentials(:user_name => "dastech18", :org_code => "0135")# #https://projects.exist.com/issues/39035
    slmc.login("dastech18", @password).should be_true
    slmc.go_to_arms_landing_page
    slmc.search_document(@@oss_pin)
    (slmc.get_text("results")).include?(@@oss_pin).should be_true
  end

  it "ARMS Das Technologist : Advance Search should have more options" do
    slmc.go_to_arms_landing_page
    slmc.arms_advance_search
    slmc.is_element_present("requestStartDate").should be_true
    slmc.is_element_present("requestEndDate").should be_true
    slmc.is_element_present("scheduleStartDate").should be_true
    slmc.is_element_present("scheduleEndDate").should be_true
    slmc.is_element_present("ciNumber").should be_true
    slmc.is_element_present("specimenNumber").should be_true
    slmc.is_element_present("itemCode").should be_true
    slmc.is_element_present("documentStatus").should be_true
    slmc.is_element_present("orderStatus").should be_true
    slmc.go_to_arms_landing_page
    slmc.arms_advance_search(:search => true)
    slmc.get_css_count("#results>tbody>tr").should_not == 0
  end

  it "ARMS Das Technologist : Das Technologist Work list" do
    slmc.go_to_arms_landing_page
    slmc.arms_advance_search(:request_start => "01/01/2005", :schedule_start => "01/01/2005", :search => true)
    contents = slmc.get_text("results")
    contents.include?("Request Date").should be_true
    contents.include?("Schedule Date").should be_true
    contents.include?("Patient Info").should be_true
    contents.include?("Item Description").should be_true
    contents.include?("CI No.").should be_true
    contents.include?("Specimen No.").should be_true
    contents.include?("HL7 Flag").should be_true
    contents.include?("Document Status").should be_true
    contents.include?("Destination App").should be_true
    contents.include?("Actions").should be_true
    slmc.get_css_count("css=#results>tbody>tr").should <= 20
  end

  # signatory  = 0409481 JULIUS CEZAR P. ROJALES
  it "Combining Test Result Data entry" do
    slmc.go_to_arms_landing_page
    slmc.arms_advance_search(:search => true)
    slmc.click("css=#results>tbody>tr>td>input")
    slmc.click_enter_results_for_selected_items.should be_true
    slmc.assign_signatory(:one => true, :code1 => "0209139", :two => true, :code2 => "0209139")
    slmc.save_signatories.should be_true
  end

  it "ARMS Doctor/Non Doctor Ancillary : Advance Search: Exam Date, Scheduled Date, Performing Unit, Procedure Name" do
    slmc.login(@user, @password)
    slmc.go_to_doctor_ancillary
    slmc.click_advanced_search
    content = slmc.get_text "advanceOptions"
    content.include?("Examination Date").should be_true
    content.include?("Request Date").should be_true
    content.include?("Performing Unit").should be_true
    content.include?("Procedure Name").should be_true
  end

  it "ARMS Doctor/Non Doctor Ancillary : Doctor/Non-Doctor Worklist" do
    content = slmc.get_text("results")
    content.include?("PIN").should be_true
    content.include?("Patient Name").should be_true
    content.include?("Exam Date").should be_true
    content.include?("Procedure Name").should be_true
    content.include?("Performing Unit").should be_true
    content.include?("Specimen No.").should be_true
    content.include?("Date Requested").should be_true
    content.include?("Date/Time Tagged as Official").should be_true
    content.include?("Actions").should be_true
  end

  it "ARMS Medical Records" do
    slmc.go_to_medical_records
    slmc.medical_search_patient(@@oss_pin)
    slmc.click "css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for => :page
    slmc.is_element_present("startExamDate").should be_true
    slmc.is_element_present("endExamDate").should be_true
    slmc.is_element_present("startRequestDate").should be_true
    slmc.is_element_present("endRequestDate").should be_true
    slmc.is_element_present("testProcedureDescription").should be_true
    slmc.is_element_present("performingUnitDescription").should be_true
  end

  it "Patient Result listing" do
    slmc.go_to_medical_records
    slmc.medical_search_patient("1")
    slmc.get_css_count("#results>tbody>tr").should <= 20
    slmc.advance_medical_search_patient(@patient)
  end

  it "Create patient for Feature #47137 and bugs on readers fee" do
    slmc.login("or21", @password).should be_true
    @@slmc_or_pin = slmc.or_create_patient_record(@or_patient.merge(:admit => true, :gender => 'F')).gsub(' ','').should be_true

    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@slmc_or_pin)
    slmc.search_order(:ancillary => true, :code => "010000385").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010000385",  :add => true).should be_true
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single").should == 1
    slmc.confirm_validation_all_items.should be_true

    #deposit payment
    slmc.login("sel_pba13", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@slmc_or_pin, :admitted => true)
    @@slmc_or_vn = slmc.get_visit_number_using_pin(@@slmc_or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@slmc_or_vn)
    slmc.pba_hb_deposit_payment(:cash => '100.00').should be_true

    #encode test result
    slmc.login("sel_readers_fee_user1", @password).should be_true
    slmc.go_to_arms_landing_page
    slmc.search_document(@@slmc_or_pin)
    @@ci_number = slmc.get_text(Locators::ARMS.ci_number_list)
    slmc.click_results_data_entry

    #panic value inserted
    slmc.type"PARAM::005800000000026::RESULT","100" #pre-defined panic value
    sleep 10
    (slmc.is_element_present'//td[@style="background-color: rgb(255, 0, 0);"]').should be_true

    slmc.assign_signatory(:one => true, :code1 => "0209139")
    slmc.assign_signatory(:two => true, :code2 => "7099")

    #save result as created
    slmc.save_signatories.should be_true
    sleep 3

    #update result to queue for validation
    slmc.queue_for_validation
    sleep 3

    #validate result
    slmc.validate_document.should be_true
    slmc.validate_credentials(:username => "dasdoc5", :password => @password, :allowed => true).should == "VALIDATED"
    sleep 3

    #tag result as official
    slmc.tag_as_official.should be_true
    slmc.official_credentials(:username => "dcvillanueva", :password => "dcvillanueva", :allowed => true).should == "OFFICIAL"
    sleep 10
    slmc.go_to_arms_landing_page
    slmc.search_document(@@slmc_or_pin)
    sleep 3
    slmc.verify_document_status.should == 'OFFICIAL'

    #check if patient can be found in search result
  end
  
  it "Bug 40047: Unable to search patient from OR in Reader's Fee page" do
    slmc.go_to_readers_fee_page
    slmc.readers_fee_search(:patient_type => "OutPatient", :arms_template => "With ARMS Template", :with_result => true, :ci_num => @@ci_number).should be_true
  end

  it "Bug#28362 - [DAS] Readers Fee: Exception error when searching an outpatient without ARMS template" do
    slmc.readers_fee_search(:patient_type => "OutPatient", :arms_template => "Without ARMS Template").should be_true
  end

  it "Feature #47137 - Outpatient SPU ER/OR/DR: Check patient visibility after tagging as official" do
    slmc.login("or21", @password).should be_true
    sleep 2
    (slmc.is_element_present"trPanicValuesPat-#{@@slmc_or_pin}").should be_true
end

  it "Feature #47137 - Outpatient SPU ER/OR/DR: User did not submit action Print gate pass after PBA discharge" do
    slmc.go_to_occupancy_list_page
    @@slmc_or_vn = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@slmc_or_pin, :pf_amount => "1000", :save => true).should be_true
    slmc.login("sel_pba13", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@slmc_or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@slmc_or_pin)
    slmc.go_to_page_using_visit_number("Print Discharge Clearance", @@slmc_or_vn)
    
    slmc.login("or21", @password).should be_true
    sleep 2
    (slmc.is_element_present"trPanicValuesPat-#{@@slmc_or_pin}").should be_true
  end

  it "Feature #47137 - Outpatient SPU ER/OR/DR: System auto dismiss patient panic alert on discharge Print Gate Pass action" do
    slmc.or_print_gatepass(:pin => @@slmc_or_pin, :visit_no => @@slmc_or_vn).should be_true
    slmc.occupancy_pin_search(:pin => @@slmc_or_pin, :discharged => true).should be_true
    sleep 2
    (slmc.is_element_present"trPanicValuesPat-#{@@slmc_or_pin}").should be_false
  end

end
