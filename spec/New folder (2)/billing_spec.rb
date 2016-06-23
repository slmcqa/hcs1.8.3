require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

describe "SLMC :: Billing Module Test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @pba_patient1 = Admission.generate_data
    @pba_patient2 = Admission.generate_data
    @user = 'billing_spec_user'
    @password = "123qweuser"

    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@pba_patient1[:age])
    @discount_type_code = "C01" if @@promo_discount == 0.16
    @discount_type_code = "C02" if @@promo_discount == 0.2
    @days = 3
    @room_rate = 4167.0
    @discount_amount = (@room_rate * @@promo_discount)
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates Patient for PBA Transactions" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pba_pin = slmc.create_new_patient(@pba_patient1.merge!(:gender => 'F'))
    slmc.admission_search(:pin => @@pba_pin).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08',
      :org_code => '0287', :diagnosis => "GASTRITIS", :package => "PLAN A FEMALE").should == "Patient admission details successfully saved."
  end

   it "Bug #24874 - Admission - Cancel Admission - System prompts Yikes!" do
    slmc.cancel_admission(:pin => @@pba_pin).should be_true
  end

  it "Readmit patient to be used in other examples" do
    slmc.admission_search(:pin => @@pba_pin).should be_true
    slmc.create_new_admission(
      :room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08',
      :org_code => '0287', :diagnosis => "GASTRITIS", :package => "PLAN A FEMALE").should == "Patient admission details successfully saved."
  end

  it "Should return all patients" do
    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => "", :no_result => false).should be_true
    slmc.pba_search(:discharged => true, :pin => "", :no_result => false).should be_true
    slmc.pba_search(:admitted => true, :pin => "", :no_result => false).should be_true
    slmc.pba_search(:all_patients => true, :pin => "", :no_result => false).should be_true
  end

  it "Should return no patient - select with discharge notice" do
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin, :no_result => true).should be_true
  end

  it "Should return no patient - select discharged patient" do
    slmc.pba_search(:discharged => true, :pin => @@pba_pin, :no_result => true).should be_true
  end

  it "Should return patient - select admitted patients" do
    @@visit_number = slmc.pba_search(:admitted => true, :pin => @@pba_pin).should be_true
  end

  it "Should return patient - select all patients" do
    slmc.pba_search(:all_patients => true, :pin => @@pba_pin).should be_true
  end

  it "Verifies list of dropdown actions" do    
    slmc.pba_get_select_options(@@visit_number).should == ["Update Patient Information", "Generation of SOA", "PhilHealth", "Payment", "Package Management"]
  end

  it "Validates package through GU's Package Management page" do
    slmc.login("user_gene", @password).should be_true
    slmc.nursing_gu_search(:pin => @@pba_pin)
    slmc.go_to_gu_page_for_a_given_pin("Package Management", @@pba_pin)
    slmc.click Locators::Wellness.order_package, :wait_for => :page
    slmc.validate_package.should be_true
    slmc.validate_credentials(:username => "sel_0287_validator", :password => @password, :package => true).should be_true
  end

  it "Validated package should be seen in PBA's Package Management page" do
    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@pba_pin).should be_true
    slmc.go_to_page_using_visit_number("Package Management", @@visit_number)
    slmc.is_text_present("PLAN A FEMALE").should be_true
  end

  it "Bug #28633 - [PBA]Refund link is not working" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_refund(:soa_no => "soa", :or_no => "or")
    slmc.is_text_present("Refund Information").should be_true
    slmc.is_text_present("Refund Details").should be_true
  end

  it "Bug #22172 - Edit package through PBA's Package Management page should not throw exception" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@pba_pin).should be_true
    slmc.go_to_page_using_visit_number("Package Management", @@visit_number)
    slmc.click Locators::Wellness.edit_package
    sleep 3
    slmc.is_text_present("Patient Billing and Accounting Home › Package Management").should be_true
  end

  it "Test if input field for Search accepts either description or item code" do
    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pba_pin)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pba_pin)
