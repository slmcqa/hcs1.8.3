require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Package Management Module Test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @patient = Admission.generate_data
    @patient2 = Admission.generate_data
    @adm_patient = Admission.generate_data
    @gu_patient = Admission.generate_data
    @password = "123qweuser"
    @@doctor = "1104000751"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


  it "Main menu page – Verify if user will be able to lauch Main menu page" do
    slmc.login("sel_wellness1", @password).should be_true
  end

  it "Verify if user will be directed to main page upon clicking on St. Luke's Medical Center logo link" do
    @@location = slmc.get_location
    slmc.click("css=#branding>a", :wait_for => :page)
    slmc.get_location.should == @@location
  end

  it "Verify if user will be directed to main page upon clicking on Home link" do
    @@location = slmc.get_location
    slmc.click("link=Home", :wait_for => :page)
    slmc.get_location.should == @@location ##Http://192.168.137.5:8084/mainMenu.html;jsessionid=1n87b33bs9vcp1rnchna4yd9r1
  end

  it "Verify if user will be able to logout upon clicking Logout link" do
    slmc.logout
    slmc.is_element_present("j_username").should be_true
    slmc.is_element_present("j_password").should be_true
    slmc.login("sel_wellness1", @password).should be_true
  end

  it "Verify if user will be able to go to Wellness Package Ordering link" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    slmc.is_text_present("Outpatient Registration").should be_true
    slmc.is_text_present("New Patient").should be_true
    slmc.is_text_present("SOA/OR Reprint").should be_true
    slmc.is_text_present("Admission").should be_true
  end

  it "Verify if user will be directed to main page upon clicking on St. Luke's Medical Center logo link" do
    slmc.go_to_wellness_package_ordering_page
    slmc.click("css=#branding>a", :wait_for => :page)
    slmc.get_location.should == @@location
  end

  it "Verify if user will be directed to main page upon clicking on Home link" do
    slmc.go_to_wellness_package_ordering_page
    slmc.click("link=Home", :wait_for => :page)
    slmc.get_alert if slmc.is_alert_present
    slmc.get_location.should == @@location
  end

  it "Verify if user will be able to logout upon clicking Logout link" do
    slmc.go_to_wellness_package_ordering_page
    slmc.logout
    slmc.is_element_present("j_username").should be_true
    slmc.is_element_present("j_password").should be_true
    slmc.login("sel_wellness1", @password).should be_true
  end

  it "Verify if user will be directed to Outpatient Registration page upon clicking on Outpatient Registration link" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    slmc.click("link=Outpatient Registration", :wait_for => :page)
    slmc.get_text("css=#breadCrumbs>ul>li:nth-child(2)").should == "Outpatient Registration"
    slmc.is_element_present("name.lastName").should be_true
    slmc.is_element_present("name.firstName").should be_true
    slmc.is_element_present("name.middleName").should be_true
  end

  it "Verify if user will be directed to Registration Form page upon clicking on New Patient" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    slmc.click("link=New Patient", :wait_for => :page)
    slmc.get_text("css=#breadCrumbs>ul>li:nth-child(2)").should == "Registration Form"
    slmc.is_element_present("name.lastName").should be_true
    slmc.is_element_present("name.firstName").should be_true
    slmc.is_element_present("name.middleName").should be_true
    slmc.is_element_present("//input[@value='Preview' and @name='action']").should be_true
  end

  it "Verify if user will be directed to OR/SOA Reprint page upon clicking on OR/SOA Reprint link" do
    slmc.go_to_wellness_package_ordering_page
    slmc.click("link=SOA/OR Reprint", :wait_for => :page)
    slmc.get_text("css=#breadCrumbs>ul>li").should == "OR/SOA Reprint"
    slmc.is_element_present("lastName").should be_true
    slmc.is_element_present("firstName").should be_true
    slmc.is_element_present("middleName").should be_true
    slmc.is_element_present("//input[@value='Search OR' and @name='_submit']").should be_true
    slmc.is_element_present("//input[@value='Search SOA' and @name='_submit']").should be_true
  end

  it "Verify if user will be able to input on Search field" do
    slmc.go_to_wellness_package_ordering_page
    slmc.type("//input[@type='text' and @name='param']", "sample")
    slmc.get_value("//input[@type='text' and @name='param']").should == "sample"
  end

  it "Verify if user will be able to search patient upon clicking on Search button" do
    slmc.go_to_wellness_package_ordering_page
    slmc.type("//input[@type='text' and @name='param']", "1") #v1.4 iteration5 system won't allow searching for incomplete pin. NO PATIENT FOUND alert will show.
    slmc.click(Locators::Admission.search_button, :wait_for => :page)
    slmc.get_css_count("#results>tbody>tr").should == 1 #20 # # it is normal that this will fail if MPI is turned ON
  end

  # temporarily remove admitted checkbox as per venz
