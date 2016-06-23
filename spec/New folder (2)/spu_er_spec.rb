require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: ER Special Units Tests" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @er_patient = Admission.generate_data
    @er_patient2 = Admission.generate_data
    @er_patient3 = Admission.generate_data
    @gu_patient = Admission.generate_data
    @patient = Admission.generate_data
    @password = '123qweuser'
    @er_user = "sel_er1"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates patient record for ER" do
    slmc.login(@er_user, @password).should be_true
    @@er_pin = slmc.er_create_patient_record(@er_patient.merge(:admit => true, :gender => 'F')).gsub(' ', '')

    @@er_pin2 = slmc.er_create_patient_record(@er_patient2.merge(:admit => true, :gender => 'F')).gsub(' ', '')

    @@er_pin5 = slmc.er_create_patient_record(@patient.merge(:admit => true)).gsub(' ', '').gsub(' ', '')
  end

  it "Test if input field for Search accepts either description or item code" do
    slmc.er_clinical_order_patient_search(:pin => @@er_pin)#.should be_true
    slmc.search_order(:drugs => true, :description =>  "040004334").should be_true
    slmc.search_order(:supplies => true, :description => "080200000").should be_true
    slmc.search_order(:ancillary => true, :description => "010000003").should be_true
    slmc.search_order(:others => true, :description => "050000009").should be_true
    slmc.search_order(:drugs => true, :description => "SOLUSET").should be_true
    slmc.search_order(:supplies => true, :description => "NASO-TRACHEAL TUBE IVORY S7").should be_true
    slmc.search_order(:ancillary => true, :description => "BONE IMAGING - THREE PHASE STUDY").should be_true
    slmc.search_order(:others => true, :description => "BLOOD WARMER - SUCCEDING HOUR").should be_true
  end

  it "Verifies that patient is searchable in ER occupancy list." do
    slmc.er_occupancy_search(:pin => @@er_pin2).should be_true
  end

  it "Gets the number of patients in admission queue." do
    slmc.login("sel_adm3", @password).should be_true
    slmc.go_to_admission_page
    sleep 2
    @@count = slmc.get_patients_for_admission_count
  end

  it "Successfully create and admit patient in GU page" do
    slmc.login("gu_spec_user2", @password).should be_true
    slmc.go_to_admission_page
    slmc.admission_search(:pin => "test")
    @@gu_pin = slmc.create_new_patient(@gu_patient.merge(:gender => 'F')).gsub(' ','')
    slmc.admission_search(:pin => @@gu_pin).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08',
      :org_code => '0287', :diagnosis => "GASTRITIS", :package => "PLAN A FEMALE").should == "Patient admission details successfully saved."
  end

  it "Should display Admission Page after saving/registering patient." do
    slmc.get_text("breadCrumbs").should =="Admission  \342\200\272  Patient Search"
  end

  it "Records of patients registered in ER or Admitted in GU are searchable in OR page" do
    slmc.login("sel_or4", @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@gu_pin, :no_result => true).should be_false
    slmc.patient_pin_search(:pin => @@er_pin2, :no_result => true).should be_false
  end

  it "Feature #38108 - System validation for the same drug order that is already been batched" do
    slmc.login("gu_spec_user2", @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.search_order(:drugs => true, :description => "042820145").should be_true
    slmc.add_returned_order(:drugs => true, :description => "042820145", :frequency => "THREE(3)TIMES A DAY AFTER MEAL - 8AM,1PM,8PM", :batch => true, :add => true ).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Feature #38108 - System validation for the same drug order that is already been batched but different frequency" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.search_order(:drugs => true, :description => "042820145").should be_true
    slmc.add_returned_order(:drugs => true, :description => "042820145", :batch => true, :add => true )#.should be_false
    sleep 2
    add_button = slmc.is_element_present("//input[@value='ADD']") ? "//input[@value='ADD']" : "//input[@value='Add']"
    slmc.click add_button
    (slmc.is_element_present"validationBatchExist").should be_true
    (slmc.click"//input[@type='button' and @value='Ok']") if slmc.is_element_present"validationBatchExist"
  end

  it "Feature #38108 - Batch ordering applies only for Inpatient not in SPU" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_landing_page
    slmc.er_clinical_order_patient_search(:pin => @@er_pin2)
    slmc.search_order(:drugs => true, :description => "042820145").should be_true
    (slmc.is_visible"checkBatch").should be_false
  end

  it "Feature #45819 - Inpatient: Clinical pharmacist/NUM/ANUM validation will display in Order validation page upon hitting the Order cart submit button" do
    slmc.login("gu_spec_user2", @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.search_order(:drugs => true, :description => "042820145").should be_true
    slmc.add_returned_order(:drugs => true, :description => "042820145", :add => true ).should be_true
    slmc.submit_added_order
    (slmc.is_element_present"validatePharmacistForm").should be_true
  end

  it "Feature #45819 - Inpatient: Only valid user credentials will be accepted upon drug order validation" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.submit_added_order(:validate => true, :username => "username").should be_false
  end

  it "Feature #45819 - Inpatient: Only valid user credentials will be accepted upon drug order validation - 2" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    (slmc.is_editable"drugOrderCartDetailCheckAll").should be_true
  end

  it "Feature #45819 - Inpatient: Access orders for validation through quicklinks" do
    @@visit_no = slmc.get_visit_number_using_pin(@@gu_pin)
    slmc.validate_pending_orders(:pin => @@gu_pin, :visit_no => @@visit_no).should be_true
  end

  it "Feature #45819 - Inpatient: User will not require validation if with role_general_units_manager" do
    slmc.login("sel_gu3", @password).should be_true
    slmc.validate_pending_orders(:with_role_manager => true, :pin => @@gu_pin, :visit_no => @@visit_no).should be_true
    slmc.validate_orders(:drugs => true, :orders => "single").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Patient name is forwarded to Admission list for room assignment" do
    slmc.login(@er_user, @password).should be_true
    slmc.er_occupancy_search(:pin => @@er_pin2)
    slmc.go_to_er_page_using_pin("Update Registration", @@er_pin2)
    slmc.click "turnedInpatientFlag1"
    slmc.click "previewAction", :wait_for => :page
    slmc.click "//input[@name='action' and @value='Save']", :wait_for => :page
    slmc.is_text_present("Patient admission details successfully saved.").should be_true
    slmc.login("sel_adm3", @password).should be_true
    slmc.admission_search(:pin => @@er_pin2)
    slmc.is_text_present("Outpatient Registration").should be_true
    slmc.er_outpatient_to_inpatient(:pin => @@er_pin2, :room_label => "REGULAR PRIVATE", :diagnosis => "GASTRITIS").should be_true
  end

  it "Encounter record is tagged as In-patient" do
    slmc.admission_search(:pin => @@er_pin2)
    if slmc.is_text_present("Master Patient Index is unavailable. Searching from local data...")
      slmc.get_text('css=table[id="results"] tbody tr[class="even"] td:nth-child(8)').should == "Inpatient Admission" #mpi is off
    else
      slmc.get_text('css=table[id="results"] tbody tr[class="odd"] td:nth-child(9)').should == "Inpatient Admission" #mpi is on
    end
  end

  # recently implemented. er can see turned inpatient. changing description as per Ludwig 11/28/2011
  it "Patient can be seen in ER occupancy list" do #"Patient record is no longer included in ER occupancy list" do
    slmc.go_to_admission_page
    sleep 8
    slmc.get_patients_for_admission_count.should == @@count
    slmc.login(@er_user, @password).should be_true
    slmc.er_occupancy_search(:pin => @@er_pin2, :no_result => true).should be_false
  end

  it "Patient record is included in GU occupancy list" do
    slmc.login("gu_spec_user2", @password).should be_true
    slmc.nursing_gu_search(:pin => @@er_pin2).should be_true
  end

  it "Encode new physician, citizenship : All encoded data are displayed in preview page" do
    slmc.login("sel_adm3", @password).should be_true
    slmc.go_to_admission_page
    slmc.reprint_patient_admission(:pin => @@er_pin2, :edit_record => true, :doc_code => "0126",  :room_label => "REGULAR PRIVATE").should be_true
  end

  it "Re-print PDS" do
    sleep 2
    slmc.go_to_reprinting_page(:patient_data_sheet => true).should be_true
  end

  it "Printed data in PDS is complete" do
    slmc.admission_search(:pin => @@er_pin2)
    slmc.update_admission(:save => true).should be_true
  end

  it 'Searches the ER patient and performs clinical ordering - Single order of DRUGS' do
    slmc.login(@er_user, @password).should be_true
    slmc.er_clinical_order_patient_search(:pin => @@er_pin)
    slmc.search_order(:drugs => true, :description => "BABYHALER").should be_true
    slmc.add_returned_order(:drugs => true, :description => "BABYHALER", :quantity => 2, :stat => true, :stock_replacement => true,
      :frequency => "STAT - NOW", :add => true).should be_true
  end

  it "Validates SINGLE order" do
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:drugs => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Performs ER clinical ordering - Multiple orders of DRUGS" do
    slmc.er_clinical_order_patient_search(:pin => @@er_pin)
    slmc.search_order(:drugs => true, :description => "BABYHALER").should be_true
    slmc.add_returned_order(:drugs => true, :description => "BABYHALER", :quantity => 2, :stat => true, :stock_replacement => true,
      :frequency => "STAT - NOW", :add => true).should be_true
    slmc.search_order(:drugs => true, :description => "NEBUCHAMBER").should be_true
    slmc.add_returned_order(:drugs => true, :description => "NEBUCHAMBER", :quantity => 2, :stat => true, :stock_replacement => true,
      :frequency => "STAT - NOW", :add => true).should be_true
  end

  it "Bug #24628 ER Order Validation - Encountered error message after validating orders." do
    slmc.search_order(:supplies => true, :description => "ALCOHOL 70% ISOPROPHYL 250ML").should be_true
    slmc.add_returned_order(:supplies => true, :description => "ALCOHOL 70% ISOPROPHYL 250ML", :quantity => 2, :stat => true,
      :stock_replacement => true, :add => true).should be_true
    slmc.search_order(:ancillary => true, :description => "ALDOSTERONE").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "ALDOSTERONE", :quantity => 2, :stat => true, :add => true).should be_true
    slmc.search_order(:others => true, :description => "CONDITIONER").should be_true
    slmc.add_returned_order(:others => true, :description => "CONDITIONER", :quantity => 2, :stat => true, :stock_replacement => true, :add => true).should be_true
    slmc.search_order(:special => true).should be_true
    slmc.add_returned_order(:special => true, :special_description => "special item", :quantity => 2, :stat => true, :stock_replacement => true, :add => true).should be_true
  end

  it "Search for special purchase(089999 item code)" do
    slmc.search_order(:supplies => true, :description => "089999").should be_true
    sleep 5
    slmc.is_editable("itemDesc").should be_true
  end

  it "Validates SOME orders of the same type" do
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:drugs => true, :orders => "single")
    slmc.confirm_validation_some_items.should be_true
  end

  it "Performs ER clinical ordering - Multiple orders of DRUGS" do
    slmc.er_clinical_order_patient_search(:pin => @@er_pin)#.should be_true
    slmc.search_order(:drugs => true, :description => "NEBUCHAMBER").should be_true
    slmc.add_returned_order(:drugs => true, :description => "NEBUCHAMBER", :quantity => 2, :stat => true, :stock_replacement => true,
      :frequency => "STAT - NOW", :add => true).should be_true
  end

  it "Get patient visit number" do
    slmc.er_occupancy_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_using_pin("Discharge Instructions\302\240", @@er_pin)
    slmc.add_final_diagnosis(:save => true)
    slmc.er_occupancy_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_using_pin("Doctor and PF Amount", @@er_pin)
    @@visit_no = slmc.get_text("banner.visitNo").gsub(' ', '')
  end

  it "Verifies pending orders in the cart prior to clinical discharge" do
    slmc.clinical_discharge(:pf_amount => "1000", :pf_type => "DIRECT").should be_false
    slmc.is_text_present("There are still pending orders in cart.").should be_true
  end

  it "Count Pending Orders" do
    slmc.go_to_er_landing_page
    @@pending_order_count = slmc.get_pending_orders_count
  end

  it "Feature #45819 - SPU ER doesnt requires to validate any drugs orders by Clinical Pharmacist/Num/ANum" do
    slmc.search_pending_orders(@@er_pin, @@visit_no)
    slmc.validate_orders(:drugs => true, :supplies => true, :ancillary => true, :others => true, :special => true, :orders => "multiple").should == 6
    slmc.confirm_validation_all_items.should be_true
  end

  it "Verify if Pending Orders decreases upon validating orders" do
    slmc.go_to_er_landing_page
    slmc.get_pending_orders_count.should == @@pending_order_count - 6
  end

  it "Bug #24837 ER Order List - Special orders validated in Order page not displayed under Special tab" do
    slmc.er_occupancy_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_using_pin("Order List", @@er_pin)#.should be_true
    slmc.search_order_list(:type => "special", :item => "special item").should be_true
  end

  it "Validates all items are visible in Order List page" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_using_pin("Order List", @@er_pin)#.should be_true
    slmc.search_order_list(:type => "drugs", :item => "040004334").should be_true#BABYHALER
    slmc.search_order_list(:type => "drugs", :item => "040004335").should be_true#NEBUCHAMBER
    slmc.search_order_list(:type => "supplies", :item => "080100022").should be_true
    slmc.search_order_list(:type => "ancillary", :item => "010000004").should be_true
    slmc.search_order_list(:type => "misc", :item => "050000009").should be_true
    slmc.search_order_list(:type => "special", :item => "9999").should be_true
  end

  it "Bug #24627 - ER Order List - Searching by order date not functional" do
    slmc.er_occupancy_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_using_pin("Order List", @@er_pin)#.should be_true
    #search by order date
    slmc.search_order_list(:type => "drugs", :item => "040004334", :order_date => Date.today.strftime("%m/%d/%Y")).should be_true
    slmc.search_order_list(:type => "drugs", :item => "040004335", :order_date => Date.today.strftime("%m/%d/%Y")).should be_true
  end

  it "Bug #24627 - ER Order List - Searching by CI number not functional" do
    #pharmacy user login to get CI number
    slmc.login("sel_pharmacy1", @password).should be_true
    slmc.go_to_pharmacy_landing_page
    slmc.medical_search_patient(@@er_pin)
    ci_number = slmc.get_ci_number
    slmc.login(@er_user, @password).should be_true
    slmc.er_occupancy_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_using_pin("Order List", @@er_pin)
    #search by CI number
    slmc.search_order_list(:status => "cancelled", :type => "drugs", :item => "040004335", :ci_number => ci_number).should be_false
    sleep 1
    slmc.search_order_list(:status => "validated", :type => "drugs", :item => "040004335", :ci_number => ci_number).should be_true
  end

  it "Discharges patient clinically" do
    slmc.er_occupancy_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_using_pin("Doctor and PF Amount", @@er_pin)#.should be_true
    slmc.clinical_discharge(:no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard").should be_true
  end

  it "Bug #24906 - ER BILLING - Pretty picture displayed when generating unofficial SOA" do
    slmc.go_to_er_billing_page
    slmc.patient_pin_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_for_a_given_pin("Generation of SOA", @@visit_no)
    slmc.click_print_unofficial_soa.should be_true
  end

  it "Updates status of clinically discharged patient" do
    slmc.er_occupancy_search(:pin => @@er_pin).should be_true
    slmc.get_text("//html/body/div/div[2]/div[2]/table/tbody/tr/td[7]").should == "Clinically Discharged"
  end

  it "Validates unpaid PF amounts before client discharge" do
    slmc.go_to_er_billing_page
    slmc.patient_pin_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_for_a_given_pin("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD")
    slmc.click_new_guarantor
    slmc.pba_update_guarantor
    slmc.update_patient_or_guarantor_info
    slmc.philhealth_page(:skip=>true)
    slmc.discount_information
    slmc.skip_generation_of_soa
    slmc.click'//input[@type="submit" and @value="Proceed with Payment"]', :wait_for => :page
    (slmc.is_element_present"validationMessage.errors").should be_true
  end

  it "Settles PF amounts through CASH" do
    slmc.go_to_er_billing_page
    slmc.patient_pin_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_for_a_given_pin("Payment", @@visit_no)
    slmc.pba_pf_payment(:deposit => true, :pf_amount => "1000").should be_true
  end

  it "Allows user to go back to landing page after PF payment" do
    slmc.click("popup_ok") if slmc.is_element_present"popup_ok"
    sleep 5
    slmc.go_to_landing_page.should be_true
  end

  it "Bug #24309 PhilHealth-ER * Able to save Cancelled PhilHealth" do
    slmc.go_to_er_billing_page
    slmc.patient_pin_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_for_a_given_pin("PhilHealth", @@visit_no)
    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE",
      :with_operation => true, :rvu_code => "10060", :compute => true )
    @@ref_num = slmc.ph_save_computation
    slmc.ph_cancel_computation.should be_true#for cancel button to appear role_philhealth_officer
    slmc.is_editable("btnSave").should be_false
  end

  it "Bug #25290 PhilHealth-ER * Unable to select claim type on standard discharge" do
    # create new er patient record
    slmc.login(@er_user, @password).should be_true
    @@er_pin4 = slmc.er_create_patient_record(Admission.generate_data.merge(:admit => true)).gsub(' ', '')

    slmc.go_to_er_landing_page
    slmc.er_clinical_order_patient_search(:pin => @@er_pin4)
    slmc.search_order(:ancillary => true, :description => "010000003").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010000003", :quantity => 2, :stat => true, :add => true).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_er_landing_page
    @@visit_no4 = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin4, :no_pending_order => true, :pf_amount => 1000, :save => true).should be_true

    slmc.go_to_er_billing_page
    slmc.patient_pin_search(:pin => @@er_pin4).should be_true
    slmc.go_to_er_page_for_a_given_pin("Discharge Patient", @@visit_no4)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.click_new_guarantor
    slmc.pba_update_guarantor
    slmc.update_patient_or_guarantor_info
    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true)
    slmc.is_editable("claimType").should be_true
    slmc.get_selected_label("claimType").should == "ACCOUNTS RECEIVABLE"
  end