#    slmc.search_order(:drugs => true, :description =>  "040004334").should be_true
#    slmc.search_order(:supplies => true, :description => "080200000").should be_true
#    slmc.search_order(:ancillary => true, :description => "010000003").should be_true
#    slmc.search_order(:others => true, :description => "050000009").should be_true
#    slmc.search_order(:drugs => true, :description => "SOLUSET").should be_true
#    slmc.search_order(:supplies => true, :description => "NASO-TRACHEAL TUBE IVORY S7").should be_true
#    slmc.search_order(:ancillary => true, :description => "BONE IMAGING - THREE PHASE STUDY").should be_true
#    slmc.search_order(:others => true, :description => "BLOOD WARMER - SUCCEDING HOUR").should be_true
#    slmc.search_order(:drugs => true, :description => "049999").should be_true
#    slmc.search_order(:supplies => true, :description => "089999").should be_true
  end

  it "Patients order an item of each type" do
    drugs = ['PROSURE VANILLA 380G', 'BABYHALER'] #drugs = ['040000357', '040004334']
    ancillary = ['ADRENOMEDULLARY IMAGING-M-IBG','ALDOSTERONE']
    supplies = ['BABY POWDER 25G (J & J)','ALCOHOL 70% ISOPROPHYL 250ML'] #supplies = ['080100021', '080100022']
    others = ['LOTION','CONDITIONER']

    slmc.nursing_gu_search(:pin => @@pba_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pba_pin)
    drugs.each do |drug|
      slmc.search_order(:description => drug, :drugs => true)
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true)
    end
    ancillary.each do |anc|
      slmc.search_order(:description => anc, :ancillary => true )
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true)
    end
    supplies.each do |supply|
      slmc.search_order(:description => supply, :supplies => true )
      slmc.add_returned_order(:description => supply, :supplies => true, :add => true)
    end
    others.each do |other|
      slmc.search_order(:description => other, :others => true)
      slmc.add_returned_order(:description => other, :others => true, :add => true)
    end
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator") #validation is required if drugs are ordered
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :others => true, :orders => "multiple").should == 8
    slmc.confirm_validation_all_items
  end

  it "Cancel Admission should validate outstanding or existing orders made to the patients" do
    slmc.admission_search(:pin => @@pba_pin)
    slmc.update_admission(:cancel => true).should == "Cannot cancel admission. Patient have orders already." #Cannot cancel admission. Patient have pending orders."
  end

  it "Clinically discharges the patient through admin user" do
    slmc.nursing_gu_search(:pin => @@pba_pin)
    @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pba_pin, :pf_type => "COLLECT", :no_pending_order => true, :pf_amount => "1000", :with_complementary => true, :save => true).should be_true
  end

  it "Verify that “Reprint Discharge Notice Slip” is available upon clinical discharge" do # Feature 45876
    slmc.nursing_gu_search(:pin => @@pba_pin)
    slmc.get_select_options("userAction#{@@pba_pin}").include?("Reprint Discharge Notice Slip").should be_true
    slmc.get_select_options("userAction#{@@pba_pin}").should == ["Reprint Discharge Notice Slip", "Defer Discharge", "Discharge Instructions\302\240", "Notice of Death", "Print Label Sticker"]
  end

  it "Bug #24987 PBA Discount - Yikes encountered in creating a discount in Room and Board" do
    # room is included in package ordered. number of days varies depending on package, used 15 days to be sure
    @my_date = slmc.adjust_admission_date(:days_to_adjust => @days, :pin => @@pba_pin, :visit_no => @@visit_no)
    Database.connect
    @days.times do |i|
      @rb = (slmc.get_last_record_of_rb_trans_no)
      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no, :rb_trans_no => @rb, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date)
      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no,  :rb_trans_no => @rb, :date_covered => @my_date, :created_datetime => @my_date, :room_rate => @room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
      @my_date = slmc.increase_date_by_one(@days - i)
    end
    Database.logoff

    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Discount", @@visit_no)
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ROOM AND BOARD", :discount_type => "Fixed", :close_window => true, :discount_rate => "500", :save => true)
  end

  it "Bug #25127 PhilHealth-Inpatient * Encountered NullValueInNestedPathException when saving NSD package" do
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
    slmc.philhealth_computation(:diagnosis => "TYPHOID MENINGITIS", :claim_type => "ACCOUNTS RECEIVABLE", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "59400", :compute => true)
    slmc.ph_save_computation
    slmc.is_text_present("The PhilHealth form is saved successfully.").should be_true
    slmc.get_text("//html/body/div/div[2]/div[2]/div[16]/h2").should == "ESTIMATE"
    slmc.is_text_present("Patient Billing and Accounting Home").should be_true
  end

  it "Add discount to patient" do
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Discount", @@visit_no)
    slmc.add_discount(:save => true, :discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :close_window => true, :discount_rate => 1000)
  end

  it "Should return no patient after clinical discharge - select discharged patient" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@pba_pin, :no_result => true).should be_true
  end

  it "Should return no patient after clinical discharge - select admitted patients" do
    slmc.pba_search(:admitted => true, :pin => @@pba_pin).should be_true
  end

  it "Should return patient after clinical discharge - select all patients" do
    slmc.pba_search(:all_patients => true, :pin => @@pba_pin, :no_result => false).should be_true
  end

  it "Bug #22451 - PhilHealth * Encountered NullPointerException when saving PhilHealth - Refund" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pba_pin, :with_discharged_notice => true, :no_result => false).should be_true
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    slmc.ph_edit
    slmc.philhealth_computation(:diagnosis => "TYPHOID MENINGITIS", :claim_type => "REFUND", :rvu => "10080", :medical_case_type => "ORDINARY CASE", :compute => true)
    slmc.ph_save_computation
    slmc.is_text_present("The PhilHealth form is saved successfully.").should be_true
    slmc.get_text("//html/body/div/div[2]/div[2]/div[16]/h2").should == "ESTIMATE"
    slmc.is_text_present("Patient Billing and Accounting Home").should be_true
  end

  it "Verifies that discharged patient is no longer searchable in pba" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pba_pin, :with_discharge_notice => true, :no_result => true).should be_true
    slmc.pba_search(:pin => @@pba_pin, :discharged => true, :no_result => false).should be_true
    slmc.pba_search(:pin => @@pba_pin, :admitted => true, :no_result => true).should be_true
    slmc.pba_search(:pin => @@pba_pin, :all_patients => true, :no_result => false).should be_true
  end

  it "Skip room and bed cancellation" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true#first discharge of @@pba_pin
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
  end

  it "Bug #24307 PhilHealth-ER * Claim Type Refund is saved as Final" do
    slmc.ph_edit
    slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true)
    slmc.ph_save_computation
    slmc.is_text_present("The PhilHealth form is saved successfully.").should be_true
    slmc.get_text("//html/body/div/div[2]/div[2]/div[16]/h2").should == "ESTIMATE"
    slmc.is_text_present("Patient Billing and Accounting Home").should be_true
  end

