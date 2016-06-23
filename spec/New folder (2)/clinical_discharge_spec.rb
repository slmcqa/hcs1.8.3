require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

describe "SLMC :: Clinical Discharge - PF Settlement" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @employee = "1106002429"
    @user = "gu_spec_user6"
    @password = "123qweuser"

    @pf_type = ["DIRECT", "COLLECT", "COMPLIMENTARY", "PF INCLUSIVE OF PACKAGE"]
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Create and Admits patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @employee)
  end

  it "Goes to Clinical Discharge page" do
    slmc.nursing_gu_search(:pin => @employee)
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @employee)
    slmc.click('//input[@type="button" and @value="Remove"]')
    slmc.add_final_diagnosis(:save => true)
    slmc.nursing_gu_search(:pin => @employee)
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @employee)
    @@visit_no = slmc.get_text("banner.visitNo").gsub(' ', '')
    slmc.is_text_present("Doctor and PF Amount").should be_true
  end

  it "System shall display PF Charging screen" do
    slmc.is_element_present("css=#admissionDoctorBeanRows>tr").should be_true
    slmc.get_css_count("css=#admissionDoctorBeanRows>tr>td").should == 6
  end

  it "System shall display Professional Fee Charging tab in the Clinical Discharge page" do
    slmc.is_element_present("professional_fees_tab").should be_true
    slmc.is_text_present("Professional Fee Charging").should be_true
  end

  it "Verify PF Table Headers" do
    slmc.get_text("css=#doctorsTable>thead>tr>th:nth-child(1)").should == "Doctor Code / Name"
    slmc.get_text("css=#doctorsTable>thead>tr>th:nth-child(2)").should == "Specialization"
    slmc.get_text("css=#doctorsTable>thead>tr>th:nth-child(3)").should == "Doctor Type"
    slmc.get_text("css=#doctorsTable>thead>tr>th:nth-child(4)").should == "Professional Fees"
    slmc.get_text("css=#doctorsTable>thead>tr>th:nth-child(5)").should == "PF Paid"
    slmc.get_text("css=#doctorsTable>thead>tr>th:nth-child(6)").should == "Selected"
  end

  it "System should allow 1 attending doctor only" do
    slmc.add_attending_doctor(:doctor=>"6726").include?("is already the ATTENDING doctor of the patient").should be_true

    slmc.add_attending_doctor(:doctor => "3325", :doctor_type => "REFERRING")
    slmc.is_visible("doctorInput").should be_false
  end

  it "Checks  PF Collection Type" do
    slmc.click("admDoctorRadioButton0")
    slmc.click Locators::NursingGeneralUnits.add_pf
    sleep 3
    slmc.get_select_options("pfTypeCode").should == @pf_type
  end

  it "Default value for PF Collection Type should be Direct" do
    slmc.get_selected_label("pfTypeCode").should == @pf_type[0]
  end

  it "PF inclusive of Package should only appear for patients under a package" do
    slmc.get_select_options("pfTypeCode").include?("PF INCLUSIVE OF PACKAGE").should be_true
  end

  it "A particular Collection type can only be chose once" do
    slmc.select("pfTypeCode", "DIRECT")
    slmc.type "pfAmountInput", "1000"
    sleep 1
    slmc.click Locators::NursingGeneralUnits.add_pf
    sleep 2

    slmc.click("admDoctorRadioButton0")
    sleep 1
    a = slmc.get_alert if slmc.is_alert_present
    slmc.click Locators::NursingGeneralUnits.add_pf
    slmc.select("pfTypeCode", "DIRECT")
    slmc.type "pfAmountInput", "1000"
    slmc.click Locators::NursingGeneralUnits.add_pf
    sleep 1
    a = slmc.get_alert if slmc.is_alert_present
    a.should == "PF Type 'DIRECT' is already in the list."
  end

  it "System shall allow multiple PF Collection Type per Doctor" do
    slmc.click("admDoctorRadioButton1")
    sleep 1
    #slmc.select("pfTypeCode", "PROFESSIONAL FEE WITH PROMISSORY NOTE")
    slmc.select("pfTypeCode", "COLLECT")
    slmc.type "pfAmountInput", "1000"
    sleep 1
    slmc.click Locators::NursingGeneralUnits.add_pf
    sleep 2
    slmc.get_text("doc1pf0_pfType").should == "COLLECT"
    (slmc.get_text("doc1pf0_pfAmount").gsub(',', '')).should == "1000.00"
  end

  it "Checks buttons in page" do
    slmc.is_element_present("btnAddDoctor").should be_true
    slmc.is_element_present("btnEditDoctor").should be_true
    slmc.is_element_present("btnRemoveDoctor").should be_true
    slmc.is_element_present("btnAddPf").should be_true
    slmc.is_element_present("//input[@type='button' and @value='Save' and @onclick='submitDischargeForm(this);']").should be_true
    slmc.is_element_present("dischargeAction").should be_true
    #slmc.is_element_present("//input[@type='button' and @value='Defer' and @onclick='submitDischargeForm(this);']").should be_true
    #slmc.is_element_present("//input[@type='button' and @value='Physically Out' and @onclick='submitDischargeForm(this);']").should be_true
  end

  it "System should compute the Total Amount of PF per Doctor" do
    slmc.get_css_count("css=#admissionDoctorBeanRows>tr").should == 2
    slmc.get_text("css=#admissionDoctorBeanRows>tr:nth-child(2)>td:nth-child(3)>div").should == "REFERRING"
    slmc.get_text("css=#admissionDoctorBeanRows>tr:nth-child(2)>td:nth-child(4)>div").should == "1,000.00"
  end

  it "System shall allow editing PF Details" do
    slmc.edit_attending_doctor(:doctor => "5343", :count => 2).should be_true
    slmc.get_text("css=#admissionDoctorBeanRows>tr:nth-child(2)>td>div").include?("5343").should be_true
  end

  it "System shall delete selected entry - PF Fee to be deleted" do
    @pf_count = slmc.get_css_count("css=#admissionDoctorBeanRowsPf1>tr")
    slmc.click("1delete_pf0")
    slmc.get_confirmation if slmc.is_confirmation_present
    sleep 1
    slmc.get_css_count("css=#admissionDoctorBeanRowsPf1>tr").should == (@pf_count - 1)
  end

  it "Update button should only appear when Edit button is clicked" do
    slmc.get_value("css=#btnAddDoctor").should == "Add"
    slmc.get_value("css=#btnEditDoctor").should == "Edit"
    slmc.get_alert if slmc.is_alert_present
    slmc.click("admDoctorRadioButton1")
    slmc.get_alert if slmc.is_alert_present
    slmc.click("css=#btnEditDoctor")
    slmc.get_value("css=#btnAddDoctor").should == "Save"
    slmc.get_value("css=#btnEditDoctor").should == "Cancel"
    slmc.click("css=#btnEditDoctor")
  end

  it "System should not allow adding/ saving PF amount more than the given Package PF" do
    slmc.click Locators::NursingGeneralUnits.add_pf
    sleep 1
    @@max = slmc.get_text("css=#maximumComplementaryText").gsub(',','').to_f
    @amount = @@max + 1000.0
    slmc.type("pfAmountInput", @amount)
    slmc.select("pfTypeCode", "PF INCLUSIVE OF PACKAGE")
    sleep 1
    slmc.click Locators::NursingGeneralUnits.add_pf
    message = slmc.get_alert
    message.should == "Only #{@@max.to_i} is available."
  end

  it "Input additional PF amount on top of Package with PF Inclusive" do
    slmc.select("pfTypeCode", "PF INCLUSIVE OF PACKAGE")
    slmc.type("pfAmountInput", @@max)
    sleep 2
    slmc.click Locators::NursingGeneralUnits.add_pf
    sleep 3
    slmc.get_css_count("css=#admissionDoctorBeanRowsPf1>tr").should == 1
    slmc.click Locators::NursingGeneralUnits.add_pf
    sleep 2
    slmc.select("pfTypeCode", "COLLECT")
    slmc.type("pfAmountInput", "2500")
    sleep 2
    slmc.click Locators::NursingGeneralUnits.add_pf
    sleep 3
    slmc.get_css_count("css=#admissionDoctorBeanRowsPf1>tr").should == 2
    slmc.get_text("css=#admissionDoctorBeanRowsPf1>tr>td").should == "PF INCLUSIVE OF PACKAGE"
    (slmc.get_text("css=#admissionDoctorBeanRowsPf1>tr>td:nth-child(2)").gsub(',','').to_f).should == @@max
    slmc.get_text("css=#admissionDoctorBeanRowsPf1>tr:nth-child(2)>td").should == "COLLECT"
    slmc.get_text("css=#admissionDoctorBeanRowsPf1>tr:nth-child(2)>td:nth-child(2)").gsub(',','').should == "2500.00"
  end

  it "Save Discharge Info" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin = slmc.create_new_patient(Admission.generate_data)
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."

    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin)
    slmc.add_final_diagnosis(:save => true)
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@pin)
    slmc.click("//input[@type='button' and @value='Save']", :wait_for => :page)
    slmc.is_text_present("Details successfully saved.").should be_true
  end

  it "Display attending doctor" do
    slmc.get_text("//table[@id='doctorsTable']/tbody/tr/td").should == "6726 - ABAD, MARCO JOSE FULVIO CICOLI"
  end

  it "Add doctor to grid" do
    slmc.additional_order_pf(:add => true, :add_doctor_type => "REFERRING", :add_doctor => "0126")
  end

  it "Remove doctor from grid" do
    slmc.additional_order_pf(:delete => true, :delete_type => "REFERRING").should be_false
  end

  it "Display discharge option" do
    slmc.click("//input[@value='Discharge']")
    sleep 5
    slmc.is_text_present("Select discharge type:").should be_true
    slmc.is_visible("//input[@value='Discharge' and @onclick='submitDischargeForm(this);']").should be_true
    slmc.is_visible("//input[@value='Cancel' and @onclick=\"CO.stopRender($('dischargeForm'));\"]").should be_true
  end

  it "Auto-Set “Standard” if patient is not express discharge in PBA" do
    slmc.click("//input[@value='Cancel' and @onclick=\"CO.stopRender($('dischargeForm'));\"]")
    slmc.is_editable("expressDischargeRadio").should be_false
    slmc.is_editable("standardDischargeRadio").should be_true
  end

end
