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
    @user = "sel_arms_spec_user"
    @password = "123qweuser"
    @items = {"010002461" => {:desc => "VECTORCARDIOGRAPHY", :code => "0076"},
                      "010001039" => {:desc => "URINALYSIS", :code => "0062"},
                     "010000385" => {:desc => "COMPLETE BLOOD COUNT", :code => "0058"}}
    @patient = Admission.generate_data
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


    it "Creates new general unit patient" do
      slmc.login(@user, @password).should be_true
      slmc.go_to_admission_page
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
      slmc.search_order(:ancillary => true, :description => "010001039").should be_true
      slmc.add_returned_order(:ancillary => true, :description => @items["010001039"][:desc], :add => true).should be_true
      slmc.submit_added_order
      slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 2
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
      sleep 4
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
      slmc.modify_user_credentials(:user_name => "sel_armsdastech", :org_code => @items["010002461"][:code]).should be_true
    end

    it "User is redirected on the next  landing page of the Results Data Entry after patient results have been successfully saved" do
        slmc.login("sel_armsdastech", @password).should be_true
        slmc.go_to_arms_landing_page
        slmc.search_document(@@gu_pin)
        slmc.click_results_data_entry
        slmc.patient_banner_content.should be_true
    end

    it "User is redirected on the next  landing page of the Results Data Entry after patient results have been successfully saved - checks two search boxes for signatories"  do
       slmc.is_text_present("Signatory 1:").should be_true
       slmc.is_element_present("name1").should be_true
       slmc.is_text_present("Signatory 2:").should be_true
       slmc.is_element_present("name2").should be_true
    end

    it "User clicks the button beside the Signatory field" do
      slmc.click '//a[@onclick="DSF1.show();"]'#validation is on the next scenarios
    end

    it "On Load of the Search Signatory Page(1)" do
       slmc.is_element_present("signatory1FinderForm").should be_true
    end

    it "On Load of the Search Signatory Page(2)" do
       slmc.is_element_present("sf1_entity_finder_key").should be_true
    end

    it "On Load of the Search Signatory Page(3)" do
       slmc.is_element_present'//input[@type="button" and @value="Search"]'.should be_true
       slmc.is_element_present'//input[@type="button" and @value="Reset"]'.should be_true
       slmc.is_element_present'//input[@type="button" and @value="Close"]'.should be_true
    end

    it "User inputs Doctor ID on Entry ID or Name field, then clicks the SEARCH button" do
       slmc.click '//input[@type="button" and @onclick="DSF1.search();"]', :wait_for => :element, :element => "//table[@class='table']/tbody/tr/td"
       sleep 1
       doc_id = slmc.get_table 'sf_finder_table_body.0.0'
       slmc.search_signatory_page(doc_id[0..1])
       slmc. is_element_present "//table[@class='table']/tbody/tr/td".should be_true
    end

    it "User inputs Doctor Name on Entry ID or Name field then clicks the SEARCH button" do
       slmc.search_signatory_page("Lopez")
       slmc. is_element_present "//table[@class='table']/tbody/tr/td".should be_true
       slmc.search_signatory_page("")
       doc_name=slmc.get_table 'sf_finder_table_body.0.1'
       doc_name = doc_name.scan(/\w+/)
       slmc.search_signatory_page(doc_name[0])
       slmc. is_element_present "//table[@class='table']/tbody/tr/td".should be_true
       slmc.search_signatory_page("")
       doc_name=slmc.get_table'sf_finder_table_body.0.1'
       slmc.search_signatory_page(doc_name[0..2])
    end

    it "There are no entries that matched either the Doctor ID or Name" do
       doc_id = slmc.get_table 'sf_finder_table_body.0.0'
       slmc.search_signatory_page(doc_id+"@@@!!!!!!")
       contents=slmc.get_text("sf_pagebanner")
       (contents.include?"0").should be_true
       (contents.include?"(s). Displaying").should be_true
     end

    it "User clicks the search button without placing any entries" do
      slmc.search_signatory_page("Lopez")
       slmc.search_signatory_page("")
       sleep 5
       slmc.get_css_count("css=#sf_finder_table_body>tr").should==20
       slmc.is_element_present"sf_PageNumbers".should be_true
       slmc.is_text_present(slmc.get_text("sf_itemsFound")).should be_true
    end

    it "User clicks the page number hyperlink" do
        slmc.search_signatory_page("")
        slmc.click"css=#sf_PageNumbers>a:nth-child(2)"
        slmc.is_element_present"css=#sf_finder_table_body>tr".should be_true
        slmc.is_text_present(slmc.get_text("sf_itemsFound")).should be_true
    end

    it "User clicks the RESET button" do
       slmc.click '//input[@type="button" and @onclick="DSF1.reset()"]'
       slmc.get_css_count("css=#sf_finder_table_body>").should==0
    end

    it "User selects signatory name by clicking the  name or ID from the list" do
       slmc.assign_signatory(:one => true, :code1 => "0209139")
       slmc.is_text_present("Signatory 1:").should be_true
    end

    it "User clicks the CLOSE button" do
      slmc.click 'xpath=//img[@alt="Search"]'
      slmc.is_element_present("signatory1FinderForm").should be_true
      if slmc.is_alert_present()
          slmc.get_alert()
      end
      slmc.type 'sf1_entity_finder_key', ''
      slmc.click '//input[@type="button" and @onclick="DSF1.search();"]', :wait_for => :element, :element => "//table[@class='table']/tbody/tr/td"
      slmc.click '//input[@type="button" and @onclick="DSF1.close()"]'
      slmc.patient_banner_content.should be_true
    end

  it "On load of DAS worklist - 003_Add_Specimen_Number" do
      slmc.login('chriss',"chriss").should be_true
      slmc.modify_user_credentials(:user_name => "sel_armsdastech", :org_code => @items["010001039"][:code]).should be_true
      slmc.login("sel_armsdastech", @password).should be_true
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
      slmc.get_css_count("css=#results>tbody>tr").should==20
  end

  it "User selects a test by ticking the check box beside the name of the patient to which the item has been ordered (By default, the check box has an empty value.)" do
      slmc.search_document(@@gu_pin)
      slmc.is_checked("//table[@id='results']/tbody/tr/td/input").should be_false
      slmc.click("//table[@id='results']/tbody/tr/td/input")
      slmc.is_checked("//table[@id='results']/tbody/tr/td/input").should be_true
  end

  it "User inputs specimen number in the Enter Specimen Number box" do
      slmc.search_document("")
      slmc.click 'slide-fade'
      slmc.type'//input[@type="text" and @name="specimenNumber"]','0076'
      (slmc.get_value'//input[@type="text" and @name="specimenNumber"]').should == '0076'
      slmc.search_document("")
  end

  it "User clicks the Save button beside the Enter Specimen Number box" do #should manually validate, using selenium and irb, when the checkbox is tick the save button is still disabled but when manually done it's ok.
      @specimen = AdmissionHelper.range_rand(1,1000).to_s
      slmc.search_document(@@gu_pin).should
      slmc.click("//table[@id='results']/tbody/tr/td/input")
      slmc.type'specimenNo', @specimen
      (slmc.get_value'specimenNo').should ==  @specimen
      sleep 2
      slmc.click '//input[@id="specimenMgmt" and @value="Save"]'
      sleep 5
      slmc.is_element_present"messages".should be_true
      slmc.is_text_present("Specimen Number Saved").should be_true
  end

  it "User selects a patient for data entry of results by clicking the Results Data Entry link beside the patient name " do
      slmc.login('chriss',"chriss").should be_true
      slmc.modify_user_credentials(:user_name => "sel_armsdastech", :org_code => @items["010002461"][:code]).should be_true
      slmc.login("sel_armsdastech", @password).should be_true
      slmc.go_to_arms_landing_page
      slmc.search_document("")
      slmc.get_css_count("css=#results>tbody>tr").should==20
  end

  it "User selects a patient for data entry of results by clicking the Results Data Entry link beside the patient name - 1.2 " do
      slmc.search_document(@@gu_pin)
      slmc.click_results_data_entry
      slmc.is_text_present("Patient's Results").should be_true
  end

  it "User lands on the Results Data Entry page - 1" do
    slmc.patient_banner_content
    slmc.is_text_present("Template").should be_true
  end

  it "User lands on the Results Data Entry page - 2" do
    slmc.is_element_present"//input[@type='checkbox']".should be_true
    slmc.is_element_present"//input[@type='text']".should be_true
    slmc.is_element_present"PARAM::007600000000008::INIT_SLOW_VALUE".should be_true
    slmc.is_element_present"PARAM::007600000000008::INTERPRETATION_NARRATIVE".should be_true
  end

  it "User inputs patient's test result - 1" do
    slmc.type'PARAM::007600000000008::MAGNITUDE_VALUE','test'
    (slmc.get_value'PARAM::007600000000008::MAGNITUDE_VALUE').should == 'test'
    slmc.type'PARAM::007600000000008::SEGMENT_VALUE','test'
  end

  it "User inputs patient's test result - 2" do
    slmc.click '//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'
    slmc.is_checked '//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'.should be_true
  end

  it "User inputs patient's test result - 3" do
    slmc.select'PARAM::007600000000008::TERM_SLOW_VALUE','index=1'
  end

  it "User inputs patient's test result - 4" do
    slmc.type'PARAM::007600000000008::INTERPRETATION_NARRATIVE','test'
    (slmc.get_value'PARAM::007600000000008::INTERPRETATION_NARRATIVE').should == 'test'
  end

  it "Examination date is a required field. Set the examination date" do
    slmc.type 'examDate',(Date.today + 1).strftime("%m/%d/%Y")
    slmc.select 'examHourStr','index=6'
    slmc.select 'examMinuteStr','index=58'
  end

  it "User append signatories to the document" do
    slmc.assign_signatory(:one => true, :code1 => "7099")
    slmc.is_text_present("Signatory 1:").should be_true
  end

  it "User click the save button" do
    slmc.save_signatories.should be_true
  end

  it "User click the save button - tag document as created" do
    contents = slmc.get_text("resultDataEntryBean")
    contents.include?("CREATED").should be_true
  end

  it "User is redirected on the next landing page of the Results Data Entry after patient results have been successfully saved  - 1" do
   slmc.patient_banner_content
  end

  it "User is redirected on the next landing page of the Results Data Entry after patient results have been successfully saved  - 2" do
    contents = slmc.get_text("resultDataEntryBean")
    contents.include?("File No.").should be_true
  end

  it "User is redirected on the next landing page of the Results Data Entry after patient results have been successfully saved  - 3" do
    contents = slmc.get_text("resultDataEntryBean")
    contents.include?("CREATED").should be_true
  end

  it "User is redirected on the next landing page of the Results Data Entry after patient results have been successfully saved  - 4" do
    slmc.is_element_present'//input[@name="a_update2"]'.should be_true
    slmc.is_element_present'//input[@name="a_queue2"]'.should be_true
    slmc.is_element_present'//input[@name="a_print4"]'.should be_true
    slmc.is_element_present'//input[@value="Revision History"]'.should be_true
  end

  it "User clicks the QUEUED FOR VALIDATION button to queue the document on the validators landing page - 1" do
    slmc.click'//input[@name="a_queue2" and @value="Queue For Validation"]', :wait_for => :page
    sleep 2
    slmc.is_element_present'//input[@name="a_queue2"]'.should be_true
  end

  it "User clicks the QUEUED FOR VALIDATION button to queue the document on the validators landing page - 2" do
    slmc.assign_signatory(:two => true, :code2 => "0209139")
    if    slmc.is_alert_present()
                    slmc.choose_ok_on_next_confirmation()
                    slmc.type 'sf1_entity_finder_key', '7099'
                    slmc.click '//input[@type="button" and @onclick="DSF1.search();"]', :wait_for => :element, :element => "//table[@class='table']/tbody/tr/td"
                    text=slmc.get_text("//table[@class='table']/tbody/tr/td")
                    slmc.click("link=" + text)
          end
    slmc.click'//input[@name="a_update2" and @value="Update"]', :wait_for => :page
    slmc.is_element_present'//input[@name="a_validate2"]'.should be_true
    sleep 1
  end

  it "User clicks the QUEUED FOR VALIDATION button to queue the document on the validators landing page - 3" do
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    information = slmc.get_table 'results.1.8'
    contents=information
    contents.include?("QUEUED").should be_true
  end

  it "On Load of the Results Data Entry Page - Result Print Preview" do
    slmc.click_results_data_entry
    slmc.patient_banner_content.should be_true
    contents1 = slmc.get_text("resultDataEntryBean")
    contents1.include?("QUEUED").should be_true
    contents1.include?("File No.").should be_true
  end

  it "User clicks the Print Preview button - A PDF form of the results will be displayed" do
    slmc.click'//input[@name="a_print_preview2"]'
    sleep 8
    slmc.is_element_present"reportFileDiv".should be_true
    sleep 5
  end

  it "On load of the Results Data Entry Page - Update Result" do
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    slmc.click_results_data_entry
    slmc.patient_banner_content.should be_true
    contents1 = slmc.get_text("resultDataEntryBean")
    contents1.include?("File No.").should be_true
  end

  it "User clicks the update button" do
    slmc.type'PARAM::007600000000008::INTERPRETATION_NARRATIVE','test for Edit_Update_Result'
    (slmc.get_value'PARAM::007600000000008::INTERPRETATION_NARRATIVE').should == 'test for Edit_Update_Result'
    slmc.click '//input[@type="checkbox" and @name="PARAM::007600000000008::PACEMAKER"]'
    slmc.is_checked'//input[@type="checkbox" and @name="PARAM::007600000000008::PACEMAKER"]'.should be_true
    slmc.click'//input[@name="a_update2"]'
    slmc.click'//input[@name="a_print_preview2" and @value="Print Preview"]'
    sleep 5
    slmc.is_element_present"reportFileDiv".should be_true
  end

  it "On load of the Tagging of Result  as Validated Page" do
    slmc.login("sel_armsdastech", @password).should be_true
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin)
    slmc.click_results_data_entry
    slmc.is_text_present(slmc.get_text("patientBanner")).should be_true
    slmc.is_text_present(slmc.get_text("resultDataEntryBean")).should be_true
    slmc.is_text_present(slmc.get_text("footer")).should be_true
  end

  it "On load of the Tagging of Result  as Validated Page - 2" do
    slmc.patient_banner_content.should be_true
    contents = slmc.get_text("patientBanner")
    contents.include?"Request Date".should be_true
    contents.include?"Requesting Physician".should be_true
    contents.include?"CI Number(s)".should be_true
  end

  it "User clicks TAG AS VALIDATED button to tag results as validated" do#note 1st signatory should be able to tag as validated
    if slmc.is_element_present'//input[@value = "Tag As Official"]'
      slmc.assign_signatory(:two => true, :code2 => "0209139")
       slmc.click'//input[@value="Update"]'
    end
    slmc.validate_result
  end

  it "On load of the TAGGING AS VALIDATED dialog box" do
    slmc.is_element_present"orderValidateForm".should be_true
    slmc.is_text_present"Please enter your credentials to confirm action on result document.".should be_true
  end

  it "User clicks CANCEL button - Validated" do
    slmc.click'btnValidationCancel'
    slmc.patient_banner_content.should be_true
    slmc.click'//input[@name="a_validate2" and @value="Validate"]'
    slmc.is_text_present"VALIDATED".should be_true
  end

  it "Input validation information for the mandatory fields provided" do
    slmc.type'validatePassword',@password+"_"
    slmc.click'//input[@type="button" and @value="Submit"]'
    slmc.is_element_present"errMessage".should be_true
    slmc.is_text_present"Invalid Username/Password.".should be_true
    slmc.click'btnValidationCancel'
    slmc.patient_banner_content.should be_true
  end

  it "User clicks OK button to tag as validated" do
    sleep 8
    slmc.validate_result(:validate => true, :username => "dasdoc5", :password => "123qweuser").should be_true
    sleep 8
    contents = slmc.get_text("resultDataEntryBean")
    contents.include?("VALIDATED").should be_true
  end

  it " On load of the Results Data Entry Page - 010_Tag_Official  " do
    sleep 2
    slmc.is_element_present'//input[@name="a_update2"]'.should be_true
    slmc.is_element_present'//input[@name="a_official2"]'.should be_true
    slmc.is_element_present'//input[@name="a_print_preview2"]'.should be_true
    slmc.is_element_present'//input[@value="Revision History"]'.should be_true
  end

  it "User clicks the TAG AS OFFICIAL  button" do
    sleep 10
    slmc.tag_official_result
  end

  it "On load of the TAGGING AS OFFICIAL dialog box" do
    slmc.is_text_present"Please enter your credentials to confirm action on result document.".should be_true
  end

  it "Input tagging as official information for  the mandatory fields provided" do
    slmc.type'validatePassword',@password+"_"
    slmc.click'//input[@type="button" and @value="Submit"]'
    slmc.is_element_present"errMessage".should be_true
  end

  it "User clicks CANCEL button" do
    slmc.click'btnValidationCancel'
    slmc.patient_banner_content.should be_true
  end

  it "User clicks OK button" do
    sleep 2
    slmc.tag_official_result(:validate=>true)
    sleep 10
    contents = slmc.get_text("resultDataEntryBean")
    contents.include?("OFFICIAL").should be_true
    sleep 8
  end

  it "On load of the Results  Data Entry Page - DAS Technologist" do
    sleep 6
    slmc.patient_banner_content.should be_true
    sleep 2
  end

  it "User clicks the REVISION HISTORY button" do
    slmc.click'//input[@type="Button" and @value="Revision History"]'
    sleep 5
    slmc.patient_banner_content.should be_true
    slmc.is_element_present'//input[@type="Button" and @value="Back to RDE"]'.should be_true
    sleep 5
    contents=slmc.get_text("versions").should be_true
    contents.include?("Document Id").should be_true
    contents.include?("Version No.").should be_true
    contents.include?("Created By").should be_true
    contents.include?("Created On").should be_true
    contents.include?("User IP Address").should be_true
    contents.include?("Action").should be_true
    contents.include?("Link").should be_true
    slmc.is_element_present'//table[@id="versions"]/tbody/tr/td'.should be_true
  end

  it "User clicks the template hyperlink on the page under the LINK column - note:other expected result stated are not applicable" do
    slmc.click"css=#versions>tbody>tr.even>td:nth-child(7)>a"
    sleep 4
    slmc.is_element_present'//embed[@type="application/pdf"]'.should be_true
    #note: To save the document, click the SAVE button on the PDF viewer and other expected result to be checked that needs a pdf action => couldn't do using selenium.
  end

  it "Patient Search - OutofNormalRange_Results" do