#  it "Cancel Room and Board Charges" do ###### cannot run through selenium due to prompt reason message
#    slmc.go_to_patient_billing_accounting_page
#    slmc.patient_pin_search(:pin => @@pba_pin)
#    slmc.cancel_room_and_board_charges.should be_true
#  end

  it "Should be able to go to PHILHEALTH page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number('PhilHealth', @@visit_no)
    slmc.is_text_present("Patient Billing and Accounting Home › PhilHealth").should be_true
  end

  it "Should be able to input required fields in Philhealth page then compute for discounts" do
    slmc.input_philhealth_reference(:diagnosis => "CHOLERA")
    slmc.philhealth_page(:compute => true)
  end

  it "Should be able to go select Claim Type = REFUND in Philhealth page then compute for discounts" do
    slmc.input_philhealth_reference(:claim_type => "REFUND")
    slmc.philhealth_page(:compute => true)
  end

  it "Set express discharge for patient" do
    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "DAS").should be_false
  end

  it "Should return patient - select with discharged" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin).should be_true
  end

  it "Verifies the drop down list for clinically discharged patient" do
    slmc.pba_get_select_options(@@visit_no).should == ["Discount", "Update Patient Information", "Discharge Patient", "Generation of SOA", "PhilHealth", "Payment", "Package Management"] #removed "Generation of Billing Notice" 1.4.1a RC3 r28728 can be found in inhouse
  end

  it "Verifies that discharged patient is no longer searchable in pba" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pba_pin, :with_discharge_notice => true, :no_result => true).should be_true
    slmc.pba_search(:pin => @@pba_pin, :discharged => true, :no_result => false).should be_true
    slmc.pba_search(:pin => @@pba_pin, :admitted => true, :no_result => true).should be_true
    slmc.pba_search(:pin => @@pba_pin, :all_patients => true, :no_result => false).should be_true
  end

  it "Bug #23751 View and Reprinting * Search by Visit No. is not working" do
    slmc.login("sel_pba3", @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:entry => @@visit_no, :select => "Discount", :search_options => "VISIT NUMBER").should be_true
  end

  it "Bug #23801 View and Reprinting * PhilHealth search is not working properly" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth" , :search_options => "DOCUMENT NUMBER", :entry => "S510700154681D").should be_true
  end

  it "View and Reprinting * PhilHealth search is by date" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth" , :search_option => "DOCUMENT DATE").should be_true
  end

  it "Bug #26049 PBA: View and reprinting of Discount : encountered error page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "Discount", :search_options => "DOCUMENT NUMBER").should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "Discount", :entry => @@visit_no, :search_options => "VISIT NUMBER").should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "Discount", :search_options => "DOCUMENT DATE").should be_true
  end

  it "Bug #25024 PBA: Gets an error page in reprinting GATEPASS using the Bdate in advanced search" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "Gate Pass", :search_option => "GATE PASS", :entry => @@pba_pin).should be_true
    m, d, y = @pba_patient1[:birth_day].split('/').map(& :to_s)
    slmc.click("slide-fade", :wait_for => :visible, :element => "monthTextField")
    slmc.type("monthTextField", m)
    slmc.type("dayTextField", d)
    slmc.type("yearOfBirth", y)
    slmc.click("//input[@value='Advanced Search' and @name='search']", :wait_for => :page)
    slmc.is_text_present("Patient Billing and Accounting Home › Reprint Gatepass").should be_true
  end

  it "Bug #26278 - [PBA] Generation of Unofficial SOA of an active patient returns an exception error" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pba_pin2 = slmc.create_new_patient(@pba_patient2.merge!(:gender => 'M'))
    slmc.admission_search(:pin => @@pba_pin2).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."

    ancillary = ['010000008','010000004']

    slmc.nursing_gu_search(:pin => @@pba_pin2)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pba_pin2)
    ancillary.each do |anc|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :doctor => "0126").should be_true
    end
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true

    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:admitted => true, :pin => @@pba_pin2)
    slmc.go_to_page_using_visit_number("Generation of SOA", @@visit_no)
    slmc.click_print_unofficial_soa.should be_true
  end

  it "Bug #26302 - [PBA]: Printing Unofficial SOA during discharge generates a NullPointerException" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pba_pin2, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true

    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin2)
    slmc.go_to_page_using_visit_number("Discount", @@visit_no)
    slmc.add_discount(:save => true, :discount => "Courtesy Discount", :discount_scope => "ANCILLARY / PROCEDURE", :discount_type => "Percent", :close_window => true, :discount_rate => 100)

    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:all_patients => true, :pin => @@pba_pin2).should be_true
    slmc.go_to_page_using_visit_number("Update Patient Information", @@visit_no)
    slmc.click_new_guarantor.should be_true
    slmc.pba_update_guarantor(:guarantor_type => "COMPANY", :guarantor_code => "ACCENTURE", :loa => "qwerty", :loa_percent => 50).should be_true

    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin2)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
    slmc.print_soa.should be_true
    slmc.click_print_unofficial_soa.should be_true
  end

  it "Bug #26226 PhilHealth-ER * Encountered NullPointerException when filed PhilHealth is edited from Document Search page" do
    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pba_pin2, :discharged => true)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
    slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "TYPHOID MENINGITIS", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "59400", :compute => true)
    @@ph_ref_no = slmc.ph_save_computation
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :search_options => "DOCUMENT NUMBER", :entry => @@ph_ref_no).should be_true
    slmc.go_to_page_using_reference_number("Display Details", @@ph_ref_no)
    slmc.ph_edit
    slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "TYPHOID MENINGITIS", :medical_case_type => "ORDINARY CASE", :compute => true)
    slmc.is_text_present("PhilHealth Reference No.:").should be_true
  end

  it "Bug #24966 PhilHealth-Adjustment * Able to adjust claims on PhilHealth saved as Estimate" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pba_pin2)
    slmc.print_gatepass(:no_result => true, :pin => @@pba_pin2).should be_true
    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :search_options => "DOCUMENT NUMBER", :entry => @@ph_ref_no).should be_true
    slmc.go_to_page_using_reference_number("Display Details", @@ph_ref_no)
    slmc.ph_cancel_computation.should be_true
    slmc.ph_recompute.should be_true
    slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "TYPHOID MENINGITIS", :medical_case_type => "ORDINARY CASE", :compute => true)#patient already discharge only refund
    slmc.is_element_present("btnAdjustClaims").should be_false
  end

  it "Verify that “Reprint Gate Pass” is available upon physical discharge when ROLE_LATE_TRANSACTION is added" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pba_pin2, :discharged => true)
    slmc.get_text("css=#occupancyList>tbody>tr>td:nth-child(5)").should == "DISCHARGED"
    slmc.get_select_options("userAction#{@@pba_pin2}").include?("Reprint Gate Pass").should be_true
  end

  it "Reprint Gate Pass" do
    slmc.go_to_gu_page_for_a_given_pin("Reprint Gate Pass", @@pba_pin2)
    slmc.is_text_present("General Units").should be_true
  end

