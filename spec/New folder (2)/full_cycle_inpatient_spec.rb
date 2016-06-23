require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Full Cycle for Inpatient" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @user = "billing_spec_user2"
    @password = "123qweuser"
    @patient = Admission.generate_data

    @drugs = {"048414006" => 1}
    @ancillary = {"010000212" => 1}
    @supplies = {"080200000" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


  it "Verify if user can Login using an invalid and valid username / password" do
    slmc.login(@user, "*'").should be_false
    slmc.is_element_present("j_username").should be_true
    slmc.is_text_present("Invalid username and/or password or account currently in use, please try again.").should be_true
    slmc.login(@user, @password).should be_true
  end

  it "Verify if user can Create a valid patient with complete information" do
    slmc.admission_search(:pin => "*")
    @@pin = slmc.create_new_patient(@patient)
  end

  it "Verify if user can Admit created patient using INDIVIDUAL as account class" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(
      :account_class => "INDIVIDUAL",
      :rch_code => "RCH08",
      :org_code => "0287",
      :room_charge => "REGULAR PRIVATE").should == "Patient admission details successfully saved."
  end

  it "Verify if user can go Order Items in General Units Page" do
    slmc.nursing_gu_search(:pin => @@pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true)
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true)
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true ).should be_true
      slmc.add_returned_order(:description => supply, :supplies => true, :add => true)
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
   end

  it "Verify if user can Clinically Discharge patient" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => "5624", :no_pending_order => true, :save => true).should be_true
    @@visit_no.should_not == false
  end

  it "Verify if user can be Discharge in PBA page" do
    slmc.login("sel_pba11", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_number = slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    @@visit_no.should == @@visit_number

    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
  end

  it "Verify if user can Print GatePass of patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:pin => @@pin, :no_result => true).should be_true
  end

  it "Verify if user can view patient as Not Admitted" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.is_text_present("Not Admitted").should be_true
  end

end

# note : this spec is just for the full cycle of inpatient and is NOT a part of selenium automation testing (julius)