#  it "Verify if user will be able to select Admitted Patients checkbox" do
#    slmc.go_to_wellness_package_ordering_page
#    slmc.type("//input[@type='text' and @name='param']", "1")
#    slmc.click("admitted")
#    slmc.click(Locators::Admission.search_button, :wait_for => :page)
#  end

  it "Verify if user will be able to search patient with other option upon clicking on More Options link" do
    slmc.go_to_wellness_package_ordering_page
    slmc.type("//input[@type='text' and @name='param']", "GREFALDA")
    slmc.click("slide-fade")
    sleep 1
    slmc.type("fName", "Elvira ")
    slmc.type("mName", "Hombre")
    slmc.type("bDate", "12/02/1987")
    slmc.click("//input[@value='F' and @name='gender']")
    slmc.click(Locators::Admission.search_button, :wait_for => :page)
    slmc.get_css_count("#results>tbody>tr").should == 1 # this will fail if MPI is on, since searching is affected
  end

  it "Verify if user will be able to clear all inputs and selections on Clear upon clicking on More Options link" do
    slmc.click("clear")
    sleep 1
    slmc.get_text("//input[@type='text' and @name='param']").should == ""
    slmc.get_text("fName").should == ""
    slmc.get_text("mName").should == ""
    slmc.get_text("bDate").should == ""
    slmc.is_checked("//input[@name='gender' and @value='F']").should be_false
    slmc.is_checked("gender").should be_false
  end

  it "Verify if pagination will break when nth page is clicked" do
    slmc.go_to_wellness_package_ordering_page
    slmc.type("//input[@type='text' and @name='param']", "1")
    slmc.click(Locators::Admission.search_button, :wait_for => :page)
    slmc.get_css_count("#results>tbody>tr").should == 1 #20