# Bug 50020 - Not a defect - user request
#  it "Verify that “Reprint Gate Pass” is available upon physical discharge when ROLE_LATE_TRANSACTION is not available" do
#    slmc.login("sel_gu1", @password).should be_true # doesnt have ROLE_LATE_TRANSACTION
#    slmc.go_to_general_units_page
#    slmc.is_element_present("//input[@type='checkbox' and @name='discharged']").should be_false
#    slmc.patient_pin_search(:pin => @@pba_pin2, :no_result => true).should be_true
#  end

  it "Professional fee settlement" do
    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
  end

  it "Discharges the patient in PBA" do
    slmc.click("popup_ok", :wait_for => :page) if slmc.is_element_present("popup_ok")
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true  #@philhealth page
    slmc.discharge_to_payment.should be_true
  end

  it "Verify that “Reprint Discharge Notice Slip” is not available upon billing discharge" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pba_pin)
    slmc.get_select_options("userAction#{@@pba_pin}").include?("Reprint Discharge Notice Slip").should be_false
  end
  
  it "Defers the patient in pba" do
    slmc.login("sel_pba3", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:discharged => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Defer Discharge", slmc.visit_number)
    slmc.pba_defer_patient.should be_true
  end

  it "Cancel OR and Reprint Cancelled OR - PF Fee Cancellation" do  # Bug #46055 PBA: WITH ERROR UPON PRINTING OF OR after cancellation
    slmc.pba_adjustment_and_cancellation(:doc_type => "OFFICIAL RECEIPT", :search_option => "VISIT NUMBER", :entry => @@visit_no)
    slmc.cancel_or(:reason => "CANCELLATION - EXPIRED", :submit => true).should be_true # ref_security and ctrl_app_user AUT005
    slmc.pba_adjustment_and_cancellation(:doc_type => "OFFICIAL RECEIPT", :search_option => "VISIT NUMBER", :entry => @@visit_no)
    slmc.pba_reprint_or.should be_true
    slmc.is_element_present("textSearchEntry").should be_true
  end

  #slmc.add_user_security(:user => @pba_user, :org_code => "0016", :tran_type => "AUT005")

end
