require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Issues for Regression" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @or_patient = Admission.generate_data
    @gu_patient = Admission.generate_data
    @patient = Admission.generate_data
    @patient2 = Admission.generate_data
    @password = '123qweuser'
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Bug #23767 Admission - Create Open admission - System prompts yikes" do
    slmc.login("sel_adm1", @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin = slmc.create_new_patient(@patient.merge!(:gender => 'F')).gsub(' ','')
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(
      :rch_code => "RCH08",
      :org_code => "0287",
      :diagnosis => "GASTRITIS",
      :doctor_code => "1000" # invalid doctor code
    ).should == "Doctor is invalid."
  end

  it "Bug #22705 Admission - Inpatient On Queue - system prompts yikes" do
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :on_queue => true, :preview => true, :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Bug #26091 Admission - Create new admission - PDS prompts yikes" do
    slmc.go_to_admission_page
    @@on_queue_count = slmc.get_pending_admission_queue_count
    slmc.admission_search(:pin => "1")
    @@pin2 = slmc.create_new_patient(@patient2.merge!(:gender => 'M')).gsub(' ','')
    slmc.admission_search(:pin => @@pin2)
    slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "GASTRITIS", :sap => true)
    slmc.is_text_present("Would you like to reprint documents?").should be_true
  end

  it "Bug #24874 Admission - Cancel Admission - System prompts Yikes!" do
    slmc.cancel_admission(:pin => @@pin2).should be_true
  end

  it "Readmit patient to be used in other examples" do
    slmc.admission_search(:pin => @@pin2)
    slmc.create_new_admission(:room_charge => 'REGULAR PRIVATE', :on_queue => true, :preview => true).should == "Patient admission details successfully saved."
  end

  it "Bug #26143 Admission - Update Admission - PDS prompts yikes" do
    slmc.admission_search(:pin => "1")
    @@gu_pin = slmc.create_new_patient(@gu_patient.merge(:gender => 'M')).gsub(' ','')
    slmc.admission_search(:pin => @@gu_pin).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS", :package => "PLAN A MALE").should == "Patient admission details successfully saved."

    #verify if package plan is saved properly
    slmc.admission_search(:pin => @@gu_pin, :admitted => true).should be_true
    slmc.click("link=Update Admission", :wait_for => :page)
    sleep 10
    slmc.get_value("admissionPackageDesc").should == "PLAN A MALE"

    #update admission by emptying package
    slmc.admission_search(:pin => @@gu_pin, :admitted => true).should be_true
    slmc.update_admission(:clear_package => true, :save => true).should be_true
  end

  it "Bug #26756 ADMISSION: Creates new PIN if the name of the patient is entered differently" do
    slmc.admission_search(:pin => "1")
    @adm_patient = Admission.generate_data
    @@adm_pin = slmc.create_new_patient(@adm_patient.merge(:gender => 'M')).gsub(' ', '')
    slmc.admission_search(:pin => @@adm_pin).should be_true
    @adm_patient[:middle_name] = (@adm_patient[:middle_name]).upcase
    @@adm_pin = slmc.create_new_patient(@adm_patient.merge(:gender => 'M')).gsub(' ', '')
    slmc.get_text("css=div[id='errorMessages']").should == "Patient with same name, gender and birthdate already exists."
  end

  it "On Queue Admission - available user actions should be Update Patient and Update Admission" do
    slmc.admission_search(:pin => @@pin)
    if slmc.is_text_present("Master Patient Index is unavailable. Searching from local data...")
      slmc.get_text(Locators::Admission.admission_search_results_actions_column).should == "View Confinement History \n Update Patient Info \n Update Admission"
    else
      slmc.get_text(Locators::Admission.admission_search_results_actions_column).should == "Update Patient Info \n Update Admission \n Reprint Patient Data Sheet And Label Sticker \n View Confinement History \n Tag for MPI Consolidation"
    end
  end

  # this will fail if the above example failed
  it "Checks if the on queue admission link counter is updated" do
    slmc.go_to_admission_page
    @@on_queue_count += 1
    slmc.get_pending_admission_queue_count.should == @@on_queue_count
  end

  it "Bug #22192 - Inpatient Admission Queue should not be able to be tagged as On Queue again" do
    slmc.admission_search(:pin => @@pin)
    slmc.update_patient(:citizenship => "FILIPINO").should be_true
    slmc.admission_search(:pin => @@pin)
    # verify that patient's on queue has no option to create new admission and tag again as On Queue
    (slmc.get_text(Locators::Admission.admission_search_results_actions_column).include? "Create New Admission").should be_false
  end

  it "Bug #21958 Admission On-queue: Cancel Onqueue" do
    visit_number = slmc.get_visit_number_using_pin(@@pin) # requires database access
    slmc.cancel_on_queue_admission(visit_number).should == "Patient admission details successfully cancelled."
  end

  it "Bug #21869 - After Cancelling On-queue Admission, available user actions should be Update Patient and Create New Admission" do
    slmc.admission_search(:pin => @@pin)
    if slmc.is_text_present("Master Patient Index is unavailable. Searching from local data...") # if MPI is off, View Information is unavailable
      slmc.get_text(Locators::Admission.admission_search_results_actions_column).should == "View Confinement History \n Update Patient Info \n Create New Admission"
    else
      slmc.get_text(Locators::Admission.admission_search_results_actions_column).should == "Update Patient Info \n Admit Patient \n Reprint Patient Data Sheet And Label Sticker \n View Confinement History \n Tag for MPI Consolidation"
    end
  end

  it "Readmits patient with package" do
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS", :package => "PLAN A FEMALE").should == "Patient admission details successfully saved."
  end

  it "Bug #21957 - Successfully switch validated items - PLAN A FEMALE package through GU's Package Management page" do#v1.4 updates
    slmc.login("gu_spec_user", @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Package Management", @@pin)
    slmc.switch_package(:username => "sel_0287_validator",
      :password => @password, :package => true,
      :from_package => "TRANSRECTAL ULTRASOUND",
      :to_package => "TRANSVAGINAL ULTRASOUND").should be_true # Bug 44841-when switching item, no validation is asked - this should have validation everytime switching is done
  end

  it "Bug #23794 - DAS PENDING ECU CANCELLATION reprints item" do
    slmc.login("breastctr", @password).should be_true
    (slmc.pending_ecu_cancellation_actions(:reprint => true).include? "print request" || "successfully").should be_true
  end

  it "Bug #22360 PBA: Package components/items not displayed in the package list/ order cart box." do
    slmc.login("user_gene", @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Package Management", @@pin)
    slmc.is_text_present("This patient is admitted without a package. Please contact Wellness or Admission Department.").should be_false
  end

  it "Clicking ECU Cancellation displays options to Cancel, Clear and Reprint" do
    slmc.login("sel_dastech1", @password).should be_true # USER ROLES saved in add_new_users.rb especially ROLE_NURSING_ADJUSTMENT_ANCILLARY
    slmc.go_to_order_adjustment_and_cancellation
    @@ecu_count = slmc.get_pending_ecu_cancellation_count
    slmc.click_pending_ecu_cancellation_link
    sleep 5
    sleep 30 if @@ecu_count > 100
    slmc.is_element_present(Locators::OrderAdjustmentAndCancellation.cancel_item).should be_true
    slmc.is_element_present(Locators::OrderAdjustmentAndCancellation.clear_item_from_list).should be_true
    slmc.is_element_present(Locators::OrderAdjustmentAndCancellation.reprint_item).should be_true
    slmc.click Locators::OrderAdjustmentAndCancellation.close_ecu_cancellation_popup
  end

  it "Bug #22317 DAS: Order Adjustment & cancellation - ECU Cancellation - Order Adjustment & Cancellation page not displayed to process cancellation/ adjustment" do
    slmc.go_to_order_adjustment_and_cancellation
    @@ecu_count = slmc.get_pending_ecu_cancellation_count
    slmc.click_pending_ecu_cancellation_link
    sleep 5
    sleep 30 if @@ecu_count > 100
    slmc.is_element_present(Locators::OrderAdjustmentAndCancellation.cancel_item).should be_true
    slmc.is_element_present(Locators::OrderAdjustmentAndCancellation.clear_item_from_list).should be_true
    slmc.is_element_present(Locators::OrderAdjustmentAndCancellation.reprint_item).should be_true
    slmc.click Locators::OrderAdjustmentAndCancellation.close_ecu_cancellation_popup
    slmc.ecu_cancel_confirmation.should == "Are you sure you want to cancel?"
    slmc.click "closeEcuConfimation"
  end

  it "Bug #22314 - Reprint Pending ECU Cancellation" do
    (slmc.pending_ecu_cancellation_actions(:reprint => true).include? "print request").should be_true
  end

  it "Cancels item from Pending ECU Cancellation" do
    slmc.login("sel_dastech2", @password).should be_true
    slmc.go_to_order_adjustment_and_cancellation
    @@ecu_count = slmc.get_pending_ecu_cancellation_count
    slmc.click_pending_ecu_cancellation_link
    slmc.is_text_present(@@pin).should be_true # before executing the next code, to avoid timeout if there is an error
    slmc.pending_ecu_cancellation_actions(:cancel => true, :pin => @@pin).should be_true # 0135 org_code of user
    @@ci = slmc.get_text("//html/body/div/div[2]/div[2]/form/div/div/h2").gsub("CI Number: ", "")
    slmc.order_adjustment(:cancel => true, :reason => "CANCELLATION - EXPIRED").should be_true
  end

  it "Pending ECU Cancellation link is updated" do
    slmc.go_to_order_adjustment_and_cancellation
    @@ecu_count -= 1
    slmc.get_pending_ecu_cancellation_count.should == @@ecu_count
  end

  it "Bug #22318 - Click Reprint Cancellation Prooflist" do
    slmc.go_to_order_adjustment_and_cancellation
    slmc.search_order_adjustment_cancellation(:ci => @@ci)
    slmc.reprint_cancellation_prooflist(@@ci)
    slmc.is_text_present("Order Adjustment and Cancellation").should be_true
  end

  it "Bug #23742 Error in Procedure Component" do
    slmc.login("jake","pass").should be_true
    slmc.go_to_services_and_rates
    slmc.click "link=ProcedureComponent"
    sleep 10
    slmc.get_css_count("#results>tbody>tr").should == 10
  end

  it "Bug #22432 PhilHealth - View and Reprinting * Encountered NullPointerException when reprinting PhilHealth Form and prooflist" do
    slmc.login("sel_pba9", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @ph_ref_num = "S510600049845D"
    slmc.pba_document_search(:select => "PhilHealth", :entry => @ph_ref_num, :search_options => "DOCUMENT NUMBER")
    slmc.go_to_page_using_reference_number("Reprint PhilHealth Form", @ph_ref_num)
    slmc.is_text_present("Patient Billing and Accounting Home").should be_true
    slmc.get_selected_label("css=select#documentTypes").should == "PHILHEALTH"
    slmc.get_selected_label("css=select#searchOptions").should == "VISIT NUMBER"
  end

  it "Payment - View and Reprinting" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "Payment", :search_options => "DOCUMENT DATE")
    slmc.is_element_present("link=Re-print OR").should be_true
    slmc.pba_reprint_or.should be_true
  end

  it "Discount - View and Reprinting" do
    @@discount_num = "AC0110120033282"
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "Discount", :entry => @@discount_num, :search_options => "DOCUMENT NUMBER")
    slmc.is_text_present("Reprint Prooflist").should be_true
    slmc.click "link=Reprint Prooflist", :wait_for => :page
    slmc.is_text_present("Patient Billing and Accounting Home").should be_true
    slmc.get_selected_label("css=select#documentTypes").should == "DISCOUNT"
    slmc.get_selected_label("css=select#searchOptions").should == "DOCUMENT NUMBER"
  end

  it "Bug #24401 GU Order Adj & Cancellation - Yikes encountered when searching by posted batch request" do
    slmc.login("gu_spec_user", @password).should be_true
    slmc.go_to_order_adjustment_and_cancellation
    slmc.click "batchOrderSearch"
    slmc.click "search", :wait_for => :page
    slmc.is_text_present "Order Search\342\200\242\n Clinical Order".should be_true
    slmc.is_element_present("results").should be_true
  end

  # commenting out - selenium cannot handle prompt message with input reason
  it "Bug #26290 [PBA] Discharge with R&B cancellation: Printing of official SOA returns an exception error" do
    slmc.login("sel_adm1", @password)
    slmc.admission_search(:pin => "1")
    @@pba_pin = slmc.create_new_patient(Admission.generate_data.merge(:gender => 'F')).gsub(' ','')
    slmc.admission_search(:pin => @@pba_pin)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."

    slmc.login("gu_spec_user", @password)
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@pba_pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true

    #slmc.add_user_security(:user => "sel_pba9", :org_code => "0016", :tran_type => "AUT003")
    slmc.login("sel_pba9", @password)
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.cancel_room_and_board_charges #sel_pba9 has data ref_user_security (ctrl_app_user for ID) AUT003
    slmc.philhealth_computation(:diagnosis => "TYPHOID MENINGITIS", :claim_type => "REFUND", :medical_case_type => "ORDINARY CASE", :compute => true)
    slmc.ph_save_computation
    slmc.skip_philhealth
    slmc.skip_discount
    slmc.click "//input[@value='Skip']", :wait_for => :page
    slmc.click "//input[@value='Print SOA']", :wait_for => :page
    slmc.click "//input[@value='Generate Official SOA']", :wait_for => :visible, :element => "ReportTypePopup"
    slmc.click "//input[@value='Submit' and @name='_submit']", :wait_for => :page
    slmc.is_element_present("myButtonGroup").should be_true
  end

  it "Bug #26542 PhilHealth-Inpatient * Encountered NullPointerException when computing PhilHealth" do
    slmc.login("sel_adm1", @password).should be_true
    slmc.admission_search(:pin => "*")
    @@pin3 = slmc.create_new_patient(Admission.generate_data.merge!(:gender => 'M')).gsub(' ','')
    slmc.admission_search(:pin => @@pin3).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."

    slmc.login("gu_spec_user", @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin3)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin3)
    drugs = {"040004334" => 2, "040800031" => 2}
    drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :quantity => q, :stock_replacement => true, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    ancillary = {"010000008" => 1}
    ancillary.each do |item, q|
      slmc.search_order(:ancillary => true, :description => item).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
    
    slmc.login("sel_or3", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin3)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@pin3)
    @@item_code = slmc.search_service(:procedure => true, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.add_returned_service(:item_code => @@item_code, :description => "WOUND DRESSING TULLE/BACTIGRAS")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:orders => "multiple", :procedures => true)
    slmc.confirm_validation_all_items.should be_true
    slmc.login("gu_spec_user", @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin3, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true

    slmc.login("sel_pba9", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin3)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true)
    @ph_ref_num = slmc.ph_save_computation
    slmc.ph_edit(:diagnosis => "HEPATOBLASTOMA")
    slmc.ph_clear
    slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.is_text_present("Patient Billing and Accounting Home › PhilHealth").should be_true
    slmc.get_text(Locators::Philhealth.reference_number_label1).should == "PhilHealth Reference No.: #{@ph_ref_num}"
  end

  it "Bug #26276 PhilHealth-Inpatient * Operation benefit claim is greater than the actual charges" do
    @operation_charge = slmc.get_text(Locators::Philhealth.actual_operation_charges).to_i
    @operation_benefit = slmc.get_text(Locators::Philhealth.actual_operation_benefit).to_i
    @operation_charge.should >= @operation_benefit
  end

  it "Verify if Room/Bed Reprint is working correctly if entered date is yesterday" do
    slmc.login("sel_adm1", @password).should be_true
    slmc.go_to_admission_page
    days_to_adjust = 1
    d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
    set_date = ((d - days_to_adjust).strftime("%m/%d/%Y").upcase).to_s
    slmc.reprint_room_bed(:target_date => set_date).should be_true
  end
end