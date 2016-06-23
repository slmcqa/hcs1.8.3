require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: One Stop Shop" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @or_patient1 = Admission.generate_data
    @or_patient2 = Admission.generate_data
    @or_patient3 = Admission.generate_data
    @or_patient4 = Admission.generate_data
    @or_patient5 = Admission.generate_data
    @or_patient5[:last_name] = "A" + @or_patient5[:last_name].downcase # for saving time in searching patient name in pending orders link
    @oss_user = "sel_oss3"
    @pba_user = "sel_pba5"
    @password = "123qweuser"
    @or_user = "sel_or2"
    @patient = Admission.generate_data
    @outpatient = Admission.generate_data
    @other_item = "060001963"
    @item = "060000253"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Should verify the required fields in OR - OP registration" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    slmc.verify_required_fields_for_op_reg.should be_true
  end

  it "Bug #26181 OSS * Creates new PIN everytime patient is updated" do
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration
    @@p = slmc.outpatient_registration(@or_patient5).gsub(' ', '')
    slmc.go_to_outpatient_nursing_page
    slmc.or_update_patient_info(:pin => @@p, :status => "MARRIED", :citizenship => "FILIPINO", :save => true).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@p)
    slmc.get_css_count("css=#results>tbody>tr").should == 1
  end

  it "Feature #45819 - Outpatient: Clinical pharmacist/NUM/ANUM validation will display in Order validation page upon hitting the Order cart submit button" do
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@p)
    slmc.click_register_patient.should be_true
    slmc.spu_or_register_patient(:acct_class => 'INDIVIDUAL', :doctor => 'ABAD', :preview => true, :save => true).should be_true
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@p)
    slmc.search_order(:drugs => true, :description => "042820145").should be_true
    slmc.add_returned_order(:drugs => true, :description => "042820145", :add => true ).should be_true
    slmc.er_submit_added_order.should be_true
    (slmc.is_element_present"validatePharmacistForm").should be_true
  end

  it "Feature #45819 - Outpatient: Only valid user credentials will be accepted upon drug order validation - 2" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@p)
    submit_button = slmc.is_element_present("//input[@value='SUBMIT']") ? "//input[@value='SUBMIT']" : "//input[@value='Submit']"
    slmc.click submit_button, :wait_for => :page
    sleep 3
    slmc.type("pharmUsername", "username")
    slmc.type("pharmPassword", "123qweuser")
    slmc.click("validatePharmacistOK")
    sleep 1
    (slmc.is_text_present"Invalid Username/Password.").should be_true
  end

  it "Feature #45819 - Outpatient: Only valid user credentials will be accepted upon drug order validation" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@p)
    slmc.er_submit_added_order(:validate => true).should be_true
  end

  it "Feature #45819 - Outpatient: Access orders for validation through quicklinks" do
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.get_visit_number_using_pin(@@p)
    slmc.or_validate_pending_orders(:pin => @@p, :visit_no => @@visit_no).should be_true
  end

  it "Feature #45819 - Outtpatient: User will not require validation if with role_spu_manager" do
    slmc.login("sel_or9", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.or_validate_pending_orders(:pin => @@p, :visit_no => @@visit_no, :with_role_manager => true).should be_true
  end

  it "Performs OR - Outpatient Registration" do
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@or_pin = slmc.outpatient_registration(@or_patient1).should be_true
    @@or_pin.should be_true
    @@pin = @@or_pin.gsub(' ', '')

    #perform outpatient registration for clinical discharge scenario
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@or_pin2 = slmc.outpatient_registration(@or_patient2).should be_true
    @@or_pin2.should be_true
    @@pin2 = @@or_pin2.gsub(' ', '')
  end

  it "Verifies error message when created patient is already existing" do
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    slmc.outpatient_registration(@or_patient1).should be_false
    slmc.get_text("//html/body/div/div[2]/div[2]/div[3]/div").should == "Patient record already exists."
  end

  it "Verifies that user cannot cancel registration of unadmitted patient" do
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_register_patient.should be_true
    slmc.spu_or_register_patient(:cancel_registration => true).should == "Patient is not yet admitted."
  end

  it "Creates patient admission" do
    # admit or_patient1
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_register_patient.should be_true
    slmc.spu_or_register_patient(:acct_class => 'INDIVIDUAL', :doctor => 'ABAD', :preview => true, :save => true).should be_true

    # admit or_patient2
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@pin2)
    slmc.click_register_patient.should be_true
    slmc.spu_or_register_patient(:acct_class => 'INDIVIDUAL', :doctor => 'ABAD', :preview => true, :save => true).should be_true
  end

  it "Should be able go to Patient Results page and visit history of a patient" do
    slmc.go_to_outpatient_nursing_page
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.go_to_su_page_for_a_given_pin("Patient Results", @@pin)
    slmc.click_patient_admission_history.should be_true
  end

  it "Updates the patient registration" do
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click Locators::NursingSpecialUnits.update_registration_link, :wait_for => :page
    slmc.spu_or_register_patient(:turn_inpatient => true, :preview => true, :save => true).should be_true
  end

  it "Verifies the new status of patient" do
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.get_text("//table[@id='results']/tbody/tr/td[8]").should == "Outpatient Registration"#mpi on
    slmc.click Locators::NursingSpecialUnits.update_registration_link, :wait_for => :page
    (slmc.get_value("turnedInpatientFlag1")).should == "on"
  end

  it "Searches for newly-admitted patient in Nursing Special Units page - Occupancy List" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.get_text("//html/body/div/div[2]/div[2]/table/tbody/tr/td[8]").include? "For Inpatient Admission"
  end

  it "Cancels admission of the patient" do
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click Locators::NursingSpecialUnits.update_registration_link, :wait_for => :page
    slmc.spu_or_register_patient(:cancel_registration => true)#.should be_true
    slmc.is_text_present("Patient admission details successfully cancelled.").should be_true
  end

  it "Clinically discharge OR patient from the Occupancy List" do
    slmc.go_to_occupancy_list_page
    slmc.clinically_discharge_patient(:outpatient => true, :pin => @@pin2, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
  end

  it "Clinically discharged OR patient should be forwarded to PBA with clinical discharge notice" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    (slmc.get_select_options("userAction#{@@visit_no}").include? "Discharge Patient").should be_true
  end

  it "Should verify the required fields in OSS - OP registration" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    slmc.verify_required_fields_for_op_reg.should be_true
  end

  it "Performs OSS Outpatient Registration" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@or_patient3).should be_true
    @@pin = @@oss_pin.gsub(' ', '')
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin2 = slmc.oss_outpatient_registration(@or_patient4).should be_true
    @@pin3 = @@oss_pin2.gsub(' ', '')
  end

  it "Bug #24294 OSS PhilHealth * Prompts, 'A server error has occurred.' after RVU is selected" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    if slmc.is_checked"checkSenior"
      slmc.type "seniorIdNumber", "123456"
    end
    slmc.oss_order(:order_add => true, :item_code => "GELFOAM SIZE 100", :doctor => "ABAD").should be_true
    slmc.oss_rvu(:philhealth => true, :rvu_key => "INCISION AND DRAINAGE OF PILONIDAL CYST").should be_true
  end

  it "Bug #25174 PhilHealth-OSS * Unable to select PF class in PhilHealth accordion" do
    slmc.oss_order(:order_add => true, :item_code => "ALDOSTERONE", :doctor => "6726").should be_true
    slmc.is_editable("philHealthBean.surgeon.pfClass").should be_true
    slmc.is_editable("philHealthBean.anesthesiologist.pfClass").should be_true
    slmc.get_select_options("philHealthBean.anesthesiologist.pfClass").should == ["GENERAL PRACTITIONER", "DOCTORS WITH TRAINING", "DIPLOMATE/FELLOW"]
    slmc.get_select_options("philHealthBean.surgeon.pfClass").should == ["GENERAL PRACTITIONER", "DOCTORS WITH TRAINING", "DIPLOMATE/FELLOW"]
  end

  it "Bug #23936 OSS PhilHealth * Claim Type is changed to Refund in PhilHealth Outpatient Computation page" do
    slmc.oss_input_philhealth(:diagnosis => "CHOLERA", :philhealth_id => "123456789")
    @amount = slmc.get_total_amount_due.to_s + '00'
    slmc.oss_add_payment(:type => "CASH", :amount => @amount.to_s)
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@pin)
    slmc.click_philhealth_link
    slmc.get_selected_label("claimType").should == "ACCOUNTS RECEIVABLE"
    slmc.get_text("//html/body/div/div[2]/div[2]/div[15]/h2").should == "FINAL"
  end

  it "Bug #24041 OSS PhilHealth * Able to compute PhilHealth with claim type = Accounts Receivable in PhilHealth Outpatient Computation page" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin3)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    slmc.oss_order(:order_add => true, :item_code => "GELFOAM SIZE 100", :doctor => "ABAD")
    @amount = slmc.get_total_amount_due.to_s + '00'
    slmc.oss_add_payment(:type => "CASH", :amount => @amount.to_s)
    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@pin3)
    slmc.click_philhealth_link
    slmc.is_element_present('//input[@type="text" and @value="REFUND" and @readonly=""]').should be_true
  end

  it "Bug #25163 PhilHealth-OSS * Returns blank page when saving PhilHealth with endoscopic procedure; claim type= Refund" do
    slmc.philhealth_computation(:diagnosis => "GLAUCOMA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "20937", :compute => true)
    @@ph_ref_num = slmc.ph_save_computation
    slmc.is_text_present(@ph_ref_num).should be_true
  end

  it "Bug #23949 OSS PhilHealth * Able to save Canceled PhilHealth" do
    slmc.ph_cancel_computation.should be_true
    slmc.get_text("//html/body/div/div[2]/div[2]/div[15]/h2").should == "CANCELLED"
    slmc.is_editable("btnSave").should be_false
  end

  it "Bug #24537 PhilHealth-OSS * Able to set claim type = Accounts Receivable in PhilHealth Outpatient Computation page" do
    slmc.ph_recompute.should be_true
    slmc.philhealth_computation(:diagnosis => "GLAUCOMA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :compute => true)
    slmc.ph_save_computation
    slmc.is_editable("claimType").should be_false
    slmc.get_selected_label("claimType").should == "REFUND"
  end

  it "Bug #25205 PhilHealth-Inpatient * PhilHealth Reference No. doesn't change when recomputed after cancellation" do
    slmc.ph_cancel_computation.should be_true
    slmc.ph_recompute.should be_true
    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "GLAUCOMA", :medical_case_type => "ORDINARY CASE", :compute => true)
    @@ph_ref_num2 = slmc.ph_save_computation
    slmc.ph_cancel_computation.should be_true
    slmc.ph_recompute.should be_true
    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "GLAUCOMA", :medical_case_type => "ORDINARY CASE", :compute => true)
    @@ph_ref_num3 = slmc.ph_save_computation
    @@ph_ref_num2.should_not == @@ph_ref_num3
  end

  it "Verifies patient information displays default values " do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.get_value("opsPatientBannerBean.patientPin").should == @@pin
    slmc.get_value("opsPatientBannerBean.lastname").should == @or_patient3[:last_name].upcase
    slmc.get_value("opsPatientBannerBean.firstname").should == @or_patient3[:first_name].upcase
    slmc.get_value("opsPatientBannerBean.middlename").should == @or_patient3[:middle_name].upcase
  end

  it "Verifies submitting an empty transaction" do
    (slmc.oss_submit_order.include?"Submitting an empty transaction.").should be_true
  end

  ##### does not accept pharmacy items########
  it "Test if input field for Search accepts either description or item code" do
    slmc.oss_order(:item_code => "010000000", :order_add => true, :doctor => "6726").should be_true
    slmc.oss_order(:item_code => "300 MCI-IODINE-131 THERAPY (IN CAPSULE)", :order_add => true, :doctor => "6726").should be_true
    slmc.oss_order(:item_code => "269407053", :order_add => true, :doctor => "6726").should be_true
    slmc.oss_order(:item_code => "BIOTRONIK LONG SHEATH", :order_add => true, :doctor => "6726").should be_true
  end

  it "Should be able to add an ORDER" do
    slmc.oss_order(:item_code => "040010002", :doctor => "6726", :order_add => true).should be_true
  end

  it "Should be able to delete an ORDER" do
    slmc.oss_order(:order_delete => true).should be_true
  end

  it "Should be able to add a PAYMENT - Cash" do
    slmc.oss_order(:item_code => "040010002", :doctor => "6726", :order_add => true).should be_true
    @@amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => @@amount, :type => "CASH")
  end

  it "Verifies submitting an order without a guarantor" do
    (slmc.oss_submit_order).include? "No guarantors."
  end

  it "Should be able to add a GUARANTOR - Individual" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_order(:item_code => "040010002", :doctor => "6726", :order_add => true)
    @@amount = slmc.get_total_amount_due.to_s
    slmc.oss_add_payment(:amount => @@amount, :type => "CASH")
    slmc.oss_add_guarantor(:guarantor_type => "INDIVIDUAL", :guarantor_add => true ).should be_true
  end

  it "Should be able to submit an order successfully and print OR" do
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "Bug #23937 - Require Employer Name and Address if Philhealth is ticked" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_order(:item_code => "040010002", :doctor => "6726", :order_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => @@amount, :type => "CASH")
    slmc.oss_submit_order.include? "No guarantors.\n PhilHealth Number is required.\n Member Number and Street is required.\n Final diagnosis is required."
  end

  it "Should be able to add a HMO(50%) GUARANTOR then proceed with Payment" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_order(:item_code => "040010002", :doctor => "6726", :order_add => true)
    slmc.oss_add_guarantor(:guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :coverage_choice => "percent", :coverage_amount => 50, :guarantor_add => true )
    @@amount = slmc.get_total_amount_due.to_s
    slmc.oss_add_payment(:amount => @@amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "Should be able to add a HMO(100%) GUARANTOR then proceed without Payment" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_order(:item_code => "040010002", :doctor => "6726", :order_add => true)
    slmc.oss_add_guarantor(:guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :coverage_choice => "percent", :coverage_amount => 100, :guarantor_add => true)
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "Should be able select Philhealth then proceed with Payment" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:guarantor_type => "INDIVIDUAL", :guarantor_add => true )
    slmc.oss_order(:item_code => "040010002", :doctor => "6726", :order_add => true)
    slmc.oss_patient_info(:philhealth => true)
    slmc.oss_input_philhealth(:diagnosis => "CHOLERA", :philhealth_id => "12345")
    @@amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => @@amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "Bug #24842 - PhilHealth-OSS * Encountered NullPointerException in PhilHealth Outpatient Computation for Endoscopic Procedure" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:guarantor_type => "INDIVIDUAL", :guarantor_add => true )
    slmc.oss_order(:item_code => "010001900", :doctor => "6726", :order_add => true)
    slmc.oss_order(:item_code => "010000004", :doctor => "0126", :order_add => true)
    slmc.oss_patient_info(:philhealth => true)
    slmc.oss_input_philhealth(:diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060", :with_operation => true, :compute => true)
    slmc.is_text_present("Complete Final Diagnosis").should be_true
  end

  it "Bug #24843 - PhilHealth-OSS * System prompts Error processing OPS : null.opsBean on Endoscopic Procedure - Accounts Receivable" do
    @@amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => @@amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "Should be able to VIEW details of Order Search" do
    sleep 10
    slmc.go_to_oss_payment_cancellation_and_reprinting
    slmc.pos_document_search(:type => "OSS OFFICIAL RECEIPT").should be_true
    slmc.click_view_details.should be_true
  end

  it "Bug #35979 - OSS Payment Cancellation and Reprinting: Error in reprinting OR upon clicking Reprint OR but ton" do
    slmc.go_to_oss_payment_cancellation_and_reprinting
    slmc.pos_document_search(:type => "OSS OFFICIAL RECEIPT").should be_true
    slmc.click_reprint_or # different page
    slmc.is_text_present("Document Search").should be_true
  end

  it "Bug #24382 DAS - No item code displayed for 999 Items" do
    slmc.go_to_oss_payment_cancellation_and_reprinting
    slmc.pos_document_search(:type => "CI NO.")
    slmc.get_text("css=#results>tbody>tr>td").should_not == ""
    slmc.get_text("css=#results>tbody>tr:nth-child(2)>td").should_not == ""
    slmc.get_text("css=#results>tbody>tr:nth-child(3)>td").should_not == ""
    slmc.is_text_present("9999").should be_false
  end

  it "Bug #22629 OSS PhilHealth * Actual charges for drugs/medicines is fill out even if all orders are ancillary" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_add => true)
    slmc.oss_order(:item_code => "010000003", :order_add => true)
    slmc.oss_order(:item_code => "010000004", :order_add => true)
    slmc.oss_patient_info(:philhealth => true)
    slmc.get_text("benefitSummary.actualMedicalCharges").should == "0.00"
  end

  it "Bug #26207 PhilHealth-OSS * Doesn't compute PF claim for anesthesiologist of endoscopic procedure on claim type=refund" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    patient = Admission.generate_data
    slmc.patient_pin_search(:pin => "test")
    slmc.oss_create_new_patient(patient.merge(:gender => 'M', :clinical_data => true))
    @@oss_pin = slmc.get_pin_number_based_on_name(:lastname => patient[:last_name], :firstname => patient[:first_name])
    @@pin = @@oss_pin.gsub(' ','')
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :coverage_choice => 'percent', :coverage_amount => '100', :guarantor_add => true)
    slmc.oss_order(:item_code => "010001900", :order_add => true, :doctor => '6726') #surgeon
    slmc.oss_order(:item_code => "010000050", :order_add => true, :doctor => '0126') #anesthesiologist
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."

    slmc.login(@pba_user, @password).should be_true
    slmc.pba_outpatient_computation(:pin => @@pin)
    slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "GLAUCOMA", :with_operation => true, :medical_case_type => "ORDINARY CASE", :rvu_code => "10060", :compute => true)
    sleep 5
    ((slmc.get_text "css=#row>tbody>tr>td:nth-child(5)") != "0").should be_true
    ((slmc.get_text "css=#row>tbody>tr:nth-child(2)>td:nth-child(5)") != "0").should be_true
  end

  it "Bug #43609 - PBA: Null Pointer Exception is encountered when Reprinting CI" do
    slmc.login(@pba_user, @password)
    slmc.pba_adjustment_and_cancellation(:doc_type => "CHARGE INVOICE", :search_option => "PIN", :entry => @@pin).should be_true
    slmc.click_reprint_ci.should be_true # as per steven, valid only in no SOA = have CHARGE INVOICE
    @@visit_no = slmc.get_visit_number_using_pin(@@pin)
    slmc.pba_adjustment_and_cancellation(:doc_type => "CHARGE INVOICE", :search_option => "VISIT NUMBER", :entry => @@visit_no).should be_true
    slmc.click_reprint_ci.should be_true
  end

  it "Bug #25154 PhilHealth-OSS * Incorrect benefit claim for claim type=Refund - Normal Case" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_add => true).should be_true
    slmc.oss_order(:item_code => "010001448", :order_add => true, :doctor => '6726').should be_true
    slmc.oss_order(:item_code => "010000050", :order_add => true).should be_true
    slmc.oss_order(:item_code => "010000003", :order_add => true).should be_true
    @amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => @amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."

    slmc.login(@pba_user, @password).should be_true
    slmc.pba_outpatient_computation(:pin => @@pin)
    slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "GLAUCOMA", :medical_case_type => "INTENSIVE CASE", :compute => true)
    (slmc.get_text "css=#benefitSummarySection>div.row>div>table>tbody>tr:nth-child(3)>td:nth-child(3)").should == "10,500.00"
  end

  it "Bug #24838 PhilHealth-OSS * PF Claims not computed in PhilHealth Outpatient Computation page" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_add => true).should be_true
    slmc.oss_order(:item_code => "010001194", :order_add => true, :doctor => '6726').should be_true
    slmc.oss_order(:item_code => "010001448", :order_add => true, :doctor => '0126').should be_true
    slmc.oss_order(:item_code => "010000050", :order_add => true, :doctor => '6726').should be_true
    @amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => @amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@pin)
    slmc.click_latest_philhealth_link_for_outpatient
    slmc.philhealth_computation(:claim_type => "REFUND", :diagnosis => "GLAUCOMA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "66987", :compute => true)
    slmc.get_text("css=#pfClaimsSection>div:nth-child(2)>table>tbody>tr>td:nth-child(5)").should == "8,000.00"
  end

  it "Bug #28321 - [DAS] OSS: No validation when adding the Guarantor that is an invalid Board member and Doctor dependent" do
    slmc.login(@oss_user,@password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:acct_class => "BOARD MEMBER DEPENDENT", :guarantor_type => "BOARD MEMBER", :guarantor_code => "BMAA001", :guarantor_add => true).should == "Invalid Board Member Dependent."
    slmc.oss_add_guarantor(:acct_class => "DOCTOR DEPENDENT", :guarantor_type => "DOCTOR", :guarantor_code => "0126", :guarantor_add => true).should == "Invalid Doctor Dependent."
    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE DEPENDENT", :guarantor_type => "EMPLOYEE", :guarantor_code => "0011125", :guarantor_add => true).should == "Invalid Employee Dependent."
  end

  it "Bug #39444 - [Patient Search] Unable to search newly created patient" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.oss_create_new_patient(@patient.merge(:save_and_print => true))
    slmc.go_to_das_oss
    slmc.advanced_search(:advanced_search=> true, :last_name => @patient[:last_name], :first_name => @patient[:first_name], :birthday => @patient[:birth_day])
    (slmc.is_element_present"css=#results>tbody>tr.odd>td:nth-child(4)").should be_true
    @@pin4 = ((slmc.get_text"css=#results>tbody>tr.odd>td:nth-child(4)").gsub(' ',''))
  end

  it "Bug #38353 - DAS Outpatient Registration - Error encountered after clicking Print Outpatient Data SHeet" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    slmc.oss_outpatient_registration(Admission.generate_data).should be_true
    slmc.click_button_on_outpatient_registration(:print_data_sheet => true)
  end

  it "Feature #41412 - Outpatient - Create patient for borrowing transaction'" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "a")
    slmc.click_outpatient_registration
    @@or_pin = slmc.outpatient_registration(@outpatient.merge(:gender => 'F')).gsub(' ','').should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.click_register_patient
    slmc.admit_er_patient(:org_code => "0164", :account_class => "INDIVIDUAL").should be_true
  end

  it "Feature #41412 - Outpatient - A checkbox 'Borrowed' should appear once 'others' is ticked" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    slmc.search_order(:description => @other_item, :others => true).should be_true
    slmc.add_returned_order(:description => @other_item, :quantity => "2.0", :others => true, :add => true).should be_true
    slmc.click('orderType4', :wait_for => :element, :element => 'borrowed_checkbox')
    slmc.click('borrowed_checkbox')
  end

  it "Feature #41412 - Outpatient - Once 'Borrowed' is ticked, an org. unit finder should be displayed to allow lookup of nursing units only(both general and special)" do
    sleep 2
    slmc.is_element_present("performCode").should be_true
    slmc.is_element_present("performDescription").should be_true
    slmc.click("btnFindPerfUnit", :wait_for => :element, :element => "orgStructureFinderForm")
    slmc.click('//input[@type="button" and @value="Close" and @onclick="PUF.close()"]')
    sleep 1
  end

  it "Feature #41412 - Outpatient - Borrowing of items applied to General and Special nursing unit order pages" do
    @other_item2 = "ACTILYZE 1 VIAL"
    slmc.click 'borrowed_checkbox' if ((slmc.get_value"borrowed_checkbox")=="on")
    sleep 1
    slmc.search_order(:borrowed => true, :description => @other_item2, :others => true).should be_true
    slmc.add_returned_order(:description => @other_item2, :others => true, :borrowed => true, :perf_unit => "0145", :add => true).should be_true #, :add_borrowed_item => true, :new_line => true).should be_true
    sleep 5
    slmc.verify_ordered_items_count(:others => 2).should be_true
   end

  it "Feature #41412 - Outpatient - Selected org. unit will be saved in TXN_OM_ORDER_GRP.PERF_UNIT" do
    @@visit_no = slmc.get_text("banner.visitNo")
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:others => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true

    @@order_dtl_no = slmc.access_from_database_with_join(:table1 => "TXN_OM_ORDER_DTL", :table2 => "TXN_OM_ORDER_GRP", :condition1 => "ORDER_GRP_NO",
      :column1 => "VISIT_NO", :where_condition1 => @@visit_no, :gate => "AND", :column2 => "PERFORMING_UNIT", :where_condition2 => "0145")
  end

  it "Feature #41412 - Outpatient - Item selected will be flagged in TXN_OM_ORDER_DTL.BORROWED_ITEM=Y" do
    slmc.access_from_database(:what => "BORROWED", :table => "TXN_OM_ORDER_DTL", :column1 => "ORDER_DTL_NO", :condition1 => @@order_dtl_no).should == "Y"
  end

  it "Feature #41412 - Outpatient Others items with perf. unit != DON should set to correct perf. Location" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    slmc.search_order(:description => @item, :others => true).should be_true
    slmc.add_returned_order(:description => @item, :quantity => "2.0", :others => true, :add => true).should be_true
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:others => true, :orders => "single").should == 1
    slmc.confirm_validation_all_items.should be_true
    @@order_dtl_no1 = slmc.access_from_database_with_join(:table1 => "TXN_OM_ORDER_DTL", 
    :table2 => "TXN_OM_ORDER_GRP", :table3 => "REF_PC_SERVICE", :condition2 => "ORDER_GRP_NO",
    :condition3 => "SERVICE_CODE", :column1 => "VISIT_NO", :where_condition1 => @@visit_no,
    :gate => "AND", :column2 => "PERFORMING_UNIT", :where_condition2 => "0164")
    @@order_grp_no = slmc.access_from_database(:what => "ORDER_GRP_NO", :table => "TXN_OM_ORDER_DTL", :column1 => "ORDER_DTL_NO", :condition1 => @@order_dtl_no1)
    slmc.access_from_database(:what => "PERFORMING_UNIT", :table => "TXN_OM_ORDER_GRP", :column1 => "ORDER_GRP_NO", :condition1 => @@order_grp_no).should == "0164"
  end
end