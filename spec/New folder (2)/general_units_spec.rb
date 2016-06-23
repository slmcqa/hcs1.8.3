require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

describe "SLMC :: General Units Tests" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @gu_patient = Admission.generate_data
    @gu_patient[:last_name] = "A" + @gu_patient[:last_name].downcase # for saving time in searching patient name in pending orders link
    @gu_patient3 = Admission.generate_data
    @user = "gu_spec_user"
    @er_user = "sel_er8"
    @password = "123qweuser"
    @other_item = "060001963"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Login as gu user" do
    slmc.login(@user, @password).should be_true
  end

  it "Creates new general unit patients" do
    slmc.admission_search(:pin => "1")
    @@gu_pin = slmc.create_new_patient(@gu_patient.merge(:gender => 'F')).gsub(' ','')

    slmc.admission_search(:pin => "1")
    @@gu_pin3 = slmc.create_new_patient(@gu_patient3.merge(:gender => 'M')).gsub(' ','')
  end

  it "Searches new patient as admitted" do
    slmc.admission_search(:pin => @@gu_pin, :admitted => true)
    slmc.verify_search_results(:no_results => true).should be_true
  end

  it "Searches the patient for general units" do
    slmc.admission_search(:pin => @@gu_pin).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
  end

  it "Admits GU patient with package" do
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08',
      :org_code => '0287', :diagnosis => "GASTRITIS", :package => "PLAN A FEMALE").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@gu_pin)
    @@room_and_bed1 = slmc.get_room_and_bed_no_in_gu_page
  end

  it "Admits GU patient 3 patient without package" do
    slmc.admission_search(:pin => @@gu_pin3).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08',
      :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Verifies that GU patient is admitted" do
    slmc.admission_search(:pin => @@gu_pin).should be_false
  end

  it "Cancels the patient admission" do
    slmc.cancel_admission(:pin => @@gu_pin).should be_true
  end

  it "Readmits patient for general units with package" do
    slmc.admission_search(:pin => @@gu_pin).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08',
      :org_code => '0287', :diagnosis => "GASTRITIS", :package => "PLAN A FEMALE").should == "Patient admission details successfully saved."
  end

  it "Reprints admission patient label and admission" do
    slmc.go_to_admission_page
    slmc.reprint_patient_admission(:pin => @@gu_pin).should be_true
    slmc.go_to_reprinting_page(:patient_data_sheet => true, :patient_label_count => "3").should be_true
  end

  it "Reprints patient admission using reprinting button" do
    slmc.reprinting_from_admission_page(:pin => @@gu_pin, :patient_data_sheet => true, :patient_label_count => "3").should be_true
  end

  it "Bug #37906 - ORDER PAGE: cannot search doctors by their specialization" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    @@visit_no = slmc.get_text('//*[@id="banner.visitNo"]').gsub(' ', '')
    slmc.search_order(:drugs => true, :description => "BABYHALER").should be_true
    slmc.add_returned_order(:drugs => true, :description => "BABYHALER", :quantity => 2,  :frequency => "ONCE A WEEK", :stock_replacement => true, :specialization => "SURGERY", :add => true).should be_true
  end

  it "Show authentication window(for drug orders only)" do
    slmc.click("//input[@value='SUBMIT']", :wait_for => :page)
    sleep 3
    slmc.is_visible("pharmUsername").should be_true
    slmc.is_visible("pharmPassword").should be_true
    slmc.is_visible("validatePharmacistOK").should be_true
    slmc.is_visible("//input[@value='Proceed W/O Authentication']").should be_true
    slmc.is_text_present("Validation Required").should be_true
    slmc.click("//input[@value='Proceed W/O Authentication']")
    slmc.click("//input[@value='Add']", :wait_for => :page)
  end

  it "Creates clinical ordering for GU patient without validation" do
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
  end

  it "Should be able to select printer" do
    slmc.click("//input[@value='Confirm']")
    sleep 5
    printer_selection = slmc.get_attribute("css=#orderPrinter_body2>tr>td:nth-child(3)>select@name")
    printer_selection2 = slmc.get_attribute("css=#orderPrinter_body>tr>td:nth-child(2)>select@name")
    select1 = slmc.get_select_options("#{printer_selection}")
    select2 = slmc.get_select_options("#{printer_selection2}")
    slmc.select("#{printer_selection}", select1[0])
    slmc.select("#{printer_selection}", select1[1])
    slmc.select("#{printer_selection2}", select2[0])
    slmc.select("#{printer_selection2}", select2[1])
    slmc.click("//input[@value='Cancel']")
  end

  it "Bug 22284 - Validates pending order before requesting for room transfer" do
    slmc.request_for_room_transfer(:pin => @@gu_pin, :remarks => "Room transfer remarks").should == "Validate pending orders before requesting for room transfer."
  end

  it "Validates pending order" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Creates clinical ordering for GU patient" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    @@visit_no2 = slmc.get_text('//*[@id="banner.visitNo"]').gsub(' ', '')
    slmc.search_order(:drugs => true, :description => "BABYHALER").should be_true
    slmc.add_returned_order(:drugs => true, :description => "BABYHALER", :quantity => 2, :frequency => "ONCE A WEEK", :stock_replacement => true, :add => true).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
  end

  it "Bug #22420 - Validates pending order through the Pending Order link" do
    slmc.validate_pending_orders(:pin => @@gu_pin, :visit_no => @@visit_no2, :username => "sel_0287_validator") # #https://projects.exist.com/issues/41625
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Allows package order transaction by Update Admission" do
    # update patient admission by adding a package
    slmc.admission_search(:pin => @@gu_pin)
    slmc.update_admission(:package => "LAP CHOLE ECU-PACKAGE", :save => true).should be_true

    slmc.nursing_gu_search(:pin => @@gu_pin)
    slmc.go_to_gu_page_for_a_given_pin("Non Ecu Package Ordering", @@gu_pin)
    slmc.is_text_present("62000 - LAP CHOLE ECU-PACKAGE").should be_true ## corresponds to added LAP CHOLE ECU-PACKAGE in the Update Admission
  end

  it "Verifies that the package orders are reflected on order list" do
    slmc.go_to_general_units_page
    slmc.verify_order_list(:pin => @@gu_pin, :package => true, :item => "LAP CHOLE ECU-PACKAGE").should be_false #package is not yet validated so false is expected

    slmc.login("user_gene", @password).should be_true
    slmc.nursing_gu_search(:pin => @@gu_pin)
    slmc.go_to_gu_page_for_a_given_pin("Non Ecu Package Ordering", @@gu_pin)
    slmc.click("//input[@type='checkbox']")
    slmc.click Locators::Wellness.order_non_ecu_package, :wait_for => :page
    sleep 1
    slmc.validate_non_ecu_package.should == 5
  end

  it "Adds clinical diet" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@gu_pin)
    slmc.go_to_gu_page_for_a_given_pin("Clinical Diet", @@gu_pin)
    slmc.add_clinical_diet(:save => true).should == "Patient diet COMPUTED DIET successfully created."
  end

  it "Update Diet Info" do
    slmc.nursing_gu_search(:pin => @@gu_pin)
    slmc.go_to_gu_page_for_a_given_pin("Clinical Diet", @@gu_pin)
    slmc.add_clinical_diet(:update => true, :height => "150", :weight => "60").should == "Patient diet COMPUTED DIET successfully created."
  end

  it "Requests for room transfer - first" do
    slmc.go_to_general_units_page
    @@count = slmc.get_room_transfer_count
    slmc.request_for_room_transfer(:pin => @@gu_pin, :remarks => "Room transfer remarks", :first => true).should be_true
  end

  it "Verifies bug 22079 - limit room transfer requests to 1 per visit number" do
    slmc.request_for_room_transfer(:pin => @@gu_pin, :remarks => "Room transfer remarks").should == "Cannot create multiple room transfer requests. Process the first request before creating another."
  end

  it "Verifies number of room transfer displayed in the link increments" do
    slmc.get_room_transfer_count == (@@count + 1)
  end

  it "Bug 22220 - Verifies status of request for room transfer - NEW" do
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin).should be_true
    (slmc.get_room_transfer_search_results.include? "NEW").should be_true
  end

  it "Updates request for room transfer - GU patient" do
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "For Room Transfer")
  end

  it "Bug 22220 - Verifies updated status of request - FOR ROOM TRANSFER" do
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin).should be_true
    (slmc.get_room_transfer_search_results.include? "FOR ROOM TRANSFER").should be_true
  end

  it "GU user requests for room transfer - GU patient 3" do
    slmc.request_for_room_transfer(:pin => @@gu_pin3, :remarks => "Room transfer remarks", :first => true).should be_true
  end

  it "Bug 22529 - Should not be able to transfer room/bed by updating admission" do
    slmc.login("sel_adm2",@password).should be_true
    slmc.admission_search(:pin => @@gu_pin, :admitted => true)
    slmc.click "link=Update Admission", :wait_for => :page
    slmc.is_editable("roomNoFinder").should be_false
  end

  it "Admin user updates request of room for GU patient 3 to feedback then assigns to DON" do
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin3).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "With Feedback", :don => true).should be_true
  end

  it "Bug #22406 - List of patients for room transfer should be paginated." do
    slmc.go_to_admission_page
    slmc.click_patients_for_room_transfer.should be_true
    if slmc.is_element_present("link=Next ›")
      slmc.click "link=Next ›", :wait_for => :element, :element => "pendingRtrRows"
      slmc.is_element_present("btnPendingRtrClose").should be_true
      slmc.click "link=Last »", :wait_for => :element, :element => "pendingRtrRows"
      slmc.is_element_present("btnPendingRtrClose").should be_true
    end
  end

  it "Bug #22531 - Request Status of type 'NEW' or 'WITH FEEDBACK' is not allowed to change request status to 'PHYSICALLY TRANSFERRED' " do
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    @@gu_count = slmc.get_room_transfer_count
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin3).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "Physically Transferred").should == "Request Status of type 'NEW' or 'WITH FEEDBACK' is not allowed to change request status to 'PHYSICALLY TRANSFERRED'."
  end

  it "Verifies the diet of a patient" do
    slmc.login("sel_fnb1", @password).should be_true
    slmc.go_to_fnb_landing_page
    slmc.patient_pin_search(:pin => @@gu_pin)
    slmc.verify_patient_diet_history(:pin => @@gu_pin, :visitno => @@visit_no).should be_true
  end

  # this scenario will failed if it successfully prints data. expects Printing Error
  it "Displays the list of diet stubs created" do
    slmc.fnb_view_diet_stub(:pin => @@gu_pin, :visitno => @@visit_no, :last_name => @gu_patient[:last_name]).should be_true
  end

  it "Bug #30730 - [Notice of death]Error upon clicking Submit or Submit and Print button" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@gu_pin4 = slmc.create_new_patient(Admission.generate_data).gsub(' ','')
    slmc.admission_search(:pin => @@gu_pin4).should be_true
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@gu_pin4)
    slmc.go_to_gu_page_for_a_given_pin("Notice of Death", @@gu_pin4)
    slmc.notice_of_death(:save => true, :print => true).should == "Notice of Death succesfully saved (patient pin: #{@@gu_pin4})"
    slmc.is_element_present("criteria").should be_true
  end

  it "Bug #39315 - Notice of Death: Does not update Deceased Flag in PATMAS table after processing Notice of Death" do
    slmc.nursing_gu_search(:pin => @@gu_pin4)
    slmc.go_to_gu_page_for_a_given_pin("Notice of Death", @@gu_pin4)
    slmc.access_from_database(:what => "DECEASED_FLAG", :table => "TXN_PATMAS", :column1 => "PIN", :condition1 => @@gu_pin4).should == "N"
    slmc.notice_of_death(:save => true, :send => true).should == "Notice of Death succesfully saved (patient pin: #{@@gu_pin4})"
    slmc.access_from_database(:what => "DECEASED_FLAG", :table => "TXN_PATMAS", :column1 => "PIN", :condition1 => @@gu_pin4).should == "Y"
  end

  # Feature 45374
  it "Verify that Frequency is automatically set to STAT-NOW" do
    slmc.nursing_gu_search(:pin => @@gu_pin4)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@gu_pin4)
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
    slmc.add_returned_order(:drugs => true, :stat => true, :description => "040004334", :add => true, :doctor => "6726")
    slmc.click_order("*BABYHALER")
    slmc.get_value("priorityCode").should == "on"
    slmc.get_selected_label("frequencyCode").should == "STAT - NOW"
    slmc.click("//input[@value='SAVE']", :wait_for => :page)
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.get_text("css=#drugOrderCartDetails>tbody>tr>td:nth-child(14)").should == "STAT - NOW"
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Verify that STAT and Frequency settings are retained in Order Cart Page and reflected in Order List" do
    slmc.nursing_gu_search(:pin => @@gu_pin4)
    slmc.go_to_gu_page_for_a_given_pin("Order List", @@gu_pin4)
    slmc.click("//a[@class='display_more']/img", :wait_for => :visible, :element => "//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[3]")
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[3]").should == "STAT - NOW"
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[4]").should == "REMARKS"
    slmc.get_text("//tbody[@id='tbody_drugs']/tr[2]/td/table/tbody/tr/td[5]").should == @user
  end

  it "Order List - Reprint Request Prooflist" do
    sleep 3
    slmc.click("//input[@value='Print']")
    sleep 5
    slmc.is_element_present("id-package-printer-dialog-1--printerConfig-0").should be_true
    slmc.is_visible("id-package-printer-dialog-1--printerConfig-0").should be_true
  end

  it "Order List - Select printer" do
    slmc.select("id-package-printer-dialog-1--printerConfig-0", "QC_REQSLIP")
    slmc.select("id-package-printer-dialog-1--printerConfig-0", "QC_REQSLIP2")
    slmc.click("//button[1]")
    slmc.is_visible("id-package-printer-dialog-1--printerConfig-0").should be_true
  end

  it "Reprint patient label" do
    slmc.nursing_patient_search(:inpatient => true, :pin => @@gu_pin4).should be_true
    slmc.click(Locators::NursingGeneralUnits.print_label_sticker, :wait_for => :page)
    slmc.go_to_reprinting_page(:patient_label => true).should be_true
  end

  it "Bug #38744 - Non ECU Package - Switching Items: Items that were switched should not appear at the" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@gu_pin5 = slmc.create_new_patient(Admission.generate_data)
    slmc.admission_search(:pin => @@gu_pin5)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "ULCER", :package => "LAP CHOLE ECU-PACKAGE").should == "Patient admission details successfully saved."

    slmc.nursing_gu_search(:pin => @@gu_pin5)
    slmc.go_to_gu_page_for_a_given_pin("Non Ecu Package Ordering", @@gu_pin5)
    slmc.switch_non_ecu_package(:select_item => true)
    slmc.click Locators::Wellness.order_non_ecu_package
    slmc.wait_for(:wait_for => :element, :element => "css=#non-ecu-id-cart-pane>div>div>table>tbody")
    ((slmc.get_text"css=#non-ecu-id-cart-pane>div>div>table>tbody").include?("URINALYSIS")).should be_true
    ((slmc.get_text"css=#non-ecu-id-onordered-pane>div>div>table>tbody").include?("LAP CHOLE ECU-PACKAGE")).should be_false
  end

  it "Non-ECU Package Management - Modify quantity of orders" do
    slmc.click("0")
    slmc.click("//input[@value='Add to Cart']", :wait_for => :page)
    slmc.click("//tr[@class='non-ecu-class-cart-row0']/td/input[@id='0']")
    slmc.click("//input[@value='Edit']")
    sleep 1
    slmc.type("//div[@class='paneContents']/table/tbody/tr/td[3]/input", "5")
    slmc.click("//div[@class='non-ecu-id-action-group']/input[2]") # Clicks Cancel first
    sleep 1
    slmc.click("//input[@value='Edit']")
    sleep 1
    slmc.type("//div[@class='paneContents']/table/tbody/tr/td[3]/input", "5")
    slmc.click("//div[@class='non-ecu-id-action-group']/input", :wait_for => :page)
    slmc.get_text("//tr[@class='non-ecu-class-cart-row0']/td[4]").should == "4"
  end

  it "Batch Order Adjustment : Edit batch orders" do
    slmc.nursing_gu_search(:pin => @@gu_pin5)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@gu_pin5)
    slmc.search_order(:description => "NEBUCHAMBER", :drugs => true).should be_true
    slmc.add_returned_order(:drugs => true, :add => true, :batch => true, :description => "NEBUCHAMBER", :dose => 3,
      :remarks => "3 TIMES A DAY FOR 5 DAYS", :quantity => "3.0", :quantity_per_batch => "5.0", :frequency => "ONCE A WEEK").should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
    slmc.nursing_gu_search(:pin => @@gu_pin5)
    slmc.go_to_gu_page_for_a_given_pin("Batch Order Adjustment", @@gu_pin5)
    slmc.get_css_count("css=#cancelledBatchOrdersTable>tbody>tr").should == 0
    slmc.batch_order_adjustment(:edit => true, :item => "NEBUCHAMBER", :quantity => "10", :submit => true).should be_true
    slmc.get_css_count("css=#cancelledBatchOrdersTable>tbody>tr").should == 1
    slmc.get_text("css=#cancelledBatchOrdersTable>tbody>tr>td:nth-child(11)").should == "NEBUCHAMBER"
    slmc.get_text("css=#cancelledBatchOrdersTable>tbody>tr>td:nth-child(13)").should == "5.0"
  end

  it "Batch Order Adjustment : Cancel batch orders" do
    slmc.get_css_count("css=#activeBatchOrdersTable>tbody>tr").should == 1
    slmc.batch_order_adjustment(:cancel => true, :item => "NEBUCHAMBER", :submit => true).should be_true
    slmc.get_css_count("css=#activeBatchOrdersTable>tbody>tr").should == 0
    slmc.get_css_count("css=#cancelledBatchOrdersTable>tbody>tr").should == 2
    slmc.get_text("css=#cancelledBatchOrdersTable>tbody>tr>td:nth-child(11)").should == "NEBUCHAMBER"
    slmc.get_text("css=#cancelledBatchOrdersTable>tbody>tr>td:nth-child(13)").should == "5.0" # intermitent error (see screenshot for manual verification) if this error occurs
  end

  it "Bug #24132 - Package items should be reflected in Order List page" do
    slmc.nursing_gu_search(:pin => @@gu_pin5)
    slmc.go_to_gu_page_for_a_given_pin("Order List", @@gu_pin5)
    slmc.search_order_list(:status => "pending", :type => "ancillary", :item => "URINALYSIS").should be_true
    slmc.get_text("css=#tbody_ancil>tr>td:nth-child(2)").should_not == "null"
    slmc.get_text("css=#tbody_ancil>tr>td:nth-child(4)").should == "URINALYSIS"
    slmc.get_text("css=#tbody_ancil>tr>td:nth-child(6)").should_not == "null"
    slmc.get_text("css=#tbody_ancil>tr>td:nth-child(7)").should_not == "null"
  end

  # Not applicable anymore in 1.5 as per steven : inpatient cannot be search in special ancillary
