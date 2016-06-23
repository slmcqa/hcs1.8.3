require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: ARMS RR Module Test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
#    @selenium_driver.evaluate_rooms_for_admission('0295', 'RCH08')
    @user = 'arms_spec_user'
    @medical_user = 'medical1'
    @password = "123qweuser"
    @items = {"010002461" => {:desc => "VECTORCARDIOGRAPHY", :code => "0076"},
                      "010000823" => {:desc => "HIV ½ ANTIBODY SCREENING TEST", :code => "0060"},
                      "010001672" => {:desc => "ECG - ELECTROCARDIOGRAPHY", :code => "0076"} }
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

 it "Creates new gu patient and performs clinical ordering for non-confidential patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@gu_pin = slmc.create_new_patient(Admission.generate_data.merge(:gender => 'M')).gsub(' ','')
    slmc.admission_search(:pin => @@gu_pin)#.should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0295', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.search_order(:ancillary => true, :description => "010002461").should be_true
    sleep 2
    slmc.add_returned_order(:ancillary => true, :description => @items["010002461"][:desc], :add => true).should be_true
    slmc.search_order(:ancillary => true, :description => "010000823").should be_true
    sleep 2
    slmc.add_returned_order(:ancillary => true, :description => @items["010000823"][:desc], :add => true).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
  end

 it "Creates new gu patient and performs clinical ordering for confidential patient" do
    slmc.admission_search(:pin => "test")#.should be_true
    @@gu_pin1 = slmc.create_new_patient(Admission.generate_data.merge(:gender => 'M')).gsub(' ','')
    slmc.admission_search(:pin => @@gu_pin1)#.should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0295', :diagnosis => "GASTRITIS", :confidentiality => true).should == "Patient admission details successfully saved."
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin1)
    slmc.search_order(:ancillary => true, :description => "010002461").should be_true
    slmc.add_returned_order(:ancillary => true, :description => @items["010002461"][:desc], :add => true).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Sets the arms user to same org code of ancillary" do
    slmc.login('exist',"123qweadmin").should be_true
    slmc.modify_user_credentials(:user_name => "armsdastech1", :org_code => @items["010002461"][:code]).should be_true
  end

  it"Non-confidential patient - non-confidential result tag as official" do
    slmc.login("armsdastech1", @password).should be_true
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    slmc.click_results_data_entry
    slmc.type 'PARAM::007600000000008::MAGNITUDE_VALUE','test'
    (slmc.get_value 'PARAM::007600000000008::MAGNITUDE_VALUE').should == 'test'
    slmc.click '//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'
    slmc.is_checked'//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'.should be_true
    slmc.assign_signatory(:one => true, :code1 => "0209139")
    slmc.assign_signatory(:two => true, :code2 => "7099")
    slmc.save_signatories.should be_true
    sleep 5
    slmc.patient_banner_content.should be_true
    sleep 10
    slmc.queue_for_validation.should be_true
    sleep 1
    slmc.validate_result(:validate => true, :username => "dasdoc5", :password => "123qweuser").should be_true
    sleep 20
    slmc.tag_official_result(:validate => true)
    sleep 10
  end

  it"Bug#27830 - [ARMS] Unable to view official test result, returns - Result not available in the Repository" do
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    slmc.results_retrieval
    sleep 10
    (slmc.is_text_present"Result Not Available in the Repository.").should be_false
    (slmc.is_element_present"errorMessages").should be_false
    sleep 10
    slmc.is_element_present"reportFileDiv".should be_true
    slmc.is_visible'//input[@type="checkbox"]'.should be_true
  end

  it"Confidential patient tag as official" do
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin1)
    slmc.click_results_data_entry
    slmc.type 'PARAM::007600000000008::MAGNITUDE_VALUE','test'
    (slmc.get_value 'PARAM::007600000000008::MAGNITUDE_VALUE').should == 'test'
    slmc.click '//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'
    slmc.is_checked'//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'.should be_true
    slmc.assign_signatory(:one => true, :code1 => "0209139")
    slmc.assign_signatory(:two => true, :code2 => "7099")
    slmc.save_signatories.should be_true
    sleep 10
    slmc.queue_for_validation.should be_true
    sleep 1
    slmc.validate_result(:validate => true, :username => "dasdoc5", :password => "123qweuser").should be_true
    sleep 10
    slmc.tag_official_result(:validate => true)
    sleep 10
    slmc.patient_banner_content.should be_true
  end

  it"Non-confidential patient - confidential result tag as official" do
    slmc.login('exist',"123qweadmin").should be_true
    slmc.modify_user_credentials(:user_name => "armsdastech1", :org_code => @items["010000823"][:code]).should be_true
    slmc.login("armsdastech1", @password).should be_true
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    slmc.click_results_data_entry
    slmc.select'COMMON_PARAM::TR::SPECIMEN','index=1'
    slmc.assign_signatory(:one => true, :code1 => "0209139")
    slmc.assign_signatory(:two => true, :code2 => "7099")
    slmc.save_signatories.should be_true
    sleep 10
    slmc.queue_for_validation.should be_true
    slmc.validate_result(:validate => true, :username => "dasdoc5", :password => "123qweuser").should be_true
    sleep 10
    slmc.tag_official_result(:validate => true)
    sleep 10
    slmc.patient_banner_content.should be_true
  end

  it "On Load of system login" do
    slmc.login("dasnondoc5",@password).should be_true
    slmc.go_to_doctor_non_ancillary
    slmc.is_text_present"PIN/Patient's Last Name:".should be_true
    slmc.is_element_present'//input[@type="submit" and @value="Search"]'.should be_true
  end

  it "User Searches patient Criteria: Valid PIN" do
    slmc.search_non_doc_document(:pin => @@gu_pin).should == @@gu_pin
  end

  it "User Searches patient Criteria: Valid Last Name" do
    @@name=slmc.get_table'results.1.2'
    @@name = @@name.scan(/\w+/)
    slmc.search_non_doc_document(:pin => @@name[0]).should == @@name[0]
    slmc.is_element_present'css=#results>tbody>tr'.should be_true
  end

  it "User Searches patient Criteria: InValid PIN" do
    #slmc.get_text("css=#results>tbody>tr>td").should=="Not Found, 0 Items to display"
    @@pin=@@gu_pin.gsub("1","9")
    slmc.search_non_doc_document(:pin => @@pin, :no_result=>true).should be_true
  end

  it "User Searches patient Criteria: InValid Last Name" do
    sleep 1
    slmc.search_non_doc_document(:pin => @@name[0]+"!!!!@@@@", :no_result=>true).should be_true
  end

  it "User Searches patient Criteria: InValid First Name" do
    slmc.search_non_doc_document(:pin => @@name[1]+"!!!!@@@@", :no_result=>true).should be_true
  end

  it "User Searches patient Criteria: InValid MIddle Name" do
    slmc.search_non_doc_document(:pin => @@name[2]+"!!!!@@@@", :no_result=>true).should be_true
  end

  it"User selects patients from the lists" do
    slmc.search_non_doc_document(:pin => @@gu_pin).should == @@gu_pin
  end

  it"User clicks on non-confidential patient" do
    slmc.click"css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for => :page
    slmc.patient_banner_content.should be_true
  end

  it"User clicks on the Procedure Name link of a confidential patient" do
    slmc.go_to_doctor_non_ancillary
    sleep 2
    slmc.search_non_doc_document(:pin => @@gu_pin1).should == @@gu_pin1
    slmc.click"css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for => :page
    slmc.patient_banner_content.should be_true
    slmc.click"css=#patientSearchResult>tbody>tr.even>td:nth-child(2)>a"
    slmc.is_alert_present
    slmc.get_alert.should == "Your current role does not allow you to view the result. Patient is Confidential"
    sleep 4
 end

  it"User clicks on the Procedure Name link of a non- confidential patient" do
    slmc.go_to_doctor_non_ancillary
    sleep 4
    slmc.search_non_doc_document(:pin => @@gu_pin).should == @@gu_pin
    slmc.click"css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for => :page
    slmc.patient_banner_content.should be_true
    slmc.click"css=#patientSearchResult>tbody>tr.odd>td:nth-child(2)>a"
    sleep 5
    slmc.is_element_present"reportFileDiv".should be_true
    sleep 5
 end

  it"Search Criteria: Valid Exam Date/Range" do
    slmc.go_to_doctor_non_ancillary
    slmc.search_non_doc_document(:pin => @@gu_pin).should == @@gu_pin
    sleep 7
    slmc.click"css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for => :page
    slmc.patient_banner_content.should be_true
    sleep 2
    slmc.result_list_advanced_search(:exam_date=>true, :date=>Time.now.strftime("%m/%d/%Y"))
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"Search Criteria: Valid Procedure/Test" do
    slmc.result_list_advanced_search(:procedure=>true, :procedure_name=>"Vectorcardiography")
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"Search Criteria: Valid Performing DAS Unit" do
    slmc.result_list_advanced_search(:performing_unit=>true, :unit=>"ECG AND HOLTER")
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"Search Criteria:Valid Requesting Date range" do
    slmc.result_list_advanced_search(:requesting_date=>true, :date=>Time.now.strftime("%m/%d/%Y"))
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"Search Criteria:Invalid Exam Date/Range" do
    slmc.result_list_advanced_search(:exam_date=>true, :date=>(Date.today+5).strftime("%m/%d/%Y"))
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"Search Criteria: Invalid Procedure/Test" do
    slmc.result_list_advanced_search(:procedure=>true, :procedure_name=>"ALDOSTERONE")
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"Search Criteria: Invalid Performing DAS Unit" do
    slmc.result_list_advanced_search(:performing_unit=>true, :unit=>"PHARMACY")
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"Search Criteria: InValid Requesting Date range" do
    slmc.result_list_advanced_search(:requesting_date=>true, :date=>(Date.today+5).strftime("%m/%d/%Y"))
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"User clicks on official confidential test of a non - confidential patient" do
    slmc.go_to_doctor_non_ancillary
    slmc.search_non_doc_document(:pin => @@gu_pin).should == @@gu_pin
    slmc.click"css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for=>:page
    slmc.patient_banner_content.should be_true
    slmc.click"css=#patientSearchResult>tbody>tr.even>td:nth-child(2)>a"
    sleep 2
    slmc.get_alert.should == "Your current role does not allow you to view the result. Document is Confidential"
  end

  it "On Load of the Nursing Units" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    contents=slmc.get_text"occupancyList".should be_true
    contents.include?("Room/Bed No.").should be_true
    contents.include?("PIN").should be_true
    contents.include?("Patient Name").should be_true
    contents.include?("Status").should be_true
    contents.include?("Action").should be_true
    slmc.is_element_present'//select[@name="action"]'.should be_true
    slmc.is_element_present'//input[@type="button" and @value="Submit"]'.should be_true
  end

  it"User Searches patient - Criteria: Valid PIN" do
    slmc.patient_pin_search(:pin => @@gu_pin).should be_true
  end

  it"Valid Last Name-general units" do
    @@name=slmc.get_table'occupancyList.1.3'
    @@name = @@name.scan(/\w+/)
    slmc.patient_pin_search(:pin => @@name[0]).should be_true
  end

  it "InValid PIN-general units" do
    slmc.patient_pin_search(:pin => @@pin, :no_result=>true).should be_true
  end

  it "InValid Last Name-general units" do
    slmc.patient_pin_search(:pin => @@name[0]+"!@#!@", :no_result=>true).should be_true
    #slmc.get_text("css=#occupancyList>tbody>tr>td").should=="Not Found, 0 Items to display"
  end

  it "InValid First Name-general units" do
    slmc.patient_pin_search(:pin => @@name[1]+"!@!@!@", :no_result=>true).should be_true
  end

  it "InValid MIddle Name-general units" do
    slmc.patient_pin_search(:pin => @@name[2]+"!@!@!@", :no_result=>true).should be_true
  end

  it"User selects patients from the list-general units" do
    slmc.patient_pin_search(:pin => @@gu_pin).should be_true
  end

  it"User selects patient by choosing Patient Results from the drop - down Actions list, then clicks SUBMIT button" do
    slmc.go_to_patient_result_page(:pin => @@gu_pin)
    slmc.patient_banner_content.should be_true
  end

  it"patient result content" do
    contents=slmc.get_text"patientSearchResult"
    contents.include?("Exam Date").should be_true
    contents.include?("Procedure Name").should be_true
    contents.include?("Performing Unit").should be_true
    contents.include?("CI Number").should be_true
    contents.include?("Date Requested").should be_true
    contents.include?("Date/Time Tagged as Official").should be_true
  end

  it"User selects a confidential patient" do
    slmc.go_to_general_units_page
    slmc.go_to_patient_result_page(:pin => @@gu_pin1)
    slmc.is_alert_present
    slmc.get_alert.should =="Patient is confidential!"
  end

  it"user selects a non-confidential patient - Criteria: Valid Exam Date/Range" do
    slmc.go_to_general_units_page
    slmc.go_to_patient_result_page(:pin => @@gu_pin)
    slmc.result_list_advanced_search(:exam_date=>true, :date=>Time.now.strftime("%m/%d/%Y"))
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"user selects a non-confidential patient - Criteria: Valid Procedure/Test" do
    slmc.result_list_advanced_search(:procedure=>true, :procedure_name=>"Vectorcardiography")
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"user selects a non-confidential patient - Criteria: Valid Performing DAS Unit" do
    slmc.result_list_advanced_search(:performing_unit=>true, :unit=>"ECG AND HOLTER")
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"user selects a non-confidential patient - Criteria: Valid Requesting Date range" do
    slmc.result_list_advanced_search(:requesting_date=>true, :date=>Time.now.strftime("%m/%d/%Y"))
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"user selects a non-confidential patient - Criteria: Invalid Exam Date/Range" do
    slmc.result_list_advanced_search(:exam_date=>true, :date=>(Date.today+5).strftime("%m/%d/%Y"))
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"user selects a non-confidential patient - Criteria: Invalid Procedure/Test" do
    slmc.result_list_advanced_search(:procedure=>true, :procedure_name=>"ALDOSTERONE")
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"user selects a non-confidential patient - Criteria: Invalid Performing DAS Unit" do
    slmc.result_list_advanced_search(:performing_unit=>true, :unit=>"PHARMACY")
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"user selects a non-confidential patient - Criteria: InValid Requesting Date range" do
    slmc.result_list_advanced_search(:requesting_date=>true, :date=>(Date.today+5).strftime("%m/%d/%Y"))
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"The Results list page is displayed" do
    slmc.go_to_general_units_page
    slmc.go_to_patient_result_page(:pin => @@gu_pin)
    slmc.is_element_present("css=#patientSearchResult>tbody>tr").should be_true
  end

  it"User clicks on the Procedure Name  link of a non- confidential patient" do
    slmc.click"css=#patientSearchResult>tbody>tr.odd>td:nth-child(2)>a", :wait_for => :page
    sleep 3
    slmc.is_element_present"reportFileDiv".should be_true
  end

  it"User clicks on Confidential result of a non-confidential patient" do
    slmc.go_to_general_units_page
    slmc.go_to_patient_result_page(:pin => @@gu_pin)
    slmc.click"css=#patientSearchResult>tbody>tr.even>td:nth-child(2)>a"
    slmc.get_alert.should=="Document is Confidential"
 end

  it "On Load of the Nursing Special Units Occupancylist Page" do
    slmc.arms_special_units
    slmc.special_units_headings.should be_true
  end

  it"User Searches patient  -Criteria: Valid PIN" do
    slmc.patient_pin_search(:pin => @@gu_pin).should be_true
  end

  it"User Searches patient -Criteria: Valid Last Name" do
    @@name=slmc.get_text("css=#occupancyList>tbody>tr>td:nth-child(4)")
    @@name = @@name.scan(/\w+/)
    slmc.patient_pin_search(:pin => @@name[0]).should be_true
  end
