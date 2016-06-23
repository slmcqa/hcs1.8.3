require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Package Order Management Enhancements" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @user = "sel_wellness2"
    @password = "123qweuser"
    @patient = Admission.generate_data
    @patient1 = Admission.generate_data
    @patient2 = Admission.generate_data
    @employee1 = "1106003659" #with package
    @employee2 = "1106003660" #with order package
    @employee3 = "1106003661" #with validated order package
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


############################ Additional Order Link

  it "Creates patient" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "test").should be_true
    @@pin = slmc.create_new_patient(@patient.merge(:gender => 'M'))
  end

  it "Verify Additional Order Button(Before Validating)" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.click_outpatient_package_management.should be_true
    slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A MALE", :doctor => "6930").should be_true
    sleep 5
    slmc.is_element_present('//input[@id="clinicalOrder" and @value="Additional Order"]').should be_true
    slmc.is_element_present("css=#formCart>div:nth-child(3)>div>div:nth-child(2)").should be_true
    slmc.is_element_present"css=#supplies_section>div>div:nth-child(2)".should be_true
    slmc.is_element_present"css=#ancillary_section>div>div:nth-child(2)".should be_true
    slmc.additional_order_package(:ancillary => true, :items => "010001194", :doctor => "6930",:save => true).should be_true
    contents=slmc.get_text"formAdditionalCart"
    contents.include?"SPECIAL X-RAY INTERPRETATION".should be_true
  end

  it "Verify Additional Order Button(After Validating)" do
    slmc.validate_wellness_package
    slmc.additional_order_package(:ancillary => true, :items => "010001448", :doctor => "6930",:save => true).should be_true
    contents=slmc.get_text"css=#cpu_0068>div:nth-child(2)>span>a"
    contents.include?"ULTRASOUND INTERPRETATION".should be_true
  end

  it "Verify Item Outside package window" do
    sleep 5
    slmc.click Locators::Wellness.additional_order
    slmc.is_element_present "outpatientOrderPopup".should be_true
    slmc.is_element_present "mServiceCode".should be_true
    slmc.is_element_present "find".should be_true
    slmc.is_element_present "clearItem".should be_true
    slmc.is_element_present "itemDesc".should be_true
    slmc.is_element_present "orderDoctorName".should be_true
    slmc.is_element_present "quantity".should be_true
    slmc.is_element_present "remarks".should be_true
    slmc.is_element_present "addOrder".should be_true
    slmc.is_element_present "clearOrder".should be_true
    slmc.is_element_present "editOrder".should be_true
    slmc.is_element_present "deleteOrder".should be_true
    slmc.click Locators::Wellness.additional_order_close
  end

  it "Successfully Add New item(Drugs)" do
    sleep 5
    slmc.additional_order_package(:drugs => true, :items => "042422511", :doctor => "6930",:save => true).should be_true
    contents=slmc.get_text"formAdditionalCart"
    contents.include?"ISOKET AMP 0.1% 10ML".should be_true
  end

  it "Successfully Add New item(Supplies)" do
    slmc.additional_order_package(:supplies => true, :items => "089000003", :doctor => "6930",:save => true).should be_true
    contents=slmc.get_text"formAdditionalCart"
    contents.include?"FACIAL TISSUE".should be_true
  end

  it "Successfully Add New item(Ancillary)" do
    slmc.additional_order_package(:ancillary => true, :items => "010000004", :doctor => "6930",:save => true).should be_true
    contents=slmc.get_text"formAdditionalCart"
    contents.include?"ALDOSTERONE".should be_true
  end

  it "Successfully Add New item(Other)" do
    slmc.additional_order_package(:others => true, :items => "060001724", :doctor => "6930",:save => true).should be_true
    contents=slmc.get_text"formAdditionalCart"
    contents.include?"ACTILYZE 1 VIAL".should be_true
  end


