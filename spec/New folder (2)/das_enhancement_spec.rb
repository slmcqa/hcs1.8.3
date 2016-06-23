require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "DAS Enhancement - Results with multiple templates" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
#    @selenium_driver.evaluate_rooms_for_admission('0295', 'RCH08')
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @arms_user = "sel_arms_spec_user"
    @user = "dastech-chem3"
    @items = {"010002375" => {:desc => "TRANSRECTAL ULTRASOUND",:code => "0135"},
                      "010002376" => {:desc => "TRANSVAGINAL ULTRASOUND",:code => "0135"}}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


  it "Creates patient" do
    slmc.login(@arms_user, @password).should be_true
    slmc.go_to_admission_page
    slmc.admission_search(:pin => "test")
    @@pin = slmc.create_new_patient(Admission.generate_data.merge(:gender => 'M')).gsub(' ','')
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0295', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end
  
  it "Performs clinical ordering" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin)
    slmc.search_order(:ancillary => true, :description => "010002375", :filter => "WOMENS HEALTH CARE").should be_true
    slmc.add_returned_order(:ancillary => true,:description => "TRANSRECTAL ULTRASOUND", :add => true ).should be_true
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
  end

  it"Login to HC Description:dastect-chem3" do
    slmc.login(@user, @password).should be_true
  end

  it"Click ARMS DAS Technologist" do
    slmc.go_to_arms_landing_page
  end

  it"Search the Patient" do
    slmc.search_document(@@pin).should be_true
  end

  it"Click Result data entry - 1" do
    slmc.enter_result_for_selected_items(@@pin).should be_true
  end

  it"Click Result data entry - 2" do
    sleep 2
    slmc.type"PARAM::013500000000007::FINDRES","RESULT TEMPLATE 1"
    (slmc.get_value"PARAM::013500000000007::FINDRES").should == "RESULT TEMPLATE 1"
  end

  it"Verify the Multiple Template - 1" do
    slmc.click"link=Template 2"
    sleep 5
    slmc.type"PARAM::013500000000009::TECHNIQUERES","TEMPLATE 2 RESULT TEMPLATE 2"
    (slmc.get_value"PARAM::013500000000009::TECHNIQUERES").should == "TEMPLATE 2 RESULT TEMPLATE 2"
    slmc.patient_banner_content.should be_true
  end

  it"Verify the Multiple Template - 2" do
    slmc.click"link=Template 1"
    sleep 2
    (slmc.get_value"PARAM::013500000000007::EXAMINATION_VALUE").should == "FIRST TRIMESTER ULTRASOUND REPORT"
  end

  it"User enter signatory " do
     slmc.assign_signatory(:one => true, :code1 => "7117").should be_true
     slmc.assign_signatory(:two => true, :code2 => "7099").should be_true
  end

  it"Click Save button " do
    slmc.save_signatories.should be_true
    contents = slmc.get_text("resultDataEntryBean")
    (contents.include?"CREATED").should be_true
  end

  it"User clicks queue for validation button." do
    slmc.queue_for_validation.should be_true
    sleep 10
  end

  it"Click Validate" do
    slmc.validate_result(:cancel_validate => true).should be_true
  end

  it"Verify the credentials to confirm" do
    slmc.validate_result(:validate => true, :password => "123qweuser", :username => "dasdoc4").should be_true
  end

  it"Click Tag As Official" do
    sleep 5
    slmc.click'//input[@type="Button" and @name="a_official2"]'
    sleep 1
    slmc.is_element_present"css=#divTemplatesSelectionPopup>div:nth-child(3)>button".should be_true
  end

  it"User unchecks templates that will not be used." do
    slmc.click"css=#divTemplatesSelectionPopup>div:nth-child(3)>button"
    sleep 5
  end

  it"System displays validation screen." do
    slmc.is_element_present"orderValidateForm".should be_true
  end

  it"User enters credentials (password) of signatory2" do
    slmc.type"validateUsername","dcvillanueva"
    slmc. type'validatePassword','dcvillanueva'
    (slmc.get_value"validateUsername").should == "dcvillanueva"
  end

it"System changes document status to OFFICIAL" do
    slmc.click'//input[@type="button" and @onclick="UserValidation.validate();" and @value="Submit"]'
    sleep 10
    contents = slmc.get_text("resultDataEntryBean")
    (contents.include?"OFFICIAL").should be_true
end

end
