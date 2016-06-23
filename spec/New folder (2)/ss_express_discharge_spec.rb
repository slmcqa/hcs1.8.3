require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Social Service - Express Discharge" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
#    @selenium_driver.evaluate_rooms_for_admission('0287', 'RCH08')
    @selenium_driver.start_new_browser_session
    @patient = Admission.generate_data
    @patient1 = Admission.generate_data
    @patient2 = Admission.generate_data
    @patient3 = Admission.generate_data
    @patient4 = Admission.generate_data
    @patient5 = Admission.generate_data
    @patient6 = Admission.generate_data
    @password = "123qweuser"
    @adm_user = "sel_adm6"
    @ss_user = "sel_ss2"
    @gu_user = "gu_spec_user9"
    @pba_user = "pba28"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


  it "Individual - Creates patient" do
    slmc.login(@adm_user, @password).should be_true
    slmc.go_to_admission_page
    slmc.admission_search(:pin => "test")
    @@pin = slmc.create_new_patient(@patient.merge(:gender => 'F')).gsub(' ','')
    slmc.admission_search(:pin => @@pin)#.should be_true
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it"Individual - Order Items" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Individual - Update guarantor - not fully settled" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin, :all_patients => true)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    #slmc.ss_update_guarantor(:pin => @@pin, :page => "Update Patient Information",:visit_number => slmc.visit_number, :guarantor_type => "INDIVIDUAL", :percent => "50", :flag => true).should be_true
    slmc.ss_update_guarantor(:guarantor_type => "INDIVIDUAL", :loa_percent => "50", :flag => true).should be_true
  end

  it"Individual - Patient’s hospital bill is not fully settled" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin)
    slmc.add_final_diagnosis(:save => true)#.should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@pin)
    sleep 2
    slmc.clinical_discharge(:pf_amount => "1000",:pf_type => "DIRECT", :type => "express")
    contents = slmc.get_text"errorMessages"
    contents.include?"Only fully paid (hospital bills and PF) patients are allowed to be express discharged".should be_true
  end

  it"Individual - Update guarantor - fully settled" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin, :all_patients => true)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.ss_update_guarantor(:guarantor_type => "INDIVIDUAL", :loa_percent => "100").should be_true
  end

  it"Individual - Patient’s hospital bill is fully settled " do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@pin)
    slmc.clinical_discharge(:pf_amount => "1000",:pf_type => "DIRECT", :type => "express")
    (slmc.get_text"successMessages").should == "Express discharge successful."
  end

  it "Company/HMO  - Creates patient" do
    slmc.login(@adm_user, @password).should be_true
    slmc.go_to_admission_page
    slmc.admission_search(:pin => "test")
    @@pin1 = slmc.create_new_patient(@patient1.merge(:gender => 'F')).gsub(' ','')
    slmc.admission_search(:pin => @@pin1)#.should be_true
    slmc.create_new_admission(:account_class => "COMPANY", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS", :guarantor_code => "ABSC001" ).should == "Patient admission details successfully saved."
  end

  it"Company/HMO  - Order Items" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin1)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Company/HMO - Update guarantor - not fully settled" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin1, :all_patients => true)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.ss_update_guarantor(:guarantor_type => "COMPANY", :loa_percent => "50", :guarantor_code => "ABSC001", :flag => true).should be_true
  end

  it"Company/HMO Guarantor not  100% covered" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin1).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin1)
    slmc.add_final_diagnosis(:save => true)#.should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin1).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@pin1)
    slmc.clinical_discharge(:pf_amount => "1000",:pf_type => "DIRECT", :type => "express")
    contents = slmc.get_text"errorMessages"
    contents.include?"Cannot express discharge.".should be_true
  end

  it"Company/HMO - Update guarantor - fully settled" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin1, :all_patients => true)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.ss_update_guarantor(:guarantor_type => "COMPANY", :loa_percent => "100").should be_true#,:guarantor_code => "ABSC001").should be_true
  end

  it"Company/HMO Guarantor with 100% covered" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin1)
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@pin1)
    slmc.clinical_discharge(:pf_amount => "1000",:pf_type => "DIRECT", :type => "express")
    (slmc.get_text"successMessages").should == "Express discharge successful."
  end

  it"Social Service  - Creates patient" do
    slmc.login(@adm_user, @password).should be_true
    slmc.go_to_admission_page
    slmc.admission_search(:pin => "test")
    @@pin2 = slmc.create_new_patient(@patient2.merge(:gender => 'F')).gsub(' ','')
    slmc.admission_search(:pin => @@pin2)#.should be_true
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :esc_no => "234", :ss_amount => "100",:dept_code => "OBSTETRICS AND GYNECOLOGY",
      :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it"Social Service  - Order Items" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin2)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    sleep 2
    slmc.is_text_present"Order item 010002376 - TRANSVAGINAL ULTRASOUND has been added successfully.".should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Social Service - Express discharge -  Express_flag  = 'Y' -  patient share = 0" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@pin2)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    amount = (slmc.get_text"//form[@id='recommendationForm']/div[4]/div/table/tbody/tr/td[1]").gsub(',','')
    sleep 2
    slmc.add_recommendation_entry(:express_discharge => true, :amount => amount)
  end

  it"Social Service - fully settled" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin2).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin2)
    slmc.add_final_diagnosis(:save => true)#.should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin2).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@pin2)
    slmc.clinical_discharge(:pf_amount => "1000",:pf_type => "COMPLIMENTARY", :type => "express")
    sleep 2
    (slmc.get_text"successMessages").should == "Express discharge successful."
  end

  it "Social Service  - Creates patient - Express_flag  = 'N'" do
    slmc.login(@adm_user, @password).should be_true
    slmc.go_to_admission_page
    slmc.admission_search(:pin => "test")
    @@pin3 = slmc.create_new_patient(@patient3.merge(:gender => 'F')).gsub(' ','')
    slmc.admission_search(:pin => @@pin3)#.should be_true
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :esc_no => "234", :ss_amount => "100",:dept_code => "OBSTETRICS AND GYNECOLOGY",
      :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it"Social Service  - Order Items" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin3)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Social Service - Express discharge -  Express_flag  = 'N" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@pin3)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    amount = (slmc.get_text"//form[@id='recommendationForm']/div[4]/div/table/tbody/tr/td[1]").gsub(',','')
    slmc.add_recommendation_entry(:amount => amount)
  end

  it"Social Service - fully settled - Express_flag  = 'N'" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin3)
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin3)
    slmc.add_final_diagnosis(:save => true)#.should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin3).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@pin3)
    slmc.clinical_discharge(:pf_amount => "1000",:pf_type => "COMPLIMENTARY", :type => "standard")
    (slmc.is_text_present"Express discharge successful.").should be_false
  end

  it "Social Service  - Creates patient - Express_flag  = 'Y' - Already settle the patient share approved by MSSD'" do
    slmc.login(@adm_user, @password).should be_true
    slmc.go_to_admission_page
    slmc.admission_search(:pin => "test")
    @@pin4 = slmc.create_new_patient(@patient4.merge(:gender => 'F')).gsub(' ','')
    slmc.admission_search(:pin => @@pin4)#.should be_true
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :esc_no => "234", :ss_amount => "100",:dept_code => "OBSTETRICS AND GYNECOLOGY",
      :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it"Social Service  - Order Items - Express_flag  = 'Y' - Already settle the patient share approved by MSSD" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin4)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    sleep 1
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Social Service - Express discharge -  Express_flag  = 'Y' - Already settle the patient share approved by MSSD" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@pin4).should be_true
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    amount = (slmc.get_text"//form[@id='recommendationForm']/div[4]/div/table/tbody/tr/td[1]").gsub(',','')
    slmc.add_recommendation_entry(:express_discharge => true, :amount => amount)
