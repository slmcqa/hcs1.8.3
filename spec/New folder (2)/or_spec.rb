require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Outpatient Registration Special Units Tests" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session

    @or_user = "sel_or6"
    @or_patient = Admission.generate_data
    @or_patient2 = Admission.generate_data
    @or_patient3 = Admission.generate_data
    @or_patient4 = Admission.generate_data
    @er_patient = Admission.generate_data
    @password = "123qweuser"    
    @soa_month = Time.now.strftime("%m")
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Create Patient Record - Patient Information Page" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click "link=Create Patient Record", :wait_for => :page
    slmc.is_text_present("Patient Information").should be_true
  end

  it "Patient Information Page - Display Titles in dropdown" do
    slmc.get_attribute("title.code@class").should == "select"
  end

  it "Patient Information Page - Display Suffixes in dropdown" do
    slmc.get_attribute("suffix.code@class").should == "select"
  end

  it "Patient Information Page - Display Calendar pop-up" do
    slmc.is_visible("ui-datepicker-div").should be_false
    slmc.click("//img[@class='ui-datepicker-trigger']")
    slmc.is_visible("ui-datepicker-div").should be_true
  end

  it "Patient Information Page - Compute age" do
    sample_patient = Admission.generate_data
    slmc.type("birthDate", sample_patient[:birth_day])
    (slmc.get_text("age").include? sample_patient[:age].to_s).should be_true
  end

  it "Patient Information Page - Display Civil Status in Dropdown" do
    slmc.get_attribute("civilStatus.code@class").should == "select formInput"
  end

  it "Patient Information Page - Display Citizenships in dropdown" do
    slmc.get_attribute("citizenship.code@class").should == "formInput select"
  end

  it "Patient Information Page - Display Nationalities in dropdown" do
    slmc.get_attribute("nationality.code@class").should == "select"
  end

  it "Patient Information Page - Display Nationalities in dropdown" do
    slmc.get_attribute("race.code@class").should == "select"
  end

  it "Patient Information Page - Display Races in dropdown" do
    slmc.get_attribute("race.code@class").should == "select"
  end

  it "Patient Information Page - Display Religions in dropdown" do
    slmc.get_attribute("religion.code@class").should == "select"
  end

  it "Patient Information Page - Display Countries in dropdown" do
    slmc.get_attribute("presentAddrCountry@class").should == "select"
  end

  it "Patient Information Page - Display Cities in dropdown if Philippines" do
    slmc.get_attribute("birthCountry.code@class").should == "formInput select"
    slmc.get_selected_label("birthCountry.code").should == "PHILIPPINES"
  end

  it "Patient Information Page - Auto-set City based from Postal Code" do
    slmc.get_selected_label("presentAddrCitySelect").should == ""
    slmc.type("presentAddrPostalCode", "1100")
    sleep 5
    slmc.get_selected_label("presentAddrCitySelect").should == "QUEZON CITY"
    slmc.type("presentAddrPostalCode", "1200")
    sleep 5
    slmc.get_selected_label("presentAddrCitySelect").should == "MAKATI CITY"
    slmc.type("presentAddrPostalCode", "1300")
    sleep 5
    slmc.get_selected_label("presentAddrCitySelect").should == "PASAY CITY"
  end

  it "Patient Information Page - Display Contact Types in dropdown" do
    slmc.get_attribute("patientContacts[0].contactTypeCode@class").should == "formInput select"
    slmc.get_attribute("patientContacts[1].contactTypeCode@class").should == "formInput select"
    slmc.get_attribute("patientContacts[2].contactTypeCode@class").should == "formInput select"
  end

  it "Patient Information Page - Auto-set Permanent Address from Present Address" do
    slmc.type("patientAddresses[0].streetNumber", "Selenium Sample Present Address")
    slmc.click("chkFillPermanentAddress")
    slmc.get_value("patientAddresses[1].streetNumber").should == "Selenium Sample Present Address"
  end

  it "Patient Information Page - Auto-set Patient Name based from PIN" do
    slmc.get_value("name.lastName").should == "test"
  end

  it "Patient Information Page - Display ID Types in dropdown" do
    slmc.get_attribute("patientIds[0].idTypeCode@class").should == "formInput select"
    slmc.get_attribute("patientIds[1].idTypeCode@class").should == "formInput select"
    slmc.get_attribute("patientIds[2].idTypeCode@class").should == "formInput select"
  end

  it "Register Patient - Display Account Classes in dropdown" do
    slmc.or_create_patient_record(Admission.generate_data)
    slmc.get_attribute("accountClass@class").should == "inputField select"
  end