#  it "Bug #38940 - [Special Ancillary Units] Exception thrown when saving the edited orders from general units" do
#    slmc.login(@spu_user, @password).should be_true
#    slmc.click_spu_patient_search
#    slmc.patient_pin_search(:pin => @@gu_pin5).should be_true
#    slmc.special_ancillary_action_page(:pin => @@gu_pin5, :action_page => "Outpatient Clinical Order")
#    slmc.click "//div[@class='item']"
#    slmc.get_text("itemDesc").should == ""
#  end
#
#  it "Bug #38982 - [Special Ancillary Units] Special Unit user should not be able to validate drug orders by other Nursing Unit"  do
#    slmc.er_submit_added_order
#    slmc.is_editable("cartDetailNumber").should be_false
#  end
#
#  it "Bug #38942 - [Special Ancillary Units] No orders from SPU gets reflected in Special Units Order Page" do
#    slmc.login(@er_user, @password).should be_true
#    @@er_pin = slmc.er_create_patient_record(Admission.generate_data.merge(:admit => true)).gsub(' ', '').should be_true
#    slmc.go_to_er_landing_page
#    slmc.patient_pin_search(:pin => @@er_pin)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin)
#    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
#    slmc.add_returned_order(:ancillary => true, :description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
#
#    slmc.login(@spu_user, @password).should be_true
#    slmc.click_spu_patient_search
#    slmc.go_to_clinical_order_page(:pin => @@er_pin).should be_true
#    ((slmc.get_text"css=#cart>div:nth-child(6)>div:nth-child(2)").include?"TRANSVAGINAL ULTRASOUND").should be_true
#  end

  it "Bug #41419 - ORDER PAGE : GU" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@gu_pin5)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@gu_pin5)
    order = "MEDICAL OXYGEN PIPE-IN"
    slmc.search_order(:description => order, :medical_gases => true)
    slmc.add_returned_order(:medical_gases => true, :description => order, :device => "SIMPLE MASK",
      :lpm => "1", :not_continous => true, :doctor => "6726", :end_date => "", :add => true).should == "Gas End Date is a required field."
    slmc.add_returned_order(:medical_gases => true, :description => order, :device => "SIMPLE MASK",
      :lpm => "1", :continous => false, :doctor => "6726", :add => true).should == "Gas Start Date should be less than the Gas End Date."
    d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
    set_date = ((d + 3).strftime("%m/%d/%Y").upcase).to_s
    slmc.search_order(:description => order, :medical_gases => true)
    slmc.add_returned_order(:medical_gases => true, :description => order, :device => "SIMPLE MASK",
      :lpm => "1", :continous => false, :doctor => "6726", :end_date => set_date, :add => true)
    slmc.is_text_present("Order item 089500011 - #{order} has been added successfully.").should be_true
  end

  it "Alert for drug clinical orders - Click to open drug info" do
    slmc.nursing_gu_search(:pin => @@gu_pin5)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@gu_pin5)
    slmc.search_order(:drugs => true, :description =>  "040004334")
    slmc.add_returned_order(:description => "BABYHALER", :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    slmc.login("sel_gu1", @password).should be_true
    slmc.go_to_clinical_ordering_landing_page
    slmc.click_clinical_ordering_sub_org
    slmc.medical_search_patient(@@gu_pin3)
    slmc.clinical_ordering_checkbox(:pin => @@gu_pin3, :item_code => "040004334", :validate => true).should be_true
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    sleep 10
    @@validated_count = slmc.get_css_count("css=#tbdClinicalOrderAlertValidateList>tr")
    slmc.click("link=#{@gu_patient3[:first_name]} #{@gu_patient3[:middle_name]} #{@gu_patient3[:last_name]}", :wait_for => :element, :element => "//label[@onclick='dismissAlertWidget(this)']")
    slmc.click("//label[@onclick='dismissAlertWidget(this)']")
    sleep 5
    slmc.get_css_count("css=#tbdClinicalOrderAlertValidateList>tr").should == @@validated_count - 1
    slmc.click Locators::NursingGeneralUnits.dismiss_all_button if slmc.is_element_present Locators::NursingGeneralUnits.dismiss_all_button
    sleep 3
    slmc.get_text("divClinicalOrderAlertNoItemMsge").should == "No rejected/validated item."
  end

  it "Feature #41412 - Inpatient - A checkbox 'Borrowed' should appear once 'others' is ticked" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "*")
    @@pin = slmc.create_new_patient(Admission.generate_data)
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission( :account_class => "INDIVIDUAL", :rch_code => "RCH08", :org_code => "0287", :room_charge => "REGULAR PRIVATE").should == "Patient admission details successfully saved."

    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)

    slmc.search_order(:description => @other_item, :others => true).should be_true
    slmc.add_returned_order(:description => @other_item, :quantity => "2.0", :others => true, :add => true).should be_true
    slmc.click("orderType4", :wait_for => :element, :element => "borrowed_checkbox")
    slmc.click("borrowed_checkbox")
  end

  it "Feature #41412 - Inpatient - Once 'Borrowed' is ticked, an org. unit finder should be displayed to allow lookup of nursing units only(both general and special)" do
    sleep 2
    slmc.is_element_present("performCode").should be_true
    slmc.is_element_present("performDescription").should be_true
    slmc.click "btnFindPerfUnit", :wait_for => :element, :element => "orgStructureFinderForm"
    slmc.click '//input[@type="button" and @value="Close" and @onclick="PUF.close()"]'
  end

  it "Feature #41412 - Inpatient - Borrowing of items applied to General and Special nursing unit order pages" do
    slmc.click("borrowed_checkbox") if (slmc.get_value("borrowed_checkbox") == "on")
    slmc.submit_added_order
    slmc.validate_orders(:others => true, :orders => "single").should == 1
    slmc.confirm_validation_all_items.should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    slmc.search_order(:borrowed => true, :description => @other_item, :others => true).should be_true
    slmc.click("//input[@type='button' and @onclick='PUF.search();' and @value='Search']", :wait_for => :element, :element => "css=#osf_finder_table_body>tr.even>td>a")
    @@perf_unit = slmc.get_text"css=#osf_finder_table_body>tr.even>td>a"
    slmc.click("link=#{@@perf_unit}", :wait_for => :not_visible, :element => "link=#{@@perf_unit}")
    slmc.add_returned_order(:description => @other_item, :others => true,
      :borrowed => true, :perf_unit => @@perf_unit, :add => true).should be_true
