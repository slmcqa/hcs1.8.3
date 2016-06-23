require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Admission Page Enchancements - Feature of #39739" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @user = "sel_adm7"

    @member_type = ["SSS", "GSIS", "OWWA", "LIFETIME MEMBER", "SELF EMPLOYED/INDIVIDUAL PAYING MEMBER", "INDIGENT"]
    @relation_to_member = ["MEMBER", "SPOUSE", "CHILD", "PARENTS"]
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Patient info data entry new additional fields" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    slmc.click Locators::Admission.create_new_patient, :wait_for => :page
    sleep 3
    slmc.is_visible("patientIds0.phMemberTypeCode").should be_false
    slmc.is_visible("patientIds0.phRelationshipCode").should be_false
    slmc.is_text_present("Member Type:").should be_false
    slmc.is_text_present("Relationship to member:").should be_false
    slmc.select("patientIds0.idTypeCode", "PHILHEALTH CARD")
    sleep 3
    slmc.is_visible("patientIds0.phMemberTypeCode").should be_true
    slmc.is_visible("patientIds0.phRelationshipCode").should be_true
    slmc.is_text_present("Member Type:").should be_true
    slmc.is_text_present("Relationship to member:").should be_true

    slmc.is_editable("patientIds0.phMemberTypeCode").should be_true
    slmc.is_editable("patientIds0.phRelationshipCode").should be_true
  end

  it "Philhealth card number not a mandatory field" do
    slmc.populate_patient_info(Admission.generate_data)
    slmc.type("patientIds0.idNo", "12345")
    slmc.click Locators::Admission.create_new_admission, :wait_for => :page
    slmc.is_text_present("Patient successfully saved.").should be_true
    @@pin2 = slmc.get_text(Locators::Registration.admission_pin).gsub(' ', '')
  end

  it "Bug #40218 - [Patient Information] User changes patient PH Member ID, doesn't update patient information and in database" do
    @@id = slmc.access_from_database(
    :what => "ID",
    :table => "TXN_PATMAS_ID",
    :column1 => "PIN",
    :condition1 => @@pin2)#.should be_true
    slmc.admission_search(:pin => @@pin2)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
    sleep 60
    slmc.login("sel_pba13", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:admitted => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    sleep 60
    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "10060", :philhealth_number => "54321", :compute => true)
    slmc.ph_save_computation
    slmc.access_from_database(
    :what => "ID_NO",
    :table => "TXN_PATMAS_ID",
    :column1 => "ID",
    :condition1 => @@id).should == "7654327"
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin2)
    slmc.click "link=Update Patient Info", :wait_for => :page
    slmc.get_value("patientIds0.idNo").should == "7654327"
  end

  it "Additional dropdrown fields is mandatory" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    slmc.click Locators::Admission.create_new_patient, :wait_for => :page
    slmc.select("patientIds0.idTypeCode", "PHILHEALTH CARD")
    slmc.is_editable("patientIds0.phMemberTypeCode").should be_true
    slmc.is_editable("patientIds0.phRelationshipCode").should be_true
    slmc.select("patientIds0.phMemberTypeCode", "LIFETIME MEMBER")
    slmc.select("patientIds0.phRelationshipCode", "CHILD")

    slmc.get_selected_label("patientIds0.phMemberTypeCode").should == "LIFETIME MEMBER"
    slmc.get_selected_label("patientIds0.phRelationshipCode").should == "CHILD"

    slmc.get_select_options("patientIds0.phMemberTypeCode").should == @member_type
    slmc.get_select_options("patientIds0.phRelationshipCode").should == @relation_to_member
  end

  it "Properly fill up the additional mandatory fields" do
    slmc.populate_patient_info(Admission.generate_data)
    slmc.type("patientIds0.idNo", "1234567")
    slmc.click Locators::Admission.preview, :wait_for => :page
    slmc.click Locators::Admission.save_patient, :wait_for => :page
    slmc.is_text_present("Patient successfully saved.").should be_true
    @@pin = slmc.get_text(Locators::Registration.pin)

    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Check DB table TXN_PATMAS if the PH_MEMBER_TYPE and PH_RELATIONSHIP is added and information encode is save" do
    slmc.access_from_database(:what => "PH_MEMBER_TYPE", :table => "TXN_PATMAS", :column1 => "PIN", :condition1 => @@pin).should == "LTM0001"
    slmc.access_from_database(:what => "PH_RELATIONSHIP", :table => "TXN_PATMAS", :column1 => "PIN", :condition1 => @@pin).should == "CHI"
  end

  it "Display on all patient banner applicable pages the philhealth notation define during patient info data entry" do
    slmc.login("sel_pba13", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:all_patients => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.get_text("banner.accountClass").should == "Individual with Philhealth"
  end

  it "No patient philhealth card number define patient info data entry form" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin2 = slmc.create_new_patient(Admission.generate_data)
    slmc.admission_search(:pin => @@pin2)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."

    slmc.login("sel_pba13", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    slmc.get_text("banner.accountClass").should == "Individual"
  end

  it "Check DB table TXN_PATMAS_ID if the PH_MEMBER_TYPE and PH_RELATIONSHIP is added and information encode is save" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin3 = slmc.create_new_patient(Admission.generate_data.merge!(:id_type1 => "PHILHEALTH CARD", :patient_id1 => "1234567", :member_type1 => "SSS", :member_relation1 => "MEMBER"))
    slmc.is_text_present("Patient successfully saved.").should be_true
    slmc.admission_search(:pin => @@pin3)
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."

    slmc.access_from_database(:what => "*", :table => "TXN_PATMAS_ID", :column1 => "PIN", :condition1 => @@pin3).should == @@pin3
    sleep 60
    slmc.login("sel_pba13", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@pin3)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    slmc.get_text("banner.accountClass").should == "Individual with Philhealth"
    sleep 60
    @@ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation

    slmc.access_from_database(:what => "*", :table => "TXN_PATMAS_ID", :column1 => "PIN", :condition1 => @@pin3).should == @@pin3
  end

  it "User encode patient PH card number in admission then changes it during PH claim computation" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin3)
    slmc.update_patient_info(:religion => "ROMAN CATHOLIC", :id_type1 => "COMPANY ID", :save => true).should be_true

    slmc.login("sel_pba13", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@pin3)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    slmc.get_text("banner.accountClass").should == "Individual"
    
    slmc.access_from_database(:what => "*", :table => "TXN_PATMAS_ID", :column1 => "PIN", :condition1 => @@pin3).should == @@pin3
  end

end