#v1.4 changes
   it "User Searches patient -Criteria:Valid First Name" do
    slmc.patient_pin_search(:pin => @@name[1])
    slmc.is_text_present("NO PATIENT FOUND").should be_true
  end

  it"User Searches patient -Criteria:Valid Middle Name" do
    slmc.patient_pin_search(:pin => @@name[2])
    #slmc.is_text_present("NO PATIENT FOUND").should be_true
    ((slmc.get_text"css=#occupancyList>tbody>tr.even>td:nth-child(3)").gsub(' ','')).should_not == @@gu_pin
  end

  it "User Searches patient -Criteria:InValid PIN" do
    slmc.patient_pin_search(:pin => @@pin, :no_result=>true).should be_true
  end

  it "User Searches patient -Criteria:InValid Last Name" do
    slmc.patient_pin_search(:pin => @@name[0]+"_", :no_result=>true).should be_true
    #slmc.get_text("css=#occupancyList>tbody>tr>td").should=="Not Found, 0 Items to display"
  end

  it "User Searches patient -Criteria:InValid First Name" do
    slmc.patient_pin_search(:pin => @@name[1]+"_", :no_result=>true).should be_true
  end

  it "User Searches patient -Criteria:InValid MIddle Name" do
    slmc.patient_pin_search(:pin => @@name[2]+"_", :no_result=>true).should be_true
  end

  it"User selects a confidential patient" do
    slmc.arms_special_units
    slmc.arms_result_page(:pin => @@gu_pin)
    sleep 2
    slmc.click"css=#patientSearchResult>tbody>tr.even>td:nth-child(2)>a"
    slmc.get_alert.should=="Document is Confidential"
    sleep 4
  end

  it"User selects a non-confidential patient" do
    slmc.arms_special_units
    slmc.arms_result_page(:pin => @@gu_pin)
    sleep 2
  end

  it"Search Criteria: Valid Exam Date/Range" do
    slmc.result_list_advanced_search(:exam_date=>true, :date=>Time.now.strftime("%m/%d/%Y"))
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"Search Criteria: Valid Procedure/Test" do
    slmc.result_list_advanced_search(:procedure=>true, :procedure_name=>"Vectorcardiography")
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"Search Criteria: Valid Performing DAS Unit" do
    slmc.result_list_advanced_search(:performing_unit=>true, :unit=>"ECG AND HOLTER")
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"Search Criteria: Valid Requesting Date range" do
    slmc.result_list_advanced_search(:requesting_date=>true, :date=>Time.now.strftime("%m/%d/%Y"))
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"Search Criteria: Invalid Exam Date/Range" do
    slmc.result_list_advanced_search(:exam_date=>true, :date=>(Date.today+5).strftime("%m/%d/%Y"))
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"Search Criteria: Invalid Procedure/Test" do
    slmc.result_list_advanced_search(:procedure=>true, :procedure_name=>"ALDOSTERONE")
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"Search Criteria: Invalid Performing DAS Unit" do
    slmc.result_list_advanced_search(:performing_unit=>true, :unit=>"PHARMACY")
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"Search Criteria: InValid Requesting Date range" do
    slmc.result_list_advanced_search(:requesting_date=>true, :date=>(Date.today+5).strftime("%m/%d/%Y"))
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"The Results list page is displayed" do
    slmc.arms_special_units
    slmc.arms_result_page(:pin => @@gu_pin)
    sleep 2
    slmc.is_element_present("css=#patientSearchResult>tbody>tr").should be_true
  end

  it"User clicks on the Procedure Name  link of a non- confidential patient" do
    slmc.click"css=#patientSearchResult>tbody>tr.odd>td:nth-child(2)>a", :wait_for => :page
    sleep 3
    slmc.is_element_present"reportFileDiv".should be_true
  end

  it"User clicks on Confidential result of a non-confidential patient" do
    slmc.arms_special_units
    slmc.arms_result_page(:pin => @@gu_pin)
    sleep 2
    slmc.click"css=#patientSearchResult>tbody>tr.even>td:nth-child(2)>a"
    slmc.get_alert.should=="Document is Confidential"
 end

  it "On Load of the Medical Records Page - 1" do
    slmc.login(@medical_user, @password).should be_true
    slmc.go_to_medical_records
    slmc.is_element_present"param".should be_true
    slmc.is_element_present"search".should be_true
    slmc.is_text_present"PIN/Patient's Last Name:".should be_true
  end

  it "On Load of the Medical Records Page - 2" do
    slmc.medical_search(:pin => @@gu_pin).should == @@gu_pin
    slmc.medical_contents.should be_true
  end

  it"User Searches patient (Medical Records) - Criteria: Valid PIN" do
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@gu_pin).should == @@gu_pin
  end

  it"User Searches patient (Medical Records) - Criteria: Valid Last Name" do
    @@name=slmc.get_table'results.1.2'
    @@name=@@name.scan(/\w+/)
    slmc.medical_search(:pin => @@name[0]).should == @@name[0]
  end

  it"User Searches patient (Medical Records) - Criteria: InValid PIN" do
    slmc.medical_search(:pin => @@pin, :no_result=>true).should be_true
  end

  it"User Searches patient (Medical Records) - Criteria:InValid Last Name" do
    slmc.medical_search(:pin => @@name[0]+"!!!!@@@", :no_result=>true).should be_true
  end

  it"User Searches patient (Medical Records) - Criteria:InValid First Name" do
    slmc.medical_search(:pin => @@name[1]+"!!!!@@@", :no_result=>true).should be_true
  end

  it"User Searches patient (Medical Records) - Criteria:InValid MIddle Name" do
    slmc.medical_search(:pin => @@name[2]+"!!!!@@@", :no_result=>true).should be_true
  end

  it"User selects a confidential patient (Medical Records)" do
    slmc.medical_search(:pin => @@gu_pin1).should == @@gu_pin1
    slmc.click"css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for=>:page
    slmc.patient_banner_content.should be_true
    slmc.click"css=#patientSearchResult>tbody>tr.even>td:nth-child(2)>a"
    slmc.is_alert_present
    slmc.get_alert.should=="Your current role does not allow you to view the result. Patient is Confidential"
  end

  it"User selects a non-confidential patient (Medical Records)" do
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@gu_pin).should == @@gu_pin
    slmc.click"css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for=>:page
    slmc.patient_banner_content.should be_true
  end

  it"(Medical Records) Search Criteria: Valid Exam Date/Range" do
    slmc.result_list_advanced_search(:exam_date=>true, :date=>Time.now.strftime("%m/%d/%Y"))
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"(Medical Records) Search Criteria:Valid Procedure/Test" do
    slmc.result_list_advanced_search(:procedure=>true, :procedure_name=>"Vectorcardiography")
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"(Medical Records) Search Criteria:Valid Performing DAS Unit" do
    slmc.result_list_advanced_search(:performing_unit=>true, :unit=>"ECG AND HOLTER")
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"(Medical Records) Search Criteria:Valid Requesting Date range" do
    slmc.result_list_advanced_search(:requesting_date=>true, :date=>Time.now.strftime("%m/%d/%Y"))
    slmc.search_result_page(:with_results=>true)
    (slmc.is_text_present"Nothing found to display.").should be_false
  end

  it"(Medical Records) Search Criteria:Invalid Exam Date/Range" do
    slmc.result_list_advanced_search(:exam_date=>true, :date=>(Date.today+5).strftime("%m/%d/%Y"))
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"(Medical Records) Search Criteria:Invalid Procedure/Test" do
    slmc.result_list_advanced_search(:procedure=>true, :procedure_name=>"ALDOSTERONE")
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"(Medical Records) Search Criteria:Invalid Performing DAS Unit" do
    slmc.result_list_advanced_search(:performing_unit=>true, :unit=>"PHARMACY")
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"(Medical Records) Search Criteria:InValid Requesting Date range" do
    slmc.result_list_advanced_search(:requesting_date=>true, :date=>(Date.today+5).strftime("%m/%d/%Y"))
    slmc.search_result_page(:no_results=>true).should == "Nothing found to display."
  end

  it"(Medical Records) The Results list page is displayed" do
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@gu_pin)
    slmc.click"css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for=>:page
    slmc.patient_banner_content.should be_true
    slmc.is_element_present("css=#patientSearchResult>tbody>tr").should be_true
  end

  it"(Medical Records) User clicks on the Procedure Name link of a non- confidential patient" do
    slmc.click"css=#patientSearchResult>tbody>tr.odd>td:nth-child(2)>a", :wait_for => :page
    sleep 3
    slmc.is_element_present"reportFileDiv".should be_true
 end

 it"(Medical Records) On HTML view, user clicks the PRINT button" do
    slmc.click'a_print2'
    slmc.is_alert_present
    slmc.get_alert.should == "Please select a printer."
 end

  it"User selects confidential test result of a non-confidential Patient" do
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@gu_pin).should == @@gu_pin
    slmc.click"css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for=>:page
    slmc.patient_banner_content.should be_true
    slmc.click"css=#patientSearchResult>tbody>tr.even>td:nth-child(2)>a"
    slmc.is_alert_present
    slmc.get_alert.should == "Your current role does not allow you to view the result. Document is Confidential"
  end

  it"On Load of the Ancillary Unit Page" do