#    slmc.click("link=5", :wait_for => :page)
#    slmc.get_css_count("#results>tbody>tr").should == 20 # it is normal that this will fail if MPI is turned ON
  end

  it "Verify if system accepts birth date later than today(manual typing) upon searching" do
    slmc.go_to_wellness_package_ordering_page
    slmc.type("//input[@type='text' and @name='param']", "1")
    slmc.click("slide-fade")
    sleep 1
    slmc.type("bDate", "06/24/2100")
    slmc.get_text("bDate").should == ""
  end

  it "Verify if user will be directed back to Admission page upon clicking on Admission link" do
    slmc.go_to_wellness_package_ordering_page
    @@wellness_location = slmc.get_location
    slmc.patient_pin_search(:pin => "1")
    slmc.click("link=Outpatient Registration", :wait_for => :page)
    slmc.click("css=#breadCrumbs>ul>li>a", :wait_for => :page)
    slmc.get_location.should == @@wellness_location
  end

  it "Verify if user will be directed to main page upon clicking on St. Luke's Medical Center logo link" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    slmc.click("link=Outpatient Registration", :wait_for => :page)
    slmc.click("css=#branding>a", :wait_for => :page)
    slmc.get_location.should == @@location
  end

  it "Verify if user will be directed to main page upon clicking on St. Luke's Medical Center logo link" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    slmc.click("link=Outpatient Registration", :wait_for => :page)
    slmc.click("link=Home", :wait_for => :page)
    slmc.get_location.should == @@location
  end

  it "Verify if user will be directed to main page upon clicking on St. Luke's Medical Center logo link" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    slmc.click("link=Outpatient Registration", :wait_for => :page)
    slmc.logout
    slmc.is_element_present("j_username").should be_true
    slmc.is_element_present("j_password").should be_true
    slmc.login("sel_wellness1", @password).should be_true
  end

  it "Outpatient Registration page Back button" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    slmc.click("link=Outpatient Registration", :wait_for => :page)
    slmc.click("//input[@value='Back' and @name='action']", :wait_for => :page)
    slmc.is_element_present("//input[@type='text' and @name='param']").should be_true
  end

  it "Registration Form page - New Patient - Preview button" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    slmc.click("link=New Patient", :wait_for => :page)
    slmc.populate_patient_info(@patient)
    slmc.click("//input[@value='Preview' and @name='action']", :wait_for => :page)
    slmc.is_text_present("Preview of Patient Details").should be_true
  end

  it "Registration Form page - New Patient - Cancel button" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    slmc.click("link=New Patient", :wait_for => :page)
    slmc.populate_patient_info(@patient)
    slmc.click("//input[@value='Cancel']", :wait_for => :page)
    slmc.patient_pin_search(:pin => "1")
    slmc.is_text_present("Outpatient Registration").should be_true
    slmc.is_text_present("New Patient").should be_true
    slmc.is_text_present("SOA/OR Reprint").should be_true
    slmc.is_text_present("Admission").should be_true
  end

  it "Verify Outpatient Package management Screen" do
    slmc.login("sel_wellness1", @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    @@wellness_pin = slmc.create_new_patient(@patient.merge!(:gender => "M"))
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    @@wellness_pin2 = slmc.create_new_patient(@patient2.merge(:gender => "M"))
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin)
    slmc.click_outpatient_package_management
    slmc.get_text("banner.visitNo").should == "Not Available"
    slmc.get_patient_full_name_outpatient(@patient).should == slmc.get_text("banner.fullName")
    slmc.return_original_pin(@@wellness_pin).should == slmc.get_text("banner.pin")
    slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A MALE", :doctor => "0269").should be_true
    slmc.validate_wellness_package
  end

  it "Packaged ordered editing" do
    slmc.edit_wellness_package(:package => "CANCER PACKAGE - ADVANCE B MALE", :doctor => "0269", :replace => true).should be_true
  end

  it "Verify Delete button" do
    slmc.edit_wellness_package(:package => "CANCER PACKAGE - BASIC MALE", :doctor => "0269")
    slmc.delete_wellness_package.should be_true
  end

  it "Patient with pending package order from Wellness should not be seen on GU page" do
    slmc.wellness_allocate_doctor_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => 16000)
    slmc.wellness_update_guarantor(:guarantor => "INDIVIDUAL")
    slmc.wellness_payment(:cash => true).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    slmc.login("gu_spec_user4", @password).should be_true
    slmc.nursing_gu_search(:pin => @@wellness_pin)
    slmc.is_text_present(slmc.return_original_pin(@@wellness_pin)).should be_false
  end

