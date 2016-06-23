require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Special Ancillary Units" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
#    @selenium_driver.evaluate_rooms_for_admission('0164','RCHSP')
    @selenium_driver.start_new_browser_session
    @patient = Admission.generate_data
    @patient1 = Admission.generate_data
    @patient2 = Admission.generate_data(:not_senior => true)
#    @user = "sel_oss3"
    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient[:age])
    @spu_user = "0164_nursing_special_units"
    @password = "123qweuser"
#    @ancillary = {"010001194" => 1, "010001448" => 1}
    @pba_user = "sel_pba18"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


############################ Patient Registration from Clinical Ordering
  it "Patient Search" do
    slmc.login(@spu_user, @password).should be_true
    slmc.click_spu_patient_search
    sleep 4
    slmc.patient_pin_search(:pin => "9999999999").should be_true
    (slmc.get_text("css=#results>tbody>tr.odd") == "NO PATIENT FOUND").should be_true
  end

  it "Outpatient Registration" do
    slmc.click_outpatient_registration.should be_true
    @@original_pin = slmc.oss_outpatient_registration(@patient).should be_true
    @@pin = @@original_pin.gsub(' ', '')
    slmc.click'//input[@type="button" and @onclick="submitForm(this);" and @value="Print Out Patient Data Sheet"]', :wait_for => :page
    slmc.is_text_present"Patient Search".should be_true
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.click_outpatient_registration.should be_true
    @@pin1 = slmc.oss_outpatient_registration(@patient1)
    @@pin1 = @@pin1.gsub(' ', '')
    slmc.click'//input[@type="button" and @onclick="submitForm(this);" and @value="Back"]', :wait_for => :page
    slmc.is_text_present"Patient Search".should be_true
  end

  it "Create New Patient" do
    slmc.click_spu_patient_search
    slmc.patient_pin_search(:pin => @@pin).should be_true
    sleep 4
    slmc.oss_create_new_patient(@patient2.merge(:gender => 'M', :clinical_data => true))
    sleep 4
    slmc.advanced_search(:advanced_search=> true, :last_name => @patient2[:last_name], :first_name => @patient2[:first_name], :middle_name => @patient2[:middle_name]).should be_true
    @@pin2 = ((slmc.get_text"css=#results>tbody>tr.odd>td:nth-child(3)").gsub(' ',''))
  end

  it "Search Created Patient in Outpatient Special Units Home" do
    slmc.click_spu_patient_search
    slmc.patient_pin_search(:pin => @@pin2).should be_true
    contents=slmc.get_text"results"
    contents.include?"PIN".should be_true
    contents.include?"Full Name".should be_true
    contents.include?"Gender".should be_true
    contents.include?"Birth Date".should be_true
    contents.include?"Age".should be_true
    contents.include?"Admission Status".should be_true
    contents.include?"Actions".should be_true
    ((slmc.get_text"css=#results>tbody>tr.odd>td:nth-child(3)").gsub(' ','')).should == @@pin2

  end

  it "Search Patient in Occupancy List" do
    slmc.go_to_clinical_order_page(:pin => @@pin2).should be_true
    slmc.search_order(:ancillary => true, :code => "010001194", :filter => "DIAGNOSTIC X-RAY").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true

    slmc.click_spu_occupancy_list.should be_true
    slmc.patient_pin_search(:pin => @@pin2).should be_true
    slmc.spu_occupancy_contents.should be_true
    ((slmc.get_text"css=#occupancyList>tbody>tr.even>td").gsub(' ','')).should == @@pin2
  end



############################ Generation of Request Prooflist

  it "Go to Outpatient Clinical Order page" do
    slmc.click_spu_patient_search
    slmc.go_to_clinical_order_page(:pin => @@pin1).should be_true
  end

  it "Clinical Ordering – Search Item" do
    slmc.search_order(:ancillary => true, :code => "010001194", :filter => "DIAGNOSTIC X-RAY").should be_true
  end

  it "Clinical Ordering – Add item/s to Order Cart" do
     slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
  end

  it "Clinical Ordering – Validate Ordered items" do
    @@visit_no = slmc.get_text("banner.visitNo").gsub(' ', '')
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end