#  it "Register Patient - Display Admission Types in dropdown" do # not applicable in 1.4.1f
#    slmc.get_attribute("admissionType.code@class").should == "select"
#  end

  it "Register Patient - Tag patient as Confidential" do
    slmc.is_checked("confidential1").should be_false
    slmc.click("confidential1")
    slmc.is_checked("confidential1").should be_true
  end

  it "Create patients record for OR" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin = (slmc.or_nb_create_patient_record(@or_patient.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0164'))).gsub(' ', '')

    @@or_pin2 = (slmc.or_nb_create_patient_record(@or_patient2.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0164'))).gsub(' ', '')

    @@or_pin3 = (slmc.or_nb_create_patient_record(@or_patient3.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0164'))).gsub(' ', '')
  end

  it "Updates the patient information" do
    slmc.go_to_outpatient_nursing_page
    slmc.or_update_patient_info(:pin => @@or_pin, :save => true).should be_true
  end

  it "Updates patient registration by cancelling its admission" do
    slmc.click_update_registration(:cancel => true, :pin => @@or_pin).should be_true
  end

  it "Bug #24976 PhilHealth-OR * Unable to save PhilHealth as Estimate" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin2)
    slmc.search_order(:drugs => true, :description => "BABYHALER")
    slmc.add_returned_order(:drugs => true, :description => "BABYHALER", :quantity => 2, :stat => true, :stock_replacement => true, :frequency => "ONCE A WEEK", :add => true)
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin2, :pf_amount => "1000", :save => true).should be_true
    slmc.login("sel_pba7", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin2)
    slmc.pba_get_select_options(@@visit_no).should == ["Discount", "Update Patient Information", "Discharge Patient", "Generation of SOA", "Payment", "Package Management"]
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@or_pin2)
    slmc.click_philhealth_link
    slmc.is_editable("claimType").should be_true
  end

  it "Turn inpatient patient should have Order page, Order List and Checklist Order" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.outpatient_to_inpatient(:pin => @@or_pin3)
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin3)
    slmc.get_select_options("userAction#{@@or_pin3}").should == ["Order Page", "Order List", "Checklist Order", "Print Label Sticker"]
  end

  it "Add Batch orders for drugs" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin3)
    slmc.search_order(:description => "NEBUCHAMBER", :drugs => true).should be_true
    slmc.add_returned_order(:drugs => true, :add => true, :batch => true, :description => "NEBUCHAMBER",
      :remarks => "3 TIMES A DAY FOR 5 DAYS", :dose => 3, :quantity => 3, :frequency => "ONCE A WEEK").should be_true
  end
  
  it "Outpatient - Select Printer" do
    slmc.er_submit_added_order(:validate => true)
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.click("validate")
    sleep 3
    slmc.select("//tbody[@id='orderPrinter_body2']/tr/td/select", "na")
    slmc.select("//tbody[@id='orderPrinter_body2']/tr/td/select", "printer 2 college of med")
    slmc.is_visible("//tbody[@id='orderPrinter_body2']/tr/td/select").should be_true
    slmc.click("//div[@id='multiplePrinterPopup']/div[3]/input[@type='button' and @value='OK']", :wait_for => :page)
  end

  it "Order List - Reprint Request Prooflist" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin3)
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin3)

    slmc.click("//input[@value='Print']")
    sleep 5
    slmc.is_visible("id-package-printer-dialog-1--printerConfig-0").should be_true
    slmc.select("id-package-printer-dialog-1--printerConfig-0", "QC_REQSLIP")
    slmc.select("id-package-printer-dialog-1--printerConfig-0", "QC_REQSLIP2")
    slmc.click("//button[1]")
    slmc.is_element_present("//html/body/div[7]/div[2]/table/tbody/tr/td[2]/select").should be_false
  end

  it "Registers the patient again" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "Bug 22733 - Verifies that Cancel Registration button is enabled in Patient's List page" do
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.click_cancel_registration.should be_true
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "Test if input field for Search accepts either description or item code" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin)
    slmc.search_order(:drugs => true, :description =>  "040004334").should be_true
    slmc.search_order(:supplies => true, :description => "080200000").should be_true
    slmc.search_order(:ancillary => true, :description => "010000003").should be_true
    slmc.search_order(:others => true, :description => "050000009").should be_true
    slmc.search_order(:drugs => true, :description => "SOLUSET").should be_true
    slmc.search_order(:supplies => true, :description => "NASO-TRACHEAL TUBE IVORY S7").should be_true
    slmc.search_order(:ancillary => true, :description => "BONE IMAGING - THREE PHASE STUDY").should be_true
    slmc.search_order(:others => true, :description => "BLOOD WARMER - SUCCEDING HOUR").should be_true
  end

  it "Performs clinical ordering - SPECIAL" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin)
    slmc.search_order(:special => true)
    slmc.add_returned_order(:special => true, :special_description => "SPECIAL ITEM TEST", :add => true)
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:special => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items
  end

  it "Bug #24132 - Ordered 9999 items should be reflected in Order List page SPECIAL Tab " do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin)
    slmc.search_order_list(:type => "special", :item => "SPECIAL ITEM TEST").should be_true
  end

  it "Performs clinical ordering - DRUGS" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin)
    slmc.search_order(:drugs => true, :description => "BABYHALER")
    slmc.add_returned_order(:drugs => true, :description => "BABYHALER", :quantity => 2,
      :stat => true, :stock_replacement => true, :frequency => "ONCE A WEEK", :add => true)
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Bug #24132 - DRUGS item should be reflected in Order List page DRUGS Tab " do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin)
    slmc.search_order_list(:type => "drugs", :item => "040004334").should be_true
  end

  it "Performs clinical ordering - SUPPLIES" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin)
    slmc.search_order(:supplies => true, :description => "BATH TOWEL")
    slmc.add_returned_order(:supplies => true, :description => "BATH TOWEL", :quantity => 2, :stat => true, :stock_replacement => true, :add => true)
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:supplies => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Bug #24132 - SUPPLIES item should be reflected in Order List page SUPPLIES Tab " do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin)
    slmc.search_order_list(:type => "supplies", :item => "BATH TOWEL").should be_true
  end

  it "Performs clinical ordering - ANCILLARY" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin)
    slmc.search_order(:ancillary => true, :description => "ALDOSTERONE")
    slmc.add_returned_order(:ancillary => true, :description => "ALDOSTERONE", :add => true)
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Bug #24132 - ANCILLARY items should be reflected in Order List page ANCILLARY Tab " do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin)
    slmc.search_order_list(:type => "ancillary", :item => "ALDOSTERONE").should be_true
  end
 
  it "Adds checklist order - PROCEDURE" do
    slmc.or_add_checklist_order(:pin => @@or_pin, :procedure => "CIRCUMCISION", :doctor => "ABAD")
  end

  it "Validates checklist order - PROCEDURE" do
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Adds checklist order - SUPPLIES AND EQUIPMENT" do
    slmc.or_add_checklist_order(:pin => @@or_pin, :supplies_equipment => "ALCOHOL SWAB", :a_quantity => "5", :s_quantity => "5", :doctor => "ABAD")
  end

  it "Validates checklist order - SUPPLIES AND EQUIPMENT" do
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:non_procedures => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end  

  it "Search & Select Procedures (Procedures only of Special Units)" do
    slmc.search_soa_checklist_order(:pin => @@or_pin, :date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month)
    slmc.adjust_checklist_order.should be_true
    slmc.checklist_order_adjustment(:checklist_order => "APPENDECTOMY", :add => true).should be_true
  end

  it "Search & Select Supplies & Equipment (Non-procedures of Special Units)" do
    slmc.search_soa_checklist_order(:pin => @@or_pin, :date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month)
    slmc.adjust_checklist_order.should be_true
  end

  it "Search & Select Doctor" do
    slmc.get_value("anaesthDoctorCode").should == "0126"
    slmc.get_value("surgeonDoctorCode").should == "6726"
    slmc.checklist_order_adjustment(:checklist_order => "AMBUBAG NEONATE DISPOSABLE", :ordertype2 => true, :add => true)
  end

  it "Edits checklist order Supplies and Equipment" do # should only allow decremental adjustment. do not allow incremental
    slmc.search_soa_checklist_order(:pin => @@or_pin, :date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month)
    slmc.adjust_checklist_order.should be_true
    #slmc.checklist_order_adjustment(:edit => true, :aqty => "6", :sqty => "6").should be_false # user requested to allow incremental adjustment
    slmc.checklist_order_adjustment(:edit => true, :aqty => "4", :sqty => "4").should be_true
  end

  it "Verifies wrong range of date for checklist order" do
    slmc.search_soa_checklist_order(:pin => @@or_pin, :date_today => (Date.today).strftime("%m/%d/%Y"), :date2 => (Date.today-1).strftime("%m/%d/%Y"), :soa_number => @soa_month).should be_true
  end

  # sample will occur if successfully printed . sample expects an error to considered to be successful
  it "Reprints the checklist order" do
    slmc.search_soa_checklist_order(:date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month)
    slmc.reprint_checklist_order(:no_printer => false).should be_true
  end

  it "Adjusts checklist order - Add" do
    slmc.search_soa_checklist_order(:pin => @@or_pin, :date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month)
    slmc.adjust_checklist_order
    slmc.checklist_order_adjustment(:add => true, :checklist_order => "RENAL ANGIOGRAM").should be_true
  end

  it "Adjusts checklist order - Remove" do
    slmc.search_soa_checklist_order(:pin => @@or_pin, :date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month)
    slmc.adjust_checklist_order
    slmc.checklist_order_adjustment(:remove => true).should be_true # remove first procedure from the table
  end

  it "Adds checklist order for cancellation" do
    slmc.or_add_checklist_order(:pin => @@or_pin, :procedure => "APPENDECTOMY", :doctor => "ABAD")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
    slmc.search_soa_checklist_order(:pin => @@or_pin, :date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month) #(Date.today + 1).strftime("%m/%d/%Y") Time.now.strftime("%m/%d/%Y")
    slmc.adjust_checklist_order
    @@soa_number = slmc.get_soa_number
    slmc.checklist_order_adjustment(:add => true, :checklist_order => "TONSILLECTOMY")
  end

  it "Adjust Checklist - Display Cancel Window" do
    slmc.search_soa_checklist_order(:soa_number => @@soa_number)
    slmc.click "link=Cancel"
    sleep 3
    slmc.fill_up_validation_info
    slmc.is_text_present("Checklist SOA No.: #{@@soa_number}").should be_true
  end

  it "Adjust Checklist - Display items" do
    sleep 5
    slmc.get_css_count("css=#tblDetails>tr").should == 2
  end

  it "Cancels checklist order" do
    slmc.search_soa_checklist_order(:soa_number => @@soa_number)
    slmc.cancel_checklist_order(:soa_number => @@soa_number).should be_true
  end

  it "Updates Action status to CANCELLED" do
    slmc.search_soa_checklist_order(:soa_number => @@soa_number)
    slmc.get_text("css=#results>tbody>tr>td:nth-child(6)>div").should == "CANCELLED"
  end

   it "Clinical Ordering for PROCEDURE - Validates item with null value for Surgeon" do
    slmc.or_add_checklist_order(:pin => @@or_pin, :procedure => "LUNG BIOPSY")
    slmc.confirm_checklist_order.should be_true #"Surgeon is required (Procedure Item Exists)"
    slmc.get_attribute("css=#procedureDetails>tbody>tr>td>input@disabled").should == "true"
  end

  it "Validate items with null value in quantity for Surgeon" do
    slmc.click("//input[@value='Add']", :wait_for => :page)
    slmc.edit_checklist_order(:procedure => "LUNG BIOPSY", :quantity => 0).should == "The sum of Anaesthesiologist Quantity and Surgeon Quantity should be greater than 0."
  end

  it "Successfully edit Surgeon quantity" do
    (slmc.edit_checklist_order(:procedure => "LUNG BIOPSY", :quantity => 2.0).include? "LUNG BIOPSY has been edited successfully.").should be_true
    slmc.assign_surgeon(:doctor => "abad")
    slmc.confirm_checklist_order.should be_true
    slmc.validate_item("LUNG BIOPSY").should be_true
  end

  it "Bug #41712 - Search Checklist Order: Unable to adjust validated items" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin4 = slmc.or_nb_create_patient_record(@or_patient4.merge(:admit => true, :gender => 'F')).gsub(' ', '')
    slmc.or_add_checklist_order(:pin => @@or_pin4, :procedure => "LUNG BIOPSY")
    @@visit_no2 = slmc.get_text("banner.visitNo")
    d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
    @set_date = ((d - 1).strftime("%d-%b-%y").upcase).to_s
    slmc.update_from_database(:table => "TXN_OM_ORDER_CART_GRP", :what => "CART_ORDR_DATETIME", :set1 => @set_date, :column1 => "VISIT_NO", :condition1 => @@visit_no2)
    slmc.update_from_database(:table => "TXN_OM_ORDER_CART_GRP", :what => "CREATED_DATETIME", :set1 => @set_date, :column1 => "VISIT_NO", :condition1 => @@visit_no2)
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.search_soa_checklist_order(:pin => @@or_pin4).should be_true
    slmc.get_text("css=#results>tbody>tr>td:nth-child(6)").should == "Adjust \n Cancel \n Reprint"
    slmc.is_element_present("link=Adjust").should be_true
    slmc.is_element_present("link=Cancel").should be_true
    slmc.is_element_present("link=Reprint").should be_true
  end

  it "Verify that “Reprint Discharge Notice Slip” is available upon clinical discharge" do
    slmc.occupancy_pin_search(:pin => @@or_pin4)
    slmc.get_select_options("userAction#{@@or_pin4}").include?("Reprint Discharge Notice Slip").should be_false
    slmc.clinically_discharge_patient(:pin => @@or_pin4, :outpatient => true, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.occupancy_pin_search(:pin => @@or_pin4)
    slmc.get_select_options("userAction#{@@or_pin4}").include?("Reprint Discharge Notice Slip").should be_true
  end

  it "Verify that “Reprint Discharge Notice Slip” is not available upon billing discharge" do
    slmc.login("sel_pba7", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin4)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
    slmc.login(@or_user, @password).should be_true
    slmc.occupancy_pin_search(:pin => @@or_pin4)
    slmc.get_select_options("userAction#{@@or_pin4}").include?("Reprint Discharge Notice Slip").should be_false
  end

  it "Verify that “Reprint Gate Pass” is available upon physical discharge when ROLE_LATE_TRANSACTION is added" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@or_pin4, :visit_no => @@visit_no2)
    slmc.occupancy_pin_search(:pin => @@or_pin4, :discharged => true)
    slmc.get_text("css=#occupancyList>tbody>tr>td:nth-child(8)").should == "DISCHARGED"
    slmc.get_select_options("userAction#{@@or_pin4}").include?("Reprint Gate Pass").should be_true
  end

