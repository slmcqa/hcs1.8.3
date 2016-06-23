require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'


describe "SLMC :: Social Service Payment and Generation of SOA Screen" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @patient = Admission.generate_data(:not_senior => true)
    @user = "billing_spec_user2"
    @password = "123qweuser"

    @esc_no = "0034341"
    @patient_share = 5000.0
    @fund_share = 1234.56
    @@pin = "1106003790"
    @drugs = {"040000357" => 1}
    @ancillary = {"010000003" => 1}
    @supplies = {"080100021" => 1}
    @operation = {"060000058" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Social Service : Payments Screen - Create and Admit Patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin = slmc.create_new_patient(@patient)
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
  end

  it "Social Service : Payments Screen - Patient orders items" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true,:frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true ).should be_true
      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end

  it "Social Service : Payments Screen - Clinically Discharge patient" do
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
  end

  it "Social Service : Payments Screen - Go to Payment Page" do
    slmc.login("pba22", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
  end

  it "Social Service : Payments Screen - Verify Payment Type" do
    slmc.is_element_present("//input[@id='fullPayment' and @type='radio' and @value='PYT02']").should be_true
    slmc.is_element_present("//input[@id='deposit' and @type='radio' and @value='PYT01']").should be_true
    slmc.get_text("css=#paymentTypes>label:nth-child(2).desc").should == "Full Payment"
    slmc.get_text("css=#paymentTypes>label:nth-child(4).desc").should == "Deposit"
    slmc.is_editable("//input[@id='fullPayment' and @type='radio' and @value='PYT02']").should be_true
    slmc.is_editable("//input[@id='deposit' and @type='radio' and @value='PYT01']").should be_true
  end

  it "Social Service : Payments Screen - Verify Transaction Type" do
    slmc.is_element_present("//input[@id='hospitalPayment' and @type='radio' and @value='PYT001']").should be_true
    slmc.is_element_present("//input[@id='pfPayment' and @type='radio' and @value='PYT002']").should be_true
    slmc.get_text("//label[@for='hospitalBill']").should == "Hospital Bill"
    slmc.get_text("//label[@for='pF']").should == "PF"
    slmc.is_editable("//input[@id='hospitalPayment' and @type='radio' and @value='PYT001']").should be_true
    slmc.is_editable("//input[@id='pfPayment' and @type='radio' and @value='PYT002']").should be_true
  end

  it "Social Service : Payments Screen - Verify Payment Summary" do
    slmc.is_element_present("css=#summaryDiv").should be_true

    slmc.is_element_present("totalCash").should be_true
    slmc.is_element_present("TotalEWT").should be_true
    slmc.is_element_present("totalCheck").should be_true
    slmc.is_element_present("totalCard").should be_true
    slmc.is_element_present("totalBankRemittance").should be_true
    slmc.is_element_present("TotalGC").should be_true

    slmc.get_text("//label[@for='totalCash']").should == "Total Cash"
    slmc.get_text("//label[@for='totalEwt']").should == "Total EWT"
    slmc.get_text("//label[@for='totalCheck']").should == "Total Check"
    slmc.get_text("//label[@for='totalCard']").should == "Total Card"
    slmc.get_text("//label[@for='totalBankRemittance']").should == "Total Bank Remittance"
    slmc.get_text("//label[@for='totalGC']").should == "Total GC"
  end

  it "Social Service : Payments Screen - Verify Payment Notes" do
    slmc.is_text_present("Payment Notes:").should be_true
    slmc.is_element_present("receivedFrom").should be_true
    slmc.is_element_present("particulars").should be_true

    slmc.get_value("receivedFrom").should == @patient[:last_name].upcase + "," + " " + @patient[:first_name] + "  " + @patient[:middle_name]
    #slmc.get_value("receivedFrom").should == "CARINO, Pia Patricia  Abot"
    slmc.get_value("particulars").should == "Full Payment of Hospital Bill."
    slmc.click("pfPayment")
    slmc.get_value("particulars").should == "Payment for Professional Fee/s."
  end

  it "Social Service : Payments Screen - Verify the Social Service Information:" do
    slmc.is_text_present("Initial Deposit Required:").should be_true
    slmc.is_text_present("Patient's Share:").should be_true
    slmc.is_element_present("css=#summaryDiv>div>span.value").should be_true
    slmc.is_element_present("css=#summaryDiv>div:nth-child(3)>span.value").should be_true
  end

  it "Social Service : Payments Screen - Verify Billing Details" do 
    @@gross = 0.0
    @@orders = @drugs.merge(@ancillary).merge(@supplies)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end

    @@discount = slmc.compute_discounts(:unit_price => @@gross, :promo => true)
    @@total_discount = ((@@discount) * 100).round.to_f / 100
    @@total_hospital_bills = @@gross - @@total_discount
    
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
    @@summary[:balance_due].should == ("%0.2f" %(@@total_hospital_bills + 0.01))
    
    slmc.is_text_present("Hospital Bills").should be_true
    slmc.is_text_present("Room Charges").should be_true
    slmc.is_text_present("Adjustments").should be_true
    slmc.is_text_present("PhilHealth").should be_true
    slmc.is_text_present("Discounts").should be_true
    slmc.is_text_present("EWT").should be_true
    slmc.is_text_present("Total Gift Check").should be_true
    slmc.is_text_present("Payments").should be_true
    slmc.is_text_present("Charged Amount").should be_true
    slmc.is_text_present("Social Service Coverage (e.g PCSO, Co-payors)").should be_true
    slmc.is_text_present("Total Hospital Bills").should be_true
    slmc.is_text_present("Add:").should be_true
    slmc.is_text_present("PF Amount").should be_true
    slmc.is_text_present("Less: PF Payments").should be_true
    slmc.is_text_present("Less: PF Charged").should be_true
    slmc.is_text_present("Total Amount Due").should be_true
    slmc.is_text_present("Total Payments").should be_true
    slmc.is_text_present("Balance Due").should be_true
  end

  it "Social Service : Generation of SOA Screen - Add Patient Share, Fund Share and Benefactor Coverage" do
    slmc.login("sel_ss1", @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.pba_search(:pin => @@pin)
    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share)
  end

  it "Social Service : Generation of SOA Screen - Go to SOA Page" do
    slmc.login("pba22", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Generation of SOA", slmc.visit_number)
  end

  it "Social Service : Generation of SOA Screen - Verify  Esc Number:" do
    slmc.get_text("css=div.groupTwo>div>div.rightForm>div:nth-child(4)>div.label").should == "Esc Number:"
    slmc.get_text("css=div.groupTwo>div>div.rightForm>div:nth-child(4)>div.ui").should == @esc_no
  end

  it "Social Service : Generation of SOA Screen - Verify Patient Share:" do
    slmc.get_text("css=div.groupTwo>div>div.rightForm>div:nth-child(5)>div.label").should == "Patient Share:"
    slmc.get_text("css=div.groupTwo>div>div.rightForm>div:nth-child(5)>div.ui").gsub(',','').should == ("%0.2f" %(@patient_share))
  end

  it "Social Service : Generation of SOA Screen - Verify Fund Share:" do
    slmc.get_text("css=div.groupTwo>div>div.rightForm>div:nth-child(6)>div.label").should == "Fund Share:"
    slmc.get_text("css=div.groupTwo>div>div.rightForm>div:nth-child(6)>div.ui").gsub(',','').should == ("%0.2f" %(@fund_share))
  end

  it "Social Service : Generation of SOA Screen - Verify Benefactor Coverage:" do
    slmc.get_text("css=div.groupTwo>div>div.rightForm>div:nth-child(7)>div.label").should == "Benefactor Coverage:"
    slmc.get_text("css=div.groupTwo>div>div.rightForm>div:nth-child(7)>div.ui").should == ("%0.2f" %(0))
  end

end