#  # Feature 45876
#  it "Feature #45876 - Verify that “Reprint Discharge Notice Slip” is available upon clinical discharge" do
#    slmc.go_to_er_landing_page
#    slmc.patient_pin_search(:pin => @@er_pin4)
#    slmc.get_select_options("userAction#{@@er_pin4}").include?("Reprint Discharge Notice Slip").should be_true
#    slmc.get_select_options("userAction#{@@er_pin4}").should == ["Reprint Discharge Notice Slip", "Defer Discharge", "Discharge Instructions\302\240", "Notice of Death", "Print Label Sticker"]
#  end

  it "Bug #25432 PhilHealth-ER * Encountered NullPointerException on Recompute after cancellation" do
    slmc.go_to_er_billing_page
    slmc.pba_search(:pin => @@er_pin)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
    slmc.ph_recompute.should be_true
    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true)
    slmc.ph_save_computation
    slmc.philhealth_computation(:edit => true, :claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true)
    slmc.is_element_present("btnRecompute").should be_false
  end

  it "Bug #24526 PhilHealth-ER * Encountered java.lang.ArithmeticException when saving computed PhilHealth" do
    slmc.go_to_er_billing_page
    slmc.patient_pin_search(:pin => @@er_pin).should be_true
    slmc.go_to_er_page_for_a_given_pin("PhilHealth", @@visit_no)

    # cancel current PH computation so user can save the computation again
    slmc.ph_cancel_computation(:reason => "sample reason only").should be_true
    slmc.ph_recompute.should be_true

    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE",
      :with_operation => true , :rvu_code => "66987", :compute => true)
    @@ph_ref_num = slmc.ph_save_computation
    slmc.is_text_present("Patient Billing and Accounting Home › PhilHealth").should be_true
  end

  it "Bug #26300 PhilHealth-Inpatient * Doesn't generate new PhilHealth Reference No. when recomputed" do
    # cancel current PH computation so user can save the computation again
    slmc.ph_cancel_computation.should be_true
    slmc.ph_recompute.should be_true

    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE",
      :with_operation => true, :rvu_code => "66987", :compute => true)
    slmc.ph_save_computation
    @@ph_ref_num.should_not == slmc.get_text(Locators::Philhealth.reference_number_label2)
  end

  it "Bug #24307 PhilHealth-ER * Claim Type Refund is saved as Final - Refund can only be saved as Estimate" do
     slmc.go_to_er_landing_page
    @@er_pin3 = slmc.er_create_patient_record(@er_patient3.merge(:admit => true)).gsub(' ', '')

    slmc.go_to_er_landing_page
    slmc.er_clinical_order_patient_search(:pin => @@er_pin3)
    slmc.search_order(:ancillary => true, :description => "010000003").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010000003", :quantity => 2, :stat => true, :add => true).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
    slmc.go_to_er_landing_page
    @@visit_no3 = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin3, :pf_amount => "1000", :no_pending_order => true, :pf_type => "DIRECT", :save => true).should be_true

    slmc.go_to_er_billing_page
    slmc.patient_pin_search(:pin => @@er_pin3)
    slmc.go_to_er_page_for_a_given_pin("Discharge Patient", @@visit_no3)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.click_new_guarantor.should be_true
    slmc.pba_update_guarantor.should be_true
    slmc.update_patient_or_guarantor_info.should be_true
    slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :with_operation => true, :compute => true)
    slmc.ph_save_computation.should be_true
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.get_text("//html/body/div/div[2]/div[2]/div[16]/h2").should == "ESTIMATE"
  end

  it "Discharges the patient successfully" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_billing_page
    slmc.patient_pin_search(:pin => @@er_pin3)
    slmc.go_to_er_page_for_a_given_pin("Discharge Patient", @@visit_no3)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
  end