#    slmc.type"patientShare", amount
#    slmc.click"expressDischarge1"
#    slmc.is_checked"expressDischarge1".should be_true
#    slmc.click'//input[@type="submit" and @value="Submit"]',:wait_for => :page
  end

#  it"Social Service - Express discharge - Update guarantor - fully settled" do
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.click"optAll"
#    slmc.patient_pin_search(:pin =>@@pin4).should be_true
#    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
#    slmc.click"hospitalPayment"
#    slmc.click"fullPayment"
#    sleep 2
#    slmc.spu_hospital_bills(:type => "CASH")
#    slmc.click'//input[@type="submit" and @value ="Proceed with Payment"]',:wait_for => :page
#  end

  it"Social Service - fully settled - Express_flag  = 'Y' - Already settle the patient share approved by MSSD'" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin4).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin4)
    slmc.add_final_diagnosis(:save => true)#.should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin4).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@pin4)
    slmc.clinical_discharge(:pf_amount => "1000",:pf_type => "COMPLIMENTARY", :type => "express")
    (slmc.get_text"successMessages").should == "Express discharge successful."
  end

  it "Social Service  - Creates patient - Express_flag  = 'Y' - Not yet  settle the patient share approved by MSSD'" do
    slmc.login(@adm_user, @password).should be_true
    slmc.go_to_admission_page
    slmc.admission_search(:pin => "test")
    @@pin5 = slmc.create_new_patient(@patient5.merge(:gender => 'F')).gsub(' ','')
    slmc.admission_search(:pin => @@pin5)#.should be_true
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :esc_no => "234", :ss_amount => "100",:dept_code => "OBSTETRICS AND GYNECOLOGY",
      :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it"Social Service  - Order Items - Express_flag  = 'Y' - Not yet  settle the patient share approved by MSSD" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin5)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    sleep 1
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    sleep 2
    slmc.is_text_present"Order item 010002376 - TRANSVAGINAL ULTRASOUND has been added successfully.".should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Social Service - Express discharge -  Express_flag  = 'Y' - Not yet  settle the patient share approved by MSSD" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@pin5).should be_true
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    slmc.click"expressDischarge1"
    slmc.type"patientShare", "100"
    (slmc.get_value"patientShare").should == "100"
    slmc.is_checked"expressDischarge1".should be_true
    slmc.click'//input[@type="submit" and @value="Submit"]',:wait_for => :page
  end


  it"Social Service - Express_flag  = 'Y' - Not yet  settle the patient share approved by MSSD'" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin5).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin5)
    slmc.add_final_diagnosis(:save => true)#.should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin5).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@pin5)
    slmc.clinical_discharge(:pf_amount => "1000",:pf_type => "COMPLIMENTARY", :type => "express")
