require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Central Sterile Supply Tests" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @gu_patient = Admission.generate_data
    @user = 'css_spec_user'
    @password = "123qweuser"
    @pharmacy_user = "sel_pharmacy1"
    @css_user = "sel_css1"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates new general unit patient for CSS ordering" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test").should be_true
    @@gu_pin = slmc.create_new_patient(@gu_patient.merge!(:gender => 'M'))
    slmc.admission_search(:pin => @@gu_pin).should be_true
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:room_charge => "DE LUXE PRIVATE", :rch_code => 'RCH07', :org_code => '0278', :diagnosis => "ULCER", :package => "LAP CHOLE ECU-PACKAGE").should == "Patient admission details successfully saved."
  end

#  it "Test if input field for Search accepts either description or item code" do
#    slmc.go_to_general_units_page
#    slmc.go_to_adm_order_page(:pin => @@gu_pin)
#    slmc.search_order(:drugs => true, :description =>  "040004334").should be_true
#    slmc.search_order(:supplies => true, :description => "080200000").should be_true
#    slmc.search_order(:ancillary => true, :description => "010000003").should be_true
#    slmc.search_order(:others => true, :description => "050000009").should be_true
#    slmc.search_order(:drugs => true, :description => "SOLUSET").should be_true
#    slmc.search_order(:supplies => true, :description => "NASO-TRACHEAL TUBE IVORY S7").should be_true
#    slmc.search_order(:ancillary => true, :description => "BONE IMAGING - THREE PHASE STUDY").should be_true
#    slmc.search_order(:others => true, :description => "BLOOD WARMER - SUCCEDING HOUR").should be_true
#  end

  it "Add compounded drug order to be edited - MAGIC MOUTHWASH 240mL" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.search_order(:drugs => true, :description => "MAGIC MOUTHWASH 240ML").should be_true
    slmc.add_returned_order(:drugs => true, :description => "MAGIC MOUTHWASH 240ML", :quantity => 2.0,
    :frequency => "ONCE A WEEK", :compounded => true, :remarks => "Compounded item", :add => true).should be_true
  end

  it "Edit compounded drug order" do
    slmc.click_order("MAGIC MOUTHWASH 240ML").should be_true
    slmc.add_returned_order(:drugs => true, :description => "MAGIC MOUTHWASH 240ML", :doctor => "5979",
    :quantity => 5.0, :frequency => "TWICE A WEEK", :remarks => "Edit compounded item", :edit => true).should be_true
  end

  it "Delete the compounded drug order" do
    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator").should be_true
    slmc.delete_order.should be_true
  end

  it "Add compounded drug order for order cancellation - MAGIC MOUTHWASH 240mL" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.search_order(:drugs => true, :description => "MAGIC MOUTHWASH 240ML").should be_true
    slmc.add_returned_order(:drugs => true, :description => "MAGIC MOUTHWASH 240ML", :quantity => 2.0, :stat => true,
    :frequency => "ONCE A WEEK", :stock_replacement => true, :compounded => true, :remarks => "Compounded item", :add => true).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator").should be_true
    slmc.validate_orders(:drugs => true, :orders => "single").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Add compounded drug order - MAGIC MOUTHWASH COMPOUNDED FEES" do
    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@gu_pin)
    slmc.search_order(:drugs => true, :description => "MAGIC MOUTHWASH COMPOUNDED FEES").should be_true
    slmc.add_returned_order(:drugs => true, :description => "MAGIC MOUTHWASH COMPOUNDED FEES", :quantity => 2.0,
    :stat => true, :frequency => "ONCE A WEEK", :stock_replacement => true, :compounded => true, :remarks => "Compounded item", :add => true).should be_true
  end

  it "Add more drugs for order adjustment scenarios - edit, cancel, replace" do
    slmc.search_order(:drugs => true, :description => "ASPIRIN 325MG TAB").should be_true
    slmc.add_returned_order(:drugs => true, :description => "ASPIRIN 325MG TAB", :quantity => 3.0, :frequency => "ONCE A WEEK", :add => true).should be_true
    slmc.search_order(:drugs => true, :description => "DECOLGEN FORTE CAP").should be_true
    slmc.add_returned_order(:drugs => true, :description => "DECOLGEN FORTE CAP", :quantity => 4.0, :frequency => "ONCE A WEEK", :add => true).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
    slmc.validate_orders(:drugs => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "Display order in view files" do
    slmc.login(@pharmacy_user, @password).should be_true
    slmc.go_to_compounded_items_update_page
    slmc.search_patient(:pin => @@gu_pin)
    @@ci1 = slmc.get_text("css=#searchResults>tbody>tr:nth-child(2)>td") ## 2nd CI record
    @@ci2 = slmc.get_ci_number
    slmc.view_compounded_request(@@ci2).should be_true
  end

  it "Add compounded formula" do
    slmc.create_compounded_formula(:item => "BIOGESIC DROPS 15ML", :cd_price => "10", :add => true, :save => true).should be_true
    slmc.search_patient(:pin => @@gu_pin)
    slmc.view_compounded_request(@@ci2).should be_true
    slmc.create_compounded_formula(:item => "040004334", :cd_price => "10", :add => true, :save => true).should be_true # BABYHALER
    slmc.search_patient(:pin => @@gu_pin)
    slmc.view_compounded_request(@@ci2).should be_true
    slmc.create_compounded_formula(:item => "040004335", :cd_price => "10", :add => true, :save => true).should be_true # NEBUCHAMBER
  end

  it "Bug 22428 - Delete compounded formula" do
    slmc.go_to_compounded_items_update_page
    slmc.search_patient(:pin => @@gu_pin)
    slmc.view_compounded_request(@@ci2).should be_true
    slmc.create_compounded_formula(:item => "042820142 BIOGESIC DROPS 15ML BOT", :delete => true, :save => true).should be_true
  end

  it "Task #41937 - Order Adjustment: Add Patient Name in C.I. Search" do
    slmc.go_to_order_adjustment_and_cancellation
    slmc.search_order_adjustment_cancellation(:ci => @@ci2)
    slmc.get_text("css=#results>thead>tr>th").should == "Name"
    slmc.get_css_count("css=#results>thead>tr>th").should == 5
  end

  it "Adjust order by Cancelling the item" do
    slmc.go_to_order_adjustment_and_cancellation
    (slmc.search_order_adjustment_cancellation(:ci => @@ci2).include?(@@ci2)).should be_true
    slmc.click_adjust(@@ci2).should be_true
    slmc.order_adjustment(:cancel => true, :cancel_locator => "css=#row>tbody>tr:nth-child(2)>td:nth-child(5)>div:nth-child(2)>a",  :reason => "CANCELLATION - ORDER", :remarks => "cancel").should be_true
    #slmc.get_text("//html/body/div/div[2]/div[2]/div[3]/div").should match /Order detail '.*' with item '.*' has been cancelled./
    slmc.search_order_adjustment_cancellation(:ci => @@ci2)
    slmc.is_text_present("Reprint Cancellation Prooflist").should be_true
  end

  it "Search only Special Purchase" do
    slmc.go_to_order_adjustment_and_cancellation
    slmc.search_order_adjustment_cancellation(:special_search => true).should be_true
  end

  it "Search only Posted Batch Request" do
    slmc.go_to_order_adjustment_and_cancellation
    slmc.search_order_adjustment_cancellation(:posted_batch_request => true).should be_true
  end

  it "Display info in Adjustment Details" do
    slmc.go_to_order_adjustment_and_cancellation
    slmc.search_order_adjustment_cancellation(:pin => @@gu_pin).should be_true
    slmc.click_adjust("RandomOnly").should be_false
    slmc.order_adjustment(:edit => true, :new_quantity => "1", :edit_locator => "//table[@id='row']/tbody/tr[1]/td[5]/div/a", :reason => "ADJUSTMENT - RETURNED MEDICINE/SUPPLIES").should be_true # might get error if first record doesn't contain link Adjust
    slmc.get_text("//table[@id='row']/tbody/tr/td").should == slmc.get_text("//table[@id='tblAdjustment']/tbody/tr/td")
    slmc.get_text("//table[@id='row']/tbody/tr/td[2]").should == slmc.get_text("//table[@id='tblAdjustment']/tbody/tr/td[2]")
    slmc.get_text("//table[@id='row']/tbody/tr/td[4]").should == slmc.get_text("//table[@id='tblAdjustment']/tbody/tr/td[3]")
  end

  it "Adjustment Details - Remove details" do
    slmc.click("link=Remove")
    sleep 2
    slmc.is_element_present("//table[@id='tblAdjustment']/tbody/tr/td").should be_false
  end

  it "Adjust order by Editing the order details" do
    slmc.go_to_order_adjustment_and_cancellation
    (slmc.search_order_adjustment_cancellation(:ci => @@ci2).include?(@@ci2)).should be_true
    slmc.click_adjust(@@ci2).should be_true
    slmc.order_adjustment(:edit => true, :new_quantity => "2", :reason => "ADJUSTMENT - REPLACEMENT", :remarks => "compounded drug").should be_true
  end

  it "Adjust order by Replacing the item" do
    slmc.go_to_order_adjustment_and_cancellation
    (slmc.search_order_adjustment_cancellation(:ci => @@ci2).include?(@@ci2)).should be_true
    slmc.click_adjust(@@ci2).should be_true
    slmc.order_adjustment(:replace => true, :item_to_be_replaced => "040888013", :item => "049999", :doctor => "6726", :reason => "ADJUSTMENT - REPLACEMENT", :remarks => "compounded drug").should be_true
    slmc.get_text("css=#tblReplacement>tbody>tr").include?("040888013").should be_true
    slmc.get_text("//table[@id='tblReplacement']/tbody/tr/td[2]").should == "MAGIC MOUTHWASH COMPOUNDED FEES"
    slmc.get_text("//table[@id='tblReplacement']/tbody/tr/td[5]").should == "SPECIAL PURCHASE DRUGS"
  end

  it "Replacement Details - Remove Details" do
    slmc.click("link=Remove")
    sleep 2
    slmc.is_element_present("//table[@id='tblReplacement']/tbody/tr/td").should be_false
  end

  it "Click Save" do
    slmc.go_to_order_adjustment_and_cancellation
    (slmc.search_order_adjustment_cancellation(:ci => @@ci2).include?(@@ci2)).should be_true
    slmc.click_adjust(@@ci2).should be_true
    slmc.order_adjustment(:replace => true, :item_to_be_replaced => "044839921", :item => "049999", :doctor => "6726", :reason => "ADJUSTMENT - REPLACEMENT", :remarks => "compounded drug").should be_true
    slmc.get_text("css=#tblReplacement>tbody>tr").include?("049999").should be_true
    slmc.click("//input[@value='Save']", :wait_for => :page)
    slmc.tag_document.should == "The CM was successfully updated with printTag = 'Y'."
  end

  it "Bug 24319 - Verifies requesting doctor is displayed in the Compounded order listing" do
    slmc.go_to_compounded_items_update_page
    slmc.search_patient(:pin => @@gu_pin)
    slmc.get_text("css=#searchResults>tbody>tr>td:nth-child(7)").should_not == ""
  end

  it "Cancel the order" do
    slmc.go_to_order_adjustment_and_cancellation
    (slmc.search_order_adjustment_cancellation(:ci => @@ci1).include?(@@ci1)).should be_true
    slmc.order_cancellation(:ci => @@ci1, :reason => "CANCELLATION - ORDER", :remarks => "cancel")
    slmc.tag_document.should == "The CM was successfully updated with printTag = 'Y'."
  end

  it "Updates Action link after cancelling the order" do
    slmc.go_to_order_adjustment_and_cancellation
    (slmc.search_order_adjustment_cancellation(:ci => @@ci1).include?(@@ci1)).should be_true
    slmc.get_text("css=#results>tbody>tr>td:nth-child(5)>div").should == "Reprint Cancellation Prooflist"
  end

  #same as top but with different functions
  it "Verify option to Reprint cancellation prooflist" do
    slmc.go_to_order_adjustment_and_cancellation
    (slmc.search_order_adjustment_cancellation(:ci => @@ci1).include?(@@ci1)).should be_true
    slmc.get_text("//html/body/div/div[2]/div[2]/div[9]/div[2]/table/tbody/tr/td[5]").should == "Reprint Cancellation Prooflist"
  end

  it "Click Reprint cancellation prooflist" do
    slmc.reprint_cancellation_prooflist(@@ci1)
    slmc.is_text_present("Order Adjustment and Cancellation").should be_true
  end

  it "Cancel the order with compounded order" do
    slmc.go_to_order_adjustment_and_cancellation
    (slmc.search_order_adjustment_cancellation(:ci => @@ci2).include?(@@ci2)).should be_true
    slmc.order_cancellation(:ci => @@ci2, :reason => "CANCELLATION - ORDER", :remarks => "cancel", :compounded => true).should == "Cannot cancel CI #{@@ci2}. Compounded item have components already."
  end

  it "Bug #22767 [CSS- POS Ordering] The option 'Open Item for edit' is not working" do
    slmc.login("supplies1", @password).should be_true
    slmc.go_to_pos_ordering
    2.times{slmc.oss_order(:item_code => "080100021", :order_add => true)}
    slmc.validate_existing_order(:open_edit => true, :quantity => "20").should == "20.00"
  end

  it "Verify create new line for the order" do
    slmc.go_to_pos_ordering
    2.times{slmc.oss_order(:item_code => "080100021", :order_add => true)}
    slmc.validate_existing_order(:new_line => true).should be_true
  end

  it "Verify override existing order data" do
    slmc.go_to_pos_ordering
    2.times{slmc.oss_order(:item_code => "080100021", :order_add => true)}
    slmc.validate_existing_order(:override => true).should == "1.00"
  end

  it "Verify Update quantity of existing order(add current quantity to existing)" do
    slmc.go_to_pos_ordering
    2.times{slmc.oss_order(:item_code => "080100021", :order_add => true)}
    slmc.validate_existing_order(:update_quantity => true).should == "2.00"
  end

  it "Validates LAP CHOLE PACKAGE of the patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@gu_pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Non Ecu Package Ordering", @@gu_pin)
    slmc.click('//input[@type="checkbox"]')
    slmc.click Locators::Wellness.order_non_ecu_package, :wait_for => :page
    slmc.validate_non_ecu_package
    #slmc.validate_credentials(:username => "gene", :password => @password, :package => true)
  end

  it "Updates Patient Package and continue to Validation" do
    slmc.admission_search(:pin => @@gu_pin)
    slmc.update_admission(:package => "PLAN A MALE", :save => true).should be_true
    slmc.nursing_gu_search(:pin => @@gu_pin).should be_true
    slmc.go_to_gu_page_for_a_given_pin("Package Management", @@gu_pin)
    slmc.gu_switch_package(:username => "gene", :password => @password, :package => true, :to_package => "PLAN A MALE")#.should be_true
  end

  it "Bug #28730 - [SCD] Clinical Order validation: Reject order not working" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test").should be_true
    @@pin = slmc.create_new_patient(Admission.generate_data)
    slmc.admission_search(:pin => @@pin).should be_true
    slmc.create_new_admission(:room_charge => "DE LUXE PRIVATE", :rch_code => 'RCH07', :org_code => '0278', :diagnosis => "ULCER").should == "Patient admission details successfully saved."

    slmc.go_to_general_units_page
    slmc.go_to_adm_order_page(:pin => @@pin)
    slmc.search_order(:drugs => true, :description => "MAGIC MOUTHWASH 240ML").should be_true
    slmc.add_returned_order(:drugs => true, :description => "MAGIC MOUTHWASH 240ML", :quantity => 2.0, :frequency => "ONCE A WEEK", :compounded => true, :remarks => "Compounded item", :add => true).should be_true
    slmc.search_order(:drugs => true, :description => "ASPIRIN 325MG TAB").should be_true
    slmc.add_returned_order(:drugs => true, :description => "ASPIRIN 325MG TAB", :quantity => 3.0, :frequency => "ONCE A WEEK", :add => true).should be_true
    slmc.search_order(:drugs => true, :description => "042820142").should be_true
    slmc.add_returned_order(:drugs => true, :description => "042820142", :quantity => 3.0, :frequency => "ONCE A WEEK", :add => true).should be_true
    slmc.search_order(:drugs => true, :description => "042820145").should be_true
    slmc.add_returned_order(:drugs => true, :description => "042820145", :quantity => 3.0, :frequency => "ONCE A WEEK", :add => true).should be_true

    slmc.login(@pharmacy_user, @password).should be_true
    slmc.go_to_clinical_ordering_landing_page
    slmc.click_clinical_ordering_sub_org
    slmc.medical_search_patient(@@pin)
    slmc.clinical_ordering_checkbox(:pin => @@pin, :item_code => "040888001", :reject => true, :reason => "CANCEL/HOLD").should be_true
  end

  it "Bug #28726 - [SCD] Clinical Order validation: Validated orders are not listed in patient order list in Nursing unit" do
    slmc.go_to_clinical_ordering_landing_page
    slmc.click_clinical_ordering_sub_org
    slmc.medical_search_patient(@@pin)
    slmc.clinical_ordering_checkbox(:pin => @@pin, :item_code => "042820142", :validate => true).should be_true
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order List", @@pin)
    sleep 5
    (slmc.get_text"css=#tbody_drugs").include?("042820142").should be_true
  end

  it "Bug #28724 - [SCD] Clinical Ordering Order validation: Not all of the validated order items are removed from the listing" do
    slmc.login(@pharmacy_user, @password).should be_true
    slmc.go_to_clinical_ordering_landing_page
    slmc.click_clinical_ordering_sub_org
    slmc.medical_search_patient(@@pin)
    slmc.clinical_ordering_checkbox(:pin => @@pin, :item_code => "042824804", :validate => true).should be_true
    slmc.go_to_clinical_ordering_landing_page
    slmc.click_clinical_ordering_sub_org
    slmc.medical_search_patient(@@pin)
    slmc.clinical_ordering_checkbox(:pin => @@pin, :item_code => "042820145", :validate => true).should be_true
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order List", @@pin)
    sleep 5
    (slmc.get_text"css=#tbody_drugs").include?("042824804").should be_true
    (slmc.get_text"css=#tbody_drugs").include?("042820145").should be_true
  end

  it "Search & Select items (owned by Central Sterile Supply)" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    slmc.search_order(:supplies => true, :description => "080100021").should be_true
    slmc.add_returned_order(:supplies => true, :description => "080100021", :quantity => 3.0, :add => true).should be_true
    slmc.submit_added_order.should be_true
    slmc.validate_orders(:supplies => true, :orders => "single").should == 1
    slmc.confirm_validation_all_items.should be_true

    slmc.login(@css_user, @password).should be_true
    slmc.go_to_order_adjustment_and_cancellation
    slmc.search_order_adjustment_cancellation(:pin => @@pin)
    slmc.click_adjust(slmc.get_text("//table[@id='results']/tbody/tr/td[2]")).should be_true
    slmc.order_adjustment(:replace => true, :item_to_be_replaced => "080100021", :item => "089999", :quantity => "2", :reason => "ADJUSTMENT - REPLACEMENT", :remarks => "replace remark").should be_true
    slmc.get_text("css=#tblReplacement>tbody>tr").include?("089999").should be_true
    slmc.click("//input[@value='Save']", :wait_for => :page)
    slmc.tag_document.should == "The CM was successfully updated with printTag = 'Y'."
  end

  it "Verify if replaced item is visible upon adjusting" do
    slmc.go_to_order_adjustment_and_cancellation
    slmc.search_order_adjustment_cancellation(:pin => @@pin)
    slmc.click_adjust(slmc.get_text("//table[@id='results']/tbody/tr/td[2]")).should be_true
    slmc.get_text("//table[@id='row']/tbody/tr/td").should == "089999"
    slmc.is_element_present("//table[@id='row']/tbody/tr[2]").should be_false
    slmc.get_text("//table[@id='tblReplacement']/tbody").should == ""
    slmc.get_text("//table[@id='tblAdjustment']/tbody").should == ""
  end

  it "Order special purchase (item code 089999)" do
    slmc.login(@css_user, @password).should be_true
    slmc.go_to_pos_ordering
    slmc.oss_order(:item_code => "089999", :service_rate_display => "10000", :order_add => true).should be_true
  end
  
end
