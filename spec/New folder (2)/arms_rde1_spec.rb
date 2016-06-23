require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: ARMS RDE Module Test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
#    @selenium_driver.evaluate_rooms_for_admission('0295', 'RCH08')
    @patient = Admission.generate_data
    @user = "sel_arms_spec_user"
    @password = "123qweuser"
    @items = {"010002461" => {:desc => "VECTORCARDIOGRAPHY", :code => "0076"},
                      "010000385" => {:desc => "COMPLETE BLOOD COUNT", :code => "0058"}}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


    it "Creates new general unit patient" do
      slmc.login(@user, @password).should be_true
      slmc.admission_search(:pin => "test")
      @@gu_pin = slmc.create_new_patient(Admission.generate_data.merge(:gender => 'M')).gsub(' ','')
      @@gu_pin.should be_true
      slmc.admission_search(:pin => @@gu_pin)#.should be_true
      slmc.verify_search_results(:with_results => true)#.should be_true => mpi is on
      slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0295', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
    end

    it "Performs clinical ordering - ANCILLARY (ADSORPTION TEST)" do
      slmc.go_to_general_units_page
      slmc.go_to_adm_order_page(:pin => @@gu_pin)
      slmc.search_order(:ancillary => true, :description => "010002461").should be_true
      slmc.add_returned_order(:ancillary => true, :description => @items["010002461"][:desc], :add => true).should be_true
      slmc.submit_added_order
      slmc.validate_orders(:ancillary => true, :orders => "single")
      slmc.confirm_validation_all_items.should be_true
    end

    it "Creates new gu patient and performs clinical ordering" do
      slmc.login(@user, @password).should be_true
      slmc.admission_search(:pin => "test")
      @@gu_pin1 = slmc.create_new_patient(@patient.merge(:gender => 'M')).gsub(' ','')
      slmc.admission_search(:pin => @@gu_pin1)#.should be_true
      slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0295', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
      slmc.go_to_general_units_page
      slmc.go_to_adm_order_page(:pin => @@gu_pin1)
      slmc.search_order(:ancillary => true, :description => "010002461").should be_true
      slmc.add_returned_order(:ancillary => true, :description => @items["010002461"][:desc], :add => true).should be_true
      slmc.submit_added_order
      slmc.validate_orders(:ancillary => true, :orders => "single").should == 1
      slmc.confirm_validation_all_items.should be_true
    end

    it "Creates new gu patient and performs clinical ordering - feature #47137" do #dividing the example for feature #47137
      slmc.go_to_general_units_page
      slmc.go_to_adm_order_page(:pin => @@gu_pin1)
      slmc.search_order(:ancillary => true, :description => "010000385").should be_true
      slmc.add_returned_order(:ancillary => true, :description => @items["010000385"][:desc], :add => true).should be_true
      sleep 4
      slmc.submit_added_order
      slmc.validate_orders(:ancillary => true, :orders => "single").should == 1
      slmc.confirm_validation_all_items.should be_true
    end

    it "Sets the arms user to same org code of ancillary" do
      slmc.login('chriss',"chriss").should be_true
      slmc.modify_user_credentials(:user_name => "sel_armsdastech2", :org_code => @items["010002461"][:code]).should be_true
    end

    it "On Load of the DAS Worklist" do
        slmc.login("sel_armsdastech2", @password).should be_true
        slmc.go_to_arms_landing_page
        contents = slmc.get_text("results")
        contents.include?("Request Date").should be_true
        contents.include?("Schedule Date").should be_true
        contents.include?("Patient Info").should be_true
        contents.include?("Item Description").should be_true
        contents.include?("CI No.").should be_true
        contents.include?("Specimen No.").should be_true
        contents.include?("HL7 Flag").should be_true
        contents.include?("Document Status").should be_true
        contents.include?("Destination App").should be_true
        contents.include?("Actions").should be_true
        slmc.get_css_count("css=#results>tbody>tr").should == 20
    end

    it "User searches valid patient  using surname" do
        last_name = slmc.get_table 'results.1.3'
        last_name = last_name.scan(/\w+/)
        slmc.search_document(last_name[1])
        slmc.verify_search(:with_results => true).should be_true
    end

    it "User searches valid patient using patient PIN" do
        slmc.search_document(@@gu_pin)
        slmc.verify_search(:with_results => true).should be_true
    end

    it "User searches invalid patient using surname" do
        invalid_surname = slmc.get_table 'results.1.3'
        invalid_surname = invalid_surname.scan(/\w+/)
        slmc.search_document(invalid_surname[1]+"_")
        slmc.verify_search(:no_results => true).should be_true
    end

    it  "User searches invalid patient using patient PIN" do
        slmc.search_document("")
        slmc.search_document(@@gu_pin+"_")
        slmc.verify_search(:no_results => true).should be_true
    end

    it "User searches valid request date" do
        slmc.search_document("")
        slmc.arms_advance_search(:request_start=>Time.now.strftime("%m/%d/%Y"), :search=>true)
        slmc.verify_search(:with_results => true).should be_true
    end

    it "User searches valid schedule date" do
        slmc.search_document("")
        slmc.arms_advance_search(:schedule_start=>Time.now.strftime("%m/%d/%Y"), :search=>true)
        slmc.verify_search(:with_results => true).should be_true
    end

    it "User searches valid CI number" do
        cnumber = slmc.get_table 'results.1.5'
        slmc.arms_advance_search(:ci_number=>cnumber, :search=>true)
        slmc.verify_search(:with_results => true).should be_true
    end

    it "User searches valid Item code" do
        slmc.arms_advance_search(:item_code=>"010002461", :search=>true)
        slmc.verify_search(:with_results => true).should be_true
    end

    it "User searches by document status" do
        slmc.search_document("")
        slmc.arms_advance_search(:request_start=>"", :request_end=>"", :document_status=>"Official", :search=>true)
        slmc.verify_search(:with_results => true).should be_true
    end

    it "User searches by order status" do
        slmc.arms_advance_search(:request_start=>"", :request_end=>"", :order_status=>"Validated", :search=>true)
        slmc.verify_search(:with_results => true).should be_true
    end

    it "User searches invalid request date" do
        slmc.arms_advance_search(:request_start=>(Date.today+1).strftime("%m/%d/%Y"), :request_end=>(Date.today+1).strftime("%m/%d/%Y"), :search=>true)
        slmc.verify_search(:no_results => true).should be_true
    end

    it "User searches invalid schedule date" do
        slmc.arms_advance_search(:schedule_start=>(Date.today+5).strftime("%m/%d/%Y"), :schedule_end=>(Date.today+5).strftime("%m/%d/%Y"), :search=>true)
        slmc.verify_search(:no_results => true).should be_true
    end

    it "User searches invalid CI number" do
        slmc.arms_advance_search(:ci_number=>"010001039", :search=>true)
        slmc.verify_search(:no_results => true).should be_true
    end

    it "User searches invalid Item code" do
        slmc.arms_advance_search(:item_code=>'12345678900987654321', :search=>true)
        slmc.verify_search(:no_results => true).should be_true
    end

    it "User clicks  the RESULTS DATA ENTRY  link under the Actions column of the patient who has a valid ordered item" do
        slmc.search_document("")
        slmc.click 'slide-fade'
        slmc.select 'orderStatus', 'index=1'
        slmc.click "css=#advanceSearchOption>div:nth-child(8)>input", :wait_for => :page
        slmc.verify_search(:with_results => true).should be_true
        slmc.click_results_data_entry
        slmc.is_text_present("Patient's Results").should be_true
    end

  it "On load of the Results Data Entry Page - 008_Deletion_of_Results" do
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    slmc.click_results_data_entry
    sleep 2
    slmc.type 'PARAM::007600000000008::MAGNITUDE_VALUE','test'
    (slmc.get_value 'PARAM::007600000000008::MAGNITUDE_VALUE').should == 'test'
    slmc.click '//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'
    (slmc.is_checked '//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]').should be_true
    slmc.select'PARAM::007600000000008::TERM_SLOW_VALUE','index=1'
    slmc.type'PARAM::007600000000008::INTERPRETATION_NARRATIVE','das technologist'
    (slmc.get_value'PARAM::007600000000008::INTERPRETATION_NARRATIVE').should == 'das technologist'
    sleep 1
    slmc.assign_signatory(:one => true, :code1 => "0209139")
    sleep 1
    slmc.assign_signatory(:two => true, :code2 => "7099")
    slmc.save_signatories.should be_true
    sleep 8
    slmc.queue_for_validation.should be_true
    sleep 5
    slmc.validate_result(:validate=>true, :username => "dasdoc5", :password => "123qweuser").should be_true
    sleep 15
    contents = slmc.get_text("resultDataEntryBean")
    contents.include?("VALIDATED").should be_true
    slmc.login('dcvillanueva','dcvillanueva').should be_true
    slmc.go_to_doctor_ancillary
    slmc.search_rr_document(:pin=>@@gu_pin).should == @@gu_pin
    slmc.click_results_data_entry
    slmc.patient_banner_content.should be_true
    slmc.is_element_present'//input[@name="a_update2"]'.should be_true
    slmc.is_element_present'//input[@name="a_delete4"]'.should be_true
    slmc.is_element_present'//input[@name="a_print_preview2"]'.should be_true
    slmc.is_element_present'//input[@value="Revision History"]'.should be_true
  end

  it "User clicks the the DELETE  button" do
    slmc.click'//input[@name="a_delete4"]'
    slmc.is_text_present"Please enter your credentials to confirm action on result document.".should be_true
  end

  it "User clicks CANCEL button" do
    slmc.click'btnValidationCancel'
    slmc.patient_banner_content.should be_true
  end

  it "On Load of the Deletion of Results Information Page" do
    slmc.click'//input[@name="a_delete2" and @value="Delete"]'
    slmc.is_text_present"Please enter your credentials to confirm action on result document.".should be_true
    slmc.is_element_present"validateUsername".should be_true
    slmc.is_element_present"validatePassword".should be_true
    slmc.is_element_present"deleteReasonCode".should be_true
  end

  it "User Deletes Official results" do
    slmc.type'validatePassword',@password+"_"
    slmc.select'deleteReasonCode','index=3'
    slmc.click'//input[@type="button" and @value="Submit"]'
    sleep 3
    (slmc.is_text_present"Invalid Username/Password.").should be_true
  end

  it "User inputs valid information for the following: Username,  Password,  Reasons for Deletion - 1" do
    slmc.type'validateUsername','dcvillanueva'
    slmc.type'validatePassword','dcvillanueva'
  end

  it "User inputs valid information for the following: Username,  Password,  Reasons for Deletion - 2" do
    slmc.select'deleteReasonCode','index=10'
  end

  it "User selects reason for deletion -1" do
    sleep 2
    slmc.select'deleteReasonCode','index=1'
    slmc.select'deleteReasonCode','index=2'
    slmc.select'deleteReasonCode','index=3'
    slmc.select'deleteReasonCode','index=4'
    slmc.select'deleteReasonCode','index=5'
    slmc.select'deleteReasonCode','index=6'
    slmc.select'deleteReasonCode','index=7'
    slmc.select'deleteReasonCode','index=8'
    slmc.select'deleteReasonCode','index=9'
    slmc.select'deleteReasonCode','index=10'
    slmc.select'deleteReasonCode','index=11'
    slmc.select'deleteReasonCode','index=12'
    sleep 1
    slmc.select'deleteReasonCode','index=13'
  end

  it "User selects reason for deletion -2" do
    sleep 2
    slmc.is_element_present"divORCIAddPopup".should be_true
  end

  it "User selects reason for deletion -3" do
    slmc.type'txtORCIAdd',rand(100000).to_s
    slmc.click'btnORCIAdd'
    slmc.is_element_present"tdOrCiTestcode-0".should be_true
    slmc.click'btnORCIClose'
    slmc.is_text_present"Please enter your credentials to confirm action on result document.".should be_true
    sleep 2
  end

  it "User clicks Submit button" do
    slmc.click'//input[@type="button" and @onclick="UserValidation.validate();"]'
    sleep 15
    slmc.patient_banner_content.should be_true
  end

  it "User clicks Submit button - 1" do
    contents = slmc.get_text("resultDataEntryBean")
    contents.include?("DELETED").should be_true
  end

