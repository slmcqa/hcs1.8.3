require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Update Final Diagnosis by Medical Records" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
#    @selenium_driver.evaluate_rooms_for_admission('0287','RCH08')

    @patient = Admission.generate_data
    @user = "sel_medical1"
    @gu_user = "gu_spec_user11"
    @pba_user = "sel_pba12"
    @er_user  = "sel_er10"
    @password = "123qweuser"
    @drugs =
      {
      "042820145" => 1,
      "042820004" => 2,
     }

    @ancillary =
      {
      "010000317" => 1,
      "010000212" => 2,
      }
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

#Physically Out patient
  it "Physically Out - Creates patient" do
    slmc.login(@gu_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@pin = slmc.create_new_patient(@patient.merge(:gender => 'F', :birth_day => '05/05/1984')).gsub(' ','')
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Physically Out - Order Items" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin)
    @drugs.each do |item, q|
    slmc.search_order(:description => item, :drugs => true).should be_true
    sleep 1
    slmc.add_returned_order(:drugs => true, :description => item, :quantity => q, :frequency => "ONCE A WEEK", :doctor => "6726",:add => true).should be_true
    end

    @ancillary.each do |item, q|
    slmc.search_order(:description => item, :ancillary => true).should be_true
    sleep 1
    slmc.add_returned_order(:ancillary => true, :description => item, :quantity => q,:doctor => "0126",:add => true).should be_true
    end

    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
  end

  it "Physically Out - Clinically discharged the patient" do
    slmc.nursing_gu_search(:pin => @@pin).should be_true
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_type => "DIRECT", :pf_amount => "1000" , :save => true).should be_true
  end

  it "Physically Out - Administratively discharged the patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
  end

  it "Physically Out - Print Gatepass" do
    slmc.login(@gu_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin).should be_true
    slmc.print_gatepass(:pin => @@pin)
  end