# Bug 50020 - Not a defect - user request
#  it "Verify that “Reprint Gate Pass” is available upon physical discharge when ROLE_LATE_TRANSACTION is not available" do
#    slmc.login("sel_or1", @password).should be_true # sel_or1 does not have ROLE_LATE_TRANSACTION
#    slmc.occupancy_pin_search(:pin => @@or_pin4)
#    slmc.is_element_present("//input[@type='checkbox' and @name='discharged']").should be_false
#  end

  it "Verify that “Reprint Discharge Notice Slip” is not available when clinical discharge is deferred" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin5 = slmc.or_nb_create_patient_record(Admission.generate_data.merge(:admit => true, :gender => 'F')).gsub(' ', '')
    slmc.occupancy_pin_search(:pin => @@or_pin5)
    slmc.clinically_discharge_patient(:pin => @@or_pin5, :outpatient => true, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
    slmc.occupancy_pin_search(:pin => @@or_pin5)
    slmc.defer_clinical_discharge(:pin => @@or_pin5, :outpatient => true).should be_true
    slmc.occupancy_pin_search(:pin => @@or_pin5)
    slmc.get_select_options("userAction#{@@or_pin5}").include?("Reprint Discharge Notice Slip").should be_false
  end

  it "Feature #32308 - Create patient" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin6 = slmc.or_nb_create_patient_record(Admission.generate_data.merge(:admit => true)).gsub(' ', '')
  end

  it "Feature #32308 - Entered patient's diet should be saved in database" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@or_pin6)
    slmc.add_clinical_diet(:save => true).should == "Patient diet COMPUTED DIET successfully created."

    @@visit_no = slmc.get_text"banner.visitNo"
    @@diet_no = slmc.access_from_database(:what => "DIET_NO", :table => "TXN_OM_PAT_DIET", :column1 => "VISIT_NO", :condition1 => @@visit_no)
    slmc.access_from_database(:what => "DESCRIPTION", :table => "TXN_OM_PAT_FOOD_ALLERGY", :column1 => "PIN", :condition1 => @@or_pin6).should == "SELENIUM TEST FOOD ALLERGY DESCRIPTION"
    slmc.access_from_database(:what => "PREFERENCE", :table => "TXN_OM_PAT_FOOD_PREF", :column1 => "VISIT_NO", :condition1 => @@visit_no).should == "SELENIUM TEST FOOD PREFERENCE"
    slmc.access_from_database(:what => "DIET_ID", :table => "TXN_OM_PAT_DIET_ALLERGY ", :column1 => "DIET_ID", :condition1 => @@diet_no).should == @@diet_no
  end

  it "Feature #32308 - Click View Diet History button" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_nu_page(:page => "Clinical Diet", :pin => @@or_pin6)
    slmc.click("//input[@type='button' and @value='View Diet History']", :wait_for => :page)
    contents = slmc.get_text"dataTable"
    #(contents.include?"Updated Datetime").should be_true
    (contents.include?"Allergies").should be_true
    (contents.include?"Food Preference").should be_true
    (contents.include?"Additional Instructions").should be_true
    (contents.include?"Diet Type").should be_true
    (contents.include?"Diet Group").should be_true
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet - Diet Type then save" do
    slmc.count_diet_history(:pin => @@or_pin6, :visit_no => @@visit_no, :back => true).should == 2
    slmc.add_clinical_diet(:diet => "CLEAR LIQUID", :update => true).should == "Patient diet CLEAR LIQUID successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@or_pin6, :visit_no => @@visit_no, :back => true).should == 3
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet - Addiitonal Instructions then save" do
    slmc.add_clinical_diet(:additional_instruction => "SELENIUM ADDITIONAL INSTRUCTIONS", :update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@or_pin6, :visit_no => @@visit_no, :back => true).should == 4
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet -Allergies then save" do
    slmc.add_clinical_diet(:description => "ALLERGIES FOR COUNTING", :update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@or_pin6, :visit_no => @@visit_no, :back => true).should == 5
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet -Patient Food Preference then save" do
    slmc.add_clinical_diet(:food_preferences => "TEST FOOD PREFERENCES FOR COUNTING", :update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@or_pin6, :visit_no => @@visit_no, :back => true).should == 6
  end

  it "Feature #32308 - Click View Diet History button - Diet Type" do
    slmc.click"//input[@type='button' and @value='View Diet History']", :wait_for => :page
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)>a")
      count-=1
      rows+=1
    end

    ((@@arr.to_s).include?"CLEAR LIQUID").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Addiitonal Instructions" do
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(6)>a")
      count-=1
      rows+=1
    end

    ((@@arr.to_s).include?"SELENIUM ADDITIONAL INSTRUCTIONS").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Allergies" do
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(4)>a")
      count-=1
      rows+=1
    end

    ((@@arr.to_s).include?"ALLERGIES FOR COUNTING").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Patient Food Preference" do
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(5)>a")
      count-=1
      rows+=1
    end

    ((@@arr.to_s).include?"TEST FOOD PREFERENCES FOR COUNTING").should be_true
  end

  it "Feature #32308 - Click patient diet details link" do
    slmc.click"link=CLEAR LIQUID"
    sleep 4
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{count})>th")
      count-=1
    end

    (@@arr.to_s).should == "Additional Instructions :Disposable Tray :Interpretation :BMI :Weight :Height :Food Allergies :Food Preference :Patient Diet Type :Patient Diet Group :"
    slmc.click"//html/body/div/div[2]/div[2]/div[7]/div[2]/div/a/input"
    sleep 2
  end

end
