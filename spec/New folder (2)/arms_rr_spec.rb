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
    @password = "123qweuser"
    @items = {"010002461" => {:desc => "VECTORCARDIOGRAPHY", :code => "0076"},
                      "010000823" => {:desc => "HIV ½ ANTIBODY SCREENING TEST", :code => "0060"}}
    @med_patient = Admission.generate_data
    @dasnondoc = "dasnondoc5"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

 it "Creates new gu patient and performs clinical ordering for non-confidential patient-non official result" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@gu_pin = slmc.create_new_patient(Admission.generate_data.merge(:gender => 'M')).gsub(' ','')
    slmc.admission_search(:pin => @@gu_pin)#.should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0295', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.search_order(:ancillary => true, :description => "010002461").should be_true
    slmc.add_returned_order(:ancillary => true, :description => @items["010002461"][:desc], :add => true).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Sets the arms user to same org code of ancillary" do
    slmc.login('exist',"123qweadmin").should be_true
    slmc.modify_user_credentials(:user_name => "sel_armsdastech3", :org_code => @items["010002461"][:code]).should be_true
  end

  it"Non-confidential patient non-official result" do
    slmc.login("sel_armsdastech3", @password).should be_true
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    slmc.click_results_data_entry
    slmc.type 'PARAM::007600000000008::MAGNITUDE_VALUE','test'
    (slmc.get_value 'PARAM::007600000000008::MAGNITUDE_VALUE').should == 'test'
    slmc.click'//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'
    slmc.is_checked'//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'.should be_true
    slmc.assign_signatory(:one => true, :code1 => "7099")
    slmc.assign_signatory(:two => true, :code2 => "0209139")
    slmc.save_signatories.should be_true
    sleep 4
    slmc.queue_for_validation
    sleep 2
    slmc.is_element_present'//input[@value="Validate"]'.should be_true
    slmc.validate_result(:validate => true).should be_true
    sleep 8
    slmc.patient_banner_content.should be_true
  end

  it "Feature#44222 - Create patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "a")
    @@med_pin = slmc.create_new_patient(@med_patient.merge(:gender => 'M', :birth_day => '05/05/1984')).gsub(' ','')
    slmc.admission_search(:pin => @@med_pin).should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

 it"User clicks on Non - official results" do
    slmc.login(@dasnondoc,@password).should be_true
    slmc.go_to_doctor_non_ancillary
    slmc.search_non_doc_document(:pin => @@gu_pin).should == @@gu_pin
    slmc.click"css=#results>tbody>tr.even>td:nth-child(3)>a", :wait_for => :page
    slmc.get_text("css=#patientSearchResult>tbody>tr>td").should =="Nothing found to display."
 end

  it "Feature#44222 - (Non Ancillary) Add checkbox to filter currently admitted patients only" do
    slmc.go_to_doctor_non_ancillary
    slmc.click'slide-fade'
    sleep 1
    (slmc.is_element_present"admitted").should be_true
    slmc.click'slide-fade'
    slmc.more_options(:admitted => true, :pin => @@med_pin, :first_name => @med_patient[:first_name]).should == @@med_pin
  end

  it "Feature#44222 - (Non Ancillary) Add options to choose the location where the patient is currently admitted" do
    slmc.click'slide-fade'
    sleep 1
    (slmc.is_element_present"radioLocQC").should be_true
    (slmc.is_element_present"radioLocGC").should be_true
    slmc.click'slide-fade'
    slmc.more_options(:admitted => true, :pin => @@med_pin, :first_name => @med_patient[:first_name]).should == @@med_pin
  end

  it "Feature#44222 - (Non Ancillary) If the user chooses to search for currently admitted patients only, by default, button for the location is that of the Application’s location" do
    slmc.click'slide-fade'
    sleep 1
    slmc.click'admitted'
    (slmc.get_attribute"radioLocGC@checked").should == "true"
    slmc.click'slide-fade'
  end

  it "Feature#44222 - (Non Ancillary) The list of currently admitted patients would show the following patient information: Room, Admitting Doctor, Admission Date" do
    slmc.login(@dasnondoc,@password).should be_true
    slmc.go_to_doctor_non_ancillary
    slmc.more_options(:admitted => true, :pin => @@med_pin, :first_name => @med_patient[:first_name]).should == @@med_pin
    @admission_date = (slmc.access_from_database(:what => "ADM_DATETIME",:table => "TXN_ADM_ENCOUNTER",:column1 => "PIN",:condition1 => @@med_pin)).to_s
    @admission_date = @admission_date.scan(/\w+/)
    contents=slmc.get_text"css=#results>tbody>tr.even"
    (contents.include?"ABAD").should be_true
    (contents.include?"Admitted").should be_true
    (contents.include?@admission_date[2]).should be_true
    (contents.include?@admission_date[7]).should be_true
  end

  it"User clicks on Non - official results" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_patient_result_page(:pin => @@gu_pin)
    slmc.get_text("css=#patientSearchResult>tbody>tr>td").should =="Nothing found to display."
  end

  it"User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid PIN" do
    slmc.login("sel_oss5", @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test").should be_true
    slmc.click_outpatient_registration.should be_true
    @@last_name = Faker::Name.last_name
    @@middle_name = Faker::Name.last_name
    @@first_name= Faker::Name.first_name
    slmc.fill_out_form( :first_name => @@first_name, :last_name => @@last_name, :middle_name => @@middle_name)
    @@oss_pin=slmc.get_text(Locators::Registration.oss_op_pin)
    @@pin = @@oss_pin.gsub(' ', '')
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin, :no_result=>true).should be_true
  end

  it"User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid Last Name" do
    slmc.patient_pin_search(:pin => @@last_name, :no_result=>true)#.should be_true
    if (slmc.is_element_present"css=#occupancyList>tbody>tr.even>td:nth-child(3)")
    (((slmc.get_text"css=#occupancyList>tbody>tr.even>td:nth-child(3)").gsub(' ','')) == @@pin).should be_false
    else
      (slmc.is_text_present"NO PATIENT FOUND").should be_true
    end
  end

  it"User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid First Name" do
    slmc.patient_pin_search(:pin => @@first_name, :no_result=>true).should be_true
  end

  it"User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid Middle Name" do
    slmc.patient_pin_search(:pin => @@middle_name, :no_result=>true)#.should be_true
    (((slmc.get_text"css=#occupancyList>tbody>tr.even>td:nth-child(3)").gsub(' ','')) == @@pin).should be_false
  end

  it"User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid PIN" do
    @@pin1=@@pin.gsub("1","9")
    slmc.patient_pin_search(:pin => @@pin1, :no_result=>true).should be_true
  end

  it"User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid Last Name" do
    slmc.patient_pin_search(:pin => @@last_name+"!!@@@!!!", :no_result=>true).should be_true
  end

  it"User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid First Name" do
    slmc.patient_pin_search(:pin => @@first_name+"!!@@@!!!", :no_result=>true).should be_true
  end

  it"User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid MIddle Name" do
    slmc.patient_pin_search(:pin => @@middle_name+"!!@@@!!!", :no_result=>true).should be_true
  end

  it"User clicks on Non - official results - Nursing_SpecialUnits" do
    slmc.arms_special_units
    slmc.search_rr_document(:pin => @@gu_pin).should == @@gu_pin
    sleep 6
    slmc.select'//select[@name="action"]','Patient Results'
    slmc.click Locators::NursingSpecialUnits.submit_button_spu
    sleep 6
    slmc.get_text("css=#patientSearchResult>tbody>tr>td").should == "Nothing found to display."
  end

  it"(SpecialUnits) User searches patient from a different unit other that the unit of the logged - in user" do
    slmc.arms_special_units
    slmc.search_arms_other_unit(:pin => @@pin, :validate=>true).should be_true
  end

  it"(SpecialUnits) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid PIN" do
     slmc.search_arms_other_unit(:pin => @@pin, :validate=>true).should be_true
  end

  it"(SpecialUnits) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid Last Name" do
    slmc.search_arms_other_unit(:validate=>true, :pin => @@last_name).should be_true
  end

  it"(SpecialUnits) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid First Name" do
    slmc.search_arms_other_unit(:validate=>true, :pin => @@first_name).should be_true
  end

  it"(SpecialUnits) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid Middle Name" do
    slmc.search_arms_other_unit(:validate=>true, :pin => @@middle_name).should be_true
  end

  it"(SpecialUnits) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid PIN" do
    slmc.patient_pin_search(:pin => @@pin1, :no_result=>true).should be_true
  end

  it"(SpecialUnits) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid Last Name" do
    slmc.patient_pin_search(:pin => @@last_name+"!!!!!@@@@@", :no_result=>true).should be_true
  end

  it"(SpecialUnits) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid First Name" do
    slmc.patient_pin_search(:pin => @@first_name+"!!!!!@@@@@", :no_result=>true).should be_true
  end

  it"(SpecialUnits) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid MIddle Name" do
    slmc.patient_pin_search(:pin => @@middle_name+"!!!!!@@@@@", :no_result=>true).should be_true
  end

  it"(Ancillary) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid PIN" do