it"On Load of Results Data Entry Page once results have been tagged as official" do
    slmc.login("sel_armsdastech2", @password).should be_true
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin1)
    slmc.click_results_data_entry
    slmc.type 'PARAM::007600000000008::MAGNITUDE_VALUE','test'
    (slmc.get_value 'PARAM::007600000000008::MAGNITUDE_VALUE').should == 'test'
    slmc.click '//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'
    (slmc.is_checked'//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]').should be_true
    slmc.assign_signatory(:one => true, :code1 => "0209139")
    slmc.assign_signatory(:two => true, :code2 => "7099")
    slmc.save_signatories.should be_true
    sleep 4
    slmc.click'//input[@name="a_queue2"]'
    sleep 10
    slmc.validate_result(:validate => true).should be_true
    sleep 10
    contents = slmc.get_text("resultDataEntryBean")
    contents.include?("VALIDATED").should be_true
    sleep 2
    slmc.is_element_present'//input[@type="Button" and @value="Update"]'.should be_true
    slmc.is_element_present'//input[@type="Button" and @value="Print"]'.should be_true
    slmc.is_element_present'//input[@type="Button" and @value="Revision History"]'.should be_true
    slmc.tag_official_result(:validate => true)
    sleep 10
    slmc.patient_banner_content.should be_true
