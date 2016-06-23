require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Admission Module Test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @password = '123qweuser'
    @or_patient = Admission.generate_data
    @patient = Admission.generate_data
    @patient2 = Admission.generate_data
    @confidentiality_options = ["Select Code", "UNWED MOTHER", "VERY RESTRICTED", "RESTRICTED", "VERY IMPORTANT PERSON", "PSYCHIATRIC PATIENT", "ALCOHOL / DRUG TREATMENT PATIENT", "EMPLOYEE", "USUAL CONTROL"]
    @account_class = ["Select Class", "BOARD MEMBER", "BOARD MEMBER DEPENDENT", "COMPANY", "DOCTOR", "DOCTOR DEPENDENT", "EMPLOYEE", "EMPLOYEE DEPENDENT", "HMO", "INDIVIDUAL", "SOCIAL SERVICE", "WOMEN'S BOARD DEPENDENT", "WOMEN'S BOARD MEMBER"]
    @admission_type = ["Select Type", "WELLNESS", "NEWBORN", "OR ADMISSION", "ER ADMISSION", "DIRECT ADMISSION", "DELIVERY"]
    @mobility_status = ["Select Type", "STRETCHERBORNE", "AMBULATORY", "AIRLIFT", "CARRIED", "WHEELCHAIR BORNE"]
    @room_charge = ["Select Charge", "TEST", "PRESIDENTIAL SUITE", "AMBASSADOR SUITE", "EXECUTIVE SUITE", "DE LUXE SUITE", "REGULAR SUITE", "EXECUTIVE PRIVATE", "DE LUXE PRIVATE", "REGULAR PRIVATE", "2-BED PRIVATE ROOM", "WARD", "NURSERY", "BIRTHING ROOM", "ISOLATION ROOM", "STEMCELL", "ASU", "EMU", "CCU/ICU/SICU/NCCU/HRPU", "ISOLATION ROOM 2", "VENTILATED IN ISOLETTE", "NOT VENTILATED IN ISOLETTE", "NOT VENTILATED IN CRIB", "SPECIAL UNITS", "ROOMING-IN CHARGES: PRESIDENTIAL SUITE", "ROOMING-IN CHARGES: AMBASSADOR SUITE", "ROOMING-IN CHARGES: EXECUTIVE SUITE", "ROOMING-IN CHARGES: DE LUXE SUITE", "ROOMING-IN CHARGES: REGULAR SUITE", "ROOMING-IN CHARGES: EXECUTIVE PRIVATE", "ROOMING-IN CHARGES: DE LUXE PRIVATE", "ROOMING-IN CHARGES: REGULAR PRIVATE", "ROOMING-IN CHARGES: 2-BED PRIVATE ROOM", "ROOMING-IN CHARGES: WARD", "ROOM CHARGE FOR RMS01", "TEST AUTOMATION SE526", "TEST AUTOMATION SE898", "MITCHIES CHARGING"]
    @diagnosis_type = ["Select Type", "ADMITTING", "INITIAL", "WORKING", "CAUSE OF DEATH", "DISCHARGE", "FINAL"]
    @relation = ["Select Relation", "-", "AUNT", "BROTHER", "BROTHER-IN-LAW", "COUSIN", "DAUGHTER", "DAUGHTER-IN-LAW", "EMPLOYER", "FATHER", "FATHER-IN-LAW", "FIANCEE", "FOSTER PARENT", "FRIEND", "GODPARENT", "GRANDPARENT", "GUARANTOR", "GUARDIAN", "HMO GUARANTOR", "HUSBAND", "MOTHER", "MOTHER-IN-LAW", "NEPHEW", "NIECE", "PARTNER", "SELF", "SISTER", "SISTER-IN-LAW", "SON", "SON-IN-LAW", "STEPMOTHER", "STEPSISTER", "STRANGER", "UNCLE", "WIFE"]
    @guarantor_type = ["HMO", "COMPANY", "INDIVIDUAL", "DOCTOR", "BOARD MEMBER", "CREDIT CARD", "WOMEN'S BOARD", "EMPLOYEE", "SOCIAL SERVICE"]
    @package = ["Select Package", "APE MERALCO - MALE", "APE MERALCO - MALE > 45 YRS OLD", "CALVO A - MALE", "CALVO B - TEEN (MALE)", "COKE A MALE", "COKE B MALE", "COMPREHENSIVE PLAN MALE", "EUROMED MALE", "FRESENIUS - MALE PACKAGE", "HIGH RISK AMKOR PACKAGE - MALE", "ISOS JOHANNESBURG", "LAP CHOLE ECU-PACKAGE", "LOW RISK AMKOR PACKAGE - MALE", "MERALCO - MALE", "MERALCO - MALE > 35 YRS OLD", "MERALCO - MALE > 45 YRS OLD", "MODERATE AMKOR PACKAGE - MALE", "NCM<50 MALE-(IN PATIENT)", "NCM=>50 MALE-(IN PATIENT)", "PLAN A 2 IN ROOM HUSBAND / WIFE", "PLAN A MALE", "PLAN A1 2 IN ROOM HUSBAND / WIFE", "PLAN A1 MALE", "PLAN B 2 IN ROOM HUSBAND/WIFE", "PLAN B MALE", "PLAN C (CARDIAC) MALE", "PLAN C 2 IN ROOM HUSBAND / WIFE", "PLAN C1 2 IN ROOM HUSBAND / WIFE", "PLAN C1 MALE", "PLAN C2 (CARDIAC) HUSBAND / WIFE", "PLAN C2 (CARDIAC) MALE", "PLAN D -(DIABETES) MALE", "PLAN D -2 IN ROOM HUSBAND / WIFE", "PLAN G GERIATRIC PROGRAM", "PLDT E - MALE", "PLDT E1 - MALE", "PLDT E3 - MALE", "PNA PACKAGE MALE (IN-PT)", "RESOLVE CAP 61000", "RESOLVE CAP 63000", "TAKECARE PACKAGE MALE"]
    @package_F = ["Select Package", "APE MERALCO - FEMALE", "APE MERALCO-FEMALE > 35 YRS OLD", "CALVO A - FEMALE", "CALVO B - TEEN (FEMALE)", "COKE A FEMALE", "COKE B FEMALE", "COMPREHENSIVE PLAN FEMALE", "EUROMED FEMALE", "FRESENIUS - FEMALE PACKAGE",
      "HIGH RISK AMKOR PACKAGE - FEMALE", "ISOS JOHANNESBURG", "LAP CHOLE ECU-PACKAGE", "LOW RISK AMKOR PACKAGE - FEMALE", "MERALCO - FEMALE", "MERALCO - FEMALE > 35 YRS OLD", "MODERATE AMKOR PACKAGE - FEMALE", "NCF<40 FEMALE-(IN PATIENT)",
      "NCF=>40 FEMALE-(IN PATIENT)", "PLAN A - 2 IN ROOM HW - WIFE", "PLAN A 2 IN ROOM HUSBAND / WIFE", "PLAN A FEMALE", "PLAN A1 - 2 IN ROOM HW - WIFE", "PLAN A1 2 IN ROOM HUSBAND / WIFE", "PLAN A1 FEMALE", "PLAN B - 2 IN ROOM HW - WIFE",
      "PLAN B 2 IN ROOM HUSBAND/WIFE", "PLAN B FEMALE", "PLAN C (CARDIAC) FEMALE", "PLAN C 2 IN ROOM HUSBAND / WIFE", "PLAN C - 2 IN ROOM HW - WIFE", "PLAN C1 - 2 IN ROOM HW - WIFE", "PLAN C1 2 IN ROOM HUSBAND / WIFE", "PLAN C1 FEMALE", "PLAN C2 (CARDIAC) 2 IN A ROOM - WIFE",
      "PLAN C2 (CARDIAC) FEMALE", "PLAN C2 (CARDIAC) HUSBAND / WIFE", "PLAN D - 2 IN ROOM HW - WIFE", "PLAN D -(DIABETES) FEMALE", "PLAN D -2 IN ROOM HUSBAND / WIFE", "PLAN F (TOTAL WOMAN CARE)", "PLAN F2 MENOPAUSAL CARE PROGRAM", "PLAN G GERIATRIC PROGRAM", "PLDT E - FEMALE",
      "PLDT E1 - FEMALE", "PLDT E3 - FEMALE", "PNA PACKAGE FEMALE (IN-PT)", "RESOLVE CAP 61000", "RESOLVE CAP 63000", "TAKECARE PACKAGE FEMALE", "WOMEN IN PINK PACKAGE 1", "WOMEN IN PINK PACKAGE 2"]
    @package_M = ["APE MERALCO - MALE", "APE MERALCO - MALE > 35 YRS OLD", "APE MERALCO - MALE > 45 YRS OLD", "CALVO A - MALE", "CALVO B - TEEN (MALE)", "COKE B MALE", "COMPREHENSIVE PLAN MALE", "EUROMED MALE", "FORTUNE MALE", "FRESENIUS - MALE PACKAGE", "ISOS JOHANNESBURG", "MERALCO - MALE", "MERALCO - MALE > 35 YRS OLD", "MERALCO - MALE > 45 YRS OLD", "PLAN A - 2 IN ROOM HW - HUSBAND", "PLAN A 2 IN ROOM HUSBAND / WIFE", "PLAN A MALE", "PLAN A1 - 2 IN ROOM HW - HUSBAND", "PLAN A1 2 IN ROOM HUSBAND / WIFE", "PLAN A1 MALE", "PLAN B - 2 IN ROOM HW - HUSBAND", "PLAN B 2 IN ROOM HUSBAND/WIFE", "PLAN B MALE", "PLAN C (CARDIAC) MALE", "PLAN C 2 IN ROOM HUSBAND / WIFE", "PLAN C - 2 IN ROOM HW - HUSBAND", "PLAN C1 - 2 IN ROOM HW - HUSBAND", "PLAN C1 2 IN ROOM HUSBAND / WIFE", "PLAN C1 MALE", "PLAN C2 (CARDIAC) 2 IN A ROOM - HUSBAND", "PLAN C2 (CARDIAC) HUSBAND / WIFE", "PLAN C2 (CARDIAC) MALE", "PLAN D - 2 IN ROOM HW - HUSBAND", "PLAN D -(DIABETES) MALE", "PLAN D -2 IN ROOM HUSBAND / WIFE", "PLAN G GERIATRIC PROGRAM", "PNA PACKAGE MALE (IN-PT)", "STAYWELL H MALE", "STAYWELL I MALE", "STAYWELL J MALE", "STAYWELL K MALE"]
    @pds_contents = ["reprintDatasheet", "reprintLabel"]
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Login as Admission User" do
    slmc.login("sel_adm2", @password).should be_true
  end