############################ Occupancy List of DAS Units

  it "Go to Occupancy List" do
    slmc.click_spu_occupancy_list.should be_true
    slmc.patient_pin_search(:pin => @@pin1).should be_true
  end

  it "Patient Search before outpatient clinical ordering is done" do
    slmc.click_spu_patient_search
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.click_spu_occupancy_list.should be_true
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.is_text_present"NO PATIENT FOUND".should be_true
    slmc.click_spu_patient_search
    slmc.go_to_clinical_order_page(:pin => @@pin).should be_true
    slmc.search_order(:ancillary => true, :code => "010001194", :filter => "DIAGNOSTIC X-RAY").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single").should == 1
    slmc.confirm_validation_all_items.should be_true
    slmc.click_spu_occupancy_list.should be_true
    slmc.patient_pin_search(:pin => @@pin).should be_true
  end

  it "Patient Search after outpatient clinical ordering" do
    slmc.click_spu_patient_search
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.click_spu_occupancy_list.should be_true
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.spu_occupancy_contents.should be_true
  end

  it "Check User Actions" do
    (slmc.get_text"css=#occupancyList>tbody>tr.even>td:nth-child(7)").should =="Update Patient Info Order Page Order List Patient Results Add/Edit Guarantor Info PF Encoding Hospital Bills and PF Settlement Print Patient Data Sheet / Patient Label"
  end

  it "Bug#41541 - [Special Ancillary Unit]: MSSD percentage not working" do
    slmc.go_to_action_page(:pin => @@pin, :action_page => "PF Encoding")
    slmc.spu_pf_charging(:add_pf =>true, :save_pf => true).should be_true
    slmc.go_to_action_page(:pin => @@pin, :action_page => "Add/Edit Guarantor Info")
    slmc.select"accountClass","SOCIAL SERVICE"
    slmc.type"escNumber","234"
    (slmc.get_value"escNumber").should == "234"
    slmc.select"clinicCode","SURGICAL ONCOLOGY"
    sleep 2
    slmc.click"optMssdApprovedDiscount"
    slmc.type"mssdApproved","50"
    (slmc.get_value"mssdApproved").should == "50"
    slmc.click"//input[@type='submit' and @value='Save']"
    sleep 5
    (slmc.is_text_present"The Patient Info was updated.").should be_true
    slmc.go_to_action_page(:pin => @@pin, :action_page => "Hospital Bills and PF Settlement")
    gross_amount = (slmc.get_text('//*[@id="totalAmountDisplay"]').gsub(',','')).to_f
    class_discount = (slmc.get_total_class_amount).to_f
    promo_discount = gross_amount * @@promo_discount
    @class_discount = (gross_amount - promo_discount) * 0.50
    @class_discount.should == class_discount
  end

  it "Update Patient Info" do
    slmc.go_to_action_page(:pin => @@pin2, :action_page => "Update Patient Info")
    slmc.is_text_present"DAS Patient Information Sheet".should be_true
    slmc.select"patient.civilStatus.code","SINGLE"
    (slmc.get_value"patient.civilStatus.code").should == "CLS01"
    slmc.click"btnSave", :wait_for => :page
    slmc.is_text_present"Patient successfully saved.".should be_true
  end

  it "Outpatient Clinical Ordering => Order Page" do
    slmc.go_to_action_page(:pin => @@pin2, :action_page => "Order Page")
    slmc.search_order(:ancillary => true, :code => "010001448",:filter => "GENERAL ULTRASONOGRAPHY").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001448", :add => true, :doctor => "0126").should be_true
    slmc.er_submit_added_order#.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Add/Edit Guarantor Info page - New Guarantor" do
    slmc.go_to_action_page(:pin => @@pin2, :action_page => "Add/Edit Guarantor Info")
    slmc.select"accountClass","INDIVIDUAL"
    slmc.click_new_guarantor.should be_true
    slmc.pba_update_guarantor(:guarantor_type => "INDIVIDUAL").should be_true
    (slmc.get_text"css=#row>tbody>tr.odd>td:nth-child(2)").should == @@pin2
  end

  it "Add/Edit Guarantor Info page - Update Guarantor" do
    slmc.select"accountClass","INDIVIDUAL"
    slmc.click'//input[@type="radio" and @name="guarantorId"]'
    slmc.click_update_guarantor.should be_true
    slmc.type"loa.maximumAmount","1000"
    (slmc.get_value"loa.maximumAmount").should == "1000"
    slmc.pba_update_guarantor(:guarantor_type => "INDIVIDUAL").should be_true
    (slmc.get_text"css=#row>tbody>tr.odd>td:nth-child(9)").should == "1000.00"
  end

  it "Add/Edit Guarantor Infopage - Delete Guarantor" do
    slmc.select"accountClass","INDIVIDUAL"
    slmc.click'//input[@type="radio" and @name="guarantorId"]'
    slmc.click_delete_guarantor.should be_true
    sleep 2
    slmc.is_text_present"Nothing found to display.".should be_true

    slmc.select"accountClass","INDIVIDUAL"
    sleep 5
    slmc.click"css=input[type=submit]", :wait_for => :page
    slmc.is_text_present"The Patient Info was updated.".should be_true
    slmc.click_new_guarantor.should be_true
    slmc.pba_update_guarantor(:guarantor_type => "INDIVIDUAL").should be_true
    (slmc.get_text"css=#row>tbody>tr.odd>td:nth-child(2)").should == @@pin2
  end

  it "Order List page" do
    slmc.go_to_action_page(:pin => @@pin2, :action_page => "Order List")
    slmc.is_text_present"Order List".should be_true
    slmc.search_order_list(:type => "ancillary", :item => "010001194").should be_true
    slmc.search_order_list(:type => "ancillary", :item => "010001448").should be_true
  end

  it "Patient Results page" do
    slmc.go_to_action_page(:pin => @@pin2, :action_page => "Patient Results")
    slmc.is_text_present"Patient Results".should be_true
  end

  it "PF Encoding page" do
    slmc.go_to_action_page(:pin => @@pin2, :action_page => "PF Encoding")
    slmc.is_text_present"PF Encoding".should be_true
  end

  it "Hospital Bills and PF Settlement page" do
    slmc.go_to_action_page(:pin => @@pin2, :action_page => "Hospital Bills and PF Settlement")
    slmc.is_text_present"Patient Information".should be_true
  end

  it "Print Patient Data Sheet / Patient Label page" do
    slmc.go_to_action_page(:pin => @@pin2, :action_page => "Print Patient Data Sheet / Patient Label")
    slmc.is_text_present"Would you like to reprint documents?".should be_true
  end