############################ Miscellaneous Items Viewing

  it "Edit additional item" do
    slmc.additional_order_package(:ancillary => true, :items => "010000317", :doctor => "6930",:close => true).should be_true
  end

  it "Validate Additional Item" do
#QUALITATIVE PROPOXYPHENE (3)
    slmc.additional_order_package_edit(:chosen_result => true, :item => "010000317", :quantity => "3.00", :save => true).should == "3.00"
  end

  it "Bug#39594 - WELLNESS Additional Order - Only 1 CI number is generated for more than 1 entry of ancillary orders in TXN_OM_ORDER_GRP" do
    sleep 1
    @visit_no = slmc.get_text"banner.visitNo"
    (slmc.count_distinct_ci_number(:visit_no => @visit_no).to_i).should == 8
  end

  it "Delete Additional Item" do
    slmc.additional_order_package(:supplies => true, :items => "082400049", :doctor => "6930",:close => true).should be_true
    slmc.additional_order_package_delete(:chosen_result => true, :item => "082400049", :save => true).should be_true
  end

  it "Verify Commit Icon" do
    slmc.is_element_present'//a[@class="validate"]'.should be_true
  end


  it "Creates second patient" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@pin).should be_true
    @@pin1 = slmc.create_new_patient(@patient1.merge(:gender => 'M'))
    @@pin1.should be_true
  end

  it "Add new Miscellanoues (Before Validating)" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@pin1).should be_true
    slmc.click_outpatient_package_management.should be_true
    slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A MALE", :doctor => "6930").should be_true
    sleep 10
    slmc.additional_order_package(:others => true, :items => "060001963", :doctor => "6930",:save => true).should be_true
    slmc.additional_order_package(:others => true, :items => "060001725", :doctor => "6930",:save => true).should be_true
  end

  it "Add new Miscellanoues (After Validating)" do
    slmc.validate_wellness_package
    slmc.additional_order_package(:others => true, :items => "060001725", :doctor => "6930",:save => true).should be_true
    slmc.is_element_present'//a[@class="validate" and @title="Validated"]'.should be_true
#    slmc.is_element_present'//div[3]/span/div/a'.should be_true
  end

  it "Successfully Order Additional Items(Drugs)" do
    slmc.additional_order_package(:drugs => true, :items => "044006788", :doctor => "6930",:close => true).should be_true
  end

  it "Add edit Drugs(Item Outside Package Window)" do
    slmc.additional_order_package_edit(:chosen_result => true, :item => "044006788", :quantity => "3.00",  :close => true).should == "3.00"
  end

  it "Add delete Drugs(Item Outside Package Window)" do
    slmc.additional_order_package_delete(:chosen_result => true, :item => "044006788", :save => true).should be_true
  end

  it "Successfully Order Additional Items(Supplies)" do
    slmc.additional_order_package(:supplies => true, :items => "080800015", :doctor => "6930",:close => true).should be_true
  end

  it "Add edit Supplies(Item Outside Package Window)" do
    slmc.additional_order_package_edit(:chosen_result => true, :item => "080800015", :quantity => "3.00",  :close => true).should == "3.00"
  end

  it "Add delete Supplies(Item Outside Package Window)" do
    slmc.additional_order_package_delete(:chosen_result => true, :item => "080800015", :save => true).should be_true
  end

  it "Successfully Order Additional Items(Ancillary)" do
    slmc.additional_order_package(:ancillary => true, :items => "010000188", :doctor => "6930",:close => true).should be_true
  end

  it "Add edit Ancillary(Item Outside Package Window)" do
    slmc.additional_order_package_edit(:chosen_result => true, :item => "010000188", :quantity => "3.00",  :close => true).should == "3.00"
  end

  it "Add delete Ancillary(Item Outside Package Window)" do
    slmc.additional_order_package_delete(:chosen_result => true, :item => "010000188", :save => true).should be_true
  end

  it "Successfully Order Additional Items(Others)" do
    slmc.additional_order_package(:others => true, :items => "060001726", :doctor => "6930",:close => true).should be_true
  end

  it "Add edit Other(Item Outside Package Window)" do
    slmc.additional_order_package_edit(:chosen_result => true, :item => "060001726", :quantity => "3.00",  :close => true).should == "3.00"
  end

  it "Add deleteOther(Item Outside Package Window)  " do
    slmc.additional_order_package_delete(:chosen_result => true, :item => "060001726", :save => true).should be_true
  end


