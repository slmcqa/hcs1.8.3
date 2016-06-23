
require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Medical Records Module Test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
#    @selenium_driver.evaluate_rooms_for_admission('0287','RCH08')
    @med_patient = Admission.generate_data
    @patient = Admission.generate_data
    @patient1 = Admission.generate_data
    @user = "sel_medical1"
    @password = "123qweuser"
    @items = {"010001047" => {:desc => "URINE HEMOSIDERIN QUALITATIVE", :code => "0062"}}

    @adm_user = "sel_adm6"
    @gu_user = "gu_spec_user7"
    @pba_user = "pba23"
    @or_user = "sel_or8"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates patient" do
    slmc.login(@gu_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@pin = slmc.create_new_patient(Admission.generate_data.merge(:gender => 'M', :birth_day => '05/05/1984')).gsub(' ','')
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."

    slmc.admission_search(:pin => "a")
    @@med_pin = slmc.create_new_patient(@med_patient.merge(:gender => 'M', :birth_day => '05/05/1984')).gsub(' ','')
    slmc.admission_search(:pin => @@med_pin).should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Order Items" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin)
    slmc.search_order(:ancillary => true, :description => "010001047").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001047", :add => true).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Administratively discharged the patient" do
    slmc.nursing_gu_search(:pin => @@pin).should be_true
    slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_type => "DIRECT", :pf_amount => "1000" , :save=> true)
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
  end

  it "Access Patient Search page" do
    slmc.login(@user, @password).should be_true
    slmc.is_text_present "Medical Records".should be_true
  end

  it "Access Patient Search page" do
    slmc.go_to_medical_records
    slmc.is_text_present("Patient Search").should be_true
    slmc.is_text_present("PIN/Patient's Last Name:").should be_true
    slmc.is_element_present('//input[@name="param"]').should be_true
    slmc.is_element_present('//input[@id="search" and @name="search"]').should be_true
  end

  it "Searh patient by PIN/ Lastname" do
    slmc.medical_search(:pin => @@pin).should == @@pin
  end

  it "Search patient by using More Options tab" do
    @@name = slmc.get_table('results.1.2')
    @@name = @@name.scan(/\w+/)
    slmc.more_options(:pin => @@pin, :first_name => @@name[1]).should == @@pin
    slmc.more_options(:pin => @@pin, :middle_name => @@name[2]).should == @@pin
    slmc.more_options(:pin => @@pin, :gender => true).should == @@pin
    slmc.more_options(:pin => @@pin, :birth_day => true).should == @@pin
  end