#Previously admitted as inpatient now admit as outpatient
  it "Previously admitted as inpatient go to outpatient - Creates patient" do
    slmc.login(@gu_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@pin2 = slmc.create_new_patient(Admission.generate_data).gsub(' ','')
    slmc.admission_search(:pin => @@pin2).should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Previously admitted as inpatient go to outpatient - Order Items" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin2)
    @ancillary.each do |item, q|
    slmc.search_order(:description => item, :ancillary => true).should be_true
    slmc.add_returned_order(:ancillary => true, :description => item, :quantity => q,:doctor => "0126",:add => true).should be_true
    end
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
  end

  it "Previously admitted as inpatient go to outpatient - Clinically discharged the patient" do
    slmc.nursing_gu_search(:pin => @@pin2).should be_true
    @@visit_no2 = slmc.clinically_discharge_patient(:pin => @@pin2, :no_pending_order => true, :pf_type => "DIRECT", :pf_amount => "1000", :save => true).should be_true
  end

  it "Previously admitted as inpatient go to outpatient - Administratively discharged the patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin2)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no2)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
  end

  it "Previously admitted as inpatient go to outpatient - Print Gatepass" do
    slmc.login(@gu_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin2).should be_true
    slmc.print_gatepass(:pin => @@pin2)
  end

  it "Previously admitted as inpatient go to outpatient - Admit again the patient" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_page
    slmc.er_patient_search(:pin => @@pin2)
    slmc.click_register_patient
    slmc.admit_er_patient(:org_code => "0173", :account_class =>  "INDIVIDUAL").should be_true
  end

  it"Previously admitted as inpatient go to outpatient - ER, Order Items" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@pin2)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin2)
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :doctor => "0126", :add => true).should be_true
    end
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
  end

  it"Previously admitted as inpatient go to outpatient - ER, Clnically Discharge Patient" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@pin2)
    @@visit_no2 = slmc.clinically_discharge_patient(:er => true, :pin => @@pin2, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
  end

  it"Previously admitted as inpatient go to outpatient - ER, Administratively Discharge Patient" do
    slmc.go_to_er_billing_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    slmc.go_to_pba_action_page(:visit_no => @@visit_no2, :page => "Discharge Patient" )
    slmc.select_discharge_patient_type(:type => "STANDARD")
    slmc.click_new_guarantor
    slmc.pba_update_guarantor(:guarantor_type => "INDIVIDUAL")
    sleep 10
    slmc.click_submit_changes.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end

  it"Previously admitted as inpatient go to outpatient - ER, Print Gatepass" do
    slmc.er_print_gatepass(:pin => @@pin2,:visit_no => @@visit_no2).should be_true
  end

  it"Verify user function with role_ICD10_coder" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_final_diagnosis_review
  end

  it"Bug#40412 - [Final Diagnosis Review] Found to have patients listed without a discharge date / time" do
    slmc.search_patient_diagnosis_review(:pin => "110").should be_true
    sleep 1
    count = slmc.get_css_count"css=#results>tbody>tr"
    rows = 0
    @w = []
    count.times do
      @w << slmc.get_text("css=#results>tbody>tr:nth-child(#{rows + 1})>td:nth-child(3)")
      rows = rows+1
    end
    (@w.include?("")).should be_false
  end

  it "Feature Checklist - Patient Search - Discharge date range" do
    slmc.search_patient_diagnosis_review(:discharge_date => true).should be_true
  end

  it "Feature Checklist - Patient Search - Discharge date range" do
    slmc.go_to_final_diagnosis_review
    slmc.search_patient_diagnosis_review(:icd10 => true).should be_true
  end

  it"Verify user function with role_ICD10_coder -  Should be able to search physically out patient" do
    slmc.search_patient_diagnosis_review(:pin => @@pin, :visit_no => @@visit_no).should be_true
  end

  it"Role medical records user w/out ICD10 role, allowed access to test results page" do
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin)
    slmc.medical_records_result_list_page
  end

  it"Role medical records user w/out ICD10 role, allowed access to test results page - Can Search, view, print results" do
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin)
    slmc.med_reprinting_page(:reprinting => true, :patient_label => true, :with_previous_confinement => true).should be_true
  end

  it"Role medical records user with ICD10 role, allowed access to Test results and Final Diagnosis review page" do
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin)
    slmc.go_to_final_diagnosis_review
  end

  it"User search discharged patient by PIN" do
    slmc.search_patient_diagnosis_review(:pin => @@pin, :visit_no => @@visit_no).should be_true
  end

  it"User search discharged patient by lastname" do
    slmc.search_patient_diagnosis_review(:pin => @patient[:last_name], :visit_no => @@visit_no).should be_true
  end

  it"System displays list of possible matches." do
    slmc.go_to_final_diagnosis_review
    slmc.search_patient_diagnosis_review(:pin => "11").should be_true
  end

  it"Patient Listing page display" do
    (slmc.get_text"css=#results>thead").should == "Patient Name PIN Discharge Date/Time Visit No Admission Date/Time Nursing Unit Diagnosis Details"
  end

  it"System should be able to retrieve patients two recent visit history respectively for Inpatient / Outpatient types" do
    slmc.search_patient_diagnosis_review(:pin => @@pin2, :visit_no => @@visit_no2).should be_true
    slmc.click'link=Out-Patient'
    slmc.search_patient_diagnosis_review(:pin => @@pin2, :visit_no => @@visit_no2).should be_true
  end

  it"There should be a link to display all discharged patient without ICD10 encoded" do
    slmc.is_element_present"wo_Icd10Count".should be_true
  end

  it"Link should contain patient count equal to the number of patient w/out ICD10 encoded" do
    slmc.is_element_present"css=#wo_Icd10Count>span".should be_true
  end

  it"User access the link of patient w/out ICD10 encoded" do
    slmc.click_final_diagnosis_review_link(:without_icd10 => true).should be_true
  end

