require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Newborn Module Tests" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @or_patient = Admission.generate_data
    @er_patient = Admission.generate_data
    @or_patient2 = Admission.generate_data
    @or_patient3 = Admission.generate_data
    @dr_patient = Admission.generate_data
    @user = "newborn_spec_user"
    @password = '123qweuser'
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Feature #39751 Newborn Admission Enhancements" do
    slmc.login("sel_dr1", @password).should be_true
    slmc.click("link=Nursing Special Units Landing Page", :wait_for => :page)
    slmc.click("link=Newborn Admission", :wait_for => :page)

    slmc.is_text_present("Room Location").should be_true
    slmc.is_text_present("Rooming In").should be_true
    slmc.is_text_present("Newborn Inpatient Admission").should be_true
  end

  it "Feature #42839 - Verify that Left for Care is available in application" do
    slmc.is_element_present("leftForCare1").should be_true
    slmc.is_checked("leftForCare1").should be_false
  end

  it "Creates patient record for OR" do
    slmc.login("sel_or2", @password).should be_true
    @@or_pin = (slmc.or_nb_create_patient_record(@or_patient.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0164'))).gsub(' ', '')

    @@or_pin2 = (slmc.or_nb_create_patient_record(@or_patient2.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0164'))).gsub(' ', '')

    @@or_pin3 = (slmc.or_nb_create_patient_record(@or_patient3.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0164'))).gsub(' ', '')
  end

  it "Creates patient record for ER" do
    slmc.login("sel_er8", @password).should be_true
    @@er_pin = (slmc.er_create_patient_record(@er_patient.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0173'))).gsub(' ', '')
  end

  it "Checks that outpatient mother cannot be accepted for newborn admission" do
    slmc.login("sel_dr1", @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.verify_or_patient_validation(@@or_pin).should == "Cannot room-in. Mother is still admitted in Special Units."
  end

  it "Turns outpatient(OR) to inpatient" do
    slmc.login("sel_or2", @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.outpatient_to_inpatient(@or_patient.merge(:pin => @@or_pin, :username => 'sel_adm1', :password => @password, :room_label => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287")).should be_true
    #currently logged as admin user in this part
    slmc.login("sel_or2", @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.outpatient_to_inpatient(@or_patient2.merge(:pin => @@or_pin2, :username => 'sel_adm1', :password => @password, :room_label => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287")).should be_true

    slmc.login("sel_or2", @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.outpatient_to_inpatient(@or_patient3.merge(:pin => @@or_pin3, :username => 'sel_adm1', :password => @password, :room_label => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287")).should be_true
  end

  it "Turns outpatient(ER) to inpatient" do
    slmc.login("sel_er8", @password).should be_true
    slmc.go_to_er_patient_search
    slmc.outpatient_to_inpatient(@er_patient.merge(:pin => @@er_pin, :username => 'sel_adm1', :password => @password, :room_label => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287")).should be_true
  end

  it "Creates new born admission for OR patient" do
    slmc.login("sel_dr1", @password).should be_true
    slmc.register_new_born_patient(:pin => @@or_pin, :bdate => (Date.today).strftime("%m/%d/%Y"), :gender => "F",
      :birth_type => "SINGLE", :birth_order => "FIRST", :delivery_type => "OTHER", :weight => 4000, :length => 54,
      :doctor_name => "ABAD", :rooming_in => true, :save => true)
    slmc.register_new_born_patient(:pin => @@or_pin2, :bdate => (Date.today).strftime("%m/%d/%Y"),
      :birth_type => "SINGLE", :birth_order => "FIRST", :delivery_type => "OTHER", :weight => 4000, :length => 54,
      :doctor_name => "ABAD", :room_charge => "NURSERY", :newborn_inpatient_admission => true, :rch_code => "RCH11", :org_code => "0301", :save => true)
    slmc.register_new_born_patient(:pin => @@or_pin3, :bdate => (Date.today).strftime("%m/%d/%Y"), :gender => "M",
      :birth_type => "SINGLE", :birth_order => "FIRST", :delivery_type => "OTHER", :weight => 4000, :length => 54,
      :doctor_name => "ABAD", :rooming_in => true, :save => true)
  end

  it "Creates new born admission for ER patient" do
    slmc.register_new_born_patient(:pin => @@er_pin, :bdate => (Date.today).strftime("%m/%d/%Y"),
      :birth_type => "SINGLE", :birth_order => "FIRST", :delivery_type => "OTHER", :weight => 4000, :length => 54,
      :doctor_name => "ABAD", :rooming_in => true, :save => true)
    slmc.advanced_search(:last_name => @er_patient[:last_name], :first_name => "baby boy", :birthday => (Date.today).strftime("%m/%d/%Y"))
    @@newborn_pin = slmc.get_text("css=#results>tbody>tr>td:nth-child(2)").gsub(' ','')
    @@newborn_pin = slmc.get_text("css=#results>tbody>tr>td:nth-child(3)").gsub(' ','') if @@newborn_pin == "SLMC_GC"
  end

  it "Verifies new born admission" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_admission_page
    @@count = slmc.get_newborn_admission_count
    slmc.acknowledge_new_born(@or_patient.merge(:last_name => @or_patient[:last_name], :account_class => "HMO", :guarantor_code => "ASAL002", :first_name => "Baby Girl", :gender => "F", :birth_day => Date.today.strftime("%m/%d/%Y"))).should be_true
    slmc.acknowledge_new_born(@or_patient2.merge(:last_name => @or_patient2[:last_name], :account_class => "HMO", :guarantor_code => "ASAL002", :first_name => "Baby Boy", :gender => "M", :birth_day => Date.today.strftime("%m/%d/%Y"))).should be_true
    slmc.acknowledge_new_born(@or_patient3.merge(:last_name => @or_patient3[:last_name], :account_class => "HMO", :guarantor_code => "ASAL002", :first_name => "Baby Boy", :gender => "M", :birth_day => Date.today.strftime("%m/%d/%Y"))).should be_true
  end

  it "Verifies that newborn count for admission decrements" do
    slmc.get_newborn_admission_count.should == (@@count - 3)
  end

  it "Bug #22347 - Should be able click Newborn for Admission link and display newborn pin number" do
    slmc.view_newborn_for_admission
    (slmc.get_newborn_for_admission_list.include? @@newborn_pin.gsub(' ','')).should be_true
    slmc.close_newborn_for_admission
  end

  it "Bug #22616 - Room Transfer History should display room-in patients" do
    slmc.go_to_admission_page
    contents = slmc.view_print_room_transfer_history
    (contents.include?(@or_patient[:last_name] + ", #{@or_patient[:first_name]} " + @or_patient[:middle_name])).should be_true
    # commenting out due to #https://projects.exist.com/issues/46846 (contents.include?(@or_patient[:last_name] + ", Baby Boy " + @or_patient[:middle_name])).should be_true
    slmc.close_room_transfer_transaction
  end

  it "Bug #22563 - Room Transfer History should display outpatient(ER) turned inpatient transactions" do
    slmc.go_to_admission_page
    (slmc.view_print_room_transfer_history.include? @er_patient[:last_name]).should be_true
  end

  it "Bug #26536 [Admission] Exemption Error upon click of Preview button on Update Admission" do
    slmc.login("billing_spec_user3", @password).should be_true
    slmc.nursing_gu_search(:pin => @@or_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@or_pin)
    slmc.search_order(:drugs => true, :description => "BABYHALER").should be_true
    slmc.add_returned_order(:drugs => true, :description => "BABYHALER", :quantity => 2,
                            :stat => true, :stock_replacement => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    slmc.login("sel_adm1", @password).should be_true
    slmc.admission_search(:pin => @@or_pin)
    slmc.update_admission.should be_true # goes to preview page only
  end

  it "Updates new born patient information" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_admission_page
    slmc.advanced_search(:last_name => @or_patient[:last_name], :first_name => "Baby Girl")
    slmc.update_patient(:citizenship => "ENGLISH").should be_true
  end

  it "Updates newborn information" do
    @@newborn_info = Admission.generate_data
    slmc.update_newborn_info(:last_name => @or_patient[:last_name], :advanced_search => true, :first_name => "Baby Girl",
      :last_name_new => @@newborn_info[:last_name], :first_name_new => @@newborn_info[:first_name], :middle_name_new => @@newborn_info[:middle_name])
    @@newborn_info2 = Admission.generate_data
    slmc.update_newborn_info(:last_name => @or_patient2[:last_name], :advanced_search => true, :first_name => "Baby Boy",
      :last_name_new => @@newborn_info2[:last_name], :first_name_new => @@newborn_info2[:first_name], :middle_name_new => @@newborn_info2[:middle_name])
  end

  it "Bug #26126 Room Transfer * Inserts record to Room Transfer History even if there are no changes made on newborn's room/bed" do
    slmc.go_to_admission_page
    result = slmc.view_print_room_transfer_history
    record = result.split
    record.each do |w|
      w.gsub!(',','')
    end
    (slmc.is_text_present(@or_patient[:last_name])).should be_true
    record.count(@or_patient[:last_name]).should == 1 ##https://projects.exist.com/issues/46846
  end

  it "Bug #22641 - Room Transfer * Rooming-in charges should also be applied for rooming-in patients" do
    slmc.go_to_admission_page
    slmc.advanced_search(:last_name => @or_patient[:last_name], :first_name => "Baby Girl", :birthday => (Date.today).strftime("%m/%d/%Y"))
    if slmc.is_text_present("Master Patient Index is unavailable. Searching from local data...")
      @@newborn_pin = slmc.get_text('css=table[id="results"] tr[class="even"] td:nth-child(3)').gsub(' ', '')
    else
      @@newborn_pin = slmc.get_pin_from_search_results.gsub(' ','')
    end
    slmc.login(@user, @password).should be_true
    slmc.request_for_room_transfer(:pin => @@newborn_pin, :remarks => "Room transfer remarks", :first => true).should be_true

    slmc.login("sel_adm1",@password).should be_true
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@newborn_pin).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "For Room Transfer").should be_true

    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.search_patient_for_room_transfer(:pin => @@newborn_pin).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "Physically Transferred").should be_true

    slmc.login("sel_adm1",@password).should be_true
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@newborn_pin).should be_true
    slmc.update_room_transfer_action(:action => "Transfer Room Location", :transfer_type => "NURSING UNIT TRANSFER", :nursing_unit => "0301", :room => true, :org_code => "0301", :room_charge => "NURSERY", :close => true).should == "Room location updated."
  end

  it "Bug #27103 [Admission] Edit Room/Bed is not allowed for newborn in special units" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_admission_page
    slmc.advanced_search(:last_name => @or_patient2[:last_name], :first_name => "baby boy", :birthday => (Date.today).strftime("%m/%d/%Y"))
    if slmc.is_text_present("Master Patient Index is unavailable. Searching from local data...")
      @@newborn_pin2 = slmc.get_text('css=table[id="results"] tr[class="even"] td:nth-child(3)').gsub(' ', '')
    else
      @@newborn_pin2 = slmc.get_pin_from_search_results.gsub(' ','')
    end

    slmc.login("hoa1", @password).should be_true
    slmc.request_for_room_transfer(:pin => @@newborn_pin2, :remarks => "Room transfer remarks", :first => true).should be_true

    slmc.login("sel_adm1", @password).should be_true
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@newborn_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "For Room Transfer").should be_true

    slmc.login("hoa1", @password).should be_true
    slmc.go_to_general_units_page
    slmc.search_patient_for_room_transfer(:pin => @@newborn_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "Physically Transferred").should be_true

    slmc.login("sel_adm1", @password).should be_true
    slmc.go_to_admission_page
    slmc.transfer_room_location(:rooming_in => true, :transfer_type => "NURSING UNIT TRANSFER", :close => true)
    slmc.view_print_room_transfer_history
    slmc.click("css=#roomTransferTransactionHistoryRows>tr:nth-child(3)>td:nth-child(13)>div>a")
    sleep 5
    slmc.is_visible("divRturlPopup").should be_true
    slmc.click("btnRturlClose")
  end

  it "Room Transfer Mother - Newborn baby should equal to mothers room" do
    slmc.login(@user, @password)
    slmc.go_to_admission_page
    slmc.advanced_search(:last_name => @or_patient3[:last_name], :first_name => "baby boy", :birthday => (Date.today).strftime("%m/%d/%Y"))
    if slmc.is_text_present("Master Patient Index is unavailable. Searching from local data...")
      @@newborn_pin3 = slmc.get_text('css=table[id="results"] tr[class="even"] td:nth-child(3)').gsub(' ', '')
    else
      @@newborn_pin3 = slmc.get_pin_from_search_results.gsub(' ','')
    end
    slmc.nursing_gu_search(:pin => @@or_pin3)
    @@before_room_and_bed_mother = slmc.get_room_and_bed_no_in_gu_page
    slmc.request_for_room_transfer(:pin => @@or_pin3, :remarks => "Room transfer remarks", :first => true).should be_true

    slmc.login("sel_adm1", @password)
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@or_pin3)
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "For Room Transfer").should be_true

    slmc.login(@user, @password)
    slmc.go_to_general_units_page
    slmc.search_patient_for_room_transfer(:pin => @@or_pin3)
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "Physically Transferred").should be_true

    slmc.login("sel_adm1", @password)
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@or_pin3)
    slmc.update_room_transfer_action(:action => "Transfer Room Location", :transfer_type => "ROOM TRANSFER", :room_charge => "REGULAR PRIVATE", :room => true, :close => true).should == "Room location updated."

    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@or_pin3)
    @@room_and_bed_mother = slmc.get_room_and_bed_no_in_gu_page
    slmc.nursing_gu_search(:pin => @@newborn_pin3)
    @@room_and_bed_newborn = slmc.get_room_and_bed_no_in_gu_page
    @@room_and_bed_mother.should == @@room_and_bed_newborn
    slmc.access_from_database(:what => "RB_STATUS", :table => "REF_ROOM_BED",
      :column1 => "ORG_STRUCTURE", :condition1 => "0287", :gate => "AND",
      :column2 => "ROOMNO", :like => true, :condition2 => @@room_and_bed_mother[0]).should == "RBS04" # verify if room is admitted
    slmc.access_from_database(:what => "RB_STATUS", :table => "REF_ROOM_BED",
      :column1 => "ORG_STRUCTURE", :condition1 => "0287", :gate => "AND",
      :column2 => "ROOMNO", :like => true, :condition2 => @@before_room_and_bed_mother[0]).should == "RBS11"
  end

  it "Room Transfer newborn - Mother should still be admitted in same room" do
    slmc.request_for_room_transfer(:pin => @@newborn_pin3, :remarks => "Room transfer remarks", :first => true).should be_true

    slmc.login("sel_adm1", @password)
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@newborn_pin3)
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "For Room Transfer").should be_true

    slmc.login(@user, @password)
    slmc.go_to_general_units_page
    slmc.search_patient_for_room_transfer(:pin => @@newborn_pin3)
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "Physically Transferred").should be_true

    slmc.login("sel_adm1", @password)
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@newborn_pin3)
    slmc.update_room_transfer_action(:action => "Transfer Room Location", :transfer_type => "ROOM TRANSFER", :room_charge => "REGULAR PRIVATE", :room => true, :close => true).should == "Room location updated."

    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@or_pin3)
    slmc.get_room_and_bed_no_in_gu_page.should == @@room_and_bed_mother
    slmc.nursing_gu_search(:pin => @@newborn_pin3)
    slmc.get_room_and_bed_no_in_gu_page.should_not == @@room_and_bed_newborn
    slmc.access_from_database(:what => "RB_STATUS", :table => "REF_ROOM_BED",
      :column1 => "ORG_STRUCTURE", :condition1 => "0287", :gate => "AND",
      :column2 => "ROOMNO", :like => true, :condition2 => @@room_and_bed_mother[0]).should == "RBS04" # checks if mothers room is still admitted
  end

# Feature # 42839 below
  it "Verify that Left for Care setting is retained when mother is discharged" do
    slmc.login("billing_spec_user3",@password).should be_true
    slmc.validate_incomplete_orders(:inpatient => true, :pin => @@or_pin, :validate => true, :username => "sel_0287_validator", :drugs => true, :orders => "multiple").should be_true
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:inpatient => true, :pin => @@or_pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true

    slmc.login("sel_pba1",@password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.discharge_patient_either_standard_or_das.should be_true

    slmc.login("sel_adm2",@password).should be_true
    slmc.admission_search(:pin => @@newborn_pin)
    slmc.click "link=Update Newborn Info", :wait_for => :page
    slmc.is_checked("leftForCare1").should be_false
  end

  it "Verify that Left for Care correctly reflects actual setting in database" do
    slmc.access_from_database(:what => "LEFT_FOR_CARE", :table => "TXN_ADM_NEWBORN", :column1 => "MOTHERS_PIN", :condition1 => @@or_pin).should == "N"
  end

  it "Verify that Left for Care can be updated from unchecked to checked" do
    slmc.click "leftForCare1"
    sleep 1
    slmc.click'//input[@type="button" and @onclick="submitForm(this);" and @value="Submit" and @name="action"]', :wait_for => :page
    slmc.is_text_present("Patient admission details successfully saved.").should be_true
    slmc.admission_search(:pin => @@newborn_pin)
    slmc.click "link=Update Newborn Info", :wait_for => :page
    slmc.is_checked("leftForCare1").should be_true
  end

  it "Verify that Left for Care correctly reflects actual setting in database" do
    slmc.access_from_database(:what => "LEFT_FOR_CARE", :table => "TXN_ADM_NEWBORN", :column1 => "MOTHERS_PIN", :condition1 => @@or_pin).should == "Y"
  end

  it "Verify that Left for Care correctly reflects actual setting in database" do
    slmc.login("sel_dr1", @password).should be_true
    @@dr_pin = slmc.or_create_patient_record(@dr_patient.merge(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0170')).gsub(' ', '')
    slmc.register_new_born_patient(:pin => @@dr_pin, :bdate => (Date.today).strftime("%m/%d/%Y"), :birth_type => "SINGLE", :birth_order => "FIRST", :delivery_type => "OTHER",
      :weight => 4000, :length => 54, :doctor_name => "ABAD", :room_charge => "NURSERY", :newborn_inpatient_admission => true, :left_for_care => true,
      :rch_code => "RCH11", :org_code => "0301", :save => true)
    slmc.access_from_database(:what => "LEFT_FOR_CARE", :table => "TXN_ADM_NEWBORN", :column1 => "MOTHERS_PIN", :condition1 => @@dr_pin).should == "Y"
  end

  it "Verify that Admission Type is set to Newborn when Left for Care is set" do
    slmc.login("sel_adm1", @password).should be_true
    slmc.go_to_admission_page
    slmc.advanced_search(:last_name => @dr_patient[:last_name], :first_name => "Baby Boy", :birthday => (Date.today).strftime("%m/%d/%Y"))
    if slmc.is_text_present("Master Patient Index is unavailable. Searching from local data...")
      @@newborn_pin4 = slmc.get_text('css=table[id="results"] tr[class="even"] td:nth-child(3)').gsub(' ', '')
    else
      @@newborn_pin4 = slmc.get_pin_from_search_results.gsub(' ','')
    end
    
    slmc.click("css=#pendingNewborn>a")
    sleep 30
    slmc.is_element_present("link=#{@@newborn_pin4}").should be_true
    slmc.click("link=#{@@newborn_pin4}", :wait_for => :page)
    slmc.select "civilStatus.code", "SINGLE"
    slmc.select"presentContactSelect", "MOBILE"
    slmc.type "presentContact1", "12309674"
    slmc.type "patientAdditionalDetails.occupation", "N/A"
    slmc.type "patientAdditionalDetails.employer", "N/A"
    slmc.type "patientAddresses[2].streetNumber", "NA"
    sleep 1
    slmc.click '//input[@type="button" and @value="Proceed to Create New Admission" and @onclick="submitForm(this);" and @name="action"]', :wait_for => :page
    slmc.get_value("admissionTypeCode").should == "ADT05"
    slmc.get_selected_label("admissionTypeCode").should == "NEWBORN"
  end

  it "Verify that Left for Care setting is retained when mother is discharged" do
    slmc.login("sel_dr1", @password).should be_true
    slmc.go_to_occupancy_list_page
    @@visit_no1 = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@dr_pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true

    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no1)
    slmc.select_discharge_patient_type(:type => "DAS").should be_true

    slmc.login("sel_dr1", @password).should be_true
    slmc.or_print_gatepass(:pin => @@dr_pin, :visit_no => @@visit_no1).should be_true

    slmc.login("sel_adm1", @password).should be_true
    slmc.admission_search(:pin => @@newborn_pin4)
    slmc.click("link=Update Newborn Info", :wait_for => :page)
    slmc.is_checked("leftForCare1").should be_true
  end

  it "Verify that Left for Care correctly reflects actual setting in database" do
    slmc.access_from_database(:what => "LEFT_FOR_CARE", :table => "TXN_ADM_NEWBORN", :column1 => "MOTHERS_PIN", :condition1 => @@dr_pin).should == "Y"
  end

  it "Verify that Left for Care can be updated from checked to unchecked" do
    slmc.click("leftForCare1")
    sleep 1
    slmc.click('//input[@type="button" and @onclick="submitForm(this);" and @value="Submit" and @name="action"]', :wait_for => :page)
    slmc.is_text_present("Patient admission details successfully saved.").should be_true
    slmc.admission_search(:pin => @@newborn_pin4)
    slmc.click("link=Update Newborn Info", :wait_for => :page)
    slmc.is_checked("leftForCare1").should be_false
  end

  it "Verify that Left for Care correctly reflects actual setting in database" do
    slmc.access_from_database(:what => "LEFT_FOR_CARE", :table => "TXN_ADM_NEWBORN", :column1 => "MOTHERS_PIN", :condition1 => @@dr_pin).should == "N"
  end

end