#     slmc.login("dasdoc5",@password).should be_true
    slmc.login("dcvillanueva","dcvillanueva").should be_true
     slmc.go_to_doctor_ancillary
     slmc.patient_pin_search(:pin => @@pin, :no_result=>true).should be_true
  end

  it"(Ancillary) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid Last Name" do
    slmc.search_dasdoc_other_unit(:validate=>true, :pin => @@last_name).should be_true
  end

  it"(Ancillary) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid First Name" do
    slmc.search_dasdoc_other_unit(:validate=>true, :pin => @@first_name).should be_true
  end

  it"(Ancillary) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: Valid Middle Name" do
    slmc.search_dasdoc_other_unit(:validate=>true, :pin => @@middle_name).should be_true
  end

  it"(Ancillary) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid PIN" do
    slmc.patient_pin_search(:pin => @@pin1, :no_result=>true).should be_true
  end

  it"(Ancillary) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid Last Name" do
    slmc.patient_pin_search(:pin => @@last_name+"!!!!!@@@@@", :no_result=>true).should be_true
  end

  it"(Ancillary) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid First Name" do
    slmc.patient_pin_search(:pin => @@first_name+"!!!!!@@@@@", :no_result=>true).should be_true
  end

  it"(Ancillary) User searches patient from a different  unit other that the unit of the logged - in user - Criteria: InValid MIddle Name" do
    slmc.patient_pin_search(:pin => @@middle_name+"!!!!!@@@@@", :no_result=>true).should be_true
  end

end