#  9/28/2011 wellness cannot admit inpatient, just outpatient (steven)
#  it "Package order item cancelllation" do
#    slmc.login("sel_wellness1", @password)
#    slmc.go_to_wellness_package_ordering_page
#    slmc.patient_pin_search(:pin => @@wellness_pin)
#    slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :room_charge => "REGULAR PRIVATE").should == "Patient admission details successfully saved."
#    slmc.login("gu_spec_user3", @password)
#    slmc.go_to_general_units_page
#    slmc.patient_pin_search(:pin => @@wellness_pin)
#    slmc.is_text_present(slmc.return_original_pin(@@wellness_pin)).should be_true
#  end

  it "System will not accept double-entry" do
    slmc.login("sel_wellness1", @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    slmc.outpatient_wellness(@patient).should == "Patient record already exists."
  end

  it "System will accept same information except the different suffix title" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "1")
    slmc.outpatient_wellness(@patient.merge(:suffix => "VI")).should == "Patient record already exists."
  end

  it "Should not have Outpatient Package Management Button" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin)
    slmc.is_text_present("Outpatient Package Management").should be_false
  end

  it "Not admitted patients should have Outpatient Package Management Button" do
    slmc.login("sel_adm4", @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin = slmc.create_new_patient(@adm_patient.merge!(:gender => "M"))
    slmc.login("sel_wellness1", @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.is_text_present("OUTPATIENT PACKAGE MANAGEMENT").should be_true
  end

  it "Inpatient Admission should not have Outpatient Package Management Button" do
    slmc.login("sel_adm4", @password)
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :room_charge => "REGULAR PRIVATE", :package => "LAP CHOLE ECU-PACKAGE").should == "Patient admission details successfully saved."
    slmc.is_text_present("OUTPATIENT PACKAGE MANAGEMENT").should be_false
  end

  it "Search Patient from Wellness page without any search criteria (No pin/lastname)" do
    slmc.login("sel_wellness1", @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "", :blank => true).should be_true
  end

  it "Patient search using Advance or More option" do
    slmc.go_to_wellness_package_ordering_page
    slmc.advance_search(:last_name => @adm_patient[:last_name], :first_name => @adm_patient[:first_name], :middle_name => @adm_patient[:middle_name], :gender => @adm_patient[:gender], :birth_day => @adm_patient[:birth_day]).should be_true
  end

  # temporarily remove admitted checkbox as per venz
#  it "Search for Admitted Patient only" do
#    slmc.go_to_wellness_package_ordering_page
#    slmc.advance_search(:admitted => true, :last_name => @adm_patient[:last_name], :first_name => @adm_patient[:first_name], :middle_name => @adm_patient[:middle_name], :gender => @adm_patient[:gender], :birth_day => @adm_patient[:birth_day]).should be_true
#  end

  it "General Units - search for the admitted patient" do
    slmc.login("gu_spec_user4", @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin).should be_true
  end

  it "Select 'Package Management' in the Action drop down" do
    slmc.go_to_gu_page_for_a_given_pin("Non Ecu Package Ordering", @@pin)
    slmc.get_text("breadCrumbs").should == "General Units › Package Management"
  end

  it "Clears / erase the default or selected requesting doctor" do
    slmc.click("clearDoctor")
    slmc.get_value("doctorNameDisplay").should == ""
    slmc.get_value("doctorCode").should == ""
  end

  it "Verify if system will allow Ordering Package without doctor" do
    slmc.click '//input[@type="checkbox"]'
    sleep 3
    slmc.click Locators::Wellness.order_non_ecu_package
    sleep 2
    slmc.get_text("doctorErr").should == "Doctor is required."
  end

  it "Login as DAS user - Displays DAS Landing page" do
    slmc.login("sel_dastech1", @password).should be_true #0052
    slmc.go_to_das_oss
  end

  it "Select Order Adjustment & Cancellation page" do
    slmc.go_to_order_adjustment_and_cancellation
    slmc.is_text_present("Pending ECU Cancellation").should be_true
  end

  it "Click ECU Cancellation link - PIN, Patient Name, CI No, Description, Action Menu" do
    slmc.go_to_order_adjustment_and_cancellation
    slmc.click Locators::OrderAdjustmentAndCancellation.pending_ecu_cancellation_link
    a = (slmc.get_text("css=div.searchResultsHeader>table>thead>tr")).split
    (a[0]).should == "PIN"
    (a[1] + " " + a[2]).should == "PATIENT NAME"
    (a[3] + " " + a[4]).should == "CI NO."
    (a[5]).should == "DESCRIPTION"
    (a[6]).should == "ACTION"
    sleep 2
    slmc.click("closeEcuCancelPopup")
  end

  it "Click Clear button" do
    slmc.type("startOrderDate", Date.today.strftime("%m/%d/%Y"))
    slmc.type("endOrderDate", Date.today.strftime("%m/%d/%Y"))
    slmc.click("//input[@type='button' and @onclick='OSF.show();']", :wait_for => :visible, :element => "orgStructureFinderForm")
    slmc.type("osf_entity_finder_key", "0069")
    slmc.click("//input[@value='Search' and @onclick='OSF.search();']")
    sleep 5
    slmc.get_value("css=#requestingUnitCode").should == "0069"
    slmc.click("//input[@value='Clear' and @name='clear']")
    slmc.get_value("startOrderDate").should == ""
    slmc.get_value("endOrderDate").should == ""
    slmc.get_value("requestingUnitCode").should == ""
    slmc.get_value("requestingUnitDescription").should == ""
  end

  it "Package Payment – Verify if user will be able to logout upon clicking Logout link" do
    slmc.login("sel_wellness1", @password)
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin2)
    slmc.click_outpatient_package_management
    slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A MALE", :doctor => "0269")
    slmc.validate_wellness_package
    slmc.logout
  end

  it "Scenario: (account class = COMPANY, guarantor type = COMPANY, guarantor code = ABS-CBN BROADCASTING CORP., percentage = 50%)" do
    slmc.login("sel_wellness1", @password)
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin2)
    slmc.click_outpatient_package_management
    slmc.wellness_allocate_doctor_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => 16000).should be_true
    slmc.wellness_update_guarantor(:account_class => "COMPANY", :guarantor => "COMPANY", :guarantor_code => "ABS-CBN BROADCASTING CORP.", :loa_percent => "50").should be_true
    slmc.wellness_payment(:cash => true).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  ## not applicable anymore in v1.4 # For Account Class 'COMPANY', the main guarantor should be of type 'COMPANY'