#  it"Patient w/out ICD10 listing should match the number of Count describe in link text" do
#    sleep 10
#    @count = slmc.get_css_count"css=#results>tbody>tr"
#    ((slmc.get_text"css=#wo_Icd10Count>span").to_i).should == @count
#  end

  it"Enables user to access patients Final Diagnosis info" do
    slmc.click'link=In-Patient'
    sleep 2
    slmc.final_diagnosis_review(:pin => @@pin2, :visit_no => @@visit_no2).should be_true
  end

  it"System displays Patient banner and Final diagnosis info upon access to patient final diagnosis page" do
    slmc.is_element_present"css=#icd10>tbody>tr>td:nth-child(2)".should be_true
  end

  it"System displays Patient banner in final diagnosis update page" do
    contents = slmc.get_text("patientBanner")
    (contents.include?(slmc.get_text"banner.pin")).should be_true
    (contents.include?(slmc.get_text"banner.fullName")).should be_true
    (contents.include?(slmc.get_text"banner.gender")).should be_true
    (contents.include?(slmc.get_text"banner.birthDate")).should be_true
    (contents.include?(slmc.get_text"banner.visitNo")).should be_true
    (contents.include?(slmc.get_text"banner.admissionDateTime")).should be_true
    (contents.include?(slmc.get_text"banner.admissionDoctor")).should be_true
    (contents.include?(slmc.get_text"banner.admissionDiagnosis")).should be_true
    (contents.include?(slmc.get_text"banner.patientType")).should be_true
    contents=slmc.get_text("banner.birthDate")
    (contents.include?("year")).should be_true
  end

  it"System displays Patient final diagnosis in final diagnosis update page" do
    slmc.is_element_present"css=#icd10>tbody>tr>td:nth-child(2)".should be_true
  end

  it"System should display the same patient final diagnosis as encoded during Discharged instruction process" do
    ((slmc.get_text"css=#icd10>tbody>tr>td:nth-child(2)").include?"CHOLERA").should be_true
  end

  it"Final diagnosis table column" do
    (slmc.get_text"css=#icd10>thead").should == "ICD10 Code Description Action"
  end

  it"ICD10 Final diagnosis lookup table" do
    slmc.is_element_present"icdFindResults"
  end

  it"Enables user to search and select appropriate final diagnosis for the patient" do
    slmc.type"txtIcdQueryCode", "Z30"
    (slmc.get_value"txtIcdQueryCode").should ==  "Z30"
    slmc.click"btnIcdFindSearch"
  end

  it"The selected new or additional ICD 10 automatically added and display for patient update page" do
    slmc.medical_final_diagnosis(:icd10_diagnosis => "Z30").should be_true
  end

  it"(Text final diagnosis) Enables user to encode and add also text as final diagnosis" do #selenium can't enable the add button
    slmc.medical_final_diagnosis(:text_diagnosis => "ACUTE GASTRITIS").should be_true
    sleep 1
    ((slmc.get_text"css=#diagnosis>tbody>tr").include?"ACUTE GASTRITIS").should be_true
  end

  it"Navigate away from the final diagnosis page without saving the encoded ICD10 / Text final diagnosis" do
    slmc.go_to_final_diagnosis_review
    slmc.final_diagnosis_review(:pin => @@pin2, :visit_no => @@visit_no2).should be_true
#    (slmc.is_element_present"css=#medicalRecords_finalDiagnosisRows>tr:nth-child(3)").should be_false  # not applicable 1.4.2
  end

# not applicable 1.4.2
#  it"Save the encoded ICD10 and Text final diagnosis" do
#    slmc.go_to_final_diagnosis_review
#    slmc.final_diagnosis_review(:pin => @@pin).should be_true
#    slmc.medical_final_diagnosis(:icd10_diagnosis => "Z30", :text_diagnosis => "ACUTE GASTRITIS", :save => true).should be_true
#  end

  it"(Text final diagnosis) Add ICD10 code (enabled for those with text but with no corresponding code and description)" do
    slmc.go_to_final_diagnosis_review
    slmc.final_diagnosis_review(:pin => @@pin, :visit_no => @@visit_no).should be_true
    slmc.medical_final_diagnosis(:text_diagnosis => "A01").should be_true
  end

  it"(Text final diagnosis) Edit ICD10 code (enabled for those with a code and description)" do
    slmc.click"//input[@type='button' and @value='Edit']", :wait_for => :element, :element => "freeText"
    slmc.type"freeText","CHOLERA DESCRIPTION"
    (slmc.get_value"freeText").should == "CHOLERA DESCRIPTION"
    slmc.click"//html/body/div[7]/div[11]/div/button[2]"
    slmc.click"//html/body/div[5]/div[11]/div/button[2]"
    sleep 5
    slmc.is_text_present"CHOLERA DESCRIPTION".should be_true
  end

  # not applicable 1.4.2
#  it"System Returns confirmation if the encoded Text or ICD10 final diagnois is saved" do
#    slmc.medical_final_diagnosis(:save => true).should be_true
#    slmc.is_text_present"Final Diagnosis was successfully saved".should be_true
#  end

  it"System should not allow deleting or removal of all Final diagnosis entries" do
    slmc.go_to_final_diagnosis_review
    slmc.final_diagnosis_review(:pin => @@pin, :visit_no => @@visit_no).should be_true
    slmc.click"//input[@value='Delete']"
    (slmc.get_text"mssgText").should == "Delete this from patient's diagnosis?"
    slmc.click"//html/body/div[5]/div[3]/div/button/span"
  end

  it"(Text final diagnosis) ICD10 Codes/Description should not get modified when editing patient text final diagnosis" do
    slmc.go_to_final_diagnosis_review
    slmc.final_diagnosis_review(:pin => @@pin, :visit_no => @@visit_no).should be_true
    slmc.click"//input[@type='button' and @value='Edit']", :wait_for => :element, :element => "freeText"
    slmc.click"//html/body/div[7]/div[11]/div/button"
    sleep 1
  end

  it"Text final diagnosis char limit set to 255 chars only" do
    slmc.click"diagnosisType2"
    sleep 1
    ((slmc.get_attribute"freeTextAdd@maxlength").to_i).should == 200
  end

  it"(Text final diagnosis) Option for user to edit Final diagnosis of patients" do
    slmc.go_to_final_diagnosis_review
    slmc.final_diagnosis_review(:pin => @@pin, :visit_no => @@visit_no).should be_true
    slmc.click"//input[@type='button' and @value='Edit']", :wait_for => :element, :element => "freeText"
    slmc.type"freeText","DESCRIPTION"
    (slmc.get_value"freeText").should == "DESCRIPTION"
    slmc.click"//html/body/div[7]/div[11]/div/button[2]"
    slmc.click"//html/body/div[5]/div[11]/div/button[2]"
    sleep 5
    slmc.is_text_present"DESCRIPTION".should be_true
  end

  it"Option for user to remove Final diagnosis of patients added" do
     slmc.click"//input[@value='Delete']"
    (slmc.get_text"mssgText").should == "Delete this from patient's diagnosis?"
    slmc.click"//html/body/div[5]/div[3]/div/button/span"
  end

