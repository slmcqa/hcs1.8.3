require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Smoke Tests" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @gu_patient = Admission.generate_data
    @su_patient = Admission.generate_data
    @user = 'smoke_test_spec_user'
    @password = "123qweuser"
    @soa_month = Time.now.strftime("%m")
    @items = {"010001047" => {:desc => "URINE HEMOSIDERIN QUALITATIVE", :code => "0062"}}
  end
    
  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end
    
  it "Login in successfully" do
    slmc.login(@user, @password).should be_true
  end

  it "Creates a new patient" do
    slmc.admission_search(:pin => "test")
    @@pin = slmc.create_new_patient(@gu_patient.merge(:gender => "F"))
  end

  it "Searches newly-created patient as admitted" do
    slmc.admission_search(:admitted => true)
    slmc.verify_search_results(:no_results =>true).should be_true
  end

  it "Advanced-searches newly-created patient" do
    slmc.admission_advance_search(
      :last_name => @gu_patient[:last_name],
      :first_name => @gu_patient[:first_name],
      :middle_name => @gu_patient[:middle_name],
      :gender => "F").should(be_true)
    slmc.admission_advance_search(
      :last_name => @gu_patient[:last_name],
      :first_name => "search test",
      :middle_name => @gu_patient[:middle_name],
      :gender => "M",
      :no_result => true).should(be_true)
  end

  it "Searches new patient (not admitted)" do
    slmc.admission_search(:pin => @gu_patient[:last_name], :admitted => false).should be_true
  end

  it "Creates new admission for new patient with package" do
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08',
      :org_code => '0287', :diagnosis => "GASTRITIS", :package => "PLAN A FEMALE").should == "Patient admission details successfully saved."
  end

  it "Searches for drugs in the nursing general units order page" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @@pending_orders = (slmc.get_text("css=#pendingOrder>span")).to_i
    slmc.search_order(:description => "040004334", :drugs => true).should be_true
  end

  it "Adds the searched drug to the cart" do
    slmc.add_returned_order(:drugs => true, :description => "040004334",
      :stock_replacement => true, :frequency => "ONCE A WEEK", :add => true).should be_true
  end

  it "Verifies added content in the cart" do
    slmc.verify_added_content_in_order_cart("BABYHALER").should be_true
  end

  it "Validates drug" do
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :orders => "single").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Checks if the order is listed successfully" do
    slmc.go_to_general_units_page
    slmc.verify_order_list(:pin => @@pin).should be_true
  end

  it "Creates and verifies a successful batch drug request" do #v1.4 all drugs requires validation. order ancillary to satisfy the scenario of clicking the General Units Order Cart Page link.
    slmc.nursing_gu_search(:pin => @@pin, :last_name => @gu_patient[:last_name].upcase)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    slmc.search_order(:description => "NEBUCHAMBER", :drugs => true).should be_true
    slmc.add_returned_order(:drugs => true, :add => true, :batch => true, :description => "NEBUCHAMBER",
      :remarks => "3 TIMES A DAY FOR 5 DAYS", :dose => 3, :quantity => 3, :frequency => "ONCE A WEEK").should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_item("NEBUCHAMBER").should be_true
    slmc.click("link=Order Page", :wait_for => :page)
    slmc.search_order(:ancillary => true, :description => "010001047").should be_true
    slmc.add_returned_order(:ancillary => true, :description => @items["010001047"][:desc], :add => true).should be_true
    slmc.submit_added_order
    slmc.validate_item("URINE HEMOSIDERIN QUALITATIVE").should be_true
    (slmc.get_text("css=#pendingOrder>span")).to_i.should == @@pending_orders
    slmc.go_to_general_units_page
    slmc.verify_order_list(:pin => @@pin).should be_true
  end

  it "Edits a patient's package by updating the doctor" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Package Management", @@pin)
    slmc.edit_package(:doctor => "6930").should be_true
  end

  it "Validates patient's package" do
    slmc.validate_package.should be_true
    slmc.validate_credentials(:username => "sel_0287_validator", :password => @password, :package => true).should be_true
  end

  it "Bug #21956 - Clicking 'Switch Validated Items' buttons without switchable item in the package should not display yikes" do
    sleep 2
    slmc.click Locators::Wellness.edit_package
    sleep 3
    slmc.click Locators::Wellness.switch_validated_item_button
    slmc.is_text_present("General Units › Package Management").should be_true
  end

  it "Edits PF amount then discharges patient clinically (test for defer)" do
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => "1000", :pf_type => "COLLECT", :with_complementary => true, :no_pending_order => true, :save => true).should be_true
  end

  it "Defers clinical discharge" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.defer_clinical_discharge(:pin => @@pin).should be_true
  end

  it "Verify that “Reprint Discharge Notice Slip” is not available when clinical discharge is deferred" do
    slmc.get_select_options("userAction#{@@pin}").include?("Reprint Discharge Notice Slip").should be_false
  end

  it "Discharges patient clinically" do
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :save => true).should be_true
  end

  it "Verify that “Reprint Discharge Notice Slip” is available upon clinical discharge" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.get_select_options("userAction#{@@pin}").include?("Reprint Discharge Notice Slip").should be_true
  end

  it "Checks if the patient is in the Patient Billing and Accounting page" do
    slmc.login("sel_pba4", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
  end

  it "Verifies that error message is displayed when PF has not been settled" do
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
    slmc.spu_hospital_bills(:type => "CASH")
    slmc.submit_payment.should be_false
    slmc.is_text_present("Payment Data Entry").should be_true # ((slmc.get_text"validationMessage.errors").include?"Payment for professional fee is not sufficient.").should be_true # modified on v1.4.
  end

  it "Goes through the payment to settle PF" do
    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
    slmc.print_or.should be_true
  end

  it "Generates patient's SOA in the Discharged patients page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.generate_soa_for_pin(@@pin).should be_true # not actually generating SOA
  end

  it "Verifies the PF amount was deducted from the SOA" do
    @@balance_due = slmc.generates_soa_after_pf_payment(@@pin)
    slmc.click("popup_ok", :wait_for => :page)
    slmc.is_text_present("The SOA was successfully updated with printTag = 'Y'.").should be_true
  end

  it "Goes through the discharge to payment page" do #already discharge the patient on the scenario's above
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@pin).should be_true
  end

  it "Verifies if the patient is no longer displayed in the patients with discharge notice page after payment" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin, :no_result => true).should be_true
  end

  it "Prints Gate Pass in the NGU page" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
  end

  it "Verifies if patient is listed only under ALL Patients after discharge and payment and physically out" do
    slmc.login("sel_pba4", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin, :no_result => true).should be_true
    slmc.pba_search(:pin => @@pin, :discharged => true, :no_result => true).should be_true
    slmc.pba_search(:pin => @@pin, :admitted => true, :no_result => true).should be_true
    slmc.pba_search(:pin => @@pin, :all_patients => true).should be_true
  end

  it "Checks the status of patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin).should be_true
  end

  it "Verifies existence of patient in general units page" do
    slmc.nursing_gu_search(:pin => @@pin, :no_result => true).should be_true
  end

  it "Outpatient Registration" do
    slmc.login("sel_or1", @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click("link=Outpatient Registration", :wait_for => :page)
    @@su_pin = slmc.outpatient_registration(@su_patient).gsub(' ', '')
  end

  it "Verifies spu patient not appearing on GU search" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.nursing_gu_search(:pin => @@su_pin, :last_name => @su_patient[:last_name].upcase, :no_result => true).should be_true
  end

  it "Registers patient for order transactions in OR" do
    slmc.login("sel_or1", @password).should be_true
    slmc.or_register_patient(:pin => @@su_pin, :rch_code => "RCHSP", :org_code =>"0164").should be_true
  end

  it "Searches for procedures in the Add Checklist Order page" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@su_pin)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@su_pin)
    sleep 5
    @@item_code = slmc.search_service(:procedure => true, :description => "REMOVAL/APPLICATION OF CAST")
  end

  it "Adds returned service item to cart" do
    sleep 1
    slmc.add_returned_service(:item_code => @@item_code, :description => "REMOVAL/APPLICATION OF CAST").should be_true
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726").should be_true
    slmc.validate_item("REMOVAL/APPLICATION OF CAST").should be_true
  end

  it "Adds procedure in the Checklist Order Adjustment page" do
    slmc.go_to_outpatient_nursing_page
    slmc.search_soa_checklist_order(:date_today => (Date.today).strftime("%m/%d/%Y"))
    slmc.adjust_checklist_order
    @@soa_number = slmc.get_soa_number
    slmc.checklist_order_adjustment(:checklist_order => 'CIRCUMCISION', :add => true).should be_true
  end

  it "Checklist ordering can be created and validated" do
    slmc.go_to_outpatient_nursing_page
    slmc.search_soa_checklist_order(:soa_number => @@soa_number).should be_true
  end

  it "Removes procedure in the Checklist Order Adjustment page" do
    slmc.go_to_outpatient_nursing_page
    slmc.search_soa_checklist_order(:date_today => (Date.today).strftime("%m/%d/%Y"), :soa_no => @@soa_number)
    slmc.adjust_checklist_order
    slmc.checklist_order_adjustment(:remove => true).should be_true
  end
  
end
