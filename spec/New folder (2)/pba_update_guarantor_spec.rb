require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: PBA Guarantor Test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @user = "update_guarantor_spec_user"
    @pba_patient = Admission.generate_data
    @password = "123qweuser"    
  
    # constant variables
    @pf_amount = "1000.0"
    @max_pf_coverage = 500.00
    @loa_percent1 = 50.00
    @loa_percent2 = 25.00
    
    @@employee = "1104000682" # "1112100128"
    @@employee_dependent = "1104000683" # "1112100129"
    @@board_member_dependent = "1104000706" # "1112100127"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates patient for pba transactions " do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pba_pin = slmc.create_new_patient(@pba_patient.merge(:gender => 'M'))
    slmc.admission_search(:pin => @@pba_pin).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0278', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

#  it "Test if input field for Search accepts either description or item code" do
#    slmc.go_to_general_units_page
#    slmc.go_to_adm_order_page(:pin => @@pba_pin)
#    slmc.search_order(:drugs => true, :description =>  "040004334").should be_true
#    slmc.search_order(:supplies => true, :description => "080200000").should be_true
#    slmc.search_order(:ancillary => true, :description => "010000003").should be_true
#    slmc.search_order(:others => true, :description => "050000009").should be_true
#    slmc.search_order(:drugs => true, :description => "SOLUSET").should be_true
#    slmc.search_order(:supplies => true, :description => "NASO-TRACHEAL TUBE IVORY S7").should be_true
#    slmc.search_order(:ancillary => true, :description => "BONE IMAGING - THREE PHASE STUDY").should be_true
#    slmc.search_order(:others => true, :description => "BLOOD WARMER - SUCCEDING HOUR").should be_true
#  end

  it "Patient performs clinical ordering" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pba_pin)
    slmc.search_order(:ancillary => true, :description => "ALDOSTERONE").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "ALDOSTERONE", :add => true).should be_true
    slmc.submit_added_order.should be_true
    slmc.validate_item("ALDOSTERONE").should be_true
  end

  it "Creates patient of account class - BOARD MEMBER DEPENDENT" do
    slmc.nursing_gu_search(:pin => @@board_member_dependent)
    slmc.print_gatepass(:no_result => true, :pin => @@board_member_dependent)
    slmc.admission_search(:pin => @@board_member_dependent)
    if (slmc.get_text("results").gsub(' ', '').include? @@board_member_dependent) && slmc.is_element_present("link=Admit Patient")
      slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0278', :diagnosis => "ULCER", :account_class => "BOARD MEMBER DEPENDENT", :guarantor_code => "BMAA001").should == "Patient admission details successfully saved."
    else
      if slmc.is_text_present("NO PATIENT FOUND")
        @@board_member_dependent = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "ANCHETA", :first_name => "BELLA", :middle_name => "CARIDAD", :birth_day => "09/25/1933", :gender => 'F'))
      else
        if slmc.verify_gu_patient_status(@@board_member_dependent) != "Clinically Discharged"
          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@board_member_dependent, :validate => true, :username => "sel_0278_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
          slmc.go_to_general_units_page
          slmc.clinically_discharge_patient(:pin => @@board_member_dependent, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
        end
        slmc.login("sel_pba3", @password).should be_true
        slmc.go_to_patient_billing_accounting_page
        slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
        slmc.discharge_patient_either_standard_or_das.should be_true
        
        slmc.login(@user, @password).should be_true
        slmc.nursing_gu_search(:pin => @@board_member_dependent)
        slmc.print_gatepass(:no_result => true, :pin => @@board_member_dependent).should be_true
      end
      slmc.admission_search(:pin => @@board_member_dependent)
      slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0278', :diagnosis => "ULCER", :account_class => "BOARD MEMBER DEPENDENT", :guarantor_code => "BMAA001").should == "Patient admission details successfully saved."
    end
  end

  it "Admits/Creates patient of account class - EMPLOYEE(HE)" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@employee)
    slmc.print_gatepass(:no_result => true, :pin => @@employee)
    slmc.admission_search(:pin => @@employee)
    if (slmc.get_text("results").gsub(' ', '').include? @@employee) && slmc.is_element_present("link=Admit Patient")
      slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0278', :diagnosis => "ULCER", :account_class => "EMPLOYEE", :guarantor_code => "0109092").should == "Patient admission details successfully saved."
    else
      if slmc.is_text_present("NO PATIENT FOUND")
        @@employee = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "Tan", :first_name => "Peter Carlo", :middle_name => "Go", :birth_day => "08/01/1986", :gender => 'M'))
      else
        if slmc.verify_gu_patient_status(@@employee) != "Clinically Discharged"
          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@employee, :validate => true, :username => "sel_0278_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
          slmc.go_to_general_units_page
          slmc.clinically_discharge_patient(:pin => @@employee, :pf_amount => '1000', :save => true).should be_true
        end
        slmc.login("sel_pba3", @password).should be_true
        slmc.go_to_patient_billing_accounting_page
        slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
        slmc.discharge_patient_either_standard_or_das.should be_true
        
        slmc.login(@user, @password).should be_true
        slmc.nursing_gu_search(:pin => @@employee)
        slmc.print_gatepass(:no_result => true, :pin => @@employee).should be_true
      end
      slmc.admission_search(:pin => @@employee)
      slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0278', :diagnosis => "ULCER", :account_class => "EMPLOYEE", :guarantor_code => "0109092").should == "Patient admission details successfully saved."
    end
  end

  it "Admits/Creates patient of account class - EMPLOYEE DEPENDENT(HED)" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@employee_dependent)
    slmc.print_gatepass(:no_result => true, :pin => @@employee_dependent)
    slmc.admission_search(:pin => @@employee_dependent)
    if (slmc.get_text("results").gsub(' ', '').include? @@employee_dependent) && slmc.is_element_present("link=Admit Patient")
      slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0278', :diagnosis => "ULCER", :account_class => "EMPLOYEE DEPENDENT", :guarantor_code => "0109092").should == "Patient admission details successfully saved."
    else
      if slmc.is_text_present("NO PATIENT FOUND")
        @@employee_dependent = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "Tan", :first_name => "Rachel Mae", :middle_name => "Go", :birth_day => "07/26/1987", :gender => 'F'))
      else
        if slmc.verify_gu_patient_status(@@employee_dependent) != "Clinically Discharged"
          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@employee_dependent, :validate => true, :username => "sel_0278_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
          slmc.go_to_general_units_page
          slmc.clinically_discharge_patient(:pin => @@employee_dependent, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
        end
        slmc.login("pba25", @password).should be_true
        slmc.go_to_patient_billing_accounting_page
        slmc.pba_search(:with_discharge_notice => true, :pin => @@employee_dependent)
        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
        slmc.discharge_patient_either_standard_or_das.should be_true

        slmc.login(@user, @password).should be_true
        slmc.nursing_gu_search(:pin => @@employee_dependent)
        slmc.print_gatepass(:no_result => true, :pin => @@employee_dependent).should be_true
     end
      slmc.admission_search(:pin => @@employee_dependent)
      slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0278', :diagnosis => "ULCER", :account_class => "EMPLOYEE DEPENDENT", :guarantor_code => "0109092").should == "Patient admission details successfully saved."
    end
  end

  it "Performs clinical ordering for EMPLOYEE/DEPENDENT, BOARD MEMBER DEPENDENT patient " do
    patients = [@@employee, @@employee_dependent, @@board_member_dependent]

    patients.each do |patient|
      slmc.go_to_general_units_page
      slmc.go_to_adm_order_page(:pin => patient)
      slmc.search_order(:ancillary => true, :description => "ALDOSTERONE").should be_true
      slmc.add_returned_order(:ancillary => true, :description => "ALDOSTERONE", :add => true).should be_true
      slmc.submit_added_order.should be_true
      slmc.validate_item("ALDOSTERONE").should be_true
    end
  end

  it "Clinical Discharge pba patient" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pba_pin, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :save => true).should be_true
  end

  it "Bug #28575 - [PBA] PF define during clinical discharge, not reflected in PBA" do
    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Update Patient Information", @@visit_no)
    slmc.get_value("css=span>input").to_f.should == 1000.0
    slmc.get_text("css=#row>tbody>tr>td:nth-child(5)").gsub(',','').to_f.should == 1000.0
  end

  it "Updates Patient Information by adding Professional Fee to PBA patient" do
    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Update Patient Information", @@visit_no)
    slmc.add_pf_amount(:pf_amount => @pf_amount).should be_true # will only appear if pf type = COLLECT
  end

  it "Updates guarantor of type INDIVIDUAL, should allow user to input any name and should not validate for LOA, maximum amount and percentage" do
    slmc.click_guarantor_to_update.should be_true
    slmc.pba_update_guarantor(:guarantor_type => "INDIVIDUAL", :loa => "test123", :name => "Company/Patient name/Third party").should be_true
  end

  it "Adds new guarantor of type HMO, should validate for mandatory fields" do
    slmc.click_new_guarantor.should be_true
    (slmc.pba_update_guarantor(:guarantor_type => "HMO").include? "Guarantor Code is a required field. \n Guarantor Name is a required field. \n Either maximum amount or percentage limit of LOA can have values but not both.").should be_true
  end

  it "Adds new guarantor of type COMPANY successfully" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Update Patient Information", @@visit_no)
    slmc.click_new_guarantor.should be_true
    slmc.pba_update_guarantor(:guarantor_type => "COMPANY", :guarantor_code => "ACCENTURE", :include_pf => true, :include_pf_doctor => true, :max_pf_coverage => @max_pf_coverage.to_s, :loa => "qwerty", :loa_percent => @loa_percent1.to_s).should be_true
  end

  it "Computes outstanding hospital bill based on added guarantor" do
    # go to payment page and verify hospital bills
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:all_patients => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)

    hospital_bill = slmc.get_hospital_bill_amount.to_f
    room_charges = slmc.get_room_charges_amount.to_f
    discount = slmc.get_discount_amount.to_f
    pf_amount = slmc.get_pf_amount.to_f
    pf_charged = slmc.get_pf_charged_amount.to_f
    pf_payment = slmc.get_pf_payment_amount.to_f

    total_amount_due = ((((hospital_bill + room_charges)  - discount) * (@loa_percent1/100.00) + (pf_amount - (pf_charged + pf_payment))) * 100 ).round.to_f / 100
    total_amount_due.should == ("%0.2f" %(slmc.get_total_amount)).to_f
  end

  it "Includes PF amount in guarantor maximum amount/percentage limit deduction if 'Include PF' is ticked" do
    pf_amount = slmc.get_pf_amount.to_i
    @@pf_balance = ((pf_amount - @max_pf_coverage) * 100 ).round.to_f / 100
    @max_pf_coverage.should == slmc.get_pf_charged_amount.to_f
  end

  it "Recomputes PF amount, charges after adding multiple guarantors" do
    # go to update patient info page to add multiple guarantor
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Update Patient Information", @@visit_no)
    slmc.click_new_guarantor.should be_true
    slmc.pba_update_guarantor(:guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :loa => "987654321", :loa_percent => @loa_percent2.to_s).should be_true

    # go to payment page and verify hospital bills
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)

    slmc.get_pf_amount.should == ("%0.2f" %(@pf_amount.to_f))
    slmc.get_pf_charged_amount.should == ("%0.2f" %(@max_pf_coverage))
  end

  it "Recomputes outstanding hospital bill based on multiple guarantor" do
    multiple_guarantor = @loa_percent1 + @loa_percent2
    hospital_bill = slmc.get_hospital_bill_amount.to_f
    room_charges = slmc.get_room_charges_amount.to_f
    discount = slmc.get_discount_amount.to_f
    pf_amount = slmc.get_pf_amount.to_f

    #verify that Charged Amount recomputes based on multiple guarantors
    charged_amount = (((hospital_bill + room_charges) - discount) * (multiple_guarantor/100.00) * 100).round.to_f / 100
    charged_amount.should == slmc.get_charged_amount.to_f

    #verify that Total Amount Due recomputes based on multiple guarantors
    @@total_amount_due = ((((hospital_bill + room_charges) - discount) - charged_amount + (pf_amount - @max_pf_coverage)) * 100 ).round.to_f / 100
    #@@total_amount_due.should == ("%0.2f" %(slmc.get_total_amount.to_f - 0.01)).to_f
    ((slmc.truncate_to((@@total_amount_due.to_f - slmc.get_total_amount.to_f),2).to_f).abs).should <= 0.02
  end

  it "Proceed PF payment successfully" do
    slmc.pba_pf_payment(:deposit => true, :pf_amount => @@pf_balance.to_s).should be_true
  end

  it "Proceed CASH payment for a patient with multiple guarantor" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    balance_due = @@total_amount_due - @max_pf_coverage + 0.1
    slmc.oss_add_payment(:type => 'CASH', :amount => (balance_due).to_s)
    slmc.submit_payment.should be_true
  end

  it "Verifies DEFAULT guarantor code for account class - BOARD MEMBER DEPENDENT" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@board_member_dependent)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.get_text(Locators::PBA.guarantor_code_info).should == "BMAA001"
  end

  it "Deletes existing guarantor code for EMPLOYEE patient" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@employee)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.select_guarantor
    slmc.click_delete_guarantor.should be_true
  end

  it "Validates INVALID guarantor code for EMPLOYEE patient" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@employee)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.click_new_guarantor.should be_true
    slmc.pba_update_guarantor(:guarantor_type => "EMPLOYEE", :guarantor_code => "0109091").should == "Employee guarantor should be the patient."
  end

  it "Adds VALID guarantor code for EMPLOYEE patient" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@employee)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.click_new_guarantor.should be_true
    slmc.pba_update_guarantor(:guarantor_type => "EMPLOYEE", :guarantor_code => "0109092", :loa => "987654321", :philhealth => true).should be_true
  end

  it "Updates existing guarantor and validates INVALID guarantor code for EMPLOYEE DEPENDENT patient" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@employee_dependent)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.select_guarantor
    slmc.click_update_guarantor.should be_true
    slmc.pba_update_guarantor(:guarantor_type => "EMPLOYEE", :guarantor_code => "0109043", :loa => "987654321").should == "Patient is not registered as Employee Dependent."  #  "Employee is not a valid benefactor."
  end

  it "Updates existing guarantor to a VALID guarantor code for EMPLOYEE DEPENDENT patient" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@employee_dependent)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.select_guarantor
    slmc.click_update_guarantor.should be_true
    slmc.pba_update_guarantor(:guarantor_type => "EMPLOYEE", :guarantor_code => "0109092", :loa => "987654321").should be_true
  end

  it "Clinically Discharge patient with EMPLOYEE and EMPLOYEE DEPENDENT guarantor" do
    slmc.login(@user, @password).should be_true
    patients = [@@employee, @@employee_dependent]
    patients.each do |patient|
      slmc.go_to_general_units_page
      slmc.clinically_discharge_patient(:pin => patient, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
    end
  end

  it "Verify if patient displays 'Clinically Discharged' status" do
    patients = [@@employee, @@employee_dependent, @@pba_pin]

    patients.each do |patient|
      slmc.nursing_gu_search(:pin => patient)
      slmc.get_text(Locators::NursingGeneralUnits.searched_item_status).should == "Clinically Discharged"
    end
  end

  # not applicable since it does not accept STANDARD Discharge for EMPLOYEE, should be DAS
#  it "If 'Philhealth Required' is ticked, HE Discount will not be computed Philhealth requirements are not submitted during Discharge of patient with EMPLOYEE guarantor" do
#    slmc.login("sel_pba3", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
#    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#    slmc.update_patient_or_guarantor_info(:percent => "50").should be_true
#    slmc.room_and_board_cancellation(:skip => true).should be_true
#    slmc.philhealth_page(:skip => true, :required_philhealth => true).should be_true
#  end

  it "Submits Philhealth requirements during Discharge of patient with EMPLOYEE guarantor where 'Philhealth Required' is ticked" do
    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS").should be_true
  end

  it "Discharge EMPLOYEE DEPENDENT patient and compute for remaining balance after HED discount" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@employee_dependent)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.update_patient_or_guarantor_info.should be_true
    slmc.room_and_board_cancellation(:skip => true).should be_true
    slmc.input_philhealth_reference(:diagnosis => "CHOLERA")
    slmc.philhealth_page(:skip => true).should be_true
    slmc.discount_information
    slmc.skip_generation_of_soa.should be_true

    @hospital_bill = slmc.get_hospital_bill_amount.to_f
    @room_charges = slmc.get_room_charges_amount.to_f

    @hospital_promo_disc = (@hospital_bill * (16.0/100.0) * 100).round.to_f / 100
    @hospital_discount = ((@hospital_bill - @hospital_promo_disc) * (40.0/100.0) * 100).round.to_f / 100

    @room_promo_disc = (@room_charges * (16.0/100.0) * 100).round.to_f / 100
    @room_discount = ((@room_charges - @room_promo_disc) * (50.0/100.0) * 100).round.to_f / 100
    @discount = @hospital_discount + @room_discount + @hospital_promo_disc + @room_promo_disc
    @discount.should == slmc.get_discount_amount.to_f #verify discount based on HED scheme

    @balance_due = (((@hospital_bill + @room_charges) - @discount) * 100).round.to_f / 100
    @balance_due.should == slmc.get_balance_due.to_f #verify remaining balance after HED discount

    slmc.oss_add_payment(:type => "CASH", :amount => @balance_due.to_s)
    slmc.proceed_with_payment
    slmc.is_text_present("Patients for DEFER should be processed before end of the day").should be_true
  end

  it "Updates Guarantor should not be possible after PBA patient is Discharged with Payment" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true

    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:all_patients => true, :pin => @@pba_pin)

    @select_options = []
    @select_options = slmc.get_select_options("userAction" + slmc.visit_number)
    @select_options.include?("Update Patient Information").should be_false
  end

  it "Prints Gatepass to complete patient discharge" do
    patients = [@@employee, @@employee_dependent]

    slmc.login(@user, @password).should be_true
    patients.each do |patient|
      slmc.nursing_gu_search(:pin => patient)
      slmc.print_gatepass(:no_result => true, :pin => patient).should be_true
    end
  end

  it "Bug #25413 [ER]- java.lang.ClassCastException encountered on Update Patient Guarantor -> Include PF" do
    slmc.login("sel_er1", @password).should be_true
    @@er_pin = slmc.er_create_patient_record(Admission.generate_data.merge(:account_class => "HMO", :admit => true, :gender => 'F')).gsub(' ','')
    slmc.go_to_er_billing_page
    slmc.er_billing_search(:pin => @@er_pin, :admitted => true)
    slmc.go_to_er_page_for_a_given_pin("Update Patient Information", slmc.visit_number)
    slmc.click_new_guarantor
    slmc.pba_update_guarantor(:guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :include_pf => true, :max_pf_coverage => @max_pf_coverage.to_s, :loa => "qwerty", :loa_percent => @loa_percent1.to_s).should be_true
    slmc.get_text("css=#main>div.commonForm>h2").should == "Update Patient Information"
    slmc.get_text("css=#main>div.commonForm>h2:nth-child(4)").should == "Update Guarantor Information"
  end

end