end

  it "Feature #47137 - Multiple alerts - 1" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin1)
    slmc.search_order(:ancillary => true, :description => "010000404").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010000404", :add => true).should be_true
    slmc.search_order(:ancillary => true, :description => "010000405").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010000405", :add => true).should be_true
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true

    slmc.login('chriss',"chriss").should be_true
    slmc.modify_user_credentials(:user_name => "sel_armsdastech2", :org_code => @items["010000385"][:code]).should be_true

    slmc.login("sel_armsdastech2", @password).should be_true
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin1)

    slmc.click_results_data_entry
    slmc.select"COMMON_PARAM::TRUN::SPECIMEN","BLOOD"
    slmc.type"PARAM::005800000000026::RESULT","100" #hemoglobin
   
    slmc.assign_signatory(:one => true, :code1 => "0209139")
    slmc.assign_signatory(:two => true, :code2 => "7099")
    slmc.save_signatories.should be_true
    sleep 4
    slmc.queue_for_validation.should be_true
    sleep 10
    slmc.validate_result(:validate => true, :username => "dasdoc5", :password => "123qweuser").should be_true
    sleep 5
    slmc.tag_official_result(:validate=>true)
    sleep 8
  end

  it "Feature #47137 - Multiple alerts - 2" do
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin1)

    count = slmc.get_css_count("css=#results>tbody>tr")
      count.times do |rows|
        my_row=slmc.get_text("css=#results>tbody>tr:nth-child(#{rows + 1})>td:nth-child(5)")
        if my_row == "Hematocrit"
          stop_row = rows
          slmc.click("css=#results>tbody>tr:nth-child(#{stop_row + 1})>td:nth-child(11)>div>a")
        end
    end

    sleep 5
    slmc.select"COMMON_PARAM::TRUN::SPECIMEN","BLOOD"
    slmc.type"PARAM::005800000000025::RESULT","100"

    slmc.assign_signatory(:one => true, :code1 => "0209139")
    slmc.assign_signatory(:two => true, :code2 => "7099")
    slmc.save_signatories.should be_true
    sleep 4
    slmc.queue_for_validation.should be_true
    sleep 5
    slmc.validate_result(:validate => true, :username => "dasdoc5", :password => "123qweuser").should be_true
    sleep 5
    slmc.tag_official_result(:validate=>true)
    sleep 10
  end

  it "Feature #47137 - Multiple alerts - 3" do
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin1)

    count = slmc.get_css_count("css=#results>tbody>tr")
      count.times do |rows|
        my_row=slmc.get_text("css=#results>tbody>tr:nth-child(#{rows + 1})>td:nth-child(5)")
        if my_row == "COMPLETE BLOOD COUNT"
          stop_row = rows
          slmc.click("css=#results>tbody>tr:nth-child(#{stop_row + 1})>td:nth-child(11)>div>a")
        end
    end 
    
    sleep 2
    slmc.type"PARAM::005800000000026::RESULT","100" #hemoglobin
    slmc.type"PARAM::005800000000025::RESULT","100" #hematocrit
    sleep 5
    (slmc.is_element_present'//td[@style="background-color: rgb(255, 0, 0);"]').should be_true
    slmc.type"COMMON_PARAM::TRUN::REMARKS","SELENIUM REMARKS" #add panic value for text
    slmc.double_click"COMMON_PARAM::TRUN::REMARKS"
    slmc.click"//input[@type='button' and @onclick='PanicFlag.validateThenSetPanicFlag();' and @value='Add Panic Value']", :wait_for => :element, :element => "validatePanicUsername"
    sleep 2
    slmc.get_confirmation if slmc.is_confirmation_present
    sleep 3
    slmc.type"validatePanicUsername", "dasdoc5"
    slmc.type"validatePanicPassword", @password
    slmc.click'//html/body/div/div[2]/div[2]/div[12]/intput/div[5]/input'
    sleep 1
    slmc.get_alert if slmc.is_alert_present
    
    slmc.assign_signatory(:one => true, :code1 => "0209139")
    slmc.assign_signatory(:two => true, :code2 => "7099")
    slmc.save_signatories.should be_true
    sleep 4
    slmc.queue_for_validation.should be_true
    sleep 5
    slmc.validate_result(:validate => true, :username => "dasdoc5", :password => "123qweuser").should be_true
    sleep 5
    slmc.tag_official_result(:validate=>true)
    sleep 10
  end

  it "Feature #47137 - Dismissing one out of three panic values" do
    slmc.login(@user, @password).should be_true
    sleep 2
    (slmc.is_element_present"trPanicValuesPat-#{@@gu_pin1}").should be_true

    slmc.click"css=#trPanicValuesPat-#{@@gu_pin1}>td>div>a"
    (slmc.get_text"divPanicValuesPatCount-#{@@gu_pin1}").should == "3"

    alert = (slmc.get_attribute("css=div[id=divPanicValuesDoc-#{@@gu_pin1}] div@id"))

    slmc.click"css=#trPanicValuesPat-#{@@gu_pin1}>td>div:nth-child(2)>div>a"
    sleep 2
    slmc.click'link=Acknowledge'

    username = alert.gsub('divPanicValuesDoc','txtPanicValuesUsername')
    password = alert.gsub('divPanicValuesDoc','txtPanicValuesPassword')
    dismiss = alert.gsub('divPanicValuesDoc','btnPanicValuesDismiss')

    slmc.type(username,"sel_arms_spec_user")
    slmc.type(password,"123qweuser")
    slmc.click("//input[@id='#{dismiss}' and @type='button' and @value='OK']")

    sleep 2
    (slmc.is_element_present"trPanicValuesPat-#{@@gu_pin1}").should be_true
    (slmc.get_text"divPanicValuesPatCount-#{@@gu_pin1}").should == "2"
  end

  it "Feature #47137 - System should automatically dismiss panic alert of discharge patient with Print gate pass printed even one of among the panic alert have already been dismissed" do
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@gu_pin1).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@gu_pin1)
    slmc.add_final_diagnosis(:save => true)#.should be_true
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@gu_pin1).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Doctor and PF Amount", @@gu_pin1)
    sleep 2
    slmc.clinical_discharge(:pf_amount => "1000",:pf_type => "DIRECT", :type => "standard")

    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@gu_pin1)
    @@visit_no = slmc.get_visit_number_using_pin(@@gu_pin1)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true

    sleep 2
    (slmc.is_element_present"trPanicValuesPat-#{@@gu_pin1}").should be_true

    slmc.nursing_gu_search(:pin => @@gu_pin1)
    slmc.print_gatepass(:no_result => true, :pin => @@gu_pin1).should be_true

    sleep 2
    (slmc.is_element_present"trPanicValuesPat-#{@@gu_pin1}").should be_false
  end

end