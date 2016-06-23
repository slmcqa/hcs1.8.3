require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: InHouse Collection Tests" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @patient = Admission.generate_data
    @adm_user = "sel_adm5"
    @gu_user = "sel_gu2"
    @pba_user = "sel_pba18"
    @inhouse_user = "sel_inhouse1"
    @password = "123qweuser"

    @drugs = {"040000357" => 1}
    @ancillary = {"010000003" => 1}
    @supplies = {"080100021" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Create patient" do
    slmc.login(@adm_user, @password).should be_true # user must have 'ROLE_ENDORSEMENT_TAGGING', and 'ROLE_ENDORSEMENT_VIEWING',
    slmc.admission_search(:pin => "test")
    @@inhouse_pin = slmc.create_new_patient(@patient)
    slmc.admission_search(:pin => @@inhouse_pin)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end

  it "View Endorsement History" do
    slmc.admission_search(:pin => @@inhouse_pin)
    slmc.view_endorsement_history(:no_result => true).should be_true
  end

  it "View Endorsement Tagging" do
    slmc.endorsement_tagging.should == "No endorsement saved."
  end

  it "Add Endorsement (Special Arrangements)" do
    slmc.admission_search(:pin => @@inhouse_pin)
    slmc.endorsement_tagging(:endorsement_type => "SPECIAL ARRANGEMENTS", :inhouse => true, :add => true, :save => true).should be_true
  end

  it "Print Prooflist" do
    slmc.endorsement_tagging_print_prooflist.should be_true
  end

  it "View Patient Tagged For Endorsement" do
    slmc.login(@inhouse_user, @password).should be_true
    slmc.go_to_in_house_landing_page
    (slmc.view_patients_tagged_with_endorsements.include?("#{@patient[:last_name]}, #{@patient[:first_name]} #{@patient[:middle_name]}")).should be_true
  end

  it "Order Items for Payment" do
    slmc.login(@gu_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@inhouse_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@inhouse_pin)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true ).should be_true
      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
    end
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "Clinically Discharge" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@inhouse_pin, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
  end

  it "View and Reprinting - Batch Billing Notice" do
    slmc.login(@inhouse_user, @password).should be_true
    slmc.go_to_in_house_landing_page
    slmc.inhouse_view_and_reprinting(:select => "Batch Billing Notice", :entry => @@inhouse_pin, :visit_no => @@visit_no, :endorsement => true).should be_true
  end

  it "View and Reprinting - Batch Unofficial SOA" do
    slmc.go_to_in_house_landing_page
    slmc.inhouse_view_and_reprinting(:select => "Batch Unofficial SOA", :itemized => true, :org_code => "0287",
      :account_class => "INDIVIDUAL", :guarantor_code => @@inhouse_pin, :print_to_printer => true).should be_true
  end

  it "Redtag Patient" do
    slmc.inhouse_search(:pin => @@inhouse_pin)
    slmc.go_to_inhouse_page("Redtag Patient", @@inhouse_pin)
    slmc.redtag_patient(:remarks => "selenium2 remarks sample", :save => true).should == "Red tag patient with visit no #{@@visit_no}"
  end

  it "View and Reprinting - Red Tag" do
    slmc.go_to_in_house_landing_page
    slmc.inhouse_view_and_reprinting(:select => "Red Tag", :print => true).should == "Success"
    slmc.is_element_present("redTagPatients").should be_true
  end

  it "Generate SOA during Discharge" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inhouse_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.click_generate_official_soa.should be_true
    @@soa_no = slmc.access_from_database(:what => "SOA_NO",:table => "TXN_PBA_OFFICIAL_SOA", :column1 => "VISIT_NO", :condition1 => @@visit_no)
  end

  it "View and Reprinting - Generation of SOA" do
    slmc.login(@inhouse_user, @password).should be_true
    slmc.go_to_in_house_landing_page
    slmc.inhouse_view_and_reprinting(:select => "Generation of SOA", :search_options => "PIN", :entry => @@inhouse_pin).should == "The SOA was successfully updated with printTag = 'Y'."
    slmc.is_element_present("textSearchEntry").should be_true
  end

  it "Patient Search - RedTag Patient" do
    slmc.inhouse_search(:pin => @@inhouse_pin, :endorsement => true).should be_true
    slmc.is_element_present("//img[@alt='RedTag Patient']").should be_true
  end

  it "Patient Search - Print Billing Notice" do
    slmc.go_to_inhouse_page("Billing Notice", @@inhouse_pin)
    slmc.is_element_present("criteria").should be_true
  end

  it "Patient Search" do
    slmc.inhouse_search(:pin => @@inhouse_pin, :endorsement => true).should be_true
    slmc.go_to_inhouse_page("Print Unofficial SOA", @@inhouse_pin)
    slmc.click("//input[@value='Submit' and @name='_submit']", :wait_for => :page)
    slmc.is_element_present("criteria").should be_true
  end

  it "Edit Endorsement Tagging" do
    slmc.inhouse_search(:pin => @@inhouse_pin, :endorsement => true).should be_true
    slmc.go_to_inhouse_page("Endorsement Tagging", @@inhouse_pin)
    slmc.endorsement_tagging(:edit => true, :endorsement_type => "TAKE HOME MEDICINES", :recipient => "ADMISSION", :save => true).should be_true
    slmc.endorsement_tagging_print_prooflist.should be_true
  end
end