############################ PF Encoding

  it "Go to Professional Fee Charging page" do
    slmc.go_to_action_page(:pin => @@pin2, :action_page => "PF Encoding")
    slmc.is_text_present"PF Encoding".should be_true
  end

  it "Add PF" do
    slmc.spu_pf_charging(:add_pf =>true)
    (slmc.get_text"css=#admissionDoctorBeanRowsPf0>tr.even>td").should == "COLLECT"
  end

  it "Edit PF" do
    slmc.spu_pf_charging(:edit_pf =>true)
    (slmc.get_text"css=#admissionDoctorBeanRowsPf0>tr.even>td:nth-child(2)").should == "5,000.00"
  end

  it "Delete PF" do
    slmc.spu_pf_charging(:delete_pf =>true)
    (slmc.is_element_present"css=#admissionDoctorBeanRowsPf0>tr.even>td").should be_false
  end

  it "Save PF" do
    slmc.spu_pf_charging(:add_pf =>true, :save_pf => true).should be_true
    sleep 10
    slmc.is_text_present"PF successfully saved.".should be_true
  end

  it "Go back to outpatientSUHome page" do
    slmc.click'//input[@type="button" and @value="Back"]', :wait_for => :page
    slmc.is_text_present"Special Units Home".should be_true
  end



