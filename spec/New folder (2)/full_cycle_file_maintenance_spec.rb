require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: File Maintenance Module Test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @user = 'sel_fm1'
    @password = '123qweuser'
    @doctor_info = Admission.generate_doctor_data
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  # Doctor
  it "Search doctor : Filter by Department" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_doctors
    slmc.doctor_search(:department => "OPERATING ROOM - MAIN").should be_true
    slmc.doctor_search(:department => "OPERATING ROOM - MAB").should be_false
  end

  it "Search doctor : Filter by Position" do
    slmc.go_to_doctors
    slmc.doctor_search(:position => "HEAD").should be_true
    slmc.doctor_search(:department => "LOGISTICS").should be_false
  end

  it "Search doctor : Filter by Specialization" do
    slmc.go_to_doctors
    slmc.doctor_search(:specialization => "CARDIOLOGY").should be_true
    slmc.doctor_search(:department => "MAGNETIC RESONANCE IMAGING").should be_false
  end

  it "Add Doctor" do
    slmc.go_to_doctors
    slmc.add_doctor(@doctor_info.merge!(:gender => 'M', :add => true)).should == "Doctor is saved successfully."
    @@doctor_code = @doctor_info[:doc_code]
  end

  it "Edit Doctor" do
    slmc.go_to_doctors
    slmc.doctor_search(:pin => @@doctor_code).should be_true
    slmc.edit_doctor(:doctor_code => @@doctor_code, :medical_status => "ACTIVE", :edit => true).should be_true
  end

  it "Delete Doctor" do
    slmc.go_to_doctors
    slmc.doctor_search(:pin => @@doctor_code).should be_true
    slmc.edit_doctor(:doctor_code => @@doctor_code, :delete => true).should be_true
  end

  #Room and Board
  it "Display Room Charging" do
    slmc.go_to_room_and_board
    slmc.room_and_board_view(:room_charging => true).should be_true
  end

  it "Display Room and Bed" do
    slmc.room_and_board_view(:room_bed => true).should be_true
  end

  it "Display Room and Bed Status" do
    slmc.room_and_board_view(:room_bed_status => true).should be_true
  end

  it "Display Room Class" do
    slmc.room_and_board_view(:room_class => true).should be_true
  end

  #Services and Rate
  it "Search Service" do
    slmc.go_to_services_and_rates
    slmc.find_service(:service => "010000008")
    slmc.get_text("css=#results>tbody>tr>td").should == "010000008"
  end

#  it "Add Service" do
#    slmc.go_to_services_and_rates
#    @@code = slmc.add_new_service
#  end
#
#  it "Edit Service" do
#    slmc.go_to_services_and_rates
#    slmc.find_service(:service => @@code)
#    slmc.click("aSvcf-1")
#    sleep 5
#    slmc.type("txtSvcfDesc", "SELENIUM ITEM1")
#    sleep 2
#    slmc.click "btnSvcfOk" , :wait_for => :page
#    slmc.is_text_present("Successfully updated Service File '040462424'").should be_true
#  end
#
#  it "Delete Service" do
#    slmc.go_to_services_and_rates
#    slmc.find_service(:service => @@code)
#    slmc.click("//a[@id='aSvcfDel-1']/img")
#    sleep 3
#    slmc.click("btnMyConfirmOk", :wait_for => :page)
#  end

  it "Print Pricelist : Display and select org. units" do
    slmc.go_to_services_and_rates
    slmc.click("btnSvcfPrintPrcLst")
    sleep 3
    slmc.is_element_present("lstPrcLstOrgUnitsLeft").should be_true
    slmc.is_element_present("selPrcLstOrdType").should be_true
  end

  it "Print Pricelist : Display order types" do
    slmc.get_select_options("selPrcLstOrdType").include?("DRUGS / MEDICINE").should be_true
  end

  it "Print Pricelist : Print" do
    slmc.click("btnPrcLstPrint", :wait_for => :element, :element => "btnMyConfirmOk")
    slmc.click("btnMyConfirmOk")
    slmc.is_element_present("txtQuery").should be_true
  end

  it "Service Rate : Display Service Rate" do
    slmc.go_to_services_and_rates
    slmc.click("link=ServiceRate", :wait_for => :page)
    slmc.get_text("breadCrumbs").should == "File Maintenance › Service › Service Rates"
  end

  it "Service Rate : Search Service Rate" do
    slmc.find_service(:service => "SELENIUM ITEM1").should be_true
  end

  it "Service Rate : Add Service Rate" do
    slmc.go_to_services_and_rates
    slmc.click("link=ServiceRate", :wait_for => :page)
    slmc.add_service_rate(:code => "0004SELENIUMFM", :status => "Active", :rate => "1000.00", :admin_cost => "1500.00",
      :readers_fee => "1500.00", :ref_service => "SELENIUM ITEM1", :room_class => "PRIVATE ROOM", :save => true).should be_true
  end

  # Feature #45430
  it "Add a duplicate ICD10 code" do
    slmc.go_to_icd10_page
    slmc.fm_add_icd10(:code => "A00", :description => "CHOLERA", :save => true).should == "Cannot add icd10 A00. It already exists."
  end

  it "Add ICD10 code" do
    slmc.go_to_icd10_page
    slmc.fm_add_icd10(:code => "SEL00", :description => "Selenium Testing Only", :save => true).should == "Icd10 SEL00 has been added successfully."
  end

  it "Edit existing ICD10 codes" do
    slmc.go_to_icd10_page
    slmc.fm_search_icd10(:code => "SEL00").should be_true
    slmc.fm_edit_icd10(:code => "SEL00", :description => "Selenium Edit", :save => true).should == "Icd10 SEL00 has been updated successfully."
    slmc.fm_search_icd10(:code => "SEL00").should be_true
    slmc.get_text("//table[@id='results']/tbody/tr/td[2]").should == "Selenium Edit"
    slmc.fm_edit_icd10(:code => "SEL00", :description => "Selenium Testing Only", :save => true).should == "Icd10 SEL00 has been updated successfully."
  end

  it "Clicks Cancel button when Editing ICD10" do
    slmc.go_to_icd10_page
    slmc.fm_search_icd10(:code => "SEL00").should be_true
    slmc.fm_edit_icd10(:code => "SEL00", :description => "Selenium Edit", :cancel => true).should be_true
  end

  it "Verify if ICD10 Code is disabled during Edit" do
    slmc.go_to_icd10_page
    slmc.fm_search_icd10(:code => "SEL00").should be_true
    slmc.fm_edit_icd10(:code => "SEL00", :description => "Selenium Edit")
    slmc.get_value("icd10_code").should == "SEL00"
    slmc.is_visible("icd10_code").should be_false
  end

  it "Delete added ICD10" do
    slmc.go_to_icd10_page
    slmc.fm_search_icd10(:code => "SEL00").should be_true
    slmc.fm_edit_icd10(:code => "SEL00", :description => "Selenium Edit", :delete => true).should == "Icd10 SEL00 has been deleted successfully."
    slmc.fm_search_icd10(:code => "SEL00").should be_false
  end

end