#  it "Feature #45876 - Verify that “Reprint Discharge Notice Slip” is not available upon billing discharge" do
#    slmc.er_occupancy_search(:pin => @@er_pin3)
#    slmc.get_select_options("userAction#{@@er_pin3}").include?("Reprint Discharge Notice Slip").should be_false
#  end
#
#  it "Feature #45876 - Verify that “Reprint Gate Pass” is available upon physical discharge when ROLE_LATE_TRANSACTION is added" do
#    slmc.go_to_er_page # sel_er1 has ROLE_LATE_TRANSACTION
#    slmc.er_print_gatepass(:pin => @@er_pin3, :visit_no => @@visit_no3).should be_true
#    slmc.er_occupancy_search(:pin => @@er_pin3, :discharged => true)
#    slmc.get_text("css=#occupancyList>tbody>tr>td:nth-child(7)").should == "DISCHARGED"
#    slmc.get_select_options("userAction#{@@er_pin3}").include?("Reprint Gate Pass").should be_true
#  end

#  it "Verify that “Reprint Gate Pass” is available upon physical discharge when ROLE_LATE_TRANSACTION is not available" do
#    slmc.login("sel_er2", @password).should be_true # doesnt have ROLE_LATE_TRANSACTION
#    slmc.go_to_er_page
#    slmc.is_element_present("//input[@type='checkbox' and @name='discharged']").should be_false
#    slmc.patient_pin_search(:pin => @@er_pin3, :no_result => true).should be_true
#  end

  it "Bug #22084 - Reprint OR successfully" do
    slmc.go_to_er_billing_page
    slmc.pba_document_search(:select => "Payment", :doc_type => "OFFICIAL RECEIPT").should be_true
    slmc.pba_reprint_or.should be_true
  end