############################ Bills Payment

  it "Go to Bill Settlement page" do
    slmc.go_to_action_page(:pin => @@pin2, :action_page => "Hospital Bills and PF Settlement")
    slmc.is_text_present"Hospital Bills and PF Settlement".should be_true
    if slmc.is_checked"checkSenior"
      slmc.type"seniorIdNumber","123456789"
    end
  end

  it "View Orders" do
    slmc.spu_view_order.should == 2
  end

  it "View Professional Fees" do
    slmc.spu_pf_payment
    slmc.click"pfPaymentToggle"
  end

  it "Add discounts" do
    slmc.oss_add_discount(:scope => "dept", :type =>  "fixed", :amount => "100").should be_true
    slmc.is_element_present"discountDetail-0".should be_true
  end
 
  it "Add Payment – Check" do
    slmc.click"paymentToggle"
    slmc.spu_hospital_bills(:type => "CHECK").should == "20.00"
    slmc.is_checked"checkPaymentMode1".should be_true
  end

  it "Add Payment – Credit Card" do
    slmc.spu_hospital_bills(:type => "CREDIT CARD").should == "100.00"
    slmc.is_checked"creditCardPaymentMode1".should be_true
  end

  it "Add Payment – Bank Remittance" do
    slmc.spu_hospital_bills(:type => "BANK").should == "80.00"
    slmc.is_checked"bankRemittanceMode1".should be_true
  end

  it "Add Payment – Gift Check" do
    slmc.spu_hospital_bills(:type => "GC").should == "100.00"
    slmc.is_checked"giftCheckPaymentMode1".should be_true
  end

  it "Add Payment – EWT" do
    slmc.spu_hospital_bills(:type => "EWT").should == "50.00"
    slmc.is_checked"ewtMode1".should be_true
  end

  it "Add Payment – Cash" do
    slmc.spu_hospital_bills(:type => "CASH").should be_true
    slmc.is_checked"cashPaymentMode1".should be_true
  end

  it "Submit Payment" do
    slmc.spu_pf_payment(:settle_pf => true)
    slmc.spu_submit_bills
  end

  it "Generate OR/CI" do
    sleep 10
    slmc.click "popup_ok"
    slmc.is_text_present"The ORWITHCI was successfully updated with printTag = 'Y'.".should be_true
  end

  it "Feature #41634 - Create patient" do
    slmc.click_spu_patient_search
    slmc.patient_pin_search(:pin => "test").should be_true
    slmc.click_outpatient_registration.should be_true
    @@pin3 = slmc.oss_outpatient_registration(Admission.generate_data).gsub(' ', '')

    slmc.click_spu_patient_search
    slmc.patient_pin_search(:pin => @@pin3).should be_true
    slmc.go_to_clinical_order_page(:pin => @@pin3).should be_true
    sleep 10
    slmc.search_order(:ancillary => true, :code => "010001194", :filter => "DIAGNOSTIC X-RAY").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
    slmc.er_submit_added_order.should be_true
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Feature #41634 - User should be able to search DAS SU patients in PBA" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:pba_special_ancillary => true)

    slmc.patient_pin_search(:pin => @@pin3).should be_true
    (slmc.get_text"userAction#{@@pin3}").should == "Add/Edit Guarantor Info PF Encoding Hospital Bills and PF Settlement"
  end

  it "Feature #41634 - User should be able to access DAS SU patients Add/Edit Guarantor page" do
    slmc.special_ancillary_action_page(:pin => @@pin3, :action_page => "Add/Edit Guarantor Info")
    (slmc.is_text_present"Update Patient Information").should be_true
  end

  it "Feature #41634 - User should be able to access DAS SU patients PF Encoding Page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:pba_special_ancillary => true)
    slmc.patient_pin_search(:pin => @@pin3).should be_true
    slmc.special_ancillary_action_page(:pin => @@pin3, :action_page => "PF Encoding")
    (slmc.is_text_present"PF Encoding").should be_true
  end

  it "Feature #41634 - User should be able to access DAS SU patients Hospital Bills and PF Payment page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:pba_special_ancillary => true)
    slmc.patient_pin_search(:pin => @@pin3).should be_true
    slmc.special_ancillary_action_page(:pin => @@pin3, :action_page => "Hospital Bills and PF Settlement")
    (slmc.is_text_present"Hospital Bills and PF Settlement").should be_true
  end

  it "Feature #41634 - User encoded and saves Guarantor info" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:pba_special_ancillary => true)
    slmc.patient_pin_search(:pin => @@pin3).should be_true
    slmc.special_ancillary_action_page(:pin => @@pin3, :action_page => "Add/Edit Guarantor Info")
    slmc.click_new_guarantor.should be_true
    slmc.pba_update_guarantor(:guarantor_type => "INDIVIDUAL").should be_true
    slmc.click_submit_changes
  end

  it "Feature #41634 - User edit and saves Guarantor info" do
    slmc.select "accountClass","COMPANY"
    sleep 1
    slmc.ss_update_guarantor(:guarantor_type => "COMPANY", :loa_percent => "50", :guarantor_code => "ABSC001",:update_acct_class => true).should be_true
  end

  it "Feature #41634 - User encoded and saves PF info" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:pba_special_ancillary => true)
    slmc.patient_pin_search(:pin => @@pin3).should be_true
    slmc.special_ancillary_action_page(:pin => @@pin3, :action_page => "PF Encoding")
    slmc.click "admDoctorRadioButton0"
    slmc.click "btnAddPf"
    sleep 5
    slmc.type "pfAmountInput","1000"
    slmc.click "btnAddPf"
    slmc.click"//input[@type='submit' and @value='Save' and @name='action']", :wait_for => :page
    (slmc.is_text_present"PF successfully saved.").should be_true
  end

  it "Feature #41634 - User edit and saves PF info" do
    slmc.click "admDoctorRadioButton0"
    sleep 1
    slmc.click"0edit_pf0"
    slmc.type "pfAmountInput","10000"
    slmc.click "btnAddPf"
    slmc.click"0save_pf0"
    slmc.click"//input[@type='submit' and @value='Save' and @name='action']", :wait_for => :page
    (slmc.get_text"admissionDoctorBeans[0].pfAmountTotalText").should == "10,000.00"
  end

  it "Feature #41634 - User should be able to pay Hospital bills and PF payment" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:pba_special_ancillary => true)
    slmc.patient_pin_search(:pin => @@pin3).should be_true
    slmc.special_ancillary_action_page(:pin => @@pin3, :action_page => "Hospital Bills and PF Settlement")
    if slmc.is_checked"checkSenior"
      slmc.type"seniorIdNumber","123456789"
    end
    slmc.click"paymentToggle"
    slmc.spu_hospital_bills(:type => "CASH").should be_true
    slmc.spu_submit_bills
    sleep 10
    slmc.click "popup_ok"
    slmc.is_text_present"The ORWITHCI was successfully updated with printTag = 'Y'.".should be_true
  end

  it "Feature #41634 - User can no longer search Special Ancillary patient when full payment already made" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:pba_special_ancillary => true)
    slmc.patient_pin_search(:pin => @@pin3, :no_result => true).should be_true
  end
end
