require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Full Cycle ER" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @er_user = "sel_er1"
    @ancillary = {"010000317" => 1,"010000212" => 2}
    @drugs = {"042820145" => 5,"042820004" => 6}
    @supplies = {"080100021" => 10}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it"ER Full Cycle - Create and admit patient" do
    slmc.login(@er_user, @password).should be_true
    @@er_pin = slmc.er_create_patient_record(Admission.generate_data(:not_senior => true).merge(:admit => true)).gsub(' ','').should be_true
  end

  it"ER Full Cycle - Order Items" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin)

    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true)
      slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
          :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726")
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true)
      slmc.add_returned_order(:ancillary => true, :description => item,:quantity => q, :add => true, :doctor => "0126")
    end
    @supplies.each do |item, q|
      slmc.search_order(:description => item, :supplies => true)
      slmc.add_returned_order(:supplies => true, :description => item,:quantity => q, :add => true, :doctor => "5979")
    end

    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:drugs => true,:supplies => true, :ancillary => true, :orders => "multiple").should == 5
    slmc.confirm_validation_all_items.should be_true
  end

  it"ER Full Cycle - Clinically discharge patient" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin)
    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"ER Full Cycle - Billing discharge patient" do
    slmc.go_to_er_billing_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD")
    slmc.click_new_guarantor
    slmc.pba_update_guarantor(:guarantor_type => "INDIVIDUAL")
    sleep 10
    slmc.click_submit_changes.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end

  it"ER Full Cycle - Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end

  it"ER Full Cycle - Print Gatepass" do
    slmc.er_print_gatepass(:pin => @@er_pin,:visit_no=>@@visit_no).should be_true
  end  
end