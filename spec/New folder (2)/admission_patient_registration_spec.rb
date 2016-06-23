require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Patient Registration" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @or_patient1 = Admission.generate_data
    @or_patient2 = Admission.generate_data
    @password = "123qweuser"
    @registration_textboxes = ["lastname","firstname","middlename"]
    @country = "PHILIPPINES"

    @registration_fields = {
      "patientRelation.erRelation"                      => "Relationship:",
      "patientAdditionalDetails.position"               => "Position:",
      "patientAdditionalDetails.yearsOfService"         => "Years in Service:",
      "patientAdditionalDetails.otherSources"           => "Other Source of Income:",
      "name.firstName"                                  => "First Name*",
      "suffix.code"                                     => "Suffix",
      "religion.code"                                   => "Religion:",
      "race.code"                                       => "Race:",
      "patientAdditionalDetails.occupation"             => "Occupation:",
      "female"                                          => "Female",
      "citizenship.code"                                => "Citizenship:*",
      "patientAdditionalDetails.salary"                 => "Salary:",
      "civilStatus.code"                                => "Civil Status:",
      "birthDate"                                       => "Birth Date:*",
      "birthCountry.code"                               => "Country of Birth:",
      "title.code"                                      => "Title",
      "patientAdditionalDetails.primaryLanguage.code"   => "Primary Language:",
      "name.middleName"                                 => "Middle Name*",
      "gender"                                          => "Gender: *",
      "name.lastName"                                   => "Last Name*",
      "male"                                            => "Male",
      "patientAdditionalDetails.employer"               => "Employer:",
      "birthPlace"                                      => "Place of Birth:",
      "patientAdditionalDetails.secondaryLanguage.code" => "Secondary Language:",
      "nationality.code"                                => "Nationality:"
    }
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Should verify fields during OP - Create new patient record" do
    slmc.login('selenium_inpatient', @password).should be_true
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.patient_pin_search(:pin => "test")
    slmc.click_create_patient_record.should be_true

    @@textfields = []
    @@textfields = slmc.get_all_elements("textbox")

    @registration_textboxes.each do |textbox|
      @@textfields.any? {|textfield| textfield.match /#{textbox}/i}.should be_true
    end
  end

  it "Should verify fields and label on the registration page" do
    @registration_fields.each_pair do |id, label|
      slmc.is_element_present(id).should be_true
      slmc.get_text("css=label[for='#{id}']").should == label
    end
  end

  it "Should validate for valid Date of Birth format" do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.patient_pin_search(:pin => "test")
    slmc.create_patient_record(@or_patient1.merge(:birth_day => "98765")).should == "Invalid date format"
  end

  it "Should display CANCEL, PREVIEW and CREATE NEW ADMISSION button in the Patient Registration page." do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.patient_pin_search(:pin => "test")
    @@pin = slmc.create_patient_record(@or_patient1.merge(:country => @country, :city => "BAGUIO CITY")).should be_true
    @@pin = @@pin.gsub(' ', '')
    slmc.is_element_present(Locators::NursingSpecialUnits.preview).should be_true
    slmc.is_element_present(Locators::NursingSpecialUnits.cancel_registration).should be_true
  end

  it "Generated PIN should be a 10-digit number used for patient Identifier" do
    @@pin.length.should == 10
    @@pin.include? Date.today.strftime("%y") + Date.today.strftime("%m")
  end

  it "Verify elements in the Patient Search Landing page" do
    slmc.verify_patient_search_page.should be_true
  end

  it "Should be able to validate and recognize surnames with spaces and capitalizations (e.g dela Cruz, Dela cruz, de la Cruz) as same entry" do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.patient_pin_search(:pin => @or_patient1[:last_name].downcase)
    slmc.get_text(Locators::Admission.admission_search_results_name).include? @or_patient1[:last_name].upcase
    slmc.patient_pin_search(:pin => @or_patient1[:last_name].upcase)
    slmc.get_text(Locators::Admission.admission_search_results_name).include? @or_patient1[:last_name].upcase
  end

  it "If patient record is found but not currently admitted, displays Update Patient and Register Patient page menus" do
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.get_text(Locators::Admission.admission_reg_search_results_actions_column).should == "Update Patient Info \n Register Patient\n Tag for MPI Consolidation \n View Information"
  end

  it "Enable admin user to search on patient through PIN or Last Name" do
    slmc.admission_search(:pin => @@pin)
    slmc.verify_search_results(:with_results => true)#.should be_true => mpi is on
    slmc.admission_search(:last_name => @or_patient1[:last_name])
    slmc.verify_search_results(:with_results => true)#.should be_true => mpi is on
  end

  it "Should validate maximum input characters for patient pin/lastname search - 10 Numeric Characters / 30 Alpha Characters" do
      (slmc.get_attribute("param@maxlength")).to_i.should == 30
  end

  it "Verify search result details for the patient that matched the entered PIN or Last name" do
    slmc.admission_search(:pin => @@pin)
    slmc.verify_search_results(:with_results => true)#.should be_true => mpi is on

    (slmc.get_text(Locators::Admission.admission_reg_pin)).gsub(' ','').should == @@pin
    slmc.get_reg_name_from_search_results.should == "#{@or_patient1[:last_name].upcase}, #{@or_patient1[:first_name]} #{@or_patient1[:middle_name]}"

    if @or_patient1[:gender] == "M"
      slmc.get_gender_from_search_results.should == "Male"
    else
      slmc.get_gender_from_search_results.should == "Female"
    end

    slmc.get_birthday_from_search_results.should == Date.strptime(@or_patient1[:birth_day],'%m/%d/%Y').strftime("%b-%d-%Y")
    age = slmc.compute_age(Date.parse(@or_patient1[:birth_day]))
    slmc.get_age_from_search_results.should == "#{age} year/s"
    slmc.get_admission_status_from_search_results.should == "Not Admitted"
  end

  it "Clicking Admitted Patient Check Box should display Admitted Patients Only" do
    slmc.admission_advance_search(
      :admitted => true,
      :pin => "1011"
    ).should be_true
    admission_status = []
    sleep 2
    rows = slmc.get_css_count('css=table[id="results"] tbody tr')
    rows.times do |row|
      admission_status << slmc.get_text("//html/body/div/div[2]/div[2]/div[21]/table/tbody/tr[#{row + 1}]/td[8]")
    end
    admission_status.each do |stat|
      stat.should_not == "Not Admitted"
    end
  end

  it "Clicking Admitted Patient Checkbox should display - PIN, Last Name, First Name, Middle Name, Gender, Date of Birth, Computed Age, Nursing Unit, Room Bed, Admission Date/Time" do
    expected_headers = [" ","Confinement No", "PIN", "Full Name", "Gender", "Birth Date", "Age", "Admission Status", "Nursing Unit", "Room/Bed Number", "Date of Admission", "Actions" ]
    actual_headers = slmc.get_text('css=table[id="results"] tr[class="odd"]')
    expected_headers.each do |header|
      actual_headers.include? header
    end
  end

  it "Unclicking Admitted Patient Checkbox should display ALL patients - Admitted and Not Admitted" do
    slmc.admission_advance_search(:pin => "test").should be_true#has been change searching for incomplete pin will show NO PATIENT FOUND alert.
    admission_status = []
    sleep 2
    rows = slmc.get_css_count('css=table[id="results"] tbody tr')
    rows.times do |row|
      #admission_status << slmc.get_text("//html/body/div/div[2]/div[2]/div[23]/table/tbody/tr[#{row + 1}]/td[8]") #mpi is off
      admission_status << slmc.get_text("//table[@id='results']/tbody/tr[#{row + 1}]/td[9]") #mpi is on
    end
    admission_status.include? "Not Admitted"
    admission_status.include? "Outpatient Registration"
    admission_status.include? "Inpatient Admission"
  end

  it "Should notify the user if there is no data that was encoded in the search box" do
    slmc.admission_search(:pin => "").should == "Enter a pin or lastname."
  end

  it "Should display search parameters in Advanced Search page" do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.click_advanced_search
    slmc.verify_advanced_search_fields.should be_true
  end

  it "Should validate maximum input characters for firstname/middlename search - 30 Alpha Characters " do
      sleep 8
      (slmc.is_element_present"fName").should be_true
      (slmc.is_element_present"mName").should be_true
#      ((slmc.get_attribute("fName@maxlength")).to_i).should == 30
#      ((slmc.get_attribute("mName@maxlength")).to_i).should == 30
  end

  it "Verify advanced search result details for the patient that matched the entered Last name or Firstname " do
    slmc.admission_advance_search(
      :last_name => @or_patient1[:last_name],
      :first_name => @or_patient1[:first_name],
      :gender => @or_patient1[:gender]
    ).should be_true

    (slmc.get_text(Locators::Admission.admission_reg_pin)).gsub(' ','').should == @@pin
    slmc.get_reg_name_from_search_results.should == "#{@or_patient1[:last_name].upcase}, #{@or_patient1[:first_name]} #{@or_patient1[:middle_name]}"

    if @or_patient1[:gender] == "M"
      slmc.get_gender_from_search_results.should == "Male"
    else
      slmc.get_gender_from_search_results.should == "Female"
    end

    slmc.get_birthday_from_search_results.should == Date.strptime(@or_patient1[:birth_day],'%m/%d/%Y').strftime("%b-%d-%Y")
    age = AdmissionHelper.calculate_age(Date.parse(@or_patient1[:birth_day]))
    slmc.get_age_from_search_results.should == "#{age} year/s"
    slmc.get_admission_status_from_search_results.should == "Not Admitted"
  end

  it "Search results page should be able to display maximum of 20 patients per page" do
    slmc.admission_search(:pin => Time.now.strftime("%y%m"))
    slmc.get_css_count("css=#results>tbody>tr").should == 20 # expected 1 if MPI is on
  end

  it "After successful search, user should be able to choose to start a new search, or access links for Update Patient, Admit patient or cancel admission" do
    slmc.admission_search(:pin => @@pin)
    slmc.verify_admission_fields.should be_true
    sleep 1
    slmc.get_text(Locators::Admission.admission_reg_actions_column).should == "Update Patient Info \n Admit Patient \n View Confinement History \n Tag for MPI Consolidation"
  end

  it "Should prompt a system message “No Record found” and shall allow the user to start a new search or Create New Patient" do
    slmc.admission_search(:pin => "1f", :no_result => true).should == "NO PATIENT FOUND"
  end

  it "Verify that Title, Suffix, Degree, Gender, Place of Birth, Country of Birth, Civil Status, Race, Nationality, Citizenship and Religion should be in drop down box" do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.patient_pin_search(:pin => "test")
    slmc.click_create_patient_record.should be_true

    @expected_dropdown_fields = ["Title", "Suffix", "Gender *","Country of Birth", "Civil Status", "Race", "Nationality", "Citizenship*", "Religion"]
    @@actual_dropdown_fields = slmc.get_fields_and_labels_by_type("dropdown")

    @expected_dropdown_fields.each { |dropdown| @@actual_dropdown_fields.has_value? dropdown }
  end

  it "Should enable user to select value parameter in the drop down box provided" do
    @@actual_dropdown_fields.each_key do |dropdown|
      label = slmc.get_text("css=select[id='#{dropdown}'] option:nth-child(2)")
      slmc.select "#{dropdown}", "label=#{label}"
    end
  end

  it "Validates 30 as maximum number of character for the Last Name, First Name and Middle Name" do
    slmc.type "name.lastName", "1234567890 1234567890 1234567890 1234567890 12345"
    slmc.get_value("name.lastName").length.should == 30
    slmc.type "name.firstName", "1234567890 1234567890 1234567890 1234567890 12345"
    slmc.get_value("name.firstName").length.should == 30
    slmc.type "name.middleName", "1234567890 1234567890 1234567890 1234567890 12345"
    slmc.get_value("name.middleName").length.should == 30
  end

  it "Should automatically compute and display the age of the patient when VALID DOB in entered" do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.patient_pin_search(:pin => @@pin).should be_true
    age = AdmissionHelper.calculate_age(Date.parse(@or_patient1[:birth_day]))
    #age = Date.today.year - Date.strptime(@or_patient1[:birth_day], '%m/%d/%Y').year
    slmc.get_text(Locators::Admission.admission_reg_search_results_age).gsub(" year/s","").should == age.to_s
  end
#is not available on 1.4
  it "Validates that CITY, PROVINCE, COUNTRY AND POSTAL CODE fields are in look-up value Function under Present Address field" do
    @@actual_dropdown_fields.has_value? "City"
    @@actual_dropdown_fields.has_value? "Country"
  end

  it "Should display list of values for City, Province, Country or Postal Code when the look-up button is clicked." do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.click_update_patient_info.should be_true
    slmc.get_select_options("presentAddrCitySelect").empty?.should be_false
    slmc.get_select_options("presentAddrCountry").empty?.should be_false
  end

  it "Should display selected value for City, Province, Country or Postal Code in the textbox provided in the Patient Registration page" do
    slmc.get_value('presentAddrNumStreet').should == @or_patient1[:address]
    slmc.get_selected_label('presentAddrCountry').should == @country
  end

  it "Permanent Address field should be in checkbox form" do
    checkboxes = slmc.get_fields_and_labels_by_type("checkbox")
    checkboxes.include? "chkFillPermanentAddress" # field id for 'Permanent Address Same As Present Address'
  end

  it "Should copy details on Present Address when permanent address checkbox is mark" do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.patient_pin_search(:pin => "test")
    slmc.click_create_patient_record.should be_true
    slmc.fill_out_patient_record(@or_patient2)
    if slmc.get_value('chkFillPermanentAddress') == "on"
      slmc.get_value('permanentAddrNumStreet').should == @or_patient2[:address]
      #slmc.get_selected_label('permanentAddrCitySelect').should == @or_patient2[:city]
      slmc.get_selected_label('permanentAddrCountry').should == @country
    else
      slmc.click_permanent_address_same_as_present_address
      slmc.get_value('permanentAddrNumStreet').should == @or_patient2[:address]
      #slmc.get_selected_label('permanentAddrCitySelect').should == @or_patient2[:city]
      slmc.get_selected_label('permanentAddrCountry').should == @country
    end
  end

  it "System shall enable user to input details for Permanent Address when the checkbox is unmark" do
    if slmc.get_value('chkFillPermanentAddress') == "on"
      slmc.click_permanent_address_same_as_present_address #to unmark
      slmc.get_value('permanentAddrNumStreet').should == ""
      slmc.get_value('permanentAddrCitySelect').should == ""
      slmc.get_selected_label('permanentAddrCountry').should == @country
    else
      slmc.get_value('permanentAddrNumStreet').should == ""
      slmc.get_value('permanentAddrCitySelect').should == ""
      slmc.get_selected_label('permanentAddrCountry').should == @country
    end
  end

  it "CITY, PROVINCE, COUNTRY AND POSTAL CODE fields are in look-up value Function under Permanent Address field" do
    @@actual_dropdown_fields = slmc.get_fields_and_labels_by_type("dropdown")
    @@actual_dropdown_fields.has_value? "City"
    @@actual_dropdown_fields.has_value? "Country"
  end

  it "Should display list of values for City, Province, Country or Postal Code when the look-up button is clicked." do
    slmc.get_select_options("permanentAddrCitySelect").empty?.should be_false
    slmc.get_select_options("permanentAddrCountry").empty?.should be_false
  end

  it "Should display selected value for City, Province, Country or Postal Code in the textbox provided in the Patient Registration page" do
    if slmc.get_value('chkFillPermanentAddress') == "on"
      slmc.get_value('permanentAddrNumStreet').should == @or_patient2[:address]
      slmc.get_selected_label('permanentAddrCountry').should == @country
    else
      slmc.click_permanent_address_same_as_present_address
      slmc.get_value('permanentAddrNumStreet').should == @or_patient2[:address]
      slmc.get_selected_label('permanentAddrCountry').should == @country
    end
  end

  it "Input field for Contact Type, Primary Language and Secondary Language should be in drop down box" do
    @@actual_dropdown_fields.has_value? "Contact Type"
    @@actual_dropdown_fields.has_value? "Primary Language"
    @@actual_dropdown_fields.has_value? "Secondary Language"
  end

  it "Clicking SAVE should display confirmation message for registration" do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.patient_pin_search(:pin => "test")
    slmc.click_create_patient_record.should be_true
    slmc.fill_out_patient_record(@or_patient2)
    slmc.save_patient_record.should == "Patient information saved."
  end

  it "Clicking CANCEL should disregard entered data in the Patient Registration page" do
    slmc.cancel_patient_registration.should be_true
  end

  it "System shall not allow saving when mandatory fields are not filled out" do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.click_register_patient.should be_true
    slmc.go_to_preview_page.should be_false
  end

  it "System shall display message alert when mandatory fields are not filled out" do
    slmc.get_text("admission.errors").should == "Account Class is a required field.\nDiagnosis Date is a required field.\nRoom is a required field.\nBed is a required field.\nDoctor is a required field."
  end

  it "Clicking PREVIEW should display Preview Page" do
    slmc.fill_out_patient_admission
    slmc.type "//html/body/div/div[2]/div[2]/form/div[5]/div[2]/div/input",Time.now.strftime("%m/%d/%Y")
    slmc.go_to_preview_page#.should be_true
  end

  it "System shall display all patient’s details in the Preview page" do
    slmc.is_text_present(@or_patient1[:lastname]).should be_true
    slmc.is_text_present(@or_patient1[:firstname]).should be_true
    slmc.is_text_present("Room Location").should be_true
    slmc.is_text_present("Chief Complaint").should be_true
    slmc.is_text_present("Consultant").should be_true
    slmc.is_text_present("Person / Party Responsible for this Account").should be_true
  end

  it "System shall display REVISE and SAVE PATIENT in the Preview  page" do
    slmc.is_element_present(Locators::NursingSpecialUnits.revise_button).should be_true
    slmc.is_element_present(Locators::NursingSpecialUnits.admin_reg_save_button).should be_true
  end

  it "Clicking REVISE should enable user to edit previewed details and Patient Registration page shall be displayed again for encoding" do
    slmc.revise_admission.should be_true
  end

  it "System shall display confirmation message after saving data" do
    slmc.go_to_preview_page#.should be_true
    slmc.click_save_admission.should be_true
  end

  it "Clicking UPDATE PATIENT from the Result List of the Patient Search page should display registration page" do
    slmc.admission_search(:pin => @@pin)
    slmc.click_update_patient.should be_true
  end

  it "Registration page should display CANCEL, PREVIEW and CREATE NEW ADMISSION button in the Patient Registration page" do
    slmc.is_element_present(Locators::Admission.cancel).should be_true
    slmc.is_element_present(Locators::Admission.preview).should be_true
    slmc.is_element_present(Locators::Admission.create_new_admission).should be_true
  end

  it "Clicking CREATE NEW PATIENT should display the Patient Registration page" do
    slmc.go_to_admission_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_create_new_patient_link.should be_true
  end

  it "Registration form - Should not proceed saving when mandatory fields are not filled out" do
    slmc.click_create_new_admission_button.should == "First Name is a required field.\nMiddle Name is a required field.\nGender is a required field.\nBirthdate is a required field.\nPlace of Birth is a required field.\nCivil Status is a required field.\nEmployer Address is a required field.\nPresent Contact is a required field.\nOccupation is a required field.\nEmployer is a required field.\nPerson to Notify is a required field."
  end

  it "Should display confirmation message for registration when CREATE NEW ADMISSION BUTTON is click" do
    slmc.fill_out_registration_form(@or_patient2.merge(:birth_day => Date.today.strftime("%m/%d/%Y"))).should == "Patient successfully saved."
    @@pin2 = slmc.get_text(Locators::Registration.pin)
  end

  it "Admission form - Should not proceed saving when mandatory fields are not filled out" do
    slmc.get_alert if slmc.is_alert_present
    slmc.click "//input[@value='Create New Admission']", :wait_for => :page
    slmc.go_to_preview_page.should be_false
    slmc.get_text("errorMessages").should == "Account Class is a required field.\nRoom Charge is a required field.\nMobility Status is a required field.\nPerson/Party Responsible for this Account Name is a required field.\nPerson/Party Responsible for this Account Telephone Number is a required field.\nPerson/Party Responsible for this Account Address is a required field.\nRoom is a required field.\nBed is a required field.\nDiagnosis is a required field.\nDoctor is a required field."
  end

  it "Should enable user to edit / modify patient details in the Patient Registration page" do
    slmc.admission_search(:pin => @@pin2)
    slmc.click_update_patient.should be_true
    slmc.fill_out_registration_form(@or_patient2.merge(:last_name => "lname" + Date.today.strftime("%m_%d_%Y"), :first_name => "fname" + Date.today.strftime("%m_%d_%Y"))).should == "Patient successfully saved."
  end

  it "Clicking UPDATE ADMISSION should display admission details to modify in the Admission page" do
    slmc.admission_search(:pin => @@pin2)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE",
      :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
    slmc.admission_search(:pin => @@pin2)
    slmc.click_update_admission.should be_true
  end

  it "Should display CANCEL ADMISSION, CANCEL AND PREVIEW BUTTON in the Admission page" do
    slmc.is_element_present(Locators::Admission.preview_reg_action).should be_true
    slmc.is_element_present(Locators::Admission.cancel_admission).should be_true
    slmc.is_element_present(Locators::Admission.cancel).should be_true
  end

  #example is not applicable anymore in v1.4 due to change of room. changing of room is not allowed anymore
#  it "Should enable user to modify / edit admission details" do
#    slmc.fill_out_admission_form(:account_class => "Select Class", :diagnosis => "ULCER", :doctor_code => "6726")
#  end
#
#  it "Should have indication for mandatory fields to be filled out" do
#    slmc.go_to_preview_page.should be_false
#    slmc.get_text("errorMessages").should == "Account Class is a required field.\nAccount Class passed for validation is null..admissionBean"
#  end
#
#  it "Should enable user to edit / modify patient admission details in the Admission page." do
#    slmc.admission_search(:pin => @@pin2)
#    slmc.click_update_admission.should be_true
#    slmc.fill_out_admission_form(:account_class => "INDIVIDUAL", :diagnosis => "STROKE", :doctor_code => "0126")
#    slmc.go_to_preview_page.should be_true
#    slmc.is_text_present("INDIVIDUAL")
#    slmc.is_text_present("STROKE")
#    slmc.is_text_present("0126")
#  end
#
#  it "Clicking Cancel should disregard entered data / modify data in the Admission page" do
#    slmc.click_revise_admission.should be_true
#    slmc.click "//input[@value='Cancel']", :wait_for => :page
#    slmc.get_text("breadCrumbs").should == "Admission"
#  end
#
#  it "Clicking PREVIEW button should display REVISE, SAVE ADMISSION and SAVE and PRINT ADMISSION in the Preview page." do
#    slmc.admission_search(:pin => @@pin2)
#    slmc.click_update_admission.should be_true
#    slmc.fill_out_admission_form(:diagnosis => "STROKE")
#    slmc.go_to_preview_page.should be_true
#    slmc.is_element_present(Locators::Admission.revise).should be_true
#    slmc.is_element_present(Locators::Admission.save_admission).should be_true
#    slmc.is_element_present(Locators::Admission.save_and_print_admission).should be_true
#  end
#
#  it "Should display confirmation message for admission record when Save BUTTON is click" do
#    slmc.save_admission.should == "Patient admission details successfully saved."
#  end

end