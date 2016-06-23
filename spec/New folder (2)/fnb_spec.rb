require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Food Nutrition and Beverage Module Tests" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @fnb_patient = Admission.generate_data
    @fnb_patient2 = Admission.generate_data
    @user = "fnb_spec_user"
    @password = "123qweuser"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Login as fnb spec user" do
    slmc.login(@user, @password).should be_true
  end

  it "Creates new patient" do
    slmc.admission_search(:pin => "1")
    @@fnb_pin = slmc.create_new_patient(@fnb_patient.merge(:gender => 'M'))
    slmc.admission_search(:pin => @@fnb_pin)
    slmc.verify_search_results(:with_results => true).should be_true
    slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0278', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Bug #22422 FND POS Ordering - Does not allow inputting description for special purchase item" do
    slmc.login("sel_fnb1",@password).should be_true
    slmc.go_to_pos_ordering
    slmc.oss_order(:item_code => "9999", :order_add => true, :item_desc => "Item Description", :service_rate => 250, :fnb_special => true).should be_true
  end

  it "Test if input field for Search accepts either description or item code" do
    slmc.go_to_pos_ordering
    slmc.oss_order(:item_code => "030000001", :order_add => true).should be_true
    slmc.oss_order(:item_code => "AMONILEBAN EN", :order_add => true).should be_true
    slmc.oss_order(:item_code => "030000136", :order_add => true).should be_true
    slmc.oss_order(:item_code => "CALIBRATED TF CUP", :order_add => true).should be_true
  end

  it "Bug #22423 FND POS Ordering - Cannot input/ change unit price of SP item" do
    slmc.go_to_pos_ordering
    slmc.oss_order(:item_code => "9999", :order_add => true, :item_desc => "Item Description", :service_rate => "250.00", :fnb_special => true).should be_true
    slmc.get_css_count("css=#tableRows>tr").should == 1
    (slmc.get_text("tableRows").include? "Item Description").should be_true
  end

  it "Refund processing of cancelled FNB order requires receiver and valid ID" do
    # make fnb order # 039999 Special FNB
    slmc.go_to_pos_ordering
    slmc.oss_order(:item_code => "030000001", :order_add => true).should be_true
    slmc.oss_order(:item_code => "030000136", :order_add => true).should be_true
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
    @@amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_f
    slmc.oss_add_payment(:amount => @@amount, :type => "CASH")
    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."

    # go to POS Order Cancellation page
    slmc.go_to_pos_order_cancellation
    slmc.pos_document_search(:type => "FNB SALES INVOICE").should be_true
    #slmc.cancel_order_for_refund(:reason => "CANCELLATION - DOCTOR'S ORDER") #.should == "Refund will be processed..." # as per erlyn/steven, if only 1 item is to be cancelled, it will not pass through refund
    slmc.cancel_order_for_refund(:reason => "CANCELLATION - DOCTOR'S ORDER").should == "Refund will be processed..."
    slmc.tag_document.should == "The CM was successfully updated with printTag = 'Y'."

    #submit refund with empty receiver and valid ID
    slmc.submit_refund.should == "Refund Received By is a required field.\nValid ID Presented is a required field."
  end

  it "Bug #24885 - FND POS ORDER CANCELLATION - Blank page displayed after clicking refund" do
    slmc.submit_refund(:receiver => "testReceiver", :valid_id => "testID").should == "The refund was successfully updated with printTag = 'Y'."
  end

  it "View list of cancelled discounts by discount date" do
    slmc.click_list_of_cancelled_discount_link
    slmc.search_discount(:search_by_date => true).should be_true
    @@discount_no = slmc.get_text("css=#results>tbody>tr>td")
  end

  it "View list of cancelled discounts by discount number" do
    slmc.click_list_of_cancelled_discount_link
    slmc.search_discount(:discount_no => @@discount_no).should_not be_false # .should be_true
  end

  it "Reprint Discount Prooflist" do
    slmc.click_reprint_prooflist.should be_true
  end

  it "View list of refund by discount date" do
    slmc.click_list_of_refund_link
    slmc.search_refund(:search_by_date => true).should be_true
    @@discount_no = slmc.get_text("css=#results>tbody>tr>td")
  end

  it "View list of refund by discount number" do
    slmc.click_list_of_refund_link
    slmc.search_refund(:discount_no => @@discount_no).should be_true
  end

  it "Reprint Refund Prooflist" do
    slmc.click_reprint_refund_slip.should be_true
  end

  it "Bug #22038 FND Ordering Special Purchase - Pop up validation box appears though item to be added not existing in Order cart" do
    slmc.login("sel_fnb1",@password).should be_true
    slmc.go_to_fnb_landing_page
    slmc.patient_pin_search(:pin => @@fnb_pin)
    slmc.go_to_fnb_page_given_pin("Order Page", @@fnb_pin)
    slmc.create_fnb_order(:special => true, :fnb_service => "apple juice").should be_true
    slmc.create_fnb_order(:special => true, :fnb_service => "ripe banana").should be_true
    slmc.click("saveCart", :wait_for => :page)
    slmc.is_text_present("Food, Nutrition and Beverages").should be_true
  end

  it "Bug #22039 FND Ordering Special Purchase - Unit price field is missing when item from the Order cart box is edited" do
    slmc.go_to_fnb_landing_page
    slmc.patient_pin_search(:pin => @@fnb_pin)
    slmc.go_to_fnb_page_given_pin("Order Page", @@fnb_pin)
    slmc.create_and_edit_fnb_order(:supplements => true, :fnb_service => "039999", :item_desc => "Item Description", :service_rate => "200.00")
    slmc.oss_edit_order(:edit_link => "Item Description", :fnb => true).should == "Order item 039999 - Item Description has been edited successfully."
  end

  it "Searches patient in FNB page" do
    slmc.go_to_fnb_landing_page
    slmc.patient_pin_search(:pin => @@fnb_pin).should be_true
  end

  it "Orders supplements in fnb" do
    slmc.go_to_fnb_page_given_pin("Order Page", @@fnb_pin)
    slmc.create_fnb_order(:supplements => true, :fnb_service => "BREAKFAST - BP", :save => true, :doctor => "6726").should be_true
  end

  it "Navigates to search patient page" do
    slmc.go_to_fnb_patient_search_page.should be_true
  end

  it "Navigates to diet stub page" do
    slmc.go_to_fnb_diet_stub_page.should be_true
  end

  it "Searches admitted patient without diet stub in ALL nursing units" do
    slmc.search_fnb_diet_stub(:label => "ALL", :advanced_search => true, :pin => @@fnb_pin, :no_result => true).should be_true
  end

  it "Searches admitted patient without diet stub in a given nursing units" do
    slmc.go_to_fnb_landing_page
    slmc.go_to_fnb_diet_stub_page
    slmc.search_fnb_diet_stub(:label => "16TH FLOOR NW SUITES", :advanced_search => true, :pin => @@fnb_pin, :no_result => true).should be_true
  end

  it "Adds clinical diet" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@fnb_pin)
    slmc.go_to_gu_page_for_a_given_pin("Clinical Diet", @@fnb_pin)
    slmc.add_clinical_diet(:save => true).should == "Patient diet COMPUTED DIET successfully created."
  end

  it "Searches admitted patient with diet stub given an incorrect nursing unit" do
    slmc.go_to_fnb_landing_page
    slmc.go_to_fnb_diet_stub_page
    slmc.search_fnb_diet_stub(:label => "16TH FLOOR SW SUITES", :advanced_search => true, :pin => @@fnb_pin, :no_result => true).should be_true
  end

  it "Searches admitted patient with diet stub in ALL nursing units" do
    slmc.go_to_fnb_landing_page
    slmc.go_to_fnb_diet_stub_page
    slmc.search_fnb_diet_stub(:label => "ALL", :advanced_search => true, :pin => @@fnb_pin, :last_name => @fnb_patient[:last_name]).should be_true
  end

  it "Searches admitted patient with diet stub in a given nursing units" do
    slmc.go_to_fnb_landing_page
    slmc.go_to_fnb_diet_stub_page
    slmc.search_fnb_diet_stub(:label => "16TH FLOOR NW SUITES", :advanced_search => true, :pin => @@fnb_pin, :last_name => @fnb_patient[:last_name]).should be_true
  end

  it "Views the diet stub for a particular patient" do
    slmc.view_patient_diet_stub.should be_true
  end

  it "Prints the diet stub for a paticular patient" do
    slmc.print_patient_diet_stub.should be_true
  end

  it "Views ALL diet stubs" do
    slmc.go_to_fnb_landing_page
    slmc.go_to_fnb_diet_stub_page
    slmc.search_fnb_diet_stub(:label => "ALL")
    slmc.view_all_diet_stub.should be_true
  end

  it "Clicks the Print All option" do
    slmc.search_fnb_diet_stub(:label => "ALL")
    slmc.print_all_diet_stub.should be_true
  end

  it "Bug #39657 - Yikes Error in selecting 11TH North" do
    slmc.go_to_fnb_landing_page
    slmc.go_to_fnb_diet_stub_page
    slmc.search_fnb_diet_stub(:label => "11TH FLOOR NW SURGICAL UNIT 1")
    (slmc.get_text"css=#admittedPatients>tbody>tr>td:nth-child(4)").should == "11TH FLOOR NW SURGICAL UNIT 1"
  end

  it "Feature #32308 - Create patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@pin1 = slmc.create_new_patient(Admission.generate_data)
    slmc.admission_search(:pin => @@pin1)
    slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0278', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Feature #32308 - Entered patient's diet should be saved in database" do
    slmc.nursing_gu_search(:pin => @@pin1)
    slmc.go_to_gu_page_for_a_given_pin("Clinical Diet", @@pin1)
    slmc.add_clinical_diet(:save => true).should == "Patient diet COMPUTED DIET successfully created."

    @@visit_no = slmc.get_text"banner.visitNo"
    @@diet_no = slmc.access_from_database(:what => "DIET_NO", :table => "TXN_OM_PAT_DIET", :column1 => "VISIT_NO", :condition1 => @@visit_no)
    slmc.access_from_database(:what => "DESCRIPTION", :table => "TXN_OM_PAT_FOOD_ALLERGY", :column1 => "PIN", :condition1 => @@pin1).should == "SELENIUM TEST FOOD ALLERGY DESCRIPTION"
    slmc.access_from_database(:what => "PREFERENCE", :table => "TXN_OM_PAT_FOOD_PREF", :column1 => "VISIT_NO", :condition1 => @@visit_no).should == "SELENIUM TEST FOOD PREFERENCE"
    slmc.access_from_database(:what => "DIET_ID", :table => "TXN_OM_PAT_DIET_ALLERGY ", :column1 => "DIET_ID", :condition1 => @@diet_no).should == @@diet_no
  end

  it "Feature #32308 - Click View Diet History button" do
    slmc.nursing_gu_search(:pin => @@pin1)
    slmc.go_to_gu_page_for_a_given_pin("Clinical Diet", @@pin1)
    slmc.click("//input[@type='button' and @value='View Diet History']", :wait_for => :page)
    contents = slmc.get_text("dataTable")
    contents.include?("Allergies").should be_true
    contents.include?("Food Preference").should be_true
    contents.include?("Additional Instructions").should be_true
    contents.include?("Diet Type").should be_true
    contents.include?("Diet Group").should be_true
  end

  it "Patient Diet History - View all patient's diet based on admission record" do
    slmc.get_text("//table[@id='dataTable']/tbody/tr[2]/td[4]/a").should == ("Selenium Test Food Allergy Description").upcase
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet - Diet Type then save" do
    slmc.count_diet_history(:pin => @@pin1, :visit_no => @@visit_no, :back => true).should == 2
    slmc.add_clinical_diet(:diet => "CLEAR LIQUID", :update => true).should == "Patient diet CLEAR LIQUID successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@pin1, :visit_no => @@visit_no, :back => true).should == 3
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet - Addiitonal Instructions then save" do
    slmc.add_clinical_diet(:additional_instruction => "SELENIUM ADDITIONAL INSTRUCTIONS", :update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@pin1, :visit_no => @@visit_no, :back => true).should == 4
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet -Allergies then save" do
    slmc.add_clinical_diet(:description => "ALLERGIES FOR COUNTING", :update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@pin1, :visit_no => @@visit_no, :back => true).should == 5
  end

  it "Feature #32308 - New line/ entry should be added on each and every update of patient clinical diet -Patient Food Preference then save" do
    slmc.add_clinical_diet(:food_preferences => "TEST FOOD PREFERENCES FOR COUNTING", :update => true).should == "Patient diet COMPUTED DIET successfully created."
    slmc.count_diet_history(:view_diet_history => true, :pin => @@pin1, :visit_no => @@visit_no, :back => true).should == 6
  end

  it "Feature #32308 - Click View Diet History button - Diet Type" do
    slmc.click("//input[@type='button' and @value='View Diet History']", :wait_for => :page)
    count = slmc.get_css_count("css=#dataTable>tbody>tr")
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text("css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)>a"))
      count-=1
      rows+=1
    end

    ((@@arr.to_s).include? "CLEAR LIQUID").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Addiitonal Instructions" do
    count = slmc.get_css_count("css=#dataTable>tbody>tr")
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(6)>a")
      count-=1
      rows+=1
    end

    ((@@arr.to_s).include? "SELENIUM ADDITIONAL INSTRUCTIONS").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Allergies" do
    count = slmc.get_css_count("css=#dataTable>tbody>tr")
    count -=1
    rows = 1
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(4)>a")
      count -= 1
      rows += 1
    end

    ((@@arr.to_s).include? "ALLERGIES FOR COUNTING").should be_true
  end

  it "Feature #32308 - Click View Diet History button - Patient Food Preference" do
    count = slmc.get_css_count("css=#dataTable>tbody>tr")
    count -=1
    rows = 1
    @@arr = []
    count.times do
    @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{rows + 1})>td:nth-child(5)>a")
      count-=1
      rows+=1
    end
    ((@@arr.to_s).include? "TEST FOOD PREFERENCES FOR COUNTING").should be_true
  end

  it "Feature #32308 - Click patient diet details link" do
    slmc.click("link=CLEAR LIQUID")
    sleep 4
    count = slmc.get_css_count "css=#dataTable>tbody>tr"
    @@arr = []
    count.times do
      @@arr << (slmc.get_text"css=#dataTable>tbody>tr:nth-child(#{count})>th")
      count -=1
    end

    (@@arr.to_s).should == "Additional Instructions :Disposable Tray :Interpretation :BMI :Weight :Height :Food Allergies :Food Preference :Patient Diet Type :Patient Diet Group :"
    slmc.click("//html/body/div/div[2]/div[2]/div[7]/div[2]/div/a/input")
    sleep 2
  end

  # Feature 39884
  it "Unvalidated order by FNB should appear in patient nursing unit validation page" do
    slmc.login(@user, @password)
    slmc.admission_search(:pin => "1")
    @@fnb_pin2 = slmc.create_new_patient(@fnb_patient2)
    slmc.admission_search(:pin => @@fnb_pin2)
    slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0278', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."

    slmc.login("sel_fnb1", @password).should be_true
    slmc.go_to_fnb_landing_page
    slmc.patient_pin_search(:pin => @@fnb_pin2)
    slmc.go_to_fnb_page_given_pin("Order Page", @@fnb_pin2)
    slmc.create_fnb_order(:supplements => true, :fnb_service => "BREAKFAST - BP", :doctor => "6726")

    slmc.login(@user, @password)
    slmc.nursing_gu_search(:pin => @@fnb_pin2)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@fnb_pin2)
    slmc.submit_added_order.should be_true
    slmc.get_text("//table[@id='supplementOrderCartDetails']/tbody/tr/td[4]").should == "BREAKFAST - BP"
    slmc.get_css_count("css=#supplementOrderCartDetails>tbody>tr").should == 1
    slmc.click("link=Order(s) for Validation")
    sleep 10
    slmc.get_text("//div[@id='pendingOrderDlg']/div[2]/table/tbody/tr/td").should == @@fnb_pin2
    slmc.click("//button[1]")
  end

  it "Patient cannot be discharge if there are still pending order" do
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@fnb_pin2, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_false
    slmc.is_text_present("There are still pending orders in cart.").should be_true
  end

  it "Unvalidated order by FNB should appear in patient nursing unit quicklink Pending orders for validation" do
    @@visit_no = slmc.get_text("banner.visitNo")
    slmc.validate_pending_orders(:pin => @@fnb_pin2, :visit_no => @@visit_no, :no_validate => true)

    slmc.get_text("//table[@id='supplementOrderCartDetails']/tbody/tr/td[4]").should == "BREAKFAST - BP"
    slmc.get_css_count("css=#supplementOrderCartDetails>tbody>tr").should == 1
    slmc.click("link=Order(s) for Validation")
    sleep 10
    slmc.get_text("//div[@id='pendingOrderDlg']/div[2]/table/tbody/tr/td").should == @@fnb_pin2
  end

  it "FNB user validates order" do
    slmc.login("sel_fnb1", @password).should be_true
    slmc.go_to_fnb_landing_page
    slmc.patient_pin_search(:pin => @@fnb_pin2)
    slmc.go_to_fnb_page_given_pin("Order Page", @@fnb_pin2)
    slmc.click("saveCart", :wait_for => :page)

    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@fnb_pin2)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@fnb_pin2)
    slmc.submit_added_order.should be_true
    slmc.is_element_present("//table[@id='supplementOrderCartDetails']/tbody/tr/td[4]").should be_false
    slmc.click("link=Order(s) for Validation")
    sleep 10
    slmc.get_text("//div[@id='pendingOrderDlg']/div[2]/table/tbody/tr/td").should == "Nothing to validate"
  end

  it "Replace - Search & Select items (owned by Food & Nutrition Dept.)" do
    slmc.login("sel_fnb1", @password)
    slmc.go_to_order_adjustment_and_cancellation
    slmc.search_order_adjustment_cancellation(:pin => @@fnb_pin2).include?(@fnb_patient2[:last_name]).should be_true
    slmc.click_adjust(slmc.get_text("//table[@id='results']/tbody/tr/td[2]")).should be_true
    slmc.order_adjustment(:replace => true, :item_to_be_replaced => "030000005", :item => "039999", :doctor => "6726", :reason => "ADJUSTMENT - REPLACEMENT", :remarks => "replce remark").should be_true
    slmc.get_text("css=#tblReplacement>tbody>tr").include?("039999").should be_true
    slmc.click("//input[@value='Save']", :wait_for => :page)
    slmc.tag_document.should == "The CM was successfully updated with printTag = 'Y'."
  end

end