#1.4.1 issues for regression
  it"Bug#40929 - [ER]: Exception encountered during admission of ER patient" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_page
    slmc.er_patient_search(:pin => "test")
    slmc.click_create_patient_record
    slmc.click'//input[@type="button" and @value="Save"]', :wait_for => :page
    (slmc.get_text"patient.errors").should == "First Name is a required field.\nMiddle Name is a required field.\nLast Name is a required field.\nGender is a required field.\nBirthdate is a required field.\nPresent Contact is a required field.\nPerson to Notify is a required field."
  end

  it"Bug#40570 - [ER-Confinement History]: Outstanding PF balance is not reflected" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_page
    slmc.er_patient_search(:pin => "test")
    @@er_pin1 = slmc.ss_create_outpatient_er(Admission.generate_data).gsub(' ','')
    slmc.go_to_er_landing_page
    slmc.er_patient_search(:pin => @@er_pin1)
    slmc.click_register_patient
    slmc.admit_er_patient(:account_class => "INDIVIDUAL")

    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin1)
    @@visit_no1 = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin1, :pf_type => "COLLECT", :pf_amount => '1000', :no_pending_order => true, :save => true)

    slmc.go_to_er_billing_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
    slmc.click_new_guarantor
    slmc.type"guarantorName", "SELENIUMTESTING,SELENIUMTESTING"
    slmc.click"includePfTag"
    sleep 1
    slmc.click"chkCovered0"
    slmc.type"loa.maximumPfAmount" , "500"
    slmc.click "_submit", :wait_for => :page
    slmc.click_submit_changes.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
    slmc.pba_pf_payment(:pf_amount => "500").should be_true
    slmc.go_to_er_landing_page
    slmc.er_print_gatepass(:pin => @@er_pin1, :visit_no=>@@visit_no1)

    slmc.go_to_er_landing_page
    slmc.er_patient_search(:pin => @@er_pin1)
    slmc.click"css=#results>tbody>tr.even>td:nth-child(9)>div>a", :wait_for => :element, :element => "divConfinementHistoryPopup"
    sleep 8
    (slmc.get_text("css=#confinementHistoryRows>tr:nth-child(2)>td:nth-child(13)").to_f).should == 500.0
  end

  it "Feature#41632 - Do not allow Unit Price to be less than 0.01" do
    slmc.login(@er_user,@password).should be_true
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin5)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin5)
    slmc.search_order(:drugs => true, :description => "049999").should be_true
    slmc.add_returned_order(:drugs => true, :description => "049999", :quantity => "3.0", :frequency => "ONCE A WEEK", :spdrugs_amount => "0", :doctor => "6726", :add => true).should == "Unit Price should not be less than 0.01."
  end

  it "Feature#41632 - Total amount field should reflect quantity entered" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin5)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin5)
    slmc.click"orderType1"
    slmc.type "oif_entity_finder_key",  "049999"
    slmc.click"search", :wait_for => :element, :element => "link=049999"
    sleep 1
    slmc.is_text_present"049999"
    (slmc.get_text"css=#order_qty_div>label>font").should == "*"
    (slmc.get_text"css=#order_unitprice_div>label>font").should == "*"
    slmc.is_editable"quantity".should be_true
    slmc.is_editable"serviceRateDisplay".should be_true
    @quantity1 = slmc.get_value"quantity"
    slmc.type"quantity" , "5.0"
    sleep 1
    (slmc.get_value"quantity").should_not == @quantity1
  end

  it "Feature#41632 - Unit Price field is editable" do
    @price1 = slmc.get_value"serviceRateDisplay"
    slmc.type"serviceRateDisplay" , "750.00"
    sleep 1
    (slmc.get_value"serviceRateDisplay").should_not == @price1
  end

  it "Feature#41632 - Add special drug order" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin5)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin5)
    slmc.search_order(:drugs => true, :description => "049999").should be_true
    slmc.type"itemDesc" , "SPECIAL DRUGS DESCRIPTION"
    slmc.add_returned_order(:drugs => true, :description => "049999", :quantity => "3.0", :frequency => "ONCE A WEEK", :spdrugs_amount => "750.00", :doctor => "6726", :add => true).should be_true

    slmc.search_order(:description => "010000684", :ancillary => true).should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010000684", :add => true, :doctor => "0126").should be_true
    slmc.search_order(:supplies => true, :description => "080200000").should be_true
    slmc.add_returned_order(:supplies => true, :description => "080200000", :add => true, :doctor => "0126").should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Feature #44822 - Verify that Unit Price is added in UI for special item Checklist order" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin5)
    slmc.go_to_er_page_using_pin("Checklist Order", @@er_pin5)
    sleep 5
    slmc.click("drugFlag")
    slmc.type("oif_entity_finder_key", "049999")
    slmc.click("search", :wait_for => :element, :element => "link=049999")
    slmc.get_value("itemCodeDisplay").should == "049999"
    slmc.is_element_present("itemCodeDisplay").should be_true
    slmc.is_element_present("itemDesc").should be_true
    slmc.is_element_present("remarks").should be_true
    slmc.is_element_present("sQuantity").should be_true
    slmc.is_element_present("serviceRateDisplay").should be_true
    slmc.is_element_present("amount").should be_true
    slmc.is_element_present("//input[@value='Add']").should be_true
    slmc.is_element_present("_clearButton").should be_true
  end

  it "Feature #44822 - Verify that Unit Price cannot be set to blank" do
    slmc.type("itemDesc", "SPECIAL DRUGS DESCRIPTION")
    slmc.type("remarks" , "REMARKS")
    slmc.type("serviceRateDisplay" , "")
    slmc.click("//input[@type='button' and @value='Add']", :wait_for => :page)
    sleep 2
    slmc.get_text("checkListOrderBean.errors").should == "Unit Price should be greater than 0."
  end

  it "Feature #44822 - Verify that Unit Price cannot be set to “0”" do
    slmc.type("serviceRateDisplay", "0.0")
    slmc.click("//input[@type='button' and @value='Add']", :wait_for => :page)
    sleep 2
    slmc.get_text("checkListOrderBean.errors").should == "Unit Price should be greater than 0."
  end

  it "Feature #44822 - Verify that Unit Price does not accept invalid values" do
    slmc.type("serviceRateDisplay" , "-1")
    slmc.click("//input[@type='button' and @value='Add']", :wait_for => :page)
    sleep 2
    slmc.get_text("checkListOrderBean.errors").should == "Unit Price should be greater than 0."
  end

  it "Feature #44822 - Verify that Unit Price accepts valid values" do
    slmc.search_er_checklist_order(:drugs => true, :description => "049999").should be_true
    slmc.add_er_checklist_order(:description => "049999", :special => true, :spdrugs_amount => "150.00").should be_true
  end

  it "Feature #44822 - Verify that UI is the still the same when item is edited" do
    sleep 5
    slmc.click("css=#clo_tbody>tr.even>td>a", :wait_for => :page)
    slmc.is_editable("sQuantity").should be_true
    slmc.is_editable("serviceRateDisplay").should be_true
  end

  it "Feature #44822 - Verify that ordered item can be edited" do
    slmc.edit_checklist_order(:special => true, :price => "200", :quantity => "2").should == "Order item 049999 - SPECIAL DRUGS DESCRIPTION has been edited successfully."
  end

  it "Feature#41632 - Check the unit price amount and total amount indicated on the OR and SOA"do
    slmc.confirm_checklist_order
    slmc.validate_item("049999").should be_true
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin5)
    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin5, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
    slmc.go_to_er_billing_page
    slmc.patient_pin_search(:pin => @@er_pin5)
    slmc.go_to_er_page_for_a_given_pin("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    if slmc.is_text_present("Nothing found to display.")
      slmc.click_new_guarantor
      slmc.pba_update_guarantor(:guarantor_type => "INDIVIDUAL")
    end
    slmc.skip_update_patient_information.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.click_generate_official_soa.should be_true
    slmc.skip_generation_of_soa.should be_true
    slmc.spu_hospital_bills(:type => "CASH").should be_true
    slmc.spu_submit_bills("defer").should == "Patients for DEFER should be processed before end of the day"
    slmc.print_or
    (slmc.is_text_present("The Official Receipt print tag has been set as 'Y'.")).should be_true
  end

  it "Verify that “Reprint Discharge Notice Slip” is not available when clinical discharge is deferred" do
    slmc.login(@er_user, @password).should be_true
    @@er_pin6 = slmc.er_create_patient_record(Admission.generate_data.merge(:admit => true, :gender => 'F')).gsub(' ', '')
    slmc.er_occupancy_search(:pin => @@er_pin6)
    slmc.clinically_discharge_patient(:pin => @@er_pin6, :er => true, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.er_occupancy_search(:pin => @@er_pin6)
    slmc.defer_clinical_discharge(:pin => @@er_pin6, :er => true).should be_true
    slmc.er_occupancy_search(:pin => @@er_pin6)
    slmc.get_select_options("userAction#{@@er_pin6}").include?("Reprint Discharge Notice Slip").should be_false
  end

  it "Verify that Frequency is automatically set to STAT-NOW" do
    slmc.er_occupancy_search(:pin => @@er_pin6)
    slmc.go_to_er_page_using_pin("Order Page", @@er_pin6)
    slmc.get_value("priorityCode").should == "on"
    slmc.search_order(:description => "040004334", :drugs => true).should be_true
    slmc.add_returned_order(:drugs => true, :stat => true, :description => "040004334", :doctor => "6726")
    slmc.get_value("priorityCode").should == "on"
    slmc.get_selected_label("frequencyCode").should == "STAT - NOW"
  end

  it "Verify that Frequency is automatically set to default value when STAT checkbox is not checked" do
    slmc.click("priorityCode")
    slmc.get_selected_label("frequencyCode").should == ""
  end

  it "Verify that STAT checkbox is automatically checked" do
    slmc.select("frequencyCode", "STAT - NOW")
    slmc.get_value("priorityCode").should == "on"
  end

  it "Verify that STAT checkbox is automatically unchecked" do
    slmc.select("frequencyCode", "EVERY OTHER DAY")
    slmc.get_value("priorityCode").should == "off"
  end

  it "Verify that STAT and Frequency settings are retained in Edit Order Page" do
    slmc.add_returned_order(:drugs => true, :stat => true, :description => "040004334", :add => true, :doctor => "6726").should be_true
    slmc.click_order("*BABYHALER")
    slmc.get_value("priorityCode").should == "on"
    slmc.get_selected_label("frequencyCode").should == "STAT - NOW"
    slmc.click("//input[@value='Save']", :wait_for => :page)
    slmc.er_submit_added_order
    slmc.get_text("css=#drugOrderCartDetails>tbody>tr>td:nth-child(14)").should == "STAT - NOW"
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Verify that STAT and Frequency settings are retained in Order Cart Page and reflected in Order List" do
    slmc.er_occupancy_search(:pin => @@er_pin6)
    slmc.go_to_er_page_using_pin("Order List", @@er_pin6)
    slmc.click("//a[@class='display_more']/img", :wait_for => :visible, :element => "//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[3]")
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[3]").should == "STAT - NOW"
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[4]").should == "REMARKS"
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[5]").should == @er_user
  end

end