#2scenarios before this is not applicable
  it "Display searched patients that matched the entered criteria" do
    slmc.medical_search(:pin => @@pin).should == @@pin
  end

  it "Patient information shall be displayed" do
    contents=slmc.get_text"results"
    contents.include?(@@pin).should be_true
    @@name=slmc.get_table'results.1.2'
    contents.include?(@@name).should be_true
    contents.include?("Male").should be_true
    contents.include?("Reprinting").should be_true
    slmc.get_text('css=#results>tbody>tr.even>td:nth-child(4)').should_not == ""
  end

  it "Seach patient by INVALID PIN" do
    slmc.more_options(:pin => @@pin).should be_true
  end

  it "Invalid pin displays alert" do
    sleep 10
    slmc.more_options(:pin => @@pin.gsub('1','9'), :alert => true).should be_true
  end

 it "Seach patient by FIRST NAME only" do
     @@name = @@name.scan(/\w+/)
     slmc.more_options(:first_name=> @@name[1], :no_result =>true).should be_true
  end

  it "Search first name displays alert" do
    slmc.more_options(:first_name=> @@name[1], :no_result => true).should be_true
  end

  it "Seach patient by MIDDLE NAME only" do
    slmc.more_options(:first_name=> @@name[2], :no_result => true).should be_true
  end

  it "Search middle name displays alert" do
    slmc.more_options(:first_name=> @@name[1], :no_result => true).should be_true
  end

  it "Seach patient by BIRTHDATE only" do
    slmc.more_options(:birth_day=> true, :no_result => true).should be_true
  end

  it "Search birth day displays alert" do
    slmc.more_options(:birth_day=> true, :no_result => true).should be_true
  end

  it "Seach patient by GENDER only" do
    slmc.more_options(:gender=> true, :no_result => true).should be_true
  end

  it "Search gender displays alert" do
    slmc.more_options(:gender=> true, :no_result => true).should be_true
  end

  it "Reprinting of PDS and label" do #3scenarios not applicable
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin).should == @@pin
    slmc.med_reprinting_page(:reprinting => true, :patient_data_sheet => true, :patient_label => true, :successful => true).should be_true
  end

  it "Reprinting without identifying/ marking document to print" do
    slmc.med_reprinting_page(:patient_label => true, :label_only => true).should be_true
  end

  it "Reprinting without inputting number of patient label/s to print " do
    slmc.med_reprinting_page(:no_items => true).should be_true
  end

  it "Cancel reprinting" do
    slmc.click'//input[@type="button" and @value="Cancel" and @onclick="submitForm(this);"]'
    sleep 10
  end

  it "Cancel reprinting - redirected to patient search page" do
    slmc.is_text_present("Patient Search").should be_true
  end

  it "Search patient not yet registered in the system for reprinting of docs" do
    slmc.go_to_medical_records
  end

  it "Displays alert when patient is not registered" do
    slmc.more_options(:pin => "SELENIUM_SURNAME", :first_name => "SAMPLE_TEST", :alert => true).should be_true
  end

  it "Creates newly registered/ created patient, not admitted and no confinement history" do
    slmc.login(@adm_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@pin1 = slmc.create_new_patient(@patient1).gsub(' ','')
    slmc.admission_search(:pin => @@pin1).should be_true
  end

  it "Search newly registered/ created patient, not admitted and no confinement history" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin1).should == @@pin1
  end

 it "Search newly registered/ created patient, not admitted and no confinement history  - printing not allowed" do
    slmc.med_reprinting_page(:reprinting => true, :patient_label => true, :with_previous_confinement => true).should be_true
 end

  it "Creates currently admitted patient" do
    slmc.login(@adm_user, @password).should be_true
    slmc.admission_search(:pin => @@pin1)#.should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

    it "Search currently admitted patient" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin1).should == @@pin1
    slmc.med_reprinting_page(:reprinting => true,:patient_data_sheet => true, :patient_label => true, :successful => true).should be_true
  end

  it "Creates clinically discharged patient where patient_type = I, for reprinting of documents" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin1)
    slmc.search_order(:ancillary => true, :description => "010001047").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001047", :add => true).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
    slmc.nursing_gu_search(:pin => @@pin1).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin1)
    slmc.add_final_diagnosis(:save => true)#.should be_true
    slmc.nursing_gu_search(:pin => @@pin1).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@pin1)
    sleep 2
    slmc.clinical_discharge(:pf_amount => "1000", :pf_type => "DIRECT", :type => "standard")
  end

  it "Search clinically discharged patient where patient_type = I, for reprinting of documents" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin1).should == @@pin1
    slmc.med_reprinting_page(:reprinting => true, :patient_data_sheet => true, :patient_label => true, :successful => true).should be_true
  end

  it "Creates administratively/ billing discharged patient where patient_type = I" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.patient_pin_search(:pin => @@pin1).should be_true
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
  end

  it "Search administratively/ billing discharged patient where patient_type = I" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin1).should == @@pin1
    slmc.med_reprinting_page(:reprinting => true, :patient_data_sheet => true, :patient_label => true, :successful => true).should be_true
  end

 it "Creates patient that is registered but not admitted BUT with previous confinement history" do
    slmc.login(@gu_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin1).should be_true
    slmc.print_gatepass(:pin => @@pin1)
 end

  it "Search patient that is registered but not admitted BUT with previous confinement history - displays alert" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin1).should == @@pin1
    slmc.med_reprinting_page(:reprinting => true, :patient_label => true, :with_previous_confinement => true).should be_true
  end

   it "Search patient tagged as Physically Out " do
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin1).should == @@pin1
  end

  it "Search patient tagged as Physically Out - displays message alert" do
    slmc.med_reprinting_page(:reprinting => true, :patient_label => true, :with_previous_confinement => true).should be_true
  end

  it "Creates patients tag as QUEUE FOR ADMISSION" do
    slmc.login(@adm_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@pin2 = slmc.create_new_patient(Admission.generate_data).gsub(' ','')
    slmc.admission_search(:pin => @@pin2).should be_true
    slmc.click("link=Admit Patient", :wait_for => :page)
    slmc.populate_admission_fields(:on_queue => true, :room_charge => "REGULAR PRIVATE")
    slmc.click("//input[@value='Preview' and @name='action' and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.click("//input[@value='Save Admission' and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.admission_search(:pin => @@pin2)
    slmc.get_text(Locators::Admission.admission_search_results_admission_status).should == "On Queue"
  end

  it "Search patients tag as QUEUE FOR ADMISSION" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin2).should == @@pin2
    slmc.med_reprinting_page(:reprinting => true, :patient_label => true, :with_previous_confinement => true).should be_true
  end

  it "Creates clinically discharged patient where patient_type = O" do
    slmc.login(@or_user, @password).should be_true
    @@pin3 = slmc.or_nb_create_patient_record(Admission.generate_data.merge!(:admit => true)).gsub(' ', '')
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin3).should be_true

    slmc.go_to_su_page_for_a_given_pin("Order Page", @@pin3).should be_true
    slmc.search_order(:ancillary => true, :description => "010001047").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001047", :add => true).should be_true
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_occupancy_list_page
    slmc.clinically_discharge_patient(:outpatient => true, :pin => @@pin3, :save => true, :pf_amount => "1000")
  end

  it "Search clinically discharged patient where patient_type = O" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin3).should == @@pin3
    slmc.med_reprinting_page(:reprinting => true, :patient_data_sheet => true, :patient_label => true, :successful => true).should be_true
  end

  it "Feature#44222 - (Medical Record) Add checkbox to filter currently admitted patients only" do
    slmc.go_to_medical_records
    slmc.click'slide-fade'
    sleep 1
    (slmc.is_element_present"admitted").should be_true
    slmc.more_options(:admitted => true, :pin => @@med_pin, :first_name => @med_patient[:first_name]).should == @@med_pin
  end

  it "Feature#44222 - (Medical Record) Add options to choose the location where the patient is currently admitted" do
    slmc.click'slide-fade'
    sleep 1
    (slmc.is_element_present"radioLocQC").should be_true
    (slmc.is_element_present"radioLocGC").should be_true
    slmc.more_options(:admitted => true, :pin => @@med_pin, :first_name => @med_patient[:first_name]).should == @@med_pin
  end

  it "Feature#44222 - (Medical Record) If the user chooses to search for currently admitted patients only, by default, button for the location is that of the Application’s location" do
    slmc.click'slide-fade'  if ((slmc.is_visible'admitted').should be_false)
    sleep 1
    slmc.click'admitted'
    sleep 1
    (slmc.is_checked"radioLocGC").should be_true
    slmc.click'slide-fade'
  end

  it "Feature#44222 - (Medical Record) The list of currently admitted patients would show the following patient information: Room, Admitting Doctor, Admission Date" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_medical_records
    slmc.more_options(:pin => @@med_pin, :first_name => @med_patient[:first_name],:admitted => true).should == @@med_pin
    @admission_date = (slmc.access_from_database(:what => "ADM_DATETIME",:table => "TXN_ADM_ENCOUNTER",:column1 => "PIN",:condition1 => @@med_pin)).to_s
    @admission_date = @admission_date.scan(/\w+/)
    contents=slmc.get_text"css=#results>tbody>tr.even"
    (contents.include?"ABAD").should be_true
    (contents.include?"Admitted").should be_true
    (contents.include?@admission_date[7]).should be_true
  end

  it "Feature #44081 - Patient List - patient is already registered and admitted, will not be found on medical records" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@med_pin)
    slmc.search_order(:ancillary => true, :description => "010001047").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001047", :add => true).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true

    slmc.login(@user, @password).should be_true
    slmc.go_to_final_diagnosis_review
    slmc.search_patient_diagnosis_review(:pin => @@med_pin, :alert => true).should be_true
  end

  it "Feature #44081 - Patient List - patient is already pba discharge, will not be found on medical records" do
    slmc.login(@gu_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@med_pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@med_pin)

    # discharge instruction w/out icd10.
    slmc.add_final_diagnosis(:text_final_diagnosis => "SELENIUM WITHOUT ICD10 DIAGNOSIS", :save => true)#.should be_true

    slmc.nursing_gu_search(:pin => @@med_pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@med_pin)
    sleep 2
    slmc.clinical_discharge(:pf_amount => "1000", :pf_type => "DIRECT", :type => "standard")

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.patient_pin_search(:pin => @@med_pin).should be_true
    @@med_original_pin = slmc.get_text"css=#results>tbody>tr>td"
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true

    slmc.login(@user, @password).should be_true
    slmc.go_to_final_diagnosis_review
    slmc.search_patient_diagnosis_review(:pin => @@med_pin, :alert => true).should be_true
  end

  it "Feature #44081 - Patient List - discharge clearance" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@med_pin)
    @@med_visit_no = slmc.get_visit_number_using_pin(@@med_pin)
    slmc.go_to_page_using_visit_number("Print Discharge Clearance", @@med_visit_no)

    slmc.login(@user, @password).should be_true
    slmc.go_to_final_diagnosis_review
    slmc.search_patient_diagnosis_review(:pin => @@med_pin, :alert => true).should be_true
  end

  it "Feature #44081 - Patient without icd10" do
    slmc.login(@gu_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@med_pin).should be_true
    slmc.print_gatepass(:pin => @@med_pin)
  end

  it "Feature #44081 - Initial Patient Display" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_final_diagnosis_review
    (slmc.is_text_present(@@med_original_pin)).should be_true
    (slmc.is_element_present"inpatient_tab").should be_true
    (slmc.is_element_present"outpatient_tab").should be_true
  end

  it "Feature #44081 - Patient List - there will be AVERAGE() summary on how many patient was discharged within the day"do
    count = slmc.get_css_count"css=#results>tbody>tr"
    (slmc.get_text"//span[@class='breadCrumbSub']").should == "#{count} Patient Discharge(s)"
  end

  it "Feature #44081 - Patient List - column checking"do
    (slmc.get_text"css=#results>thead").should == "Patient Name PIN Discharge Date/Time Visit No Admission Date/Time Nursing Unit Diagnosis Details"
     slmc.search_patient_diagnosis_review(:pin => @@med_pin, :visit_no => @@med_visit_no).should be_true
  end

  it "Feature #44081 - Patient List - Create turned as inpatient" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration
    @@or_pin = slmc.outpatient_registration(Admission.generate_data).gsub(' ','').should be_true

    slmc.adjust_outpatient_date(:days_to_adjust => 1,:table => "TXN_PATMAS",:table_column=>"CREATED_DATETIME", :pin => @@or_pin)

    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.click_register_patient
    slmc.spu_or_register_patient(:turn_inpatient => true,:acct_class => "INDIVIDUAL",:doctor => "6726", :preview => true, :save => true).should be_true

    slmc.login(@adm_user, @password).should be_true
    slmc.admission_search(:pin => @@or_pin)
    slmc.er_outpatient_to_inpatient(:pin => @@or_pin, :room_label => "REGULAR PRIVATE", :diagnosis => "GASTRITIS")

    slmc.login(@gu_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@or_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@or_pin)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    sleep 2
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true

    slmc.nursing_gu_search(:pin=> @@or_pin)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@or_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    @@or_original_pin = slmc.get_text"css=#results>tbody>tr>td"
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true

    slmc.login(@gu_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@or_pin).should be_true
    slmc.print_gatepass(:pin => @@or_pin)
  end

 it "Feature #44081 - Patient List - Admission date and time will be the time patient was turned as inpatient" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_final_diagnosis_review
    slmc.search_patient_diagnosis_review(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
    ((slmc.get_text"css=#results>tbody>tr>td:nth-child(5)>a").include?Time.now.strftime("%Y-%m-%d")).should be_true
 end

  it "Feature #44081 - Patient List - Patient Seach Criteria – search by Visit_No" do
    slmc.go_to_final_diagnosis_review
    slmc.search_patient_diagnosis_review(:visit_no => @@visit_no).should be_true
  end

  it "Feature #44081 - Pending Patient Alerts - patient should be included in Patient Confinement/s w/o Text Diagnosis list" do #med_pin
    slmc.click_final_diagnosis_review_link(:without_icd10 => true)
    slmc.search_without_icd10_table(:pin =>  @@med_original_pin).should be_true
  end

  it "Feature #44081 - Editing an exisitng free text diagnosis" do
    slmc.final_diagnosis_review(:pin => @@med_pin, :visit_no => @@med_visit_no).should be_true
    slmc.click"//input[@type='button' and @value='Edit']"
    sleep 1
    (slmc.is_element_present"freeTextPopup").should be_true
    slmc.type"freeText",("SELENIUM WITHOUT ICD10 DIAGNOSIS" * 3)
    slmc.click"//html/body/div[7]/div[11]/div/button[2]"
    sleep 1
    (slmc.is_element_present"confirmSubmitPopup").should be_true
    slmc.click"//html/body/div[5]/div[3]/div/button[2]/span", :wait_for => :page
    (slmc.get_text"css=#diagnosis>tbody>tr>td").should == ("SELENIUM WITHOUT ICD10 DIAGNOSIS" * 3)
  end

  it "Feature #44081 - View Diagnosis Page -  ICD10 code reflected is the to what was entered during clinical discharge" do
    slmc.go_to_final_diagnosis_review
    slmc.final_diagnosis_review(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
    (slmc.get_text"css=#icd10>tbody>tr>td:nth-child(2)").should == "CHOLERA"
  end

  it "Feature #44081 - View Diagnosis Page/Deleting an existing ICD 10 code per patient" do
    slmc.click"//input[@type='button' and @value='Delete']"
    slmc.click"//html/body/div[5]/div[3]/div/button[2]/span", :wait_for => :page
    (slmc.get_text"css=#icd10>tbody>tr>td").should == "Nothing to display"
    (slmc.access_from_database(:what => "STATUS",:table => "TXN_ADM_DIAGNOSIS",:column1=>"VISIT_NO",:condition1 => @@visit_no,
      :gate => "AND",:column2 => "DIAGNOSIS_DESCRIPTION",:condition2 => "CHOLERA")).should == "C"
  end

  it "Feature #44081 - Pending Patient Alerts - patient will not be included in the list anymore, since patient already have an ICD10 code final diagnosis" do
    slmc.go_to_final_diagnosis_review
    sleep 2
    count = slmc.get_css_count "css=#results>tbody>tr"
    rows = 0
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#results>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)>a")
      count-=1
      rows+=1
    end
    ((@@arr.to_s).include?@@or_original_pin).should be_true

    slmc.final_diagnosis_review(:pin => @@or_pin, :visit_no => @@visit_no).should be_true
    slmc.medical_final_diagnosis(:icd10_diagnosis => "K29.0").should be_true

    slmc.go_to_final_diagnosis_review
    sleep 2
    count = slmc.get_css_count "css=#results>tbody>tr"
    rows = 0
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#results>tbody>tr:nth-child(#{rows + 1})")
      count-=1
      rows+=1
    end
    ((@@arr.to_s).include?@@or_original_pin).should be_false
  end

  it "Feature #44081 - Adding ICD 10 code on Patient" do
    slmc.final_diagnosis_review(:pin => @@med_pin, :visit_no => @@med_visit_no).should be_true
    slmc.medical_final_diagnosis(:icd10_diagnosis => "A00").should be_true

    slmc.medical_final_diagnosis(:icd10_diagnosis => "A01.03").should be_true
    sleep 1
    (slmc.get_text"css=#icd10>tbody>tr:nth-child(2)>td").should == "A01.03"
  end

  it "Feature #44081 - Deleting an exisitng free text diagnosis" do  #selenium cannot do the Adding Free text diagnosis on Patient scenario
    slmc.click"css=#diagnosis>tbody>tr>td:nth-child(2)>input:nth-child(2)"
    sleep 1
    slmc.click"//html/body/div[5]/div[11]/div/button[2]", :wait_for => :page
    (slmc.get_text"css=#diagnosis>tbody>tr>td").should == "Nothing to display"
  end

  it "Feature Checlist - ICD10 File Maintenance" do
    slmc.login(@user, @password).should be_true
    slmc.click"link=ICD10", :wait_for => :page
  end

  it "Feature Checlist - List ICD10" do
    (slmc.get_css_count"css=#results>tbody>tr").should == 20
    (slmc.get_text"css=#results>thead>tr").should == "Icd10 Code Description"
  end

  it "Feature Checklist -  Search ICD10 - through code" do
    ((slmc.search_file_maintenance_icd10(:code => "A00")).include?"A00").should be_true
  end

  it "Feature Checklist -  Search ICD10 - through description" do
    ((slmc.search_file_maintenance_icd10(:desc => "CHOLERA")).include?"CHOLERA").should be_true

    count = slmc.get_css_count"css=#results>tbody>tr"
    count.times do |row|
      my_row = slmc.get_text("css=#results>tbody>tr:nth-child(#{row + 1})>td:nth-child(2)")
      @@result = my_row.include?("CHOLERA")
    end

    (@@result.to_s).should == "true"
  end

  it "Feature Checklist -  Add ICD10" do
    slmc.click"//input[@type='button' and @value='Add']", :wait_for => :page
    (slmc.get_text"icd10Form").should == "Icd10 Code: \n Description: \n Sub-Category Code: \n \n Sub-Category Description: \n Sub-Category Range: \n Major Category Code: \n Major Category Description: \n Major Category Range:"
  end

  it "Feature Checlist - Search & select ICD10 sub category" do
    slmc.search_icd10_sub_cat(:diagnosis => "TUBERCULOSIS").should be_true
  end

  it "Feature Checlist - Save - Manage ICD10 List" do
    slmc.click"saveBtn"
    (slmc.get_text"errorText").should == "code is required to continue."
    slmc.click"//html/body/div[4]/div[11]/div/button/span"
    sleep 1

    slmc.type"icd10_code","SE00"
    slmc.click"saveBtn"
    (slmc.get_text"errorText").should == "description is required to continue."
    slmc.click"//html/body/div[4]/div[11]/div/button/span"

    slmc.type"icd10_description","Selenium Diagnosis"
    slmc.click"saveBtn", :wait_for => :page

    (slmc.get_text"successMessages").should == "Icd10 SE00 has been added successfully."
  end

  it "Feature Checlist - Edit ICD10" do
    (slmc.search_file_maintenance_icd10(:code => "SE00").include?"SE00").should be_true
    slmc.click"link=SE00", :wait_for => :page
  end

  it "Feature Checlist - Edit ICD10 - Search & select ICD10 sub category" do
    slmc.search_icd10_sub_cat(:diagnosis => "GLAUCOMA").should be_true
  end

  it "Feature Checlist - Edit ICD10 - Update" do
    slmc.click"saveBtn", :wait_for => :page
    (slmc.get_text"successMessages").should == "Icd10 SE00 has been updated successfully."
  end

  it "Feature Checlist - Delete ICD10" do
    (slmc.search_file_maintenance_icd10(:code => "SE00").include?"SE00").should be_true
    slmc.click"link=SE00", :wait_for => :page
    slmc.click"delete"
    sleep 1
    (slmc.is_element_present"deleteDialog").should be_true
    slmc.click"//html/body/div[8]/div[11]/div/button[2]", :wait_for => :page
    (slmc.get_text"successMessages").should == "Icd10 SE00 has been deleted successfully."
  end

end