### CREATE NEW PATIENT ###

  it "Feature Checklist - Patients with Endorsement" do
    slmc.go_to_admission_page
    slmc.click"link=Patient(s) with Endorsement", :wait_for => :element, :element => "ui-dialog-title-endorsementsDlg"
  end

  it "Feature Checklist - Click and display endorsement" do
    sleep 5
    (slmc.get_css_count"css=#endorsementsDlg>div:nth-child(2)>table>tbody>tr").should_not == 0
    slmc.click"//html/body/div[8]/div[3]/div/button/span"
    (slmc.is_text_present"Patient Search").should be_true
  end

  it "Go to Create Patient link" do
    slmc.admission_search(:pin => "test")
    slmc.click "link=New Patient", :wait_for => :page
    (slmc.is_element_present"//img[@src='/images/calendar.png']").should be_true
  end

  it "Saving null required fields should not be allowed" do
    slmc.click "//input[@value='Create New Admission']", :wait_for => :page
    slmc.get_text("errorMessages").should == "First Name is a required field.\nMiddle Name is a required field.\nGender is a required field.\nBirthdate is a required field.\nPlace of Birth is a required field.\nCivil Status is a required field.\nEmployer Address is a required field.\nPresent Contact is a required field.\nOccupation is a required field.\nEmployer is a required field.\nPerson to Notify is a required field."
  end

  it "Creates new patient" do
    slmc.admission_search(:pin => "test")
    @@pin = slmc.create_new_patient(@patient.merge!(:gender => "M")).gsub(' ', '')
  end

  it "Bug #30185 - [ER-SS]: No validation on Guarantor" do
    slmc.admission_search(:pin => @@pin)
    slmc.click("link=Admit Patient", :wait_for => :page)
    slmc.select("accountClass", "SOCIAL SERVICE")
    slmc.type("escNumber", "234")
    slmc.type("initialDeposit", "100")
    slmc.select("clinicCode", "MEDICINE")
    sleep 3
    slmc.fill_out_admission_form(:diagnosis => "GASTRITIS", :doctor => "0126", :org_code => "287")
    slmc.select("guarantorTypeCode", "COMPANY")
    sleep 1
    (slmc.get_text"popup_message").should == "For Account Class SOCIAL SERVICE, the main guarantor should be MSSD003."
    slmc.click("popup_ok")
  end