#Currently admitted
  it "Currently admitted - Creates patient" do
    slmc.login(@gu_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@pin3 = slmc.create_new_patient(Admission.generate_data).gsub(' ','')
    slmc.admission_search(:pin => @@pin3).should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Currently admitted - Order Items" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin3)
    @ancillary.each do |item, q|
    slmc.search_order(:description => item, :ancillary => true).should be_true
    slmc.add_returned_order(:ancillary => true, :description => item, :quantity => q,:doctor => "0126",:add => true).should be_true
    end
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
  end

  it"User search for a patient not yet discharged" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_final_diagnosis_review
    slmc.search_patient_diagnosis_review(:pin => @@pin3, :alert => true).should be_true
  end

#Clinically discharged
  it "Clinically discharged - Clinically discharged the patient" do
    slmc.login(@gu_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin3).should be_true
    @@visit_no3 = slmc.clinically_discharge_patient(:pin => @@pin3, :no_pending_order => true, :pf_type => "DIRECT", :pf_amount => "1000" , :save => true).should be_true
  end

  it"User search for a patient that is clinically discharged already" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_final_diagnosis_review
    slmc.search_patient_diagnosis_review(:pin => @@pin3, :alert => true).should be_true
  end

#With previous confinement currently admitted
  it "With previous confinement currently admitted - Administratively discharged the patient" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@pin3)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no3)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
  end

  it "With previous confinement currently admitted - Print Gatepass" do
    slmc.login(@gu_user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin3).should be_true
    slmc.print_gatepass(:pin => @@pin3)
  end

  it "With previous confinement currently admitted - Admit again the patient" do
    slmc.admission_search(:pin => @@pin3).should be_true
    slmc.create_new_admission(:rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it"User search for a patient that is not admitted for sometime but with previous visit" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_final_diagnosis_review
    slmc.search_patient_diagnosis_review(:pin => @@pin3).should be_true
  end

  it "Feature Checklist - Add New ICD10" do
    slmc.final_diagnosis_review(:pin => @@pin3, :visit_no => @@visit_no3).should be_true
    slmc.click"icd10AddNewBtn", :wait_for => :element, :element => "diagnosisPopupDiv"
    slmc.type"icd10_code","SEL001"
    slmc.type"icd10_description","SELENIUM ICD10 DESCRIPTION"
  end

  it "Feature Checklist - Search & select ICD10 sub category" do
    slmc.click"//input[@type='button' and @onclick='SubCatFinder.displayPopup();']"
    slmc.type"txtSubCatQuery","ICS002"
    slmc.click"btnSubCatFindSearch", :wait_for => :element, :element => "css=#subCatFindResults>tr>td>div"
    slmc.click"css=#subCatFindResults>tr>td>div"
  end

  it "Feature Checklist - ICD10 sub-category - Save" do
    slmc.click"//html/body/div[6]/div[3]/div/button[2]/span"
    (slmc.get_text"mssgText").should == "Add SEL001 to patient's diagnosis?"
    slmc.click"//html/body/div[5]/div[3]/div/button[2]/span", :wait_for => :page
    (slmc.get_text"css=#icd10>tbody>tr>td").should == "SEL001"
  end

  it "Feature Checklist - Patient Admission History" do
    slmc.go_to_medical_records
    slmc.medical_search(:pin => @@pin3).should == @@pin3
    slmc.click"css=#results>tbody>tr>td:nth-child(3)>a", :wait_for => :page
    slmc.click"link=Patient Admission History", :wait_for => :page
    slmc.is_element_present"css=#patientAdmVisitHistory>tbody>tr>td".should be_true
  end
end