############################ PF Amount Viewing and Payment

  it "Verify Allocate Doctor PF Button" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.click_outpatient_package_management.should be_true
    slmc.is_element_present"allocatePf".should be_true
    slmc.click("allocatePf", :wait_for => :element, :element => "admDoctorRadioButton0")
  end

  it "Delete Referring Doctor" do
    sleep 3
    slmc.additional_order_pf(:add => true, :add_doctor_type => "REFERRING", :add_doctor => "0126")
    slmc.is_element_present"css=#admissionDoctorBeanRows>tr.odd>td".should be_true
    slmc.additional_order_pf(:delete => true, :delete_type => "REFERRING")
    (slmc.is_element_present"css=#admissionDoctorBeanRows>tr.odd>td").should be_false
  end

  it "Delete Attending Doctor" do#can't delete attending doctor, not a valid scenario
    slmc.additional_order_pf(:add => true, :add_doctor_type => "REFERRING", :add_doctor => "0126")
    slmc.is_element_present"css=#admissionDoctorBeanRows>tr.odd>td".should be_true
  end

  it "Edit Referring Doctor" do
    sleep 2
    slmc.additional_order_pf(:edit => true, :edit_type => "REFERRING", :add_doctor => "5979")
    (slmc.get_text"css=#admissionDoctorBeanRows>tr.odd>td:nth-child(2)>div").should == "SURGERY"
  end

  it "Edit Attending Doctor" do
    slmc.additional_order_pf(:edit => true, :edit_type => "ATTENDING", :add_doctor => "0126")
  end

  it "Add Referring Doctor" do
    slmc.additional_order_pf(:delete => true, :delete_type => "REFERRING")
    (slmc.is_element_present"css=#admissionDoctorBeanRows>tr.odd>td").should be_false
    slmc.additional_order_pf(:add => true, :add_doctor_type => "REFERRING", :add_doctor => "5979")

  end

  it "Add Attending Doctor" do
     slmc.additional_order_pf(:edit => true, :edit_type => "ATTENDING", :add_doctor => "6930")
  end

  it "Add pf - Direct" do
     slmc.click"admDoctorRadioButton0"
     slmc.additional_order_pf(:pf_type => "DIRECT", :add_pf_type => true, :pf_amount => "100").should == "DIRECT"
  end

  it "Add pf - Collect" do
    slmc.additional_order_pf(:pf_type => "COLLECT", :add_pf_type => true, :pf_amount => "100").should == "COLLECT"
  end

  it "Add pf - Complementary" do
    slmc.additional_order_pf(:pf_type => "COMPLIMENTARY", :add_pf_type => true, :pf_amount => "100").should == "COMPLIMENTARY"
  end

  it "Add pf - Professional Fee with promissory note" do
    slmc.additional_order_pf(:pf_type => "PROFESSIONAL FEE WITH PROMISSORY NOTE", :add_pf_type => true, :pf_amount => "100").should == "PROFESSIONAL FEE WITH PROMISSORY NOTE"
  end

  it "Add pf - Inclusion of package" do
    slmc.additional_order_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :add_pf_type => true, :pf_amount => "100").should == "PF INCLUSIVE OF PACKAGE"
  end

  it "Edit pf - Direct" do
    slmc.additional_order_pf(:pf_type => "DIRECT", :edit_pf_type => true , :pf_amount => "200").should == "200"
  end

  it "Edit pf - Collect" do
    slmc.additional_order_pf(:pf_type => "COLLECT", :edit_pf_type => true , :pf_amount => "200").should == "200"
  end

  it "Edit pf - Complementary" do
    slmc.additional_order_pf(:pf_type => "COMPLIMENTARY", :edit_pf_type => true, :pf_amount => "200").should == "200"
  end

  it "Edit pf - Professional Fee with promissory note" do
    slmc.additional_order_pf(:pf_type => "PROFESSIONAL FEE WITH PROMISSORY NOTE", :edit_pf_type => true, :pf_amount => "200").should == "200"
  end

  it "Edit pf - Inclusion of package" do
    slmc.additional_order_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :edit_pf_type => true, :pf_amount => "200").should == "200"
  end

  it "Delete pf - Inclusion of package" do
    slmc.additional_order_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :delete_pf_type => true).should == "Delete PF of PF INCLUSIVE OF PACKAGE ?"
  end

  it "Delete pf - Professional Fee with promissory note" do
    slmc.additional_order_pf(:pf_type => "PROFESSIONAL FEE WITH PROMISSORY NOTE", :delete_pf_type => true).should == "Delete PF of PROFESSIONAL FEE WITH PROMISSORY NOTE ?"
  end

  it "Delete pf - Complementary" do
    slmc.additional_order_pf(:pf_type => "COMPLIMENTARY", :delete_pf_type => true) == "Delete PF of COMPLIMENTARY ?"
  end

  it "Delete pf - Collect" do
    slmc.additional_order_pf(:pf_type => "COLLECT", :delete_pf_type => true) == "Delete PF of COLLECT ?"
  end

  it "Delete pf - Direct" do
    slmc.additional_order_pf(:pf_type => "DIRECT", :delete_pf_type => true).should == "Delete PF of DIRECT ?"
  end