### CREATE NEW ADMISSION ###

  it "Go to Admission page" do
    slmc.admission_search(:pin => @@pin)
    slmc.click("link=Admit Patient", :wait_for => :page)
    sleep 5
    @@dropdowns = slmc.get_all_elements("dropdown")
    @@elements = slmc.get_all_elements("textbox")
    @@radios = slmc.get_all_elements("radio")
  end

  it "System displays Admission Details page." do
    slmc.is_text_present("Admission Info").should be_true
    slmc.is_text_present("Package Info").should be_true
    slmc.is_text_present("Admitting Diagnosis").should be_true
    slmc.is_text_present("Room Location").should be_true
    slmc.is_text_present("Person/Party Responsible for this Account").should be_true
  end

  it "The Page provide for the following data entry." do
    sleep 2
    slmc.is_text_present(@patient[:last_name]).should be_true
    slmc.is_text_present(@patient[:first_name]).should be_true
    slmc.is_text_present(@patient[:middle_name]).should be_true
    ((slmc.is_text_present("Inpatient") || slmc.is_text_present("Outpatient")) && slmc.is_text_present(" Patient Type: ")).should be_true
    (slmc.is_element_present("confidentialityCode") && slmc.is_text_present("Confidentiality Code:")).should be_true
    (slmc.is_element_present("residentFlag1") && slmc.is_element_present("residentFlag2") && slmc.is_text_present("Residency:")).should be_true
    (slmc.is_element_present("accountClass") && slmc.is_text_present("Account Class:")).should be_true
    (slmc.is_element_present("admissionTypeCode") && slmc.is_text_present("Admission Type:")).should be_true
    (slmc.is_element_present("mobilizationTypeCode") && slmc.is_text_present("Mobility Status:")).should be_true
    (slmc.is_element_present("referringHospital") && slmc.is_text_present("Referring Hospital:")).should be_true
    (slmc.is_element_present("admissionPackageDesc") && slmc.is_text_present("Package")).should be_true
    (slmc.is_element_present("viewPackageContent")).should be_true
    (slmc.is_element_present("nursingUnitCode") && slmc.is_text_present("Nursing Unit:")).should be_true
    (slmc.is_element_present("roomNo") && slmc.is_element_present("roomNoFinder") && slmc.is_text_present("Room:")).should be_true
    (slmc.is_element_present("bedNo") && slmc.is_text_present("Bed:")).should be_true
    (slmc.is_element_present("diagnosisDate") && slmc.is_text_present("Date/Time:")).should be_true
    (slmc.is_element_present("diagnosisTypeCode") && slmc.is_text_present("Diagnosis Type:")).should be_true
    (slmc.is_element_present("diagnosisCode") && slmc.is_text_present("Diagnosis Code:")).should be_true
    (slmc.is_element_present("//input[@value='' and @type='button']")).should be_true
    (slmc.is_element_present("doctorCode") && slmc.is_text_present("Doctor Code:")).should be_true
    (slmc.is_element_present("//input[@type='button' and @onclick=\"searchType='D';reinitDoctor();DF.show();\"]")).should be_true
    (slmc.is_element_present("guarantorCode") && slmc.is_text_present("Guarantor Code:")).should be_true
    (slmc.is_element_present("searchGuarantorBtn")).should be_true
    (slmc.is_element_present("guarantorTypeCode") && slmc.is_text_present("Guarantor Type:")).should be_true
    (slmc.is_element_present("guarantorName") && slmc.is_text_present("Guarantor Name:")).should be_true
    (slmc.is_element_present("guarantorRelationCode") && slmc.is_text_present("Relation to Patient:")).should be_true
    (slmc.is_element_present("guarantorAddress") && slmc.is_text_present("Address:")).should be_true
    (slmc.is_element_present("guarantorTelNo") && slmc.is_text_present("Telephone:")).should be_true
    (slmc.is_element_present("employer") && slmc.is_text_present("Employer:")).should be_true
    (slmc.is_element_present("employerAddress") && slmc.is_text_present("Employer Address:")).should be_true
    (slmc.is_element_present("officeTelNo") && slmc.is_text_present("Office Telephone:")).should be_true
    (slmc.is_element_present("position") && slmc.is_text_present("Position in the Company:")).should be_true
    (slmc.is_element_present("serviceYears") && slmc.is_text_present("Years in Service")).should be_true
    (slmc.is_element_present("salary") && slmc.is_text_present("Monthly Salary")).should be_true
    (slmc.is_element_present("otherIncome") && slmc.is_text_present("Other Source of Income")).should be_true
    slmc.get_select_options("diagnosisTypeCode").should == @diagnosis_type
  end

  it "Preview and Cancellations buttons displayed on the page are clickable." do
    slmc.is_editable("//input[@value='Preview' and @name='action']").should be_true
    slmc.is_editable("//input[@value='Cancel']").should be_true
  end

  it "Data for PIN, Lastname, Firstname,And Middlename are retrieved from database and displayed on non-editable mode." do
    full_name = slmc.get_patient_full_name(@patient)
    #slmc.get_text("css=#admissionInfo>div:nth-child(3)>div>div").should == ("#{@patient[:title]}").capitalize + " #{full_name}"
    slmc.get_text("css=#admissionInfo>div:nth-child(3)>div>div").should == "#{full_name}"
    op = slmc.return_original_pin(@@pin)
    slmc.get_text("css=#admissionInfo>div:nth-child(2)>div>div").should == op
  end

  it "Look-up button beside Package Name, Nursing Unit, Diagnosis Code, and Doctor Code text boxes" do
    @@elements.include?("rbf_entity_finder_key").should be_true
    @@elements.include?("diagnosis_entity_finder_key").should be_true
    @@elements.include?("entity_finder_key").should be_true
  end

  it "Only 1 attending doctor is allowed" do
    2.times do
      slmc.assign_doctor
      slmc.is_element_present "doctorNameDisplay".should be_true
    end
    slmc.get_css_count("css=#doctorNameDisplay").should == 1
  end

  it "Input field is drop down box with the following selection" do
    @@dropdowns.include?("confidentialityCode").should be_true
    slmc.get_select_options("confidentialityCode").should == @confidentiality_options
  end

  it "Residency Flag : Input field is radio button" do
    @@radios.include?("residentFlag1").should be_true
    @@radios.include?("residentFlag2").should be_true
  end

  it "Input Account Class : Input field is drop down list box with the following selection (*), mark as required field" do
    @@dropdowns.include?("accountClass").should be_true
    slmc.get_text("css=#admissionInfo>div:nth-child(2)>div:nth-child(3)>label").include?("*").should be_true
    slmc.get_select_options("accountClass").should == @account_class
  end

  it "Input Admission Type : Input field is drop down list box with the following selection (*), mark as required field" do
    @@dropdowns.include?("admissionTypeCode").should be_true
    slmc.get_text("css=#admissionInfo>div:nth-child(2)>div:nth-child(5)>label").include?("*").should be_true
    slmc.get_select_options("admissionTypeCode").should == @admission_type
  end

  it "Input Ambulatory Status : Input field is drop down list box" do
    @@dropdowns.include?("mobilizationTypeCode").should be_true
    slmc.get_select_options("mobilizationTypeCode").should == @mobility_status
  end

  it "Input Referring Hospital : Input field is text box, may input up to 30 characters" do
    @@elements.include?("referringHospital").should be_true
    slmc.type("referringHospital", "1234567890123456789012345678901")
    slmc.get_value("referringHospital").should == "123456789012345678901234567890"
  end

  it "Input Nursing Units : Input field is text box, mark as required field" do
    @@elements.include?("nursingUnitCode").should be_true
    slmc.get_text("//div[@id='roomLocation']/div[2]/div[2]/label/font").include?("*").should be_true
  end

  it "Input Room Charging : mark as required field" do
    slmc.get_text("css=#roomLocation>div:nth-child(2)>div>label").include?("*").should be_true
    slmc.get_select_options("roomChargeCode").should == @room_charge
  end

  it "Input Room No : Input field is text box, input field is disabled, mark as required field" do
    @@elements.include?("roomNo").should be_true
    slmc.is_editable("roomNo").should be_false
    slmc.get_text("css=#roomNoLabel").include?("*").should be_true
  end

  it "Input Bed No : Input field is text box, input field is disabled, mark as required field" do
    @@elements.include?("bedNo").should be_true
    slmc.is_editable("bedNo").should be_false
    slmc.get_text("css=#roomLocation>div:nth-child(3)>div:nth-child(1)>label").include?("*").should be_true
  end

  it "Input Date / Time : mark as required field" do
    slmc.get_text("css=#admittingDiagnosis>div:nth-child(2)>div>label").include?("*").should be_true
    diagnosis_date = slmc.get_value("diagnosisDate")
    diagnosis_date.include?(Date.today.strftime("%m/%d/%Y")+" " + Time.now.strftime("%H:%m"))
  end

  it "Input Diagnosis Category" do
    @@dropdowns.include?("diagnosisTypeCode").should be_true
  end

  it "Input Diagnosis Code : Input field is text box" do
    @@elements.include?("diagnosisCode").should be_true
    slmc.get_text("css=#admittingDiagnosis>div:nth-child(2)>div:nth-child(3)>label").include?("*").should be_true
  end

  it "Input Doctor Code : Input field is text box" do
    @@elements.include?("doctorCode").should be_true
  end

  it "Input Guarantor Code : Input field is text box, user will search guarantor code thru search button" do
    @@elements.include?("guarantorCode").should be_true
    slmc.click("searchGuarantorBtn", :wait_for => :visible, :element => "patientFinderForm")
    slmc.type("patient_entity_finder_key", "TEST")
    slmc.click "//input[@value='Search' and @type='button' and @onclick='PF.search();']"
    sleep 5
    @@guarantor_test = slmc.get_text"css=#patient_finder_table_body>tr.even>td:nth-child(2)>a"
    slmc.click"css=#patient_finder_table_body>tr.even>td:nth-child(2)>a"
    sleep 3
  end

  it "Input Guarantor Type" do
    @@dropdowns.include?("guarantorTypeCode").should be_true
    slmc.get_select_options("guarantorTypeCode").should == @guarantor_type
  end

  it "Input Guarantor Name : Input field is text box" do
    @@elements.include?("guarantorName").should be_true
    slmc.get_value("guarantorName").should == @@guarantor_test
  end

  it "Input Address : Input field is text box, limited to 100 characters only" do
    @@elements.include?("guarantorAddress").should be_true
    you = "1234567890"
    me = (you * 9) + "12345678901"
    slmc.type("guarantorAddress", me)
    slmc.get_value("guarantorAddress").should == you * 10
  end

  it "Input Employer : Input field is text box, limited to 50 characters only" do
    @@elements.include?("employer").should be_true
    you = "1`cdef&*(0"
    me = (you * 4) + "1`cdef&*(01"
    slmc.type("employer", me)
    slmc.get_value("employer").should == you * 5
  end

  it "Input Employer Address : Input field is text box, limited to 100 characters only" do
    @@elements.include?("employerAddress").should be_true
    you = "1`cdef&*(0"
    me = (you * 9) + "1`cdef&*(01"
    slmc.type("employerAddress", me)
    slmc.get_value("employerAddress").should == you * 10
  end

  it "Input Position in the Company : Input field is text box, limited to 30 characters only" do
    @@elements.include?("position").should be_true
    you = "1`cdef&*(0"
    me = (you * 2) + "1`cdef&*(01"
    slmc.type("position", me)
    slmc.get_value("position").should == you * 3
  end

  it "Input Years in Service : Input field is text box, limited to 30 numbers only" do
    @@elements.include?("serviceYears").should be_true
    you = "1234567890"
    me = (you * 2) + "12345678901"
    slmc.type("serviceYears", me)
    slmc.get_value("serviceYears").should == you * 3
  end

  it "Assume that all fields are correctly filled, Years in Service = input special characters" do
    slmc.assign_doctor
    slmc.add_diagnosis
    slmc.assign_room_location(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287')
    slmc.select("accountClass", "label=HMO")
    slmc.select("guarantorTypeCode","HMO")
    slmc.select("admissionTypeCode", "label=DIRECT ADMISSION")
    slmc.type"guarantorTelNo","23907654"
    slmc.select"mobilizationTypeCode","AIRLIFT"
    slmc.click"searchGuarantorBtn"
    slmc.type"bp_entity_finder_key", "ASAL002"
    slmc.click("//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']")
    sleep 2
    slmc.type("serviceYears", "!@#")
    slmc.click("//input[@value='Preview' and @name='action']", :wait_for => :page)
    slmc.get_text("errorMessages").should == "Years in Service must be a number."
  end

  it "Assume that all fields are correctly filled, Years in Service = input alphanumerical characters" do
    slmc.assign_doctor
    slmc.add_diagnosis
    slmc.assign_room_location(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287')
    slmc.select("accountClass", "label=HMO")
    slmc.select("guarantorTypeCode","HMO")
    slmc.select("admissionTypeCode", "label=DIRECT ADMISSION")
    slmc.type"guarantorTelNo","23907654"
    slmc.select"mobilizationTypeCode","AIRLIFT"
    slmc.click"searchGuarantorBtn"
    slmc.type"bp_entity_finder_key", "ASAL002"
    slmc.click("//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']")
    sleep 2
    slmc.type("serviceYears", "ASD123")
    slmc.click("//input[@value='Preview' and @name='action']", :wait_for => :page)
    slmc.get_text("errorMessages").should == "Years in Service must be a number."
  end

  it "Input Relation to Patient : Input field is text box, user can choose from the list" do
    @@dropdowns.include?("guarantorRelationCode").should be_true
    slmc.select("guarantorRelationCode", "label=HMO GUARANTOR")
    slmc.get_select_options("guarantorRelationCode").should == @relation
  end

  it "Input Telephone : Input field is text box, limited to 15 characters only" do
    @@elements.include?("guarantorTelNo").should be_true
    you = "1234567890"
    me = (you) + "12345678901"
    slmc.type("guarantorTelNo", me)
    slmc.get_value("guarantorTelNo").should == you + "12345"
  end

  it "Input Office Telephone : Input field is text box, limited to 15 characters only" do
    @@elements.include?("officeTelNo").should be_true
    you = "1234567890"
    me = (you) + "12345678901"
    slmc.type("officeTelNo", me)
    slmc.get_value("officeTelNo").should == you + "12345"
  end

  it "Assume that all other fields are filled up properly" do
    slmc.admission_search(:pin => @@pin)
    slmc.click("link=Admit Patient", :wait_for => :page)
    slmc.select("accountClass", "label=Select Class")
    slmc.select("admissionTypeCode", "label=Select Type")
    slmc.type("diagnosisDate", "")
    slmc.select("diagnosisTypeCode", "label=Select Type")
    slmc.select("mobilizationTypeCode","AIRLIFT")
    slmc.assign_doctor
    slmc.type("guarantorTelNo", "23907654")
    slmc.click('//input[@type="button" and @value="Preview" and @onclick="submitForm(this);"]', :wait_for => :page)
    slmc.get_text("errorMessages").should == "Account Class is a required field.\nAdmission Type is a required field.\nRoom Charge is a required field.\nDiagnosis Date is a required field.\nPerson/Party Responsible for this Account Name is a required field.\nPerson/Party Responsible for this Account Address is a required field.\nRoom is a required field.\nBed is a required field.\nDiagnosis is a required field."
  end

  it "User clicks cancel button" do # #https://projects.exist.com/issues/36205
    slmc.click'//input[@value="Cancel" and @name="cancel" and @onclick="submitForm(this);"]', :wait_for => :page
    slmc.is_text_present("Admission").should be_true
  end

  it "The user clicks preview button" do
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.click("link=Admit Patient", :wait_for => :page)
    slmc.populate_admission_fields(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => "0287")
    all = slmc.get_all_admission_info
    slmc.click('//input[@type="button" and @value="Preview" and @onclick="submitForm(this);"]', :wait_for => :page)
    patient = slmc.get_patient_full_name(@patient)
    op = slmc.return_original_pin(@@pin)
    slmc.verify_admission_preview(all.merge(:patient => patient, :pin => op))
    slmc.is_editable("//input[@value='Revise' and @type='button' and @onclick='submitForm(this);']").should be_true
    slmc.is_editable("//input[@value='Save Admission' and @type='button' and @onclick='submitForm(this);']").should be_true
    slmc.is_editable("//input[@value='Save and Print Admission' and @type='button' and @onclick='submitForm(this);']").should be_true
    slmc.get_all_elements("radio").should == []
    slmc.get_all_elements("textbox").should == ["printerName"]
    slmc.get_all_elements("dropdown").should == []
  end

  it "User clicks save button, Generates visit number" do
    slmc.click("//input[@value='Save Admission' and @type='button' and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.get_text("successMessages").should == "Patient admission details successfully saved."
    sleep 2
    @@visit_number = slmc.get_visit_number_using_pin(@@pin)
  end

  it "If user chooses to Edit data, system displays Admission Page again for encoding. - Admission Page is filled out with existing data." do
    slmc.admission_search(:pin => @@pin)
    slmc.click("link=Update Admission", :wait_for => :page)
    sleep 5
    slmc.get_selected_label("accountClass").should == "INDIVIDUAL"
    slmc.get_selected_label("admissionTypeCode").should == "DIRECT ADMISSION"
    slmc.get_selected_label("roomChargeCode").should == "REGULAR PRIVATE"
    slmc.get_value("nursingUnitCode").should == "0287"
    slmc.get_selected_label("diagnosisTypeCode").should == "ADMITTING"
    slmc.get_text("diagnosisDisplay").should == "GASTRITIS"
    slmc.get_value("doctorCode").should == "6726"
  end

  it "If user chooses Cancel, system goes back to landing page." do
    slmc.click'//input[@value="Cancel" and @name="cancel" and @onclick="submitForm(this);"]', :wait_for => :page
    slmc.is_text_present("Admission").should be_true
    slmc.is_text_present("Quick Links").should be_true
  end

  it "User update patient information" do
    #@@package_pin="1106002358"
    slmc.admission_search(:pin => @@pin)
    slmc.click("link=Update Admission", :wait_for => :page)
    sleep 5
    slmc.select("confidentialityCode", "label=USUAL CONTROL")
    slmc.click "searchAdmissionPackage"
    sleep 2
    slmc.click "link=LAP CHOLE ECU-PACKAGE"
    sleep 1
    slmc.type "guarantorAddress","1234 ADDRESS"
    slmc.type "guarantorTelNo","23907654"
    slmc.click("//input[@value='Preview' and @name='action' and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.click("//input[@value='Save Admission' and @type='button' and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.get_text("successMessages").should == "Patient admission details successfully saved."
  end

  # CREATE NEW ADMISSION
  it "Input Package Name : User will click look up button near the text box, input field is drop down" do
    slmc.admission_search(:pin => @@pin)
    slmc.click("link=Update Admission", :wait_for => :page)
    slmc.wait_for(:wait_for => :text, :text => "REGULAR PRIVATE" )
    slmc.click("searchAdmissionPackage")
    sleep 5
    count = slmc.get_css_count("css=#ecuPackages>tbody>tr")
    arr = []
    count.times do |rows|
      arr << slmc.get_text("css=#ecuPackages>tbody>tr:nth-child(#{rows + 1})>td>a>div")
    end
    arr.should == (@package_M)
  end

  it "Input Package Type : Automatically filled out upon selecting package" do
    sleep 5
    slmc.click("link=LAP CHOLE ECU-PACKAGE")
    sleep 1
    slmc.get_value("admissionPackageDesc").should == "LAP CHOLE ECU-PACKAGE"
    slmc.get_selected_label("packageRate").should == "PRIVATE"
  end

# cannot select roomcharge anymore in 1.4
#  it "Verify Package Info according to the Selected Room." do
#    slmc.select("roomChargeCode", "label=2-BED PRIVATE ROOM")
#    sleep 5
#    slmc.get_value("admissionPackageDesc").should == "MERALCO - MALE > 35 YRS OLD"
#    slmc.select("roomChargeCode","label=EMU")
#    sleep 5
#    slmc.get_value("admissionPackageDesc") != ""
#    slmc.select("roomChargeCode", "label=ASU")
#    sleep 5
#    slmc.get_value("admissionPackageDesc").should == "LAP CHOLE ECU-PACKAGE"
#  end

  # CANCEL ADMISSION
  it "Select Search currently admitted to the main menu, Admission/Direct Admission/Search Currently Admitted" do
    slmc.go_to_admission_page
    slmc.is_element_present("param").should be_true
    slmc.is_element_present("slide-fade").should be_true
    slmc.is_element_present("admitted").should be_true
  end

  it "Input field for birth date accepts numeric and convert entry to date format" do
    slmc.click("slide-fade", :wait_for => :visible, :element => "//div[@name='advanceSearchOptions']")
    slmc.type("param", @patient[:last_name])
    slmc.type("fName", @patient[:first_name])
    slmc.type("mName", @patient[:middle_name])
    slmc.type("bDate", @patient[:birth_day])
    gender = @patient[:gender]
    slmc.click("//input[@value='M']") if gender == "M"
    slmc.click("//input[@value='F']") if gender == "F"
  end

  it "System shall have an alert if the encoded data are invalid" do
    slmc.type("bDate", "2222222")
    slmc.click("//input[@value='Search' and @type='submit' and @name='action']", :wait_for => :page)
    slmc.get_text("errorMessages").should == "Invalid date format."
  end

  it "Records matching the encoded data is displayed" do
    slmc.type("param", @@pin)
    slmc.click("slide-fade", :wait_for => :visible, :element => "//div[@name='advanceSearchOptions']")
    slmc.type("bDate", @patient[:birth_day])
    slmc.click("//input[@value='Search' and @type='submit' and @name='action']", :wait_for => :page)
    slmc.get_css_count("#results>tbody>tr").should == 1
  end

  it "System shall display maximum of 20 Patients per page" do
    slmc.click("clear")
    slmc.patient_pin_search(:pin => "test")
    slmc.get_css_count("#results>tbody>tr").should == 20
    slmc.click('//a[@title="Go to page 2"]', :wait_for => :page)
    slmc.get_css_count("#results>tbody>tr").should == 20
    slmc.click('//a[@title="Go to page 3"]', :wait_for => :page)
    slmc.get_css_count("#results>tbody>tr").should == 20
  end

  it "Select Cancel admission from list of actions of admitted patient" do
    slmc.go_to_admission_page
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click "link=Cancel Admission", :wait_for => :visible, :element => "admCancelDlg"
    slmc.type("//*[@name='reason']", "cancel")
  end

  it "System shall display the filled out admission page with text field input for reason of cancellation." do
    slmc.is_element_present("//*[@name='reason']").should be_true
    sleep 8
    slmc.click("//html/body/div[10]/div[3]/div/button", :wait_for => :page)
    slmc.is_text_present("Patient admission details successfully cancelled.").should be_true
    slmc.admission_search(:pin => @@pin).should be_true
  end

  # ROOM BED REPRINT
  it "Verify Room/Bed Reprint link : Generate room bed posting as 12 midnight" do
    slmc.reprint_room_bed.should be_true
  end

  it "Verify Close Button" do
    slmc.click "link=Room/Bed Reprint", :wait_for => :element, :element => "roomBedDateFilter"
    slmc.click("//html/body/div[11]/div[3]/div/button[2]")
    sleep 1
    slmc.is_visible("rbReprintDlg").should be_false
  end

  # REPRINT PDS LABEL
  it "Access Reprinting Page / Admission Complete Page" do
    slmc.login("sel_or4", @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient.merge!(:admit => true, :gender => 'F', :sap => true)).gsub(' ', '')
    slmc.login("sel_adm2", @password).should be_true
    slmc.admission_search(:pin => @@or_pin)
    slmc.click("link=Reprint Patient Data Sheet And Label Sticker", :wait_for => :page)
  end

  it "System shall display Reprint PDS checkbox, Reprint Patient Label checkbox and No. of Copies in the Reprinting page." do
    @@checkbox = slmc.get_all_elements("checkbox").should == @pds_contents
    slmc.is_element_present("labelCount").should be_true
  end

  it "System shall display Reprint Button in the Reprinting page / Admission Complete page" do
    slmc.is_element_present("//input[@type='button' and @value='Reprint' and @onclick='submitForm(this);']").should be_true
  end

  it "Mark Reprint Patient Label checkbox in the Reprinting page then input Number of copies in the textbox provided" do
    slmc.click("reprintLabel")
    sleep 3
    slmc.is_editable("labelCount").should be_true
    slmc.type("labelCount", "5")
  end

  it "Mark both the Reprint PDS checkbox and Reprint Patient Label checkbox in the Reprinting page" do
    slmc.click("reprintDatasheet")
    sleep 3
    slmc.get_value("reprintDatasheet").should == "on"
    slmc.get_value("reprintLabel").should == "on"
  end

  it "Click Reprint Button in the Reprinting page" do
    slmc.click("//input[@type='button' and @value='Reprint' and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.is_element_present("reprintForm").should be_true
  end

  it "System shall print number of copies specified / entered in the Reprinting page" do
    slmc.click('//input[@id="reprintLabel" and @name="reprintLabel"]')
    slmc.type("labelCount", "5")
    sleep 2
    slmc.click("//input[@type='button' and @value='Reprint' and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.get_text("errorMessages") if slmc.is_element_present("errorMessages")
    slmc.get_text("successMessages").should == "Reprinted 5 copies of patient label." if slmc.is_element_present("successMessages")
  end

  it "Click Update Admission Data Button from the Patient Registration page" do
    slmc.login("sel_adm2", @password).should be_true
    slmc.admission_search(:pin => @@or_pin)
    slmc.click("link=Update Admission", :wait_for => :page)
    slmc.populate_admission_fields
    or_info = slmc.get_all_admission_info
    slmc.go_to_preview_page
    slmc.verify_admission_preview(or_info).should be_true
    slmc.click("//input[@type='button' and @value='Revise' and @onclick='submitForm(this);']", :wait_for  => :page)
    or_info.should == slmc.get_all_admission_info
  end

  # Admission - Patient On - Queue
  it "Admission - Patient Search - Lastname - On Queue" do
    slmc.login("sel_adm2", @password).should be_true
    slmc.admission_search(:pin => @@pin)
    slmc.click("link=Admit Patient", :wait_for => :page)
    sleep 3
    slmc.populate_admission_fields(:on_queue => true, :room_charge => "REGULAR PRIVATE")
    slmc.click("//input[@value='Preview' and @name='action' and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.click("//input[@value='Save Admission' and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.admission_advance_search(:last_name => @patient[:last_name], :first_name => @patient[:first_name], :middle_name => @patient[:middle_name], :gender => @patient[:gender])
    slmc.get_text(Locators::Admission.admission_search_results_admission_status).should == "On Queue"
  end

  it "Admission - Patient Search - PIN - On Queue" do
    slmc.admission_search(:pin => @@pin)
    slmc.get_text(Locators::Admission.admission_search_results_admission_status).should == "On Queue"
  end

  it "Admission - Patient Search - All Admitted Patient" do
    slmc.admission_search(:pin => @@pin)
    slmc.get_text(Locators::Admission.admission_search_results_admission_status).should == "On Queue"
    slmc.admission_search(:admitted => true, :pin => @@pin)
    slmc.is_text_present("NO PATIENT FOUND").should be_true
  end

  it "Create New Admission  - Inpatient Admission Queue" do
    slmc.admission_search(:pin => @@pin)
    slmc.click("link=Update Admission", :wait_for => :page)
    sleep 3
    slmc.click("onQueue")
    slmc.is_editable("nursingUnitCode").should be_true
    slmc.is_editable("nursingUnitFinder").should be_true
    sleep 3
  end

  it "Already On queue patient should update admission not allow to make a request again" do
    slmc.admission_search(:pin => @@pin)
    slmc.click("link=Update Admission", :wait_for => :page)
    sleep 3
    slmc.click("onQueue")
    slmc.populate_admission_fields(:room_charge => "REGULAR PRIVATE", :org_code => "0287", :rch_code => "RCH08")
    slmc.click("//input[@value='Preview' and @name='action' and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.click("//input[@type='button' and @value='Save Admission'and @onclick='submitForm(this);']", :wait_for => :page)
    slmc.admission_search(:pin => @@pin)
    slmc.click("link=Update Admission", :wait_for => :page)
    slmc.is_checked("onQueue").should be_false
  end

  it "Bug#40743 - [NewBorn Admission] In Newborn Notice of birth preview page, change label Left-for-Care to Newborn Inpatient Admission" do
    slmc.login("sel_or4", @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.outpatient_to_inpatient(@or_patient.merge(:pin => @@or_pin, :username => 'sel_adm2', :password => @password, :room_label => "REGULAR PRIVATE")).should be_true
    slmc.login("dr1", @password).should be_true
    slmc.register_new_born_patient(:pin => @@or_pin, :bdate => (Date.today).strftime("%m/%d/%Y"),
      :birth_type => "SINGLE", :birth_order => "FIRST", :delivery_type => "OTHER", :weight => 4000, :length => 54,
      :doctor_name => "ABAD", :room_charge => "NURSERY", :newborn_inpatient_admission => true, :rch_code => "RCH11", :org_code => "0301")
    slmc.is_text_present("Newborn Notice of Birth Preview").should be_true
  end

  it "Newborn for Admission : Should be redirect to Admission Preview Page" do
    slmc.click("//input[@name='action' and @value='Save Admission']", :wait_for => :page)
    (slmc.is_text_present("Patient admission details successfully saved.")).should be_true
  end

  it "Gets the pin number of the baby" do
    sleep 1
    slmc.advanced_search(:last_name => @or_patient[:last_name], :first_name => "baby boy", :birthday => (Date.today).strftime("%m/%d/%Y"))
    @@newborn_pin = slmc.get_newborn_pin_from_search_results
  end

  it "Create New Admission - Inpatient Admission Queue - Newborn for Admission : On Queue checkbox should be disable" do
    slmc.login("sel_adm2", @password).should be_true
    slmc.go_to_admission_page
    slmc.view_newborn_for_admission
    sleep 25
    slmc.click("link=#{@@newborn_pin}", :wait_for => :page)
    slmc.populate_patient_info(@or_patient.merge(:newborn => true, :occupation => "n/a", :employer=>"n/a", :employer_address=>"n/a", :spouse_fname=>"n/a", :spouse_mname=>"n/a", :spouse_lname=>"n/a"))
    slmc.click '//input[@type="button" and @value="Proceed to Create New Admission" and @onclick="submitForm(this);"]', :wait_for => :page
    sleep 5
    slmc.click("onQueue")
    slmc.is_checked("onQueue").should be_false
  end

  it "Creates another patient on-queue" do
    slmc.admission_search(:pin => "1")
    @@pin2 = slmc.create_new_patient(@patient2).gsub(' ', '')
    slmc.admission_search(:pin => @@pin2)
    slmc.click("link=Admit Patient", :wait_for => :page)
    sleep 3
    slmc.populate_admission_fields
    sleep 1
    slmc.select("roomChargeCode", "REGULAR PRIVATE")
    slmc.click("onQueue")
    slmc.click("//input[@onclick='submitForm(this);' and @value='Preview' and @name='action']", :wait_for => :page)
    slmc.click("//input[@value='Save Admission']", :wait_for => :page)
    slmc.is_text_present("Patient admission details successfully saved.").should be_true
  end

  it "The columns that will display are PIN, Visit No., Complete Patient Name, Room Charge" do
    slmc.go_to_admission_page
    sleep 5
    @@on_queue_count = slmc.get_pending_admission_queue_count
    slmc.click("pendingAdmQueueCount")
    sleep 10
    arr = slmc.get_text("css=#pendingAdmQueuePopup>div.searchResultsHeader>table>thead>tr").split.map
    (arr[0]).should == slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[4]/div[4]/table/thead/tr/th")
    (arr[1] + " " + arr[2]).should == slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[4]/div[4]/table/thead/tr/th[2]")
    (arr[3] + " " + arr[4]).should == slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[4]/div[4]/table/thead/tr/th[3]")
    (arr[5] + " " + arr[6]).should == slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[4]/div[4]/table/thead/tr/th[4]")
    (arr[7]).should == slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[4]/div[4]/table/thead/tr/th[5]")
  end

  it "Admission Page will display with filled-out data" do
    slmc.get_css_count("css=#pendingAdmQueueRows>tr").should_not == 0
  end

  it "On-queue checkbox should be unchecked to enable searching of Room Location" do
    @@visit_number = slmc.get_visit_number_using_pin(@@pin2)
    slmc.click_patient_on_queue(@@visit_number, @@pin2)
    sleep 10
  end

  it "Cancel Admission on-queue : One Visit Number can be cancelled at a time" do
    slmc.click_cancel_admission_inside
    @@on_queue_count -= 1
  end

  it "Cancelled Patient will be removed from the list of on-queue admission" do
    slmc.click("pendingAdmQueueCount")
    sleep 10
    slmc.is_text_present(@@visit_number).should be_false
    slmc.get_pending_admission_queue_count.should == @@on_queue_count
  end

  it "Once cancelled, during patient search, user actions should be Update Patient and Create New Admission" do
    slmc.admission_search(:pin => @@pin2)
    slmc.get_text(Locators::Admission.admission_search_results_actions_column).should == "Update Patient Info \n Admit Patient \n Reprint Patient Data Sheet And Label Sticker \n View Confinement History \n Tag for MPI Consolidation"
  end

  it "Once cancelled, during patient search, Admission Status should be Not Admitted" do
    slmc.get_text(Locators::Admission.admission_search_results_admission_status).should == "Not Admitted"
  end
end