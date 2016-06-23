require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

describe "SLMC :: PBA Cancellation of Refund" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @patient1 = Admission.generate_data
    @or_patient = Admission.generate_data

    @user = "gu_spec_user12"
    @pba_user = "sel_pba21"
    @or_user = "sel_or11"

    @drugs = {"040000357" => 1}
    @ancillary = {"010000003" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  # Feature 45906
  it "Inpatient - Creates and Admit Patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin1 = slmc.create_new_patient(@patient1.merge!(:gender => "M"))
    slmc.admission_search(:pin => @@pin1)
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0287').should == "Patient admission details successfully saved."
  end

  it "Inpatient - Orders items" do
    slmc.nursing_gu_search(:pin => @@pin1)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin1)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Inpatient - Create a deposit that exceed the hospital bill" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no1 = slmc.pba_search(:admitted => true, :pin => @@pin1)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no1)
    amount_due = slmc.get_text("//*[@id=\"totalAmountDue\"]").gsub(",","")
    @@excess_amount = 10000.0
    deposit_value = amount_due.to_f + @@excess_amount
    slmc.pba_hb_deposit_payment(:deposit => true, :cash => deposit_value).should be_true
    slmc.print_or.should be_false
    slmc.is_text_present("The Official Receipt print tag has been set as 'Y'.").should be_true
  end

  it "Inpatient - Clinical and PBA Discharge" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no1 = slmc.clinically_discharge_patient(:pin => @@pin1, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true # user must have a record in ref_user_security table with 'AUT002'
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no1)
    slmc.select_discharge_patient_type(:type => "DAS").should be_true
  end

  it "Cancel button will be present for all Refund processed Within The Day" do # Process Refund and Go to Adjustment and Cancellation
    slmc.pba_refund(:after_discharge => true, :reason => "OVERPAYMENT", :status => "PAID", :submit => true, :successful_refund => true).should == "Refund information successfully saved!"
    slmc.pba_adjustment_and_cancellation(:doc_type => "REFUND", :search_option => "VISIT NUMBER", :entry => @@visit_no1).should be_false
    slmc.is_element_present("link=Cancel").should be_true
    slmc.is_text_present("OVERPAYMENT").should be_true
  end

  it "Search the created refund yesterday thus Cancel button will not be present" do
    @@refund_number = slmc.access_from_database(:what => "REFUND_SLIP_NO", :table => "TXN_PBA_REFUND_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no1).should be_true
    days_before = (((Date.strptime(Time.now.strftime('%Y-%m-%d'))) - 1).strftime("%d-%b-%y").upcase).to_s
    slmc.update_from_database(:table => "TXN_PBA_REFUND_HDR", :what => "CREATED_DATETIME", :set1 => days_before, :column1 => "REFUND_SLIP_NO", :condition1 => @@refund_number)
    slmc.pba_adjustment_and_cancellation(:doc_type => "REFUND", :search_option => "VISIT NUMBER", :entry => @@visit_no1).should be_false
    slmc.is_element_present("link=Cancel").should be_false
    slmc.is_text_present("OVERPAYMENT").should be_true
    slmc.update_from_database(:table => "TXN_PBA_REFUND_HDR", :what => "CREATED_DATETIME", :set1 => (Time.now.strftime('%d-%b-%y').upcase), :column1 => "REFUND_SLIP_NO", :condition1 => @@refund_number)
    slmc.pba_adjustment_and_cancellation(:doc_type => "REFUND", :search_option => "VISIT NUMBER", :entry => @@visit_no1).should be_false
  end

  it "User will be directed to the refund page" do
    slmc.cancel_refund(:refund_number => @@refund_number).should be_true
    slmc.get_text("//form[@id='refundCancellationBean']/div/div[3]/div").gsub("Amount: ", "").should == @@excess_amount.to_s
    slmc.get_text("//form[@id='refundCancellationBean']/div/div[2]/div").gsub("Refund Slip No.: ", "").should == @@refund_number
  end

  it "Refund will be cancelled" do
    slmc.cancel_refund(:submit => true).should be_true
    slmc.pba_adjustment_and_cancellation(:doc_type => "REFUND", :search_option => "DOCUMENT NUMBER", :entry => @@refund_number).should be_false
    slmc.get_text("//tbody[@id='refundTableBody']/tr/td[8]").should == "CANCELLED"
  end

  it "Print Refund Slip" do
    slmc.click_print_refund_slip.should be_true
  end

  it "Check DB ( TXN_PBA_REFUND_HDR.STATUS)" do
    slmc.access_from_database(:what => "STATUS", :table => "TXN_PBA_REFUND_HDR", :column1 => "REFUND_SLIP_NO", :condition1 => @@refund_number).should == "C"
  end

  it "Outpatient - Create Patient in OR and Order items" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient.merge!(:admit => true, :gender => 'F')).gsub(' ', '')

    slmc.occupancy_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Outpatient - Create a deposit that exceed the hospital bill" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no2 = slmc.pba_search(:admitted => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no2)
    amount_due = slmc.get_text("//*[@id=\"totalAmountDue\"]").gsub(",","")
    @@excess_amount2 = 100000.0
    deposit_value = amount_due.to_f + @@excess_amount2
    slmc.pba_hb_deposit_payment(:deposit => true, :cash => deposit_value).should be_true
    slmc.print_or.should be_false
    slmc.is_text_present("The Official Receipt print tag has been set as 'Y'.").should be_true
  end

  it "Outpatient - Turn Outpatient to Inpatient" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.outpatient_to_inpatient(@or_patient.merge(:pin => @@or_pin, :username => @user, :password => @password, :room_label => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287")).should be_true
  end

  it "Outpatient - Clinically Discharge and PBA Discharge" do
    slmc.go_to_general_units_page
    @@visit_no2 = slmc.clinically_discharge_patient(:pin => @@or_pin, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
    slmc.login(@pba_user, @password).should be_true # user must have a record in ref_user_security table with 'AUT002'
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no2)
    slmc.select_discharge_patient_type(:type => "DAS").should be_true
  end

  it "Outpatient - Cancel button will be present for all Refund processed Within The Day" do # Process Refund and Go to Adjustment and Cancellation
    slmc.pba_refund(:after_discharge => true, :reason => "OVERPAYMENT", :status => "PAID", :submit => true, :successful_refund => true).should == "Refund information successfully saved!"
    slmc.pba_adjustment_and_cancellation(:doc_type => "REFUND", :search_option => "VISIT NUMBER", :entry => @@visit_no2).should be_false
    slmc.is_element_present("link=Cancel").should be_true
    slmc.is_text_present("OVERPAYMENT").should be_true
  end

  it "Outpatient - User will be directed to the refund page" do
    @@refund_number2 = slmc.access_from_database(:what => "REFUND_SLIP_NO", :table => "TXN_PBA_REFUND_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no2).should be_true
    slmc.cancel_refund(:refund_number => @@refund_number2, :submit => true).should be_true
    slmc.pba_adjustment_and_cancellation(:doc_type => "REFUND", :search_option => "DOCUMENT NUMBER", :entry => @@refund_number2).should be_false
    slmc.get_text("//tbody[@id='refundTableBody']/tr/td[8]").should == "CANCELLED"
    slmc.click_print_refund_slip.should be_true
  end

#  slmc.add_user_security(:user => @pba_user, :org_code => "0016", :tran_type => "AUT002")
#  AUTHORIZATION CODE     TRANSACTION TYPE
#       AUT001            Discount Cancellation
#       AUT002            Refund Transactions
#       AUT003            Room & Board Cancellation
#       AUT005            Payment/OR Cancellation
#       AUT007            Adhoc Room-Bed Posting
#       AUT008            Adhoc Batch Drugs Posting

end