############################ Clinical Discharge Validation

  it "Create and admit patient(with package) - Clinically discharge patient" do
    slmc.login("sel_gu1", @password).should be_true
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @employee1, :with_complementary => true, :save => true)
    sleep 2
    (slmc.get_text"css=#errorMessages>div").should == "Cannot discharge SELENIUM, SELENIUM SELENIUM. Package is selected but not yet ordered."
#    (slmc.get_text"clinicalDischargeBean.errors").should == "Please distribute the amount of 5,300.00 using PF Inlcusive of Package."
  end

  it "Create and admit patient(with package) - Order Package - Clinically discharge patient" do
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @employee2, :with_complementary => true, :save => true)
    (slmc.get_text"css=#errorMessages>div").should == "Cannot discharge SELENIUMM, SELENIUMM SELENIUMM. There are still pending packaged orders."
#    (slmc.get_text"clinicalDischargeBean.errors").should == "Please distribute the amount of 5,300.00 using PF Inlcusive of Package."
  end

  it "Create and admit patient(with package) - Order and Validate Package - Clinically discharge patient" do
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @employee3, :with_complementary => true, :save => true)
    
    slmc.patient_pin_search(:pin => @employee3)
    if (slmc.get_text"css=#occupancyList>tbody>tr.even>td:nth-child(5)").should == "Clinically Discharged"
      slmc.select "userAction#{@employee3}", "label=Defer Discharge"
      slmc.defer_clinical_discharge
    end

    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @employee3)
    #slmc.go_to_er_page_for_a_given_pin("Doctor and PF Amount", @employee3)
    slmc.select "userAction#{@employee3}", "Doctor and PF Amount"
    slmc.click"css=#occupancyList>tbody>tr.even>td:nth-child(7)>input", :wait_for => :page
    slmc.click"admDoctorRadioButton0"
    slmc.click"0delete_pf0"
    slmc.get_confirmation if slmc.is_confirmation_present
    slmc.click'//input[@type="button" and @value="Save" and @onclick="submitDischargeForm(this);"]', :wait_for => :page
  end

end