#    slmc.login("sel_armsdastech", @password).should be_true
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin1)
    sleep 8
    slmc.click_results_data_entry
    slmc.type 'PARAM::007600000000008::MAGNITUDE_VALUE','test'
    (slmc.get_value 'PARAM::007600000000008::MAGNITUDE_VALUE').should == 'test'
    slmc.click '//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'
    slmc.is_checked '//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'.should be_true
    slmc.assign_signatory(:one => true, :code1 => "0209139")
    slmc.assign_signatory(:two => true, :code2 => "7099")
    slmc.save_signatories.should be_true
    sleep 4
    slmc.queue_for_validation.should be_true
    sleep 10
    slmc.validate_result(:validate => true, :username => "dasdoc5", :password => "123qweuser").should be_true
    sleep 10
    contents = slmc.get_text("resultDataEntryBean")
    contents.include?("VALIDATED").should be_true
    sleep 2
    slmc.login("dcvillanueva","dcvillanueva").should be_true
    slmc.go_to_doctor_ancillary
  end

  it "Results Entry" do
    slmc.search_rr_document(:pin=>@@gu_pin1).should == @@gu_pin1
    slmc.click_results_data_entry
  end

  it "Results Entry - User inputs entries " do
    slmc.click '//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'
    slmc.click '//input[@type="checkbox" and @name="PARAM::007600000000008::EKG"]'
    slmc.click '//input[@type="checkbox" and @name="PARAM::007600000000008::PACEMAKER_ICD"]'
    slmc.is_checked'//input[@type="checkbox" and @name="PARAM::007600000000008::VECTORCARDIOGRAPHY"]'.should be_true
    slmc.is_checked '//input[@type="checkbox" and @name="PARAM::007600000000008::EKG"]'.should be_true
    slmc.is_checked '//input[@type="checkbox" and @name="PARAM::007600000000008::PACEMAKER_ICD"]'.should be_true
  end

  it "Results Entry  - text boxes " do
    slmc.type'//input[@type="text" and @name="PARAM::007600000000008::MAXIMAL_VALUE"]','1000test'
    slmc.type'//input[@type="text" and @name="PARAM::007600000000008::MAXIMAL_VALUE"]','1000'
    slmc.type'//input[@type="text" and @name="PARAM::007600000000008::DURATION_VALUE"]','1000'
  end

  it "Results Entry  - drop down entries with values " do
    slmc.select'PARAM::007600000000008::TERM_SLOW_VALUE','index=1'
    slmc.select'PARAM::007600000000008::INIT_SLOW_VALUE','index=2'
    slmc.select'PARAM::007600000000008::F_BITES_VALUE','index=1'
  end

  it "Result entries - result entries greater than the normal range" do #test data management - fields -result - e
    slmc.login('chriss',"chriss").should be_true
    slmc.modify_user_credentials(:user_name => "sel_armsdastech", :org_code => @items["010000385"][:code]).should be_true
    slmc.login("sel_armsdastech", @password).should be_true
    slmc.go_to_arms_landing_page
    slmc.search_document(@@gu_pin1)
    slmc.click_results_data_entry
    slmc.select"COMMON_PARAM::TRUN::SPECIMEN","index=2"
    slmc.select"PARAM::005800000000026::MACHINE","index=2"
    slmc.click"PARAM::005800000000026::NORMALVAL"
    slmc.type"PARAM::005800000000026::RESULT","1000"
    sleep 5
    slmc.is_element_present'//td[@style="background-color: rgb(255, 0, 0);"]'.should be_true
  end

  it "Result entries - smaller than the normal range" do
    slmc.type"PARAM::005800000000026::RESULT","1"
    sleep 5
    slmc.is_element_present'//td[@style="background-color: rgb(255, 0, 0);"]'.should be_true
  end

  it "Result entries - values that is within the normal range" do
    slmc.select"PARAM::005800000000026::MACHINE","index=2"
    slmc.click"PARAM::005800000000026::NORMALVAL"
    slmc.type"PARAM::005800000000026::RESULT","50"
    sleep 5
    (slmc.is_element_present'//td[@style="background-color: rgb(255, 0, 0);"]').should be_false
  end

  it "Feature #47137 - Create patient panic value" do#hemoglobin and hematocrit are set are set at arms admin
    slmc.type"PARAM::005800000000026::RESULT","100" #pre-defined panic value
    sleep 5
    (slmc.is_element_present'//td[@style="background-color: rgb(255, 0, 0);"]').should be_true
    slmc.type"COMMON_PARAM::TRUN::REMARKS","SELENIUM REMARKS" #add panic value for text
    slmc.double_click"COMMON_PARAM::TRUN::REMARKS"
    slmc.click"//input[@type='button' and @onclick='PanicFlag.validateThenSetPanicFlag();' and @value='Add Panic Value']", :wait_for => :element, :element => "validatePanicUsername"
    sleep 2
    slmc.get_confirmation if slmc.is_confirmation_present
    sleep 5
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
    sleep 10
    slmc.validate_result(:validate => true, :username => "dasdoc5", :password => "123qweuser").should be_true
    sleep 8
    slmc.tag_official_result(:validate=>true)
    sleep 10
    slmc.login(@user, @password).should be_true
    sleep 5
    (slmc.is_element_present"trPanicValuesPat-#{@@gu_pin1}").should be_true
  end

  it "On Load of Results Data Entry Page once results have been tagged as official - OnDemand Printing" do
    #slmc.login("dasdoc5",@password).should be_true
    slmc.login("dcvillanueva","dcvillanueva").should be_true
    slmc.go_to_doctor_ancillary
    slmc.search_rr_document(:pin=>@@gu_pin1).should == @@gu_pin1
    slmc.click_results_data_entry
    slmc.is_element_present'//input[@type="Button" and @value="Update"]'.should be_true
    slmc.is_element_present'//input[@type="Button" and @value="Print"]'.should be_true
    slmc.is_element_present'//input[@type="Button" and @value="Revision History"]'.should be_true
    slmc.validate_result(:validate=>true) if slmc.is_element_present'//input[@name="a_validate2" and @value="Validate"]'
    slmc.tag_official_result(:validate=>true)
    sleep 10
    slmc.patient_banner_content.should be_true
    contents = slmc.get_text("resultDataEntryBean")
    (contents.include?"File No.").should be_true
    slmc.is_element_present'//input[@type="Button" and @value="Print"]'.should be_true
    slmc.is_element_present'//input[@type="Button" and @value="Revision History"]'.should be_true
    sleep 8
  end

  it "User choose which printer the document will be sent by clicking the magnifying glass beside the Printer field" do
    slmc.click 'xpath=//img[@alt="Search"]'
    slmc.is_element_present"printerFinderForm".should be_true
    slmc.is_element_present"pf_finder_table_body".should be_true
    slmc.click'//input[@onclick="PrinterFinder.close()" and @value="Close"]'
    slmc.patient_banner_content.should be_true
  end

  it "Feature #47137 - Inpatient: User did not submit action Print gate pass after PBA discharge" do
    slmc.login(@user, @password).should be_true
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
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@gu_pin1)
    slmc.go_to_page_using_visit_number("Print Discharge Clearance", @@visit_no)
    sleep 2
    (slmc.is_element_present"trPanicValuesPat-#{@@gu_pin1}").should be_true
  end

  it "Feature #47137 - Inpatient: System auto dismiss patient panic alert on discharge print gatepass action" do
    slmc.nursing_gu_search(:pin => @@gu_pin1)
    slmc.print_gatepass(:no_result => true, :pin => @@gu_pin1).should be_true

    sleep 2
    (slmc.is_element_present"trPanicValuesPat-#{@@gu_pin1}").should be_false
  end
end