#    slmc.verify_ordered_items_count(:others => 2).should be_true # not applicable on version1.5 all orders must be validated
   end

  it "Feature #41412 - Inpatient - Selected org. unit will be saved in TXN_OM_ORDER_GRP.PERF_UNIT" do
    @@visit_no = slmc.get_text("banner.visitNo")
    slmc.submit_added_order
    slmc.validate_orders(:others => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true

    @@order_dtl_no = slmc.access_from_database_with_join(:table1 => "TXN_OM_ORDER_DTL", :table2 => "TXN_OM_ORDER_GRP", :condition1 => "ORDER_GRP_NO",
      :column1 => "VISIT_NO", :where_condition1 => @@visit_no, :gate => "AND", :column2 => "PERFORMING_UNIT", :where_condition2 => @@perf_unit)
  end

  it "Feature #41412 - Inpatient - Item selected will be flagged in TXN_OM_ORDER_DTL.BORROWED_ITEM=Y" do
    slmc.access_from_database(:what => "BORROWED", :table => "TXN_OM_ORDER_DTL", :column1 => "ORDER_DTL_NO", :condition1 => @@order_dtl_no).should == "Y"
  end

  it "Feature #41412 - Inpatient – Others items with perf. unit != DON should set to correct perf. Location" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)

    slmc.search_order(:description => @other_item, :others => true).should be_true
    slmc.add_returned_order(:description => @other_item, :quantity => "2.0", :others => true, :add => true).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:others => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true

    @@order_dtl_no1 = slmc.access_from_database_with_join(
      :table1 => "TXN_OM_ORDER_DTL",
      :table2 => "TXN_OM_ORDER_GRP",
      :table3 => "REF_PC_SERVICE",
      :condition2 => "ORDER_GRP_NO",
      :condition3 => "SERVICE_CODE",
      :column1 => "VISIT_NO",
      :where_condition1 => @@visit_no,
      :gate => "AND",
      :column2 => "PERFORMING_UNIT",
      :where_condition2 => "0287")

     @@order_grp_no = slmc.access_from_database(:what => "ORDER_GRP_NO", :table => "TXN_OM_ORDER_DTL", :column1 => "ORDER_DTL_NO", :condition1 => @@order_dtl_no1)
     slmc.access_from_database(:what => "PERFORMING_UNIT", :table => "TXN_OM_ORDER_GRP", :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no).should == "0287"
  end
end
