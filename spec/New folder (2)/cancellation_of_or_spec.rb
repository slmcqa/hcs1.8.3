require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

describe "SLMC :: PBA - Cancellation of OR" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @patient = Admission.generate_data
    @oss_patient = Admission.generate_data

    @user = "gu_spec_user12"
    @pba_user = "sel_pba20"
    @oss_user = "sel_oss12"
    @pharmacy_user = "sel_pharmacy6"

    @drugs = {"040000357" => 1}
    @ancillary = {"010000003" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  # Feature 46122
  it "Inpatient - Creates and Admit Patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin1 = slmc.create_new_patient(@patient.merge!(:gender => "M"))
    slmc.admission_search(:pin => @@pin1)
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS", :account_class => "INDIVIDUAL").should == "Patient admission details successfully saved."
  end

  it "Inpatient - Orders items" do
    slmc.nursing_gu_search(:pin => @@pin1)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin1)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
    end
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
  end

  it "Inpatient - Clinical Discharge patient in general units" do
    slmc.go_to_general_units_page
    @@visit_no1 = slmc.clinically_discharge_patient(:pin => @@pin1, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
  end

  it "Inpatient - PBA Discharge patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no1 = slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no1)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
  end

  it "Inpatient - Generate SOA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@pin1)
    slmc.go_to_page_using_visit_number("Generation of SOA", @@visit_no1)
    slmc.click_generate_official_soa.should be_true
  end

  # Feature 46122
  it "Cancellation of OR two days after it was generated" do
    @@or_number1 = slmc.access_from_database(:what => "OR_NUMBER", :table => "TXN_PBA_PAYMENT_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no1)
    two_days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 2).strftime("%d-%b-%y").upcase).to_s
    slmc.update_from_database(:table => "TXN_PBA_PAYMENT_HDR", :what => "OR_DATETIME", :set1 => two_days_before, :column1 => "OR_NUMBER", :condition1 => @@or_number1)
    slmc.pba_adjustment_and_cancellation(:doc_type => "OFFICIAL RECEIPT", :search_option => "DOCUMENT NUMBER", :entry => @@or_number1).should be_true
    slmc.is_element_present("link=Cancel OR").should be_false
    slmc.is_element_present("//tbody[@id='orTableBody']/tr[2]").should be_false
    slmc.get_text("//tbody[@id='orTableBody']/tr/td[1]").should == @@or_number1
  end

  it "Cancellation of OR within the day is allowed" do
    current_day = (((Date.strptime(Time.now.strftime('%Y-%m-%d')))).strftime("%d-%b-%y").upcase).to_s
    slmc.update_from_database(:table => "TXN_PBA_PAYMENT_HDR", :what => "OR_DATETIME", :set1 => current_day, :column1 => "OR_NUMBER", :condition1 => @@or_number1)
    slmc.pba_adjustment_and_cancellation(:doc_type => "OFFICIAL RECEIPT", :search_option => "VISIT NUMBER", :entry => @@visit_no1).should be_true
    slmc.cancel_or(:reason => "CANCELLATION - EXPIRED", :submit => true).should be_true # ref_security and ctrl_app_user AUT005
  end

  it "OSS - Creates patient in DAS - OSS" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@oss_patient).gsub(' ', '')
  end

  it "OSS - Add Guarantor in OSS page" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:guarantor_type => 'COMPANY', :acct_class => 'COMPANY', :guarantor_code => "PLDT001", :guarantor_add => true)
  end

  it "OSS Order items" do
    slmc.oss_order(:item_code => "010000000", :order_add => true, :doctor => "6726").should be_true
    slmc.oss_order(:item_code => "081000001", :order_add => true, :doctor => "0126").should be_true
  end

  it "OSS Settles Payment and Submit" do
    @@amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => @@amount, :type => "CASH")
    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  # Feature 46122
  it "Cancellation of OR more than a day it was generated" do
    @@visit_no2 = slmc.get_visit_number_using_pin(@@oss_pin)
    @@or_number2 = slmc.access_from_database(:what => "OR_NUMBER", :table => "TXN_PBA_PAYMENT_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no2)

    slmc.go_to_oss_payment_cancellation_and_reprinting
    slmc.pos_document_search(:type => "OSS OFFICIAL RECEIPT", :doc_no => @@or_number2).should be_true
    slmc.click_view_details.should be_true
    slmc.pos_cancel_item(:reason => "CANCELLATION - PATIENT REFUSAL", :order_of_item => 2).should == "The CM was successfully updated with printTag = 'Y'."

    slmc.go_to_oss_payment_cancellation_and_reprinting
    slmc.pos_document_search(:type => "OSS OFFICIAL RECEIPT", :doc_no => @@or_number2).should be_true
    slmc.click_view_details.should be_true
    slmc.pos_cancel_item(:reason => "CANCELLATION - PATIENT REFUSAL", :order_of_item => 1).should == "The CM was successfully updated with printTag = 'Y'."

    two_days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 2).strftime("%d-%b-%y").upcase).to_s
    slmc.update_from_database(:table => "TXN_PBA_PAYMENT_HDR", :what => "OR_DATETIME", :set1 => two_days_before, :column1 => "OR_NUMBER", :condition1 => @@or_number2)
    slmc.login(@pba_user, @password).should be_true
    slmc.pba_adjustment_and_cancellation(:doc_type => "OFFICIAL RECEIPT", :search_option => "DOCUMENT NUMBER", :entry => @@or_number2).should be_true
    slmc.is_element_present("link=Cancel OR").should be_false
    slmc.is_element_present("//tbody[@id='orTableBody']/tr[2]").should be_false
    slmc.get_text("//tbody[@id='orTableBody']/tr/td[1]").should == @@or_number2
  end

  it "Cancellation of OR after the day it was generated" do
    one_day_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 1).strftime("%d-%b-%y").upcase).to_s
    slmc.update_from_database(:table => "TXN_PBA_PAYMENT_HDR", :what => "OR_DATETIME", :set1 => one_day_before, :column1 => "OR_NUMBER", :condition1 => @@or_number2)
    slmc.pba_adjustment_and_cancellation(:doc_type => "OFFICIAL RECEIPT", :search_option => "DOCUMENT NUMBER", :entry => @@or_number2).should be_true
    slmc.is_element_present("link=Cancel OR").should be_true # does not cancel OR, verifies only if cancel_or link is present
    slmc.is_element_present("//tbody[@id='orTableBody']/tr[2]").should be_false
    slmc.get_text("//tbody[@id='orTableBody']/tr/td[1]").should == @@or_number2
  end

  it "Cancellation of OR within the day it was generated" do
    current_day = (((Date.strptime(Time.now.strftime('%Y-%m-%d')))).strftime("%d-%b-%y").upcase).to_s
    slmc.update_from_database(:table => "TXN_PBA_PAYMENT_HDR", :what => "OR_DATETIME", :set1 => current_day, :column1 => "OR_NUMBER", :condition1 => @@or_number2)
    slmc.pba_adjustment_and_cancellation(:doc_type => "OFFICIAL RECEIPT", :search_option => "VISIT NUMBER", :entry => @@visit_no2).should be_true
    slmc.cancel_or(:reason => "CANCELLATION - EXPIRED", :submit => true).should be_true # ref_security and ctrl_app_user AUT005
  end

  it "Create transcation in POS and cancels Sales Invoice" do
    slmc.login(@pharmacy_user, @password).should be_true
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
    slmc.oss_order(:item_code => "BABYHALER", :order_add => true).should be_true
    slmc.oss_order(:item_code => "042450011", :order_add => true).should be_true
    @amount = slmc.get_db_net_amount.to_s + '0'
    slmc.oss_add_payment(:type => "CASH", :amount => @amount).should be_true
    slmc.submit_order.should be_true
    @@doc_no = slmc.get_document_number
    slmc.print_or_confirmation("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    @@sales_invoice_number = (slmc.get_or_number_using_pos_number(@@doc_no)).gsub(' ', '')
    slmc.go_to_pos_order_cancellation
    slmc.pos_document_search(:type => "PHARMACY SALES INVOICE", :doc_no => @@sales_invoice_number, :start_date => "", :end_date => "").should be_true
    slmc.pos_cancel_order(:reason => "CANCELLATION - PATIENT REFUSAL").should == "The OR must be cancelled at the billing department. No refund to be processed."
  end

  it "Cancellation of OR more than one day it was generated is not allowed" do
    slmc.login(@pba_user, @password).should be_true
    two_days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 2).strftime("%d-%b-%y").upcase).to_s
    slmc.update_from_database(:table => "TXN_PBA_PAYMENT_HDR", :what => "OR_DATETIME", :set1 => two_days_before, :column1 => "OR_NUMBER", :condition1 => @@sales_invoice_number)
    slmc.pba_adjustment_and_cancellation(:doc_type => "OFFICIAL RECEIPT", :search_option => "DOCUMENT NUMBER", :entry => @@sales_invoice_number).should be_true
    slmc.is_element_present("link=Cancel OR").should be_false # does not cancel OR, verifies only if cancel_or link is present
    slmc.is_element_present("//tbody[@id='orTableBody']/tr[2]").should be_false
    slmc.get_text("//tbody[@id='orTableBody']/tr/td[1]").should == @@sales_invoice_number
  end

  it "Cancel Official Receipt (Sales Invoice) in PBA" do
    current_day = (((Date.strptime(Time.now.strftime('%Y-%m-%d')))).strftime("%d-%b-%y").upcase).to_s
    slmc.update_from_database(:table => "TXN_PBA_PAYMENT_HDR", :what => "OR_DATETIME", :set1 => current_day, :column1 => "OR_NUMBER", :condition1 => @@sales_invoice_number)
    slmc.pba_adjustment_and_cancellation(:doc_type => "OFFICIAL RECEIPT", :search_option => "DOCUMENT NUMBER", :entry => @@sales_invoice_number).should be_true
    slmc.cancel_or(:reason => "CANCELLATION - EXPIRED", :submit => true).should be_true # ref_security and ctrl_app_user AUT005
    slmc.get_text("//table[@id='transactionType']/tbody/tr/td").should == "OUTPATIENT SALES"
    slmc.is_text_present("OR##{@@sales_invoice_number} cancelled successfully!").should be_true
  end

  #slmc.add_user_security(:user => @pba_user, :org_code => "0016", :tran_type => "AUT005")
#  AUTHORIZATION CODE     TRANSACTION TYPE
#       AUT001            Discount Cancellation
#       AUT002            Refund Transactions
#       AUT003            Room & Board Cancellation
#       AUT005            Payment/OR Cancellation
#       AUT007            Adhoc Room-Bed Posting
#       AUT008            Adhoc Batch Drugs Posting

end