#    (slmc.get_text"successMessages").should == "Express discharge successful."
    contents = slmc.get_text"errorMessages"
    contents.include?"Cannot express discharge"

  end

  it "Social Service  - Creates patient - Express_flag  = 'Y' - OR AMOUNT IS LESS THAN the Patient share" do
    slmc.login(@adm_user, @password).should be_true
    slmc.go_to_admission_page
    slmc.admission_search(:pin => "test")
    @@pin6 = slmc.create_new_patient(@patient6.merge(:gender => 'F')).gsub(' ','')
    slmc.admission_search(:pin => @@pin6)#.should be_true
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :esc_no => "234", :ss_amount => "100",:dept_code => "OBSTETRICS AND GYNECOLOGY",
      :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it"Social Service  - Order Items - Express_flag  = 'Y' - OR AMOUNT IS LESS THAN the Patient share" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin6)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Social Service - Express discharge -  Express_flag  = 'Y' - OR AMOUNT IS LESS THAN the Patient share" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@pin6).should be_true
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    slmc.type"patientShare","100"
    (slmc.get_value"patientShare").should === "100"
    slmc.click"expressDischarge1"
    slmc.is_checked"expressDischarge1".should be_true
    slmc.click'//input[@type="submit" and @value="Submit"]', :wait_for => :page
  end

  it"Social Service - Express_flag  = 'Y' - OR AMOUNT IS LESS THAN the Patient share" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin6).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin6)
    slmc.add_final_diagnosis(:save => true)#.should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin6).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@pin6)
    slmc.clinical_discharge(:pf_amount => "1000",:pf_type => "COMPLIMENTARY", :type => "express")
    contents = slmc.get_text"errorMessages"
    contents.include?"is lesser than patient share".should be_true
  end

#  it"Successfully Discharge - Expresss Discharge" do#requires database manipulation
#
#  end

end
