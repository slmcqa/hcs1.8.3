require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "DON - Clinical Discharge Instruction Screen" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @adm_user = "sel_adm5"
    @gu_user = "gu_spec_user2"
    @order_description = "ALAXAN FR CAP BENADRYL ANTIHISTAMINE SYRUP 60mL BIOGESIC 500mg TAB ADRENALINE (EPINEPHRINE) 1MG/ML AMP (ALERT) 8.4% SODIUM BICARBONATE"
    @search_service_header = "Item Code Generic Name Description"
    @take_home_medicine_header = "Description Generic Name Quantity Duration Dose Frequency Prescription Grouping"
    @add_new_med ={"010003152" => 1, "010003161" => 1, "060001664" => 1, "010003160" => 1, "060001710" => 1}
    @drugs ={"042820145" => 5, "042820004" => 5, "042800018" => 5, "042410030" => 5, "044006039" => 5}
    @prescription_group = "GROUP 1 GROUP 2 GROUP 3 GROUP 4 GROUP 5"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


  it "Creates patient" do
    slmc.login(@adm_user, @password).should be_true
    slmc.go_to_admission_page
    slmc.admission_search(:pin => "test")
    @@pin = slmc.create_new_patient(Admission.generate_data.merge(:gender => 'F')).gsub(' ','')
  end

  it "Admit Patient" do
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Order drug items that will show on medication table" do
    slmc.login(@gu_user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :quantity => q, :frequency => "ONCE A WEEK", :doctor => "6726", :add => true).should be_true
    end
    sleep 1
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 5
    slmc.confirm_validation_all_items.should be_true
  end

  it "Go to Clinical Discharge Instruction Screen" do
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin)
  end

  it "Verify 8 tabs under Clinical Discharge Instruction" do
    slmc.is_element_present"clinicalDischargeHomeInstructionForm".should be_true
  end

  it "Verify 8 tabs under Clinical Discharge Instruction(2)" do
    slmc.is_element_present"diagnosis_tab".should be_true
    slmc.is_element_present"medicine_tab".should be_true
    slmc.is_element_present"exercise_tab".should be_true
    slmc.is_element_present"treatment_tab".should be_true
    slmc.is_element_present"health_teaching_tab".should be_true
    slmc.is_element_present"outpatient_consultation_tab".should be_true
    slmc.is_element_present"diet_tab".should be_true
    slmc.is_element_present"social_tab".should be_true
  end

  it "Verify Patient Banner" do
    slmc.patient_banner_content.should be_true
  end

  it "Verify DISCHARGE DIAGNOSIS Tab" do
    slmc.click "link=Diagnosis/Disposition"
    sleep 1
    slmc.is_element_present"txt_icd10Search".should be_true
    slmc.is_element_present"btn_icd10Add".should be_true
    slmc.is_element_present"txtFinalDiagnosis".should be_true
    slmc.is_element_present"//input[@type='button' and @onclick='addFinalDiagnosis();' and @value='Add']".should be_true
  end

  it "Option user to search for the ICD 10 diagnosis" do
    slmc.click"btn_icd10Add", :wait_for => :element, :element => "icd10FinderForm"
    slmc.type"icd10_entity_finder_key", "CHOLERA"
    slmc.click"//input[@type='button' and @value='Search' and @onclick='Icd10Finder.search();']"
    sleep 5
    slmc.get_text("css=#icd10_finder_table_body>tr.even>td:nth-child(2)>a").should == "CHOLERA"
    slmc.click"css=#icd10_finder_table_body>tr.even>td:nth-child(2)>a"
    sleep 2
    contents=slmc.get_text"diagnosisRows"
    contents.include?("CHOLERA").should be_true
  end

  it "Option user to encode free text final diagnosis" do
    slmc.type"txtFinalDiagnosis","TYPHOID PNEUMONIA"
    (slmc.get_value"txtFinalDiagnosis").should == "TYPHOID PNEUMONIA"
  end
  
  it "Option user to encode free text final diagnosis(2)" do
    slmc.type"txtFinalDiagnosis","CHOLERA DUE TO VIBRIO CHOLERAE 01, BIOVAR CHOLERAE"
    (slmc.get_value"txtFinalDiagnosis").should == "CHOLERA DUE TO VIBRIO CHOLERAE 01, BIOVAR CHOLERAE"
  end
  
  it "Option user to encode free text final diagnosis(3)" do
    slmc.type"txtFinalDiagnosis","TYPHOID PNEUMONIA"
    (slmc.get_value"txtFinalDiagnosis").should == "TYPHOID PNEUMONIA"#code A01.03
    slmc.click"//input[@type='button' and @onclick='addFinalDiagnosis();' and @value='Add']"
    sleep 1
    contents=slmc.get_text"diagnosisRows"
    contents.include?("A01.03").should be_false
  end  

  it "Free text final diagnosis should not mix with ICD10 save listings" do
    contents=slmc.get_text"diagnosisRows"
    contents.include?("TYPHOID PNEUMONIA").should be_true
  end

  it "Delete ICD10 Final Diagnosis" do
    slmc.click("//input[@value='Remove']")
    contents=slmc.get_text"diagnosisRows"
    contents.include?("CHOLERA").should be_false
  end

  it "Verify MEDICATION Tab" do
    slmc.click "link=Medication"
    sleep 1
    slmc.is_element_present"drugs_ordered_div".should be_true
  end

  it "Verify MEDICATION Tab(2)" do
    @@contents=slmc.get_text"css=#drugs_ordered_result"
  end

  it "Verify MEDICATION Tab(3)" do
    (slmc.get_css_count"css=#drugs_ordered_result>tr").should == 5
    (@@contents.include?"BIOGESIC 500mg TAB").should be_true
  end

  it "Verify MEDICATION Tab(4)" do
    slmc.get_value("css=#drugs_ordered_result>tr.even>td>span>input").should == "off"
    slmc.get_value("css=#drugs_ordered_result>tr:nth-child(2)>td>span>input").should == "off"
    slmc.get_value("css=#drugs_ordered_result>tr:nth-child(3)>td>span>input").should == "off"
    slmc.get_value("css=#drugs_ordered_result>tr:nth-child(4)>td>span>input").should == "off"
    slmc.get_value("css=#drugs_ordered_result>tr:nth-child(5)>td>span>input").should == "off"
  end

  it "Drug Description – Users should be able to select one or more medications to be added as a take-home medication" do
   ##https://projects.exist.com/issues/31329 as per this, selecting multiple drugs that will result on multiple pop-up is complicate and will not be implemented
    sleep 1
    slmc.click"css=#drugs_ordered_result>tr:nth-child(2)>td>span>input", :wait_for => :element, :element => "medication_select_popup"
    slmc.type"prescription_quantityPerTake","1"
    slmc.type"prescription_duration","10"
    slmc.click"btnDoctorFind"
    sleep 1
    slmc.type"entity_finder_key","6726"
    slmc.click "//input[@value='Search']"
    sleep 5
    slmc.click "//tbody[@id='finder_table_body']/tr/td[2]/div" if slmc.is_element_present"//tbody[@id='finder_table_body']/tr/td[2]/div"
    slmc.click"btnPopupAction"#, :wait_for => :page
    sleep 4
    slmc.is_element_present"css=#take_home_medication_result>tr>td".should be_true
  end

  it "Verify buttons under Take Home Medication Area" do