#  it "Scenario: (account class = COMPANY, Guarantor type = DOCTOR, guarantor code = ABS-CBN BROADCASTING CORP., percentage = 50%)" do
#    slmc.go_to_wellness_package_ordering_page
#    slmc.patient_pin_search(:pin => @@doctor)
#    slmc.click_outpatient_package_management
#    slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A FEMALE", :doctor => "0269").should be_true
#    slmc.validate_wellness_package.should be_true
#    slmc.wellness_allocate_doctor_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => 16600).should be_true
#    slmc.wellness_update_guarantor(:account_class => "COMPANY", :guarantor => "DOCTOR", :guarantor_code => "6055", :loa_percent => "50").should be_true
#    @amount = slmc.get_total_amount_due.to_s + '00'
#    slmc.oss_add_payment(:type => "CASH", :amount => @amount.to_s)
#    slmc.submit_package_order("yes")
#    slmc.tag_document.should == "The SOA was successfully updated with printTag = 'Y'."
#  end

  it "Bug #24394 DON: Package Management - Validate, edit and cancel button missing after Order button is clicked" do
    slmc.login("sel_adm4", @password).should be_true
    slmc.go_to_admission_page
    slmc.patient_pin_search(:pin => "1")
    @@gu_pin = slmc.create_new_patient(@gu_patient.merge!(:gender => 'M')).gsub(' ','')
    slmc.admission_search(:pin => @@gu_pin)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS", :package => "PLAN A MALE").should == "Patient admission details successfully saved."
    slmc.login("gu_spec_user4", @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@gu_pin)
    slmc.go_to_gu_page_for_a_given_pin("Package Management", @@gu_pin)
    slmc.click Locators::Wellness.order_package, :wait_for => :page
    sleep 5
    slmc.is_element_present("validate").should be_true
    slmc.is_element_present("edit").should be_true
    slmc.is_element_present("cancelEdit").should be_true
    slmc.is_editable("cancelEdit").should be_false
  end

  it "Bug #25257 PBA Package Management - Cannot switch items, package components not displayed in the package list" do
    (slmc.get_css_count("css=#ancillary_section>div")).should_not == 0 || (slmc.get_css_count("css=#supplies_section>div")).should_not == 0 || (slmc.get_css_count("css=#drugs_section>div")).should_not == 0
  end
end