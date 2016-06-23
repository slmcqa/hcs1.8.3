require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Scenarios about Room Transfer" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @gu_patient = Admission.generate_data
    @gu_patient2 = Admission.generate_data
    @gu_patient3 = Admission.generate_data
    @user = "billing_spec_user8"
    @password = "123qweuser"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates new patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@gu_pin = slmc.create_new_patient(@gu_patient.merge(:gender => 'F')).gsub(' ','')

    slmc.admission_search(:pin => "1")
    @@gu_pin2 = slmc.create_new_patient(@gu_patient2.merge(:gender => 'M')).gsub(' ','')

    slmc.admission_search(:pin => "1")
    @@gu_pin3 = slmc.create_new_patient(@gu_patient3.merge(:gender => 'M')).gsub(' ','')
  end

  it "Admits GU patient" do
    slmc.admission_search(:pin => @@gu_pin).should be_true
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08',
      :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@gu_pin)
    @@room_and_bed1 = slmc.get_room_and_bed_no_in_gu_page
  end

  it "Verifies that the admitted room is not available in the list" do
    slmc.admission_search(:pin => @@gu_pin2).should be_true
    slmc.click("link=Admit Patient", :wait_for => :page)
    slmc.wait_for(:wait_for => :text, :text => "REGULAR PRIVATE")
    slmc.select "roomChargeCode", "label=REGULAR PRIVATE"
    slmc.find_room_using_room_charge(:rch_code => "RCH08", :org_code => "0287")
    slmc.get_text("rbf_finder_table_body").include?(@@room_and_bed1[0]).should be_false
    slmc.get_text("rbf_finder_table_body").include?(@@room_and_bed1[1]).should be_false

    slmc.admission_search(:pin => @@gu_pin2).should be_true
    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08',
      :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@gu_pin2)
    @@room_and_bed2 = slmc.get_room_and_bed_no_in_gu_page
  end

  it "GU user requests for room transfer - GU patient 2" do
    slmc.request_for_room_transfer(:pin => @@gu_pin2, :remarks => "Room transfer remarks", :first => true).should be_true
  end

  it "Admin user updates request of room transfer for GU patient 2 to feedback then assigns to In-house collection" do
    slmc.login("sel_adm2",@password).should be_true
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "With Feedback", :in_house => true).should be_true
  end

  it "Admin verifies status of request for room transfer - PENDING" do
    sleep 5
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    (slmc.get_room_transfer_search_results.include? "PENDING").should be_true
  end

  it "Bug 22361 - In house collection verifies patient on the room transfer patient list" do
    slmc.login("sel_inhouse1", @password).should be_true
    slmc.go_to_in_house_landing_page
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
  end

  it "Inhouse verifies status of request for room transfer - WITH FEEDBACK" do
    @@inhouse_count = slmc.get_room_transfer_count
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    (slmc.get_room_transfer_search_results.include? "WITH FEEDBACK").should be_true
  end

  it "Bug 22528 - In house collection updates room transfer status and assigns to Admission" do
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "With Feedback").should be_true
  end

  it "Verifies number of room transfer displayed in the link decrements in In House landing page" do
    slmc.go_to_in_house_landing_page
    slmc.get_room_transfer_count.should == (@@inhouse_count - 1)
  end

  it "Admission updates request for room transfer" do
    slmc.login("sel_adm2", @password).should be_true
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "For Room Transfer").should be_true
  end

  it "GU user updates status of request to physically transferred" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    @@gu_count = slmc.get_room_transfer_count
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "Physically Transferred").should be_true
  end

  it "Verifies number of room transfer displayed in the link decrements in General Units page" do
    slmc.go_to_general_units_page
    slmc.get_room_transfer_count.should == (@@gu_count - 1)
  end

  it "Room Transfer - Should be able to cancel request and Request again for room transfer" do # Feature # 46051 - Room Transfer Request: Unable to Cancel Request
    slmc.login("sel_adm2", @password).should be_true
    slmc.go_to_admission_page
    @@cancel_count = slmc.get_room_transfer_count
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "Cancelled").should be_true
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_false
    slmc.go_to_admission_page
    slmc.get_room_transfer_count.should == (@@cancel_count - 1)

    slmc.login(@user, @password).should be_true
    slmc.request_for_room_transfer(:pin => @@gu_pin2, :remarks => "Room transfer remarks", :first => true).should be_true

    slmc.login("sel_adm2", @password).should be_true
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "For Room Transfer").should be_true

    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Update Request Status", :request_status => "Physically Transferred").should be_true
  end

  it "Admission verifies status of request - PHYSICALLY TRANSFERRED" do
    slmc.login("sel_adm2", @password).should be_true
    slmc.go_to_admission_page
    @@adm_count = slmc.get_room_transfer_count
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    (slmc.get_room_transfer_search_results.include? "PHYSICALLY TRANSFERRED").should be_true
  end

  it "Bug 22287 - Prompts alert when saving room location with the same room the patient is admitted" do
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Transfer Room Location", :transfer_type => "ROOM TRANSFER", :room_charge => "REGULAR PRIVATE", :room_no => @@room_and_bed2[0], :bed_no => @@room_and_bed2[1], :close => true).should == "Cannot transfer to same room and/or bed. Please update room/bed."
  end

  it "Bug 22283 - Prompts alert when saving room location that is already occupied" do
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    slmc.update_room_transfer_action(:action => "Transfer Room Location", :transfer_type => "ROOM TRANSFER", :room_charge => "REGULAR PRIVATE", :room_no => @@room_and_bed1[0], :bed_no => @@room_and_bed1[1], :close => true).should ==  "Either Room/Bed is already occupied."
  end

  it "Admission updates room location successfully" do
    slmc.go_to_admission_page
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2)
    slmc.update_room_transfer_action(:action => "Transfer Room Location", :transfer_type => "ROOM TRANSFER", :room_charge => "REGULAR PRIVATE", :room => true).should == "Room location updated."
  end

  it "Verifies number of room transfer displayed in the link decrements in Admission page" do
    slmc.go_to_admission_page
    slmc.get_room_transfer_count.should == (@@adm_count - 1)
  end

  it "Bug 22076 - Reprint room/bed successfully" do
    slmc.go_to_admission_page
    slmc.reprint_room_bed.should be_true
  end

  it "Bug 22178 - View room transfer history successfully" do
    slmc.go_to_admission_page
    (slmc.view_print_room_transfer_history.empty?).should be_false
    slmc.print_room_transfer_transactions.should be_true
  end

  it "Bug 22176 - Request new room transfer to View Room Transfer History" do
    slmc.login(@user, @password).should be_true
    slmc.request_for_room_transfer(:pin => @@gu_pin2, :remarks => "Room transfer remarks", :first => true).should be_true
    slmc.search_patient_for_room_transfer(:pin => @@gu_pin2).should be_true
    (slmc.update_room_transfer_action(:action => "View Room Transfer History").include? @@gu_pin2).should be_true
  end

  it "Check box for Additional Bed is present" do
    slmc.admission_search(:pin => @@gu_pin3).should be_true
    slmc.click("link=Admit Patient", :wait_for => :page)
    slmc.wait_for(:wait_for => :text, :text => "REGULAR PRIVATE")
    slmc.is_element_present("chkTempFloater").should be_true
    #slmc.is_element_present("tempRoomChargeFlag").should be_true
  end

  it "Room charge option/choice will only be 'Maternity Floater'" do
    #slmc.click("tempRoomChargeFlag")
    slmc.click("chkTempFloater")
    sleep 5
    #slmc.get_select_options("roomChargeCode").should == ["Select Charge", "MATERNITY FLOATER", "TEMPORARY ROOM-BED", "HALF-RATE PRESIDENTIAL SUITE", "HALF-RATE DE LUXE PRIVATE", "HALF-RATE MATERNITY FLOATER", "HALF-RATE SPECIAL UNITS"]
    slmc.get_selected_label("roomChargeCode").should == "MATERNITY FLOATER"
  end

  it "Temporary Room check box will automatically be checked" do
    slmc.click("chkTempFloater")
    slmc.select("roomChargeCode", "MATERNITY FLOATER")
    sleep 1
    slmc.is_checked("chkTempFloater").should be_true
  end

  it "Admit Patient in Maternity Floater" do
    slmc.admission_search(:pin => @@gu_pin3).should be_true
    slmc.create_new_admission(:room_charge => "MATERNITY FLOATER", :rch_code => 'RCH40',
      :org_code => '0287', :diagnosis => "GASTRITIS", :additional_bed => true).should == "Patient admission details successfully saved."
    slmc.nursing_gu_search(:pin => @@gu_pin3)
    @@room_and_bed3 = slmc.get_room_and_bed_no_in_gu_page
  end

end
