require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Special Units Tests" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @or_patient = Admission.generate_data
    @or_patient2 = Admission.generate_data
    @er_patient = Admission.generate_data
    @password = "123qweuser"
    @soa_month = Time.now.strftime("%m")
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Create patients record for OR" do
    slmc.login("sel_or1", @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient.merge(:admit => true, :gender => 'F')).gsub(' ', '').should be_true

    @@or_pin2 = slmc.or_create_patient_record(@or_patient2.merge(:admit => true, :gender => 'F')).gsub(' ', '').should be_true
  end

  it "Updates the patient information" do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.or_update_patient_info(:pin => @@or_pin, :save => true).should be_true
  end

  it "Updates patient registration by cancelling its admission" do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.click_update_registration(:cancel => true, :pin => @@or_pin).should be_true
  end

  it "Bug #24976 PhilHealth-OR * Unable to save PhilHealth as Estimate" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin2)
    slmc.search_order(:drugs => true, :description => "BABYHALER").should be_true
    slmc.add_returned_order(:drugs => true, :description => "BABYHALER", :quantity => 2, :stat => true, :stock_replacement => true,
      :frequency => "ONCE A WEEK", :add => true).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_item("BABYHALER").should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin2).should be_true
    slmc.go_to_su_page_for_a_given_pin("Discharge Instructions\302\240", @@or_pin2)
    slmc.add_final_diagnosis(:save => true)
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin2).should be_true
    slmc.go_to_su_page_for_a_given_pin("Doctor and PF Amount", @@or_pin2)
    slmc.clinical_discharge(:no_pending_order => true, :pf_amount => "1000", :type => "standard").should be_true
    slmc.login("sel_pba5", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @visit_no = slmc.pba_search(:pin => @@or_pin2)
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@or_pin2).should be_true
    slmc.click_philhealth_link.should be_true
    slmc.is_editable("claimType").should be_true
  end

  it "Registers the patient again" do
    slmc.login("sel_or1", @password).should be_true
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "Bug #22733 - Verifies that Cancel Registration button is enabled in Patient's List page" do
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.click_cancel_registration.should be_true
    slmc.or_register_patient(:pin => @@or_pin, :org_code => "0164").should be_true
  end

  it "Test if input field for Search accepts either description or item code" do
    slmc.go_to_occupancy_list_page.should be_true
    slmc.go_to_order_page(:pin => @@or_pin)
    slmc.search_order(:drugs => true, :description =>  "040004334").should be_true
    slmc.search_order(:supplies => true, :description => "080200000").should be_true
    slmc.search_order(:ancillary => true, :description => "010000003").should be_true
    slmc.search_order(:others => true, :description => "050000009").should be_true
    slmc.search_order(:drugs => true, :description => "SOLUSET").should be_true
    slmc.search_order(:supplies => true, :description => "NASO-TRACHEAL TUBE IVORY S7").should be_true
    slmc.search_order(:ancillary => true, :description => "BONE IMAGING - THREE PHASE STUDY").should be_true
    slmc.search_order(:others => true, :description => "BLOOD WARMER - SUCCEDING HOUR").should be_true
  end

  it "Performs clinical ordering - SPECIAL" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin)
    slmc.search_order(:special => true).should be_true
    slmc.add_returned_order(:special => true, :special_description => "SPECIAL ITEM TEST", :add => true).should be_true
    slmc.er_submit_added_order.should be_true
    slmc.validate_item("SPECIAL ITEM TEST").should be_true
  end

  it "Bug #24132 - Ordered 9999 items should be reflected in Order List page SPECIAL Tab " do
    slmc.go_to_occupancy_list_page.should be_true
    slmc.patient_pin_search(:pin => @@or_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin).should be_true
    slmc.search_order_list(:type => "special", :item => "SPECIAL ITEM TEST").should be_true
  end

  it "Performs clinical ordering - DRUGS" do
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin)
    sleep 2
    @@visit_no = slmc.get_text("banner.visitNo").gsub(' ', '')
    slmc.search_order(:drugs => true, :description => "BABYHALER")
    slmc.add_returned_order(:drugs => true, :description => "BABYHALER", :quantity => 2,
      :stat => true, :stock_replacement => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    slmc.er_submit_added_order(:validate => true).should be_true
    slmc.validate_item("BABYHALER").should be_true
  end

  it "Bug #24132 - DRUGS item should be reflected in Order List page DRUGS Tab " do
    slmc.go_to_occupancy_list_page.should be_true
    slmc.patient_pin_search(:pin => @@or_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin).should be_true
    slmc.search_order_list(:type => "drugs", :item => "040004334").should be_true
  end

  it "Reprint Request Slip Prooflist" do
    slmc.click("//input[@value='Print']")
    sleep 5
    slmc.click'//html/body/div[7]/div[11]/div/button' if slmc.is_text_present'Select Printer For Non-Checklist Orders'
    sleep 2
    slmc.is_element_present("searchOrders").should be_true
  end

  it "Performs clinical ordering - SUPPLIES" do
    slmc.get_alert if slmc.is_alert_present
    slmc.go_to_occupancy_list_page.should be_true
    slmc.go_to_order_page(:pin => @@or_pin)
    slmc.search_order(:supplies => true, :description => "BATH TOWEL").should be_true
    slmc.add_returned_order(:supplies => true, :description => "BATH TOWEL", :quantity => 2, :stat => true, :stock_replacement => true, :add => true).should be_true
    slmc.er_submit_added_order.should be_true
    slmc.validate_item("BATH TOWEL").should be_true
  end

  it "Bug #24132 - SUPPLIES item should be reflected in Order List page SUPPLIES Tab " do
    slmc.go_to_occupancy_list_page.should be_true
    slmc.patient_pin_search(:pin => @@or_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin).should be_true
    slmc.search_order_list(:type => "supplies", :item => "BATH TOWEL").should be_true
  end

  it "Performs clinical ordering - ANCILLARY" do
    slmc.go_to_occupancy_list_page.should be_true
    slmc.go_to_order_page(:pin => @@or_pin)
    slmc.search_order(:ancillary => true, :description => "ALDOSTERONE").should be_true
    slmc.add_returned_order(:ancillary => true, :description => "ALDOSTERONE", :add => true).should be_true
    slmc.er_submit_added_order.should be_true
    slmc.validate_item("ALDOSTERONE").should be_true
  end

  it "Bug #24132 - ANCILLARY items should be reflected in Order List page ANCILLARY Tab " do
    slmc.go_to_occupancy_list_page.should be_true
    slmc.patient_pin_search(:pin => @@or_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin).should be_true
    slmc.search_order_list(:type => "ancillary", :item => "ALDOSTERONE").should be_true
  end

  it "Performs clinical ordering - OTHERS" do
    slmc.go_to_occupancy_list_page.should be_true
    slmc.go_to_order_page(:pin => @@or_pin)
    slmc.search_order(:others => true, :description => "ADDITIONAL CAUTERY MACHINE").should be_true
    slmc.add_returned_order(:others => true, :description => "ADDITIONAL CAUTERY MACHINE", :add => true).should be_true
    slmc.er_submit_added_order.should be_true
    slmc.validate_item("ADDITIONAL CAUTERY MACHINE").should be_true
  end

  it "Bug #24132 - OTHERS items should be reflected in Order List page OTHERS Tab" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin).should be_true
    slmc.search_order_list(:type => "misc", :item => "ADDITIONAL CAUTERY MACHINE").should be_true
  end

  it "Adds checklist order - PROCEDURE" do
    slmc.or_add_checklist_order(:pin => @@or_pin, :procedure => "CIRCUMCISION", :doctor => "0126").should be_true
  end

  it "Validates checklist order - PROCEDURE" do
    slmc.confirm_checklist_order.should be_true
    slmc.validate_orders(:procedures => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it "Adds checklist order - SUPPLIES AND EQUIPMENT" do
    slmc.or_add_checklist_order(:pin => @@or_pin, :supplies_equipment => "ALCOHOL SWAB", :doctor => "0126").should be_true
  end

  it "Validates checklist order - SUPPLIES AND EQUIPMENT" do
    slmc.confirm_checklist_order.should be_true
    slmc.validate_item("ALCOHOL SWAB").should be_true
  end

  it "Adds checklist order and Validate - OTHERS/MISCELLANEOUS" do
    slmc.or_add_checklist_order(:pin => @@or_pin, :supplies_equipment => "AMBO BAG", :doctor => "0126").should be_true
    slmc.confirm_checklist_order.should be_true
    slmc.validate_item("AMBO BAG").should be_true
  end

  it "Edits checklist order Supplies and Equipment" do
    slmc.go_to_outpatient_nursing_page.should be_true
    slmc.search_soa_checklist_order(:date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month).should be_true
    slmc.type("param", @@or_pin)
    slmc.click("search", :wait_for => :page)
    slmc.adjust_checklist_order # 1.5 can't adjust to higher value
    if (slmc.get_text"css=#clo_tbody_np>tr.even>td").include?"Edit"
      slmc.checklist_order_adjustment(:edit => true, :aqty => "0") #, :sqty => "2")
    else
      slmc.type("oif_entity_finder_key","ALCOHOL SWAB")
      slmc.click("//input[@type='radio' and @name='procedureFlag' and @value='N']")
      slmc.click("search")
      sleep 1
      slmc.click("_addButton")
      sleep 1
      slmc.checklist_order_adjustment(:edit => true, :aqty => "0") #, :sqty => "2")
    end
  end

  it "Verifies wrong range of date for checklist order" do
    slmc.search_soa_checklist_order(:date_today => (Date.today).strftime("%m/%d/%Y"), :date2 => (Date.today-1).strftime("%m/%d/%Y"), :soa_number => @soa_month).should be_true
  end

  it "Reprints the checklist order" do
    slmc.search_soa_checklist_order(:date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month).should be_true
    slmc.reprint_checklist_order(:no_printer => false).should be_true
  end

#  it "Adjusts checklist order - Add" do #1.5 not applicable
#    slmc.search_soa_checklist_order(:pin => @@or_pin, :date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month).should be_true
#    slmc.adjust_checklist_order
#    slmc.checklist_order_adjustment(:add => true, :checklist_order => "RENAL ANGIOGRAM").should be_true
#  end

  it "Adjusts checklist order - Remove" do
    slmc.search_soa_checklist_order(:pin => @@or_pin, :date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month).should be_true
    count = slmc.get_css_count("css=#results>tbody>tr")
    slmc.click"css=#results>tbody>tr:nth-child(#{count})>td:nth-child(6)>div>a", :wait_for => :page
    slmc.checklist_order_adjustment(:remove => true).should be_true # remove first procedure from the table
  end

  it "Adds checklist order for cancellation" do
    slmc.or_add_checklist_order(:pin => @@or_pin, :procedure => "APPENDECTOMY", :doctor => "0126").should be_true
    slmc.confirm_checklist_order.should be_true
    slmc.validate_item("APPENDECTOMY").should be_true
    slmc.search_soa_checklist_order(:pin => @@or_pin, :date_today => (Date.today).strftime("%m/%d/%Y"), :soa_number => @soa_month).should be_true #(Date.today + 1).strftime("%m/%d/%Y") Time.now.strftime("%m/%d/%Y")
    slmc.adjust_checklist_order
    @@soa_number = slmc.get_soa_number
    #slmc.checklist_order_adjustment(:add => true, :checklist_order => "TONSILLECTOMY").should be_true #1.5 adding of checklist order not allowed.
  end

  it "Cancels checklist order" do
    slmc.search_soa_checklist_order(:soa_number => @@soa_number).should be_true
    slmc.cancel_checklist_order(:soa_number => @@soa_number).should be_true
  end

  it "Updates Action status to CANCELLED" do
    slmc.search_soa_checklist_order(:soa_number => @@soa_number).should be_true
    slmc.get_text("css=#results>tbody>tr.even>td:nth-child(6)>div").should == "CANCELLED"
  end

   it "Clinical Ordering for PROCEDURE - Validates item with null value for Surgeon" do
    slmc.or_add_checklist_order(:pin => @@or_pin, :procedure => "LUNG BIOPSY")
  end

  it "Validate items with null value in quantity for Surgeon" do
    slmc.edit_checklist_order(:procedure => "LUNG BIOPSY", :quantity => 0).should == "The sum of Anaesthesiologist Quantity and Surgeon Quantity should be greater than 0."
  end

  it "Successfully edit Surgeon quantity" do
    slmc.edit_checklist_order(:procedure => "LUNG BIOPSY", :quantity => 2.0).include? "LUNG BIOPSY has been edited successfully."
  end

  it "Cancel Ordered Drug and Verify if it is reflected in Order List" do
    slmc.login("sel_pharmacy1", @password).should be_true
    slmc.go_to_order_adjustment_and_cancellation
    slmc.search_order_adjustment_cancellation(:patient_type => "Outpatient", :start_date => Time.now.strftime("%m/%d/%Y"), :end_date => Time.now.strftime("%m/%d/%Y"))
    count = slmc.get_css_count("css=#results>tbody>tr")
    count.times do |rows|
      if @or_patient[:last_name].upcase == slmc.get_text("css=#results>tbody>tr:nth-child(#{rows+1})>td>b").upcase
          @stop_row = rows
      end
    end
    slmc.order_adjustment(:cancel => true, :cancel_locator => "css=#results>tbody>tr:nth-child(#{@stop_row + 1})>td:nth-child(5)>div:nth-child(2)>a",  :reason => "CANCELLATION - ORDER", :remarks => "cancel")
    sleep 3
    @@cm_no = slmc.access_from_database(:what => "ADJ_CAN_DOCUMENT_NO", :table => "TXN_PBA_ORDER_ADJ_CANCEL_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no, :gate => "AND", :column2 => "PER_DEPT", :condition2 => "0004")

    slmc.login("sel_or1", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin).should be_true
    slmc.search_order_list(:status => "cancelled", :type => "drugs", :item => "BABYHALER").should be_true
  end

  it "Cancel Ordered Supplies and Verify if it is reflected in Order List" do
    slmc.login("sel_supplies1", @password).should be_true
    slmc.go_to_order_adjustment_and_cancellation
    slmc.search_order_adjustment_cancellation(:patient_type => "Outpatient", :start_date => Time.now.strftime("%m/%d/%Y"), :end_date => Time.now.strftime("%m/%d/%Y"))
    count = slmc.get_css_count("css=#results>tbody>tr")
    count.times do |rows|
      if (@or_patient[:last_name]+","+" "+@or_patient[:first_name]+" "+@or_patient[:middle_name]).upcase == slmc.get_text("css=#results>tbody>tr:nth-child(#{rows + 1})>td").upcase
          @stop_row = rows
      end
    end
    slmc.order_adjustment(:supplies => true, :cancel => true, :cancel_locator => "css=#results>tbody>tr:nth-child(#{@stop_row + 1})>td:nth-child(5)>div:nth-child(2)>a",  :reason => "CANCELLATION - ORDER", :remarks => "cancel")

    slmc.login("sel_or1", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin).should be_true
    slmc.search_order_list(:status => "cancelled", :type => "supplies", :item => "BATH TOWEL").should be_true
  end

  it "Verify if Cancelled Ancillary is reflected in Order List" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order List", @@or_pin).should be_true
    slmc.search_order_list(:status => "cancelled", :type => "ancillary", :item => "APPENDECTOMY").should be_true
  end

  it "Search by CM No. and Clicks Reprint" do
    slmc.login("sel_pharmacy1", @password).should be_true
    slmc.go_to_order_adjustment_and_cancellation
    result = slmc.search_order_adjustment_cancellation(:patient_type => "Outpatient", :doc_type => "CM No.", :org_code => "0164", :ci => @@cm_no, :start_date => Time.now.strftime("%m/%d/%Y"), :end_date => Time.now.strftime("%m/%d/%Y"))
    result.include?(@@cm_no).should be_true
    slmc.is_element_present("link=Reprint Cancellation Prooflist").should be_true
    slmc.click("link=Reprint Cancellation Prooflist")
    sleep 5
    slmc.is_element_present("link=Reprint Cancellation Prooflist").should be_true
  end

end