#    slmc.login("dasdoc5",@password).should be_true
    slmc.login("dcvillanueva","dcvillanueva").should be_true
    slmc.go_to_doctor_ancillary
    slmc.rr_content.should be_true
  end

  it"(Ancillary) User Searches patient - Criteria: Valid PIN" do
    slmc.search_rr_document(:pin => @@gu_pin).should == @@gu_pin
  end

  it"(Ancillary) User Searches patient - Criteria:Valid Last Name" do
    @@name=slmc.get_table'results.1.1'
    @@name=@@name.scan(/\w+/)
    slmc.search_rr_document(:pin => @@name[0]).should == @@name[0]
  end

  it"(Ancillary) User Searches patient - Criteria: InValid PIN" do
    sleep 2
    slmc.search_rr_document(:pin => @@pin)
    (slmc.get_text"css=#results>tbody>tr.even>td").should == "NO PATIENT FOUND"
  end

  it"(Ancillary) User Searches patient - Criteria:InValid Last Name" do
    slmc.search_rr_document(:pin => @@name[0]+"!@@@@!!!!")
     (slmc.get_text"css=#results>tbody>tr.even>td").should == "NO PATIENT FOUND"
  end

  it"(Ancillary) User Searches patient - Criteria:InValid First Name" do
    slmc.search_rr_document(:pin => @@name[1]+"!@@@@!!!!")
     (slmc.get_text"css=#results>tbody>tr.even>td").should == "NO PATIENT FOUND"
  end

  it"(Ancillary) User Searches patient - Criteria:InValid MIddle Name" do
    slmc.search_rr_document(:pin => @@name[2]+"!@@@@!!!!")
     (slmc.get_text"css=#results>tbody>tr.even>td").should == "NO PATIENT FOUND"
  end

  it"(Ancillary) User selects a patient" do
    slmc.search_rr_document(:pin => @@gu_pin).should == @@gu_pin
  end

  it"(Ancillary) Search - Criteria: Valid Exam Date/Range" do
    slmc.search_rr_document(:pin => "")
    slmc.more_options_arms_rr(:exam_date=>true, :date=>Time.now.strftime("%m/%d/%Y"), :search=>true)
    slmc.verify_search(:with_results=>true).should be_true
  end

  it"(Ancillary) Search - Criteria: Valid Procedure/Test" do
    slmc.result_list_advanced_search(:slide=>true, :procedure=>true, :procedure_name=>"Vectorcardiography", :search=>true)
    slmc.verify_search(:with_results=>true).should be_true
  end

  it"(Ancillary) Search - Criteria:Valid Performing DAS Unit" do
    slmc.result_list_advanced_search(:slide=>true, :performing_unit=>true, :unit=>"ECG AND HOLTER", :search=>true)
    slmc.verify_search(:with_results=>true).should be_true
  end

  it"(Ancillary) Search - Criteria:Valid Requesting Date range" do
    slmc.more_options_arms_rr(:requesting_date=>true, :date=>Time.now.strftime("%m/%d/%Y"), :search=>true)
    sleep 5
    slmc.verify_search(:with_results=>true).should be_true
  end

  it"(Ancillary) Search - Criteria:Invalid Exam Date/Range" do
    slmc.more_options_arms_rr(:exam_date=>true, :date=>(Date.today+5).strftime("%m/%d/%Y"), :search=>true)
    slmc.verify_search(:no_result_rr=>true).should be_true
  end

  it"(Ancillary) Search - Criteria: Invalid Procedure/Test" do
    slmc.result_list_advanced_search(:slide=>true, :procedure=>true, :procedure_name=>"ALDOSTERONE", :search=>true)
    slmc.verify_search(:no_result_rr=>true).should be_true
  end

  it"(Ancillary) Search - Criteria: Invalid Performing DAS Unit" do
    slmc.result_list_advanced_search(:slide=>true, :performing_unit=>true, :unit=>"PHARMACY", :search=>true)
    slmc.verify_search(:no_result_rr=>true).should be_true
  end

  it"(Ancillary) Search - Criteria:Invalid Requesting Date range" do
    slmc.more_options_arms_rr(:requesting_date=>true, :date=>(Date.today+5).strftime("%m/%d/%Y"), :search=>true)
    slmc.verify_search(:no_result_rr=>true).should be_true
    slmc.search_rr_document(:pin => "")
  end

  it"(Ancillary) On HTML view, user clicks the PRINT button" do
      slmc.search_rr_document(:pin => @@gu_pin).should == @@gu_pin
      slmc.click_result_retrieval(:chosen_result=>true)
      slmc.click'//input[@name="a_print4" and @value="Print"]'
      slmc.get_alert.should=="Please select a printer."
  end

  it"On Load of Results Data Entry Page once results have been tagged as official" do
      sleep 2
      slmc.patient_banner_content.should be_true
      contents = slmc.get_text("resultDataEntryBean")
      contents.include?("File No.").should be_true
      contents.include?("OFFICIAL").should be_true
      slmc.is_element_present'//input[@type="Button" and @value="Print"]'.should be_true
      slmc.is_element_present('//img[@alt="Search"]').should be_true
      slmc.is_element_present'//input[@type="Button" and @value="Revision History"]'.should be_true
  end

end