#    slmc.is_element_present"btnClear".should be_true
    slmc.is_element_present"//input[@type='button' and @value='ADD NEW' and @onclick='performAddNewOperation()']".should be_true
  end

  it "Add Take Home Medications" do
    contents=slmc.get_text"rx_description_0"
    (@order_description.include?contents).should be_true
  end

  it "Click ADD NEW button under Take Home Medications" do
    slmc.click"//input[@type='button' and @value='ADD NEW' and @onclick='performAddNewOperation()']", :wait_for => :element, :element => "medication_select_popup"
  end

  it "Click ADD NEW button under Take Home Medications(2)" do
    slmc.is_element_present"medication_select_popup".should be_true
  end

  it "Search medication item" do
    slmc.click"btnMedicineFind", :wait_for => :element, :element => "orderItemFinderForm"
    slmc.type"oif_entity_finder_key","042820142"
    slmc.click'//input[@type="button" and @onclick="DIF.search();" and @value="Search"]'
    sleep 1
  end

  it "Search medication item(2)" do
    slmc.click"btnMedicineFind", :wait_for => :element, :element => "orderItemFinderForm"
    slmc.type"oif_entity_finder_key","BIOGESIC DROPS 15ML"
    slmc.click'//input[@type="button" and @onclick="DIF.search();" and @value="Search"]'
    sleep 4
    contents=slmc.get_text"oif_sortedTHead"
    (contents.include?@search_service_header).should be_true
  end

  it "Search medication item(3)" do
    slmc.click"css=#oif_finder_table_body>tr.even>td:nth-child(2)>div>a"
    sleep 1
    slmc.is_element_present"prescription_mServiceCode".should be_true
    slmc.is_element_present"prescription_medicineName".should be_true
    slmc.is_element_present"prescription_genericName_description".should be_true
    slmc.is_element_present"prescription_uomDescription".should be_true
    slmc.is_element_present"btnMedicineClear".should be_true
    slmc.is_element_present"btnMedicineFind".should be_true
    slmc.is_element_present"prescription_doctorCode".should be_true
    slmc.is_element_present"prescription_doctorName".should be_true
    slmc.is_element_present"btnDoctorClear".should be_true
    slmc.is_element_present"btnDoctorFind".should be_true
    slmc.is_element_present"drug_related_div".should be_true
    slmc.is_element_present"prescription_medFrequency".should be_true
    slmc.is_element_present"prescription_route".should be_true
    slmc.is_element_present"prescription_dosage".should be_true
    slmc.is_element_present"order_qty_per_take_div".should be_true
    slmc.is_element_present"order_qty_div".should be_true
    slmc.is_element_present"dates_div".should be_true
    slmc.is_element_present"prescription_startDate".should be_true
    slmc.is_element_present"prescription_endDate".should be_true
    slmc.is_element_present"duration_div".should be_true
    slmc.is_element_present"med_remarks_div".should be_true
    slmc.is_element_present"btnCancel".should be_true
    slmc.is_element_present"btnPopupAction".should be_true
  end

  it "Search medication item(4)" do
    slmc.type"prescription_startDate", Time.now.strftime("%m/%d/%Y")
    slmc.type"prescription_endDate", (Date.today+5).strftime("%m/%d/%Y")
    (slmc.get_value"prescription_duration").should == "5"
  end

  it "Search medication item(5)" do
    slmc.click"btnDurationClear"
    slmc.type"prescription_duration","5"
    slmc.type"prescription_remarks","Medication Remarks"
  end

  it "Search medication item(6)" do
    sleep 1
    slmc.click"css=#dates_div>img"
    slmc.click "link=#{Time.new.day}"
    slmc.click"btnDurationClear"
  end

  it "Search medication item(7)" do
    slmc.type"prescription_dosage","1"
    slmc.type"prescription_quantityPerTake","1"
    slmc.type"prescription_quantity","5"
    slmc.click"btnPopupAction"
    (slmc.get_text"errorText").should == "Duration is required to continue."
    sleep 1
    slmc.click"//html/body/div[7]/div[11]/div/button"
  end

  it "Search medication item(7)" do
    slmc.type"prescription_duration","5"
    slmc.click"btnPopupAction"#, :wait_for => :page
    sleep 1
    contents=slmc.get_text"take_home_medication_result"
    contents.include?"BIOGESIC DROPS 15ML".should be_true
  end

  it "Add new drug for Take Home Medications" do
    contents=slmc.get_text"css=#take_home_medication_table"
    (contents.include?@take_home_medicine_header).should be_true
  end

  it "Add new drug for Take Home Medications(2)" do
    slmc.click "link=Diagnosis/Disposition"
    slmc.select("diagnosisForm.disposition", "AS PER DOCTOR'S ADVISE")
    slmc.click"btnPrint"
    sleep 10
    slmc.is_text_present"Instructions printed successfully".should be_true
  end

  it "Add new drug for Take Home Medications(3)" do
    slmc.click "link=Medication"
    sleep 4
    count = slmc.get_css_count("css=#take_home_medication_result>tr")
    if count <= 5
      slmc.get_text("css=#rx_grouping_select_#{count - 1}>option").should == "GROUP 1"
    end
  end

  it "Add new drug for Take Home Medications(4)" do
    slmc.add_take_home_med(:type_med => "BETADINE", :add => true).should be_true
    sleep 1
    slmc.add_take_home_med(:find_med => true, :service_code => "010003152", :add => true).should be_true
  end

  it "Edit selected drug from list" do
    slmc.edit_take_home_med(:edit => true, :item => "BETADINE", :service_code => "LANTUS PER UNIT", :update => true).should be_true
  end

  it "Remove drug from grid" do
    slmc.edit_take_home_med(:delete => true, :item => "LANTUS PER UNIT").should be_true
  end

  it "Add new drug for Take Home Medications(5)" do
    slmc.is_element_present"medication_instruction_div".should be_true
  end

  it "Add new drug for Take Home Medications(6)" do
    slmc.is_element_present"countdownMedication".should be_true
  end

  it "Select for Prescription Grouping" do
    slmc.is_element_present"css=#rx_grouping_select_0".should be_true
  end

  it "Select for Prescription Grouping(2)" do
    (slmc.get_text"css=#rx_grouping_select_0").should == @prescription_group
  end

  it "Select for Prescription Grouping(3)" do
    slmc.select"css=#rx_grouping_select_0","GROUP 2"
    (slmc.get_value"css=#rx_grouping_select_0").should == "RXG02"
  end

  it "Select for Prescription Grouping(4)" do
    @add_new_med.each do |item, q|
      slmc.click "link=Medication"
      sleep 1
      slmc.add_take_home_med(:find_med => true, :service_code =>  item, :quantity => q, :add => true)
      slmc.click'//button[@type="button"]' if slmc.is_element_present"fieldRequiredPopup"
    end
    ((slmc.get_value"rx_grouping_select_0") || (slmc.get_value"rx_grouping_select_7")).should == "RXG02"
    slmc.click"btnSave"
    sleep 10
    slmc.is_text_present"Discharge Instruction was successfully saved".should be_true
  end

  it "Click CLEAR Button" do
    slmc.go_to_general_units_page
    slmc.patient_pin_search(:pin => @@pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Discharge Instructions\302\240", @@pin)
    slmc.click "link=Medication"
    sleep 1
    @count = slmc.get_css_count"css=#take_home_medication_result>tr"
    row = 0
    @count.times do |row|
      slmc.click("btnRxDelete_#{row}")
      sleep 1
      row = + 1
    end
    sleep 1
    slmc.click "btnSave"
    sleep 10
    (slmc.is_text_present"Discharge Instruction was successfully saved").should be_true
    slmc.click "link=Medication"
    sleep 1
    (slmc.is_element_present"css=#take_home_medication_result>tr").should be_false
  end

  it "Verify EXERCISE Tab" do
    slmc.click"link=Exercise"
    sleep 1
    slmc.is_element_present"exercise_div".should be_true
  end

  it "Verify EXERCISE Tab(2)" do
    slmc.is_element_present"countdownMedication".should be_true
  end

  it "Encode Exercise" do
    slmc.type("exercise", "Sample Exercise for Selenium Testing")
    slmc.get_value("exercise").should == "Sample Exercise for Selenium Testing"
  end

  it "Validate and truncate, if chars encoded exceeds the 1000 limit " do
    (slmc.get_attribute("exercise@onkeydown").include?"1000").should be_true
  end

  it "Verify TREATMENT Tab" do
    slmc.click"link=Treatment"
    sleep 1
    slmc.is_element_present"treatment_div".should be_true
  end

  it "Encode Treatment" do
    slmc.type("treatment", "Sample Treatment for Selenium Testing")
    slmc.get_value("treatment").should == "Sample Treatment for Selenium Testing"
  end

  it "Validate and truncate, if chars encoded exceeds the 1000 limit " do
    (slmc.get_attribute("treatment@onkeydown").include?"1000").should be_true
    slmc.is_element_present"countdownTreatment".should be_true
  end

  it "Verify HEALTH TEACHING Tab" do
    slmc.click"link=Health Teaching"
    sleep 1
    slmc.is_element_present"health_teaching_div".should be_true
  end

  it "Encode Health Teaching" do
    slmc.type("healthTeaching", "Sample Health Teaching for Selenium Testing")
    slmc.get_value("healthTeaching").should == "Sample Health Teaching for Selenium Testing"
  end

  it "Validate and truncate, if chars encoded exceeds the 1000 limit " do
    (slmc.get_attribute("healthTeaching@onkeydown").include?"1000").should be_true
    slmc.is_element_present"countdownHealthTeaching".should be_true
  end
  
  it "Verify OUTPATIENT CONSULTATION Tab" do
    slmc.click"link=Outpatient Consultation"
    sleep 1
    slmc.is_element_present("doctorDiv").should be_true
  end

  it "Verify OUTPATIENT CONSULTATION Tab(2)" do
    slmc.outpatient_consultation(:doctor => "6726").should be_true
    sleep 2
    slmc.click("link=Outpatient Consultation")
    slmc.get_css_count("css=#appointmentBean>tbody>tr").should == 1
  end

  it "Display doctor specialization" do
    slmc.get_text("//table[@id='appointmentBean']/tbody/tr/td[2]").should == "SURGERY"
  end

  it "Display clinic schedule and location" do
    slmc.get_text("//table[@id='appointmentBean']/tbody/tr/td[3]").should == "MON (08:00-14:00) / Clinic Location"
  end

  it "Set appointment date" do
    slmc.get_text("//table[@id='appointmentBean']/tbody/tr/td[4]").include?((Date.today+1).strftime("%m/%d/%Y")).should be_true
  end

  it "Clear appointment date" do
    slmc.type "appointmentBean.appointmentDate", (Date.today+1).strftime("%m/%d/%Y")
    sleep 1
    slmc.click("link=Clear")
    sleep 1
    slmc.get_value("appointmentBean.appointmentDate").should == ""
  end

  it "Clear appointment time" do
    slmc.type "appointmentBean.appointmentTime", (Time.now.strftime("%I:%M"))
    sleep 1
    slmc.click("//html/body/div/div[2]/div[2]/form/div[3]/div[6]/div[3]/div/table/tbody/tr/td[5]/div/a")
    sleep 1
    slmc.get_value("appointmentBean.appointmentDate").should == ""
  end

  it "Delete outpatient consultation" do
    slmc.edit_delete_outpatient_consultation(:doctor_name => "ABAD, MARCO JOSE FULVIO CICOLI", :delete => true).should be_true
  end

  it "Select a corresponding doctor from the list" do
    slmc.type"appointmentBean.clinicSchedule", "MON (08:00-14:00)"
    slmc.type"appointmentBean.clinicLocation", "Clinic Location"
    slmc.type"appointmentBean.appointmentDate", (Date.today+1).strftime("%m/%d/%Y")
    slmc.click'//input[@type="button" and @onclick="submitForm(this)" and @value="Add Outpatient Consultation"]'
    sleep 5
    (slmc.get_text"clinicalDischargeHomeInstructionForm.errors").should == "Doctor Name is a required field.\nAppointment Time is a required field."
  end

  it "Add the selected doctor in the Appointment list" do
    slmc.outpatient_consultation(:doctor => "0126").should be_true
  end

  it "Add the selected doctor in the Appointment list(2)" do
    slmc.outpatient_consultation(:doctor => "0206").should be_true
    slmc.click"link=Outpatient Consultation"
    sleep 5
    (slmc.get_css_count"css=#appointmentBean>tbody>tr").should == 2
  end

  it "Determine the date and time of the appointment" do
    slmc.click"btnSave", :wait_for => :page
    slmc.click"link=Outpatient Consultation"
    sleep 5
    @referral_code = slmc.access_from_database(:what => "DOCTOR_REFERRAL_CODE",
                              :table => "TXN_OM_DISCHARGE_DOCTOR",
                              :column1 => "DOCTOR_CODE",
                              :condition1 => "6726",
                              :gate => "and",
                              :column2 => "LOCATION",
                              :condition2 => "Clinic Location")
    @referral_code.should_not == ""
  end

  it "Determine the date and time of the appointment(2)" do
    slmc.click'//img[@alt="Edit" and @src="/images/pencil.gif"]'
    sleep 8
    slmc.type"appointmentBean.appointmentDate", (Date.today+3).strftime("%m/%d/%Y")
  end

  it "Determine the date and time of the appointment(3)" do
    slmc.click"//img[@src='/images/calendar.png']"
    slmc.click'//input[@type="button" and @onclick="submitForm(this)" and @value="Add Outpatient Consultation"]', :wait_for => :page
  end

  it "Display clinic schedule of selected doctor" do
    slmc.click"css=#doctorDiv>input"
    sleep 10
    slmc.type"entity_finder_key", "0126"
    slmc.click "//input[@value='Search']"
    slmc.click "//tbody[@id='finder_table_body']/tr/td[2]/div" if slmc.is_element_present"//tbody[@id='finder_table_body']/tr/td[2]/div"
    sleep 8
    #REF_DR_CLINIC_SCHED
    (slmc.get_value"appointmentBean.clinicSchedule").should == "MON (08:00-14:00)"
  end

  it "Input clinic schedule of the selected doctor" do
    sleep 2
    slmc.click"css=#doctorDiv>input"
    slmc.type"entity_finder_key", "5814"
    slmc.click "//input[@value='Search']"
    slmc.click "//tbody[@id='finder_table_body']/tr/td[2]/div" if slmc.is_element_present"//tbody[@id='finder_table_body']/tr/td[2]/div"
    sleep 8
    (slmc.get_value"appointmentBean.clinicSchedule").should == ""
  end

  it "Add doctors not found in the TXN_ADM_DOCTOR table" do
     slmc.click"css=#doctorDiv>input"
  end

  it "Add doctors not found in the TXN_ADM_DOCTOR table(2)" do
    slmc.is_element_present"doctorFinderForm".should be_true
  end

  it "Add doctors not found in the TXN_ADM_DOCTOR table(3)" do
    slmc.type"entity_finder_key", "5814"
    slmc.click "//input[@value='Search']"
  end

  it "Input appointment date and time" do
    slmc.outpatient_consultation(:doctor => "5814", :date => (Date.today+3).strftime("%m/%d/%Y"))
  end

  it "Click DELETE OUTPATIENT CONSULTATION button" do
    slmc.click"link=Outpatient Consultation"
    sleep 8
    slmc.click"btnDelete"
    (slmc.get_alert).should == "Please select an Out-Patient Consultation item to delete"
  end

  it "Click DELETE OUTPATIENT CONSULTATION button(1)" do
    slmc.click"btnSave", :wait_for => :page
    slmc.click"link=Outpatient Consultation"
    sleep 5
    slmc.access_from_database(:what => "DOCTOR_REFERRAL_CODE",
                              :table => "TXN_OM_DISCHARGE_DOCTOR",
                              :column1 => "DOCTOR_CODE",
                              :condition1 => "6726",
                              :gate => "and",
                              :column2 => "LOCATION",
                              :condition2 => "Clinic Location")
    sleep 4
    @@appointment_bean = slmc.get_css_count"css=#appointmentBean>tbody>tr"
  end

  it "Click DELETE OUTPATIENT CONSULTATION button(2)" do
    slmc.click"css=#appointmentBean>tbody>tr:nth-child(3)>td:nth-child(5)>input"
    (slmc.get_value"css=#appointmentBean>tbody>tr:nth-child(3)>td:nth-child(5)>input").should == "on"
  end

  it "Click DELETE OUTPATIENT CONSULTATION button(3)" do
    slmc.click"btnDelete", :wait_for => :page
    @@appointment_bean1 = slmc.get_css_count"css=#appointmentBean>tbody>tr"
    @@appointment_bean1.should == @@appointment_bean - 1
  end

  it "Verify DIET Tab" do
    slmc.click"link=Diet"
    slmc.is_element_present"dietDescription".should be_true
    slmc.is_element_present"countdownDiet".should be_true
  end

  it "Verify diet type encoding pattern of Inpatient (Diet type only)" do
    slmc.click"btnDiagnosisLookup", :wait_for => :visible, :element => "//input[@type='button' and @onclick='DietFinder.search();' and @value='Search']"
    slmc.click '//input[@type="button" and @onclick="DietFinder.search();" and @value="Search"]', :wait_for => :element, :element => "css=#diet_finder_table_body>tr.even>td>a"
    slmc.click "css=#diet_finder_table_body>tr.even>td>a", :wait_for => :not_visible, :element => "css=#diet_finder_table_body>tr.even>td>a"
  end

  it "Add additional Instruction field" do
    slmc.type'//*[@name="dietInstructions"]','Additional Diet Instructions'
  end

  it "Validate and truncate the additional instruction field, if chars encoded exceeds the 1000 limit " do
    (slmc.get_attribute("dietInstructions@onkeydown").include?"1000").should be_true
  end

  it "Verify SOCIAL Tab" do
    slmc.click"link=Social"
    slmc.is_element_present"social_div".should be_true
    slmc.is_element_present"countdownSocial".should be_true
  end

  it "Validate and truncate, if chars encoded exceeds the 1000 limit " do
    (slmc.get_attribute("social@onkeydown").include?"1000").should be_true
  end

  it "Verify location of  SAVE and PRINT button in Discharge Home Instruction Page" do
    (slmc.get_value"css=#clinicalDischargeHomeInstructionForm>div>input").should == "Save"
    (slmc.get_value"css=#clinicalDischargeHomeInstructionForm>div>input:nth-child(2)").should == "Print"
  end

  it "Click SAVE BUTTON" do
    slmc.click"btnSave", :wait_for => :page
    slmc.is_text_present"Discharge Instruction was successfully saved".should be_true
  end

  it "Click PRINT BUTTON" do
    slmc.click"btnPrint", :wait_for => :page
    slmc.is_text_present"Instructions printed successfully".should be_true 
  end

  it "Move from one tab to the other without losing the encoded data in each tab." do
    slmc.click"link=Outpatient Consultation"
    slmc.is_element_present"css=#appointmentBean>tbody>tr.even>td".should be_true
    slmc.click "link=Diagnosis/Disposition"
    slmc.click"link=Outpatient Consultation"
    slmc.is_element_present"css=#appointmentBean>tbody>tr.even>td".should be_true
  end

  it "Bug#41508 - DON Discharge Instruction - ICD10 Description for Final Diagnosis is removed in TXN_ADM_DIAGNOSIS" do
    slmc.click "link=Diagnosis/Disposition"
    sleep 1
    @visit_no = slmc.get_text("banner.visitNo").gsub(' ', '').to_i
    count = slmc.get_css_count"css=#diagnosisRows>tr"
    (slmc.count_number_of_entries(:what => "DIAGNOSIS_DESCRIPTION", :table => "TXN_ADM_DIAGNOSIS", :column1 => "VISIT_NO", :condition1 => @visit_no).to_i).should == count
  end

  it "Bug#39186 - DIAGNOSIS ENTERED ON THE TEXT FINAL DIAGNOSIS IS NOT APPEARING ON DISPLAY" do
    slmc.type"txtFinalDiagnosis","CHOLERA DUE TO VIBRIO CHOLERAE 01, BIOVAR CHOLERAE"
    slmc.click"//input[@type='button' and @onclick='addFinalDiagnosis();' and @value='Add']"
    slmc.type"txtFinalDiagnosis","PARATYPHOID FEVER A"
    slmc.click"//input[@type='button' and @onclick='addFinalDiagnosis();' and @value='Add']"
    slmc.select("diagnosisForm.disposition", "AS PER DOCTOR'S ADVISE")
    slmc.click"btnSave"
    sleep 8
    slmc.click"//input[@value='Remove']"  while slmc.is_element_present"//input[@value='Remove']"
    slmc.click"btnSave"
    sleep 8
    slmc.type"txtFinalDiagnosis","CHOLERA DUE TO VIBRIO CHOLERAE 01, BIOVAR CHOLERAE"
    slmc.click"//input[@type='button' and @onclick='addFinalDiagnosis();' and @value='Add']"
    sleep 5
    (slmc.get_text"css=#diagnosisRows>tr>td:nth-child(2)>a>div").should == "CHOLERA DUE TO VIBRIO CHOLERAE 01, BIOVAR CHOLERAE"
  end

end
