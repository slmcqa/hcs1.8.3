require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Discounts - Outpatient" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @oss_patient = Admission.generate_data(:not_senior => true)
    @oss_patient2 = Admission.generate_data(:senior => true)
    @or_patient = Admission.generate_data(:not_senior => true)
    @or_patient2 = Admission.generate_data(:not_senior => true)
    @password = "123qweuser"
    @lname = "oss_user" + Time.now.strftime("%d%H%M")

    @@employee = "1104000682" # "1112100128"
    @@employee_dependent = "1104000683" # "1112100129"
    @@doctor_dependent = "1105000899" # "1112100133"
    @@board_member = "1102000359" # "1112100137" existing BME patient - CABILI, LEONORA
    @@special_rate = 5000.00
    @@courtesy_amount = 10.0

    @@orders = {"040004334" => 5, "040010002" => 1,"044810074" => 1}
    @@orders2 = {"010000009" => 1, "010000022" => 1, "010000074" => 1, "010000073" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

#  it "1st Scenario: POS - Courtesy Discount per Department(10%) with HMO(35000.00) guarantor, Senior citizen discount(20%)" do
#    slmc.login('sel_pharmacy2', @password).should be_true
#    slmc.go_to_pos_ordering
#    slmc.oss_patient_info(:senior => true)
#    @@class_discount = 35000.0
#    slmc.oss_add_guarantor(:acct_class => "HMO", :guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :coverage_choice => "max_amount", :coverage_amount => @@class_discount.to_s, :guarantor_add => true)
#
#    @@orders.each do |item,q|
#      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true)
#    end
#
#    slmc.oss_order(:item_code => "9999", :org_code => "0004", :special => true, :rate => @@special_rate, :order_add => true).should be_true
#
#    ## add courtesy discount by department - 10%
#    slmc.oss_add_discount(:scope => "dept", :type => "percent" , :amount => @@courtesy_amount).should be_true
#
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt
#    end
#
#    @@gross = ((@@gross + @@special_rate)*100).round.to_f / 100
#
#    @@pos = slmc.pos_computation(:senior => true, :total_gross => @@gross)
#    #@@courtesy_discount = slmc.truncate_to(slmc.compute_courtesy_discount(:percent => true, :net => @@pos[:net_amount], :amount => @@courtesy_amount),2)
#    @@courtesy_discount = slmc.truncate_to(slmc.compute_courtesy_discount(:percent => true, :net => @@pos[:net_of_promo], :amount => @@courtesy_amount),2)
#
#    if @@pos[:net_amount] < @@class_discount
#      @@charged_amount = slmc.truncate_to((((@@pos[:net_amount] - @@courtesy_discount)*100).round.to_f / 100),2)
#    else
#      @@charged_amount = @@class_discount
#    end
#
#    @@balance_due = ( @@gross - (slmc.truncate_to(@@pos[:discount],2) + slmc.truncate_to(@@pos[:vat],2) + slmc.truncate_to(@@courtesy_discount,2) + slmc.truncate_to(@@charged_amount,2)))
#  end
#
#  it "1st Scenario: POS - Verifies computation for VAT, Promo/Senior, Courtesy, Charged and Balance due amount displayed in total summary details" do
#    @@summary1 = slmc.get_summary_totals
#
#    ((slmc.truncate_to((@@summary1[:total_gross_amount].to_f - @@pos[:gross]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary1[:total_promo].to_f - @@pos[:discount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary1[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary1[:total_discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary1[:total_vat].to_f - @@pos[:vat]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary1[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary1[:total_charge_amount].to_f - @@charged_amount),2).to_f).abs).should <= 0.02
#  end
#
#  it "1st Scenario: POS - Verifies computation for Total Net, Discount, Charged and Balance due amount displayed in billing details" do
#    @@billing1 = slmc.get_billing_details
#
#    ((slmc.truncate_to((@@billing1[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing1[:discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing1[:charge_amount].to_f - @@charged_amount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing1[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#
#  it "1st Scenario: POS - Submit payment successfully" do
#    @@amount = slmc.get_total_net_amount.to_s
#    slmc.oss_add_payment(:type => "CASH", :amount => @@amount) if @@amount != "0.00"
#    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
#  it "2nd Scenario: POS - Courtesy Discount per Service(10%) with Individual guarantor" do
#    slmc.go_to_pos_ordering
#    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
#
#    @@orders.each do |item,q|
#      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true)
#    end
#
#    slmc.oss_order(:item_code => "9999", :org_code => "0004", :special => true, :rate => @@special_rate, :order_add => true).should be_true
#
#    slmc.oss_add_discount(:scope => "service", :type => "percent" , :amount => @@courtesy_amount).should be_true
#
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt
#    end
#
#    @@gross = (( @@gross + @@special_rate ) * 100 ).round.to_f / 100
#
#    @@pos = slmc.pos_computation(:total_gross => @@gross)
#    @@courtesy_discount = slmc.compute_courtesy_discount(:percent => true, :net => @@pos[:net_of_promo], :amount => @@courtesy_amount)
#
#    @@balance_due = ( @@gross - (slmc.truncate_to(@@pos[:discount],2) + slmc.truncate_to(@@courtesy_discount, 2) ))
#  end
#
#  it "2nd Scenario: POS - Verifies computation for VAT, Promo/Senior, Courtesy, Charged and Balance due amount displayed in total summary details" do
#    @@summary2 = slmc.get_summary_totals
#
#    ((slmc.truncate_to((@@summary2[:total_gross_amount].to_f - @@pos[:gross]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary2[:total_promo].to_f - @@pos[:discount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary2[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary2[:total_discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary2[:total_vat].to_f - @@pos[:vat]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary2[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#
#  it "2nd Scenario: POS - Verifies computation for Total Net, Discount, Charged and Balance due amount displayed in billing details" do
#    @@billing2 = slmc.get_billing_details
#
#    ((slmc.truncate_to((@@billing2[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing2[:discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing2[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#
#  it "2nd Scenario: POS - Submit payment successfully" do
#    @@amount = slmc.get_total_net_amount.to_s
#    slmc.oss_add_payment(:type => "CASH", :amount => @@amount)
#    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
#  it "3rd Scenario: POS - Employee Dependent(20%)" do
#    slmc.go_to_pos_ordering
#    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE DEPENDENT", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109092", :guarantor_add => true)
#
#    @@orders.each do |item,q|
#      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true)
#    end
#
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@discount = slmc.compute_discounts(:unit_price => @@gross, :promo => true)
#    @@net_of_promo = @@gross - @@discount
#    @@class_discount = slmc.compute_class_discount(:unit_price => @@gross, :discount => @@discount, :percent => 20)
#    @@vat = slmc.compute_vat(:net_promo => @@net_of_promo, :class_discount => @@class_discount)
#    @@total_net_amount = @@net_of_promo - @@class_discount
#    @@balance_due = ( @@gross - @@discount - @@class_discount )
#  end
#
#  it "3rd Scenario: POS - Verifies computation for VAT, Promo/Senior, Charged and Balance due amount displayed in total summary details" do
#    @@summary3 = slmc.get_summary_totals
#
#    ((slmc.truncate_to((@@summary3[:total_gross_amount].to_f - @@gross),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary3[:total_promo].to_f - @@discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary3[:total_net_amount].to_f - @@total_net_amount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary3[:total_vat].to_f - @@vat),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary3[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary3[:total_class_discount].to_f - @@class_discount),2).to_f).abs).should <= 0.02
#  end
#
#  it "3rd Scenario: POS - Verifies computation for Total Net, Discount, Charged and Balance due amount displayed in billing details" do
#    @@billing3 = slmc.get_billing_details
#
#    ((slmc.truncate_to((@@billing3[:total_net_amount].to_f - @@total_net_amount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing3[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#
#  it "3rd Scenario: POS - Submit payment successfully" do
#    @@amount = slmc.get_total_net_amount.to_s + '00'
#    slmc.oss_add_payment(:type => "CASH", :amount => @@amount)
#    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
#  it "4th Scenario: POS - With Employee guarantor" do
#    slmc.go_to_pos_ordering
#    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109092", :guarantor_add => true)
#
#    ## order items
#    @@orders.each do |item,q|
#      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true)
#    end
#
#    ## order special item
#    slmc.oss_order(:item_code => "9999", :org_code => "0004", :special => true, :rate => @@special_rate, :order_add => true).should be_true
#
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    # Jan 25 2012 - debugged computation of vat for GC
#    # get total gross with special rate amount
#    @@gross = ((@@gross + @@special_rate)*100).round.to_f / 100
#    @@discount = slmc.compute_discounts(:unit_price => @@gross, :promo => true)
#    @@net_of_promo = @@gross - @@discount
#    @@class_discount = slmc.compute_class_discount(:unit_price => @@gross, :discount => @@discount, :percent => 100)
#    @@vat = slmc.compute_vat(:net_promo => @@net_of_promo, :class_discount => @@class_discount)
#    @@balance_due = @@gross - slmc.truncate_to((@@discount + @@class_discount),2)
#  end
#
#  it "4th Scenario: POS - Verifies computation for VAT, Promo/Senior, Courtesy, Charged and Balance due amount displayed in total summary details" do
#    @@summary4 = slmc.get_summary_totals
#
#    ((slmc.truncate_to((@@summary4[:total_gross_amount].to_f - @@gross),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary4[:total_promo].to_f - @@discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary4[:total_net_amount].to_f - 0.00),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary4[:total_vat].to_f - @@vat),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary4[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary4[:total_amount_due].to_f - 0.00),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary4[:total_class_discount].to_f - @@class_discount),2).to_f).abs).should <= 0.02
#  end
#
#  it "4th Scenario: POS - Verifies computation for Total Net, Discount, Charged and Balance due amount displayed in billing details" do
#    @@billing4 = slmc.get_billing_details
#
#    ((slmc.truncate_to((@@billing4[:total_net_amount].to_f - 0.00),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing4[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing4[:balance_due].to_f - 0.00),2).to_f).abs).should <= 0.02
#  end
#
#  it "4th Scenario: POS - Submit payment successfully" do
#    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
#  it "5th Scenario: POS - Courtesy Discount per Service(10%) with Company guarantor" do
#    slmc.go_to_pos_ordering
#    @@class_discount = 100.0
#    slmc.oss_add_guarantor(:acct_class => "COMPANY", :guarantor_type => "COMPANY", :guarantor_code => "ABSC001",
#    :coverage_choice => "percent", :coverage_amount => @@class_discount.to_s, :guarantor_add => true)
#
#    @@orders.each do |item,q|
#      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true)
#    end
#
#    slmc.oss_order(:item_code => "9999", :org_code => "0004", :special => true, :rate => @@special_rate, :order_add => true).should be_true
#
#    ## add courtesy discount by service - 10%
#    slmc.oss_add_discount(:scope => "service", :type => "percent" , :amount => @@courtesy_amount).should be_true
#
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    # get total gross with special rate amount
#    @@gross = ((@@gross + @@special_rate)*100).round.to_f / 100
#
#    @@pos = slmc.pos_computation(:total_gross => @@gross)
#    @@courtesy_discount = (slmc.compute_courtesy_discount(:percent => true, :net => @@pos[:net_of_promo], :amount => @@courtesy_amount) * 100).round.to_f / 100
#    @@charge_discount = ((@@pos[:net_of_promo] - @@courtesy_discount) * (@@class_discount/100.0) * 100 ).round.to_f / 100 ## 100% discount for Company guarantor
#
#    @@balance_due = (@@gross - (slmc.truncate_to(@@pos[:discount],2) + @@courtesy_discount + @@charge_discount))
#  end
#
#  it "5th Scenario: POS - Verifies computation for VAT, Promo/Senior, Courtesy and Balance due amount displayed in total summary details" do
#    @@summary5 = slmc.get_summary_totals
#
#    ((slmc.truncate_to((@@summary5[:total_gross_amount].to_f - @@pos[:gross]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary5[:total_promo].to_f - @@pos[:discount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary5[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary5[:total_discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary5[:total_vat].to_f - @@pos[:vat]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary5[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary5[:total_charge_amount].to_f - @@charge_discount),2).to_f).abs).should <= 0.02
#  end
#
#  it "5th Scenario: POS - Verifies computation for Total Net, Discount and Balance due amount displayed in billing details" do
#    @@billing5 = slmc.get_billing_details
#
#    ((slmc.truncate_to((@@billing5[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing5[:discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing5[:charge_amount].to_f - @@charge_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing5[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing5[:balance_due].to_f - 0.00),2).to_f).abs).should <= 0.02
#  end
#
#  it "5th Scenario: POS - Submit payment successfully" do
#    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
#  it "6th Scenario: POS - Courtesy Discount per Department(10%) with Individual guarantor, Senior citizen discount(20%)" do
#    slmc.go_to_pos_ordering
#    slmc.oss_patient_info(:senior => true)
#    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
#
#    @@orders.each do |item,q|
#      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true)
#    end
#
#    slmc.oss_order(:item_code => "9999", :org_code => "0004", :special => true, :rate => @@special_rate, :order_add => true).should be_true
#
#    ## add courtesy discount by service - 10%
#    slmc.oss_add_discount(:scope => "service", :type => "percent" , :amount => @@courtesy_amount).should be_true
#
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt
#    end
#
#    @@gross = ((@@gross + @@special_rate)*100).round.to_f / 100
#
#    @@pos = slmc.pos_computation(:senior => true, :total_gross => @@gross)
#    @@courtesy_discount = slmc.truncate_to(slmc.compute_courtesy_discount(:percent => true, :net => @@pos[:net_of_promo], :amount => @@courtesy_amount),2)
#
#    @@balance_due = ( @@gross - (slmc.truncate_to(@@pos[:discount],2) + slmc.truncate_to(@@pos[:vat],2) + slmc.truncate_to(@@courtesy_discount,2)))
#  end
#
#  it "6th Scenario: POS - Verifies computation for VAT, Promo/Senior, Courtesy and Balance due amount displayed in total summary details" do
#    @@summary6 = slmc.get_summary_totals
#
#    ((slmc.truncate_to((@@summary6[:total_gross_amount].to_f - @@pos[:gross]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary6[:total_promo].to_f - @@pos[:discount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary6[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary6[:total_discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary6[:total_vat].to_f - @@pos[:vat]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary6[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#
#  it "6th Scenario: POS - Verifies computation for Total Net, Discount and Balance due amount displayed in billing details" do
#    @@billing6 = slmc.get_billing_details
#
#    ((slmc.truncate_to((@@billing6[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing6[:discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing6[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#
#  it "6th Scenario: POS - Submit payment successfully" do
#    @@amount = slmc.get_total_amount_due.to_s + '00'
#    slmc.oss_add_payment(:type => "CASH", :amount => @@amount)
#    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
#  it "7th Scenario: OSS - Courtesy Discount per Department(15000) with Company guarantor(100%)" do
#    # create patient for OSS transaction
#    slmc.login("sel_oss3", @password).should be_true
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => "test")
#    slmc.click_outpatient_registration.should be_true
#    @@pin = slmc.oss_outpatient_registration(@oss_patient).gsub(' ', '')
#
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@pin)
#    slmc.click_outpatient_order.should be_true
#    @@class_discount = 100.0
#    slmc.oss_add_guarantor(:acct_class => "COMPANY", :guarantor_type => "COMPANY", :guarantor_code => "ABSC001",
#    :coverage_choice => "percent", :coverage_amount => @@class_discount.to_s, :guarantor_add => true)
#
#    @@orders2.each do |item,q|
#      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true).should be_true
#    end
#
#    slmc.oss_order(:item_code => "9999", :doctor => "6726", :special => true, :rate => @@special_rate, :order_add => true).should be_true
#
#    ## add courtesy discount by service - 10%
#    @@courtesy_amount = 15000.0
#    slmc.oss_add_discount(:scope => "dept", :type => "fixed" , :amount => @@courtesy_amount).should be_true
#
#    @@gross = 0.0
#    @@orders2.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt
#    end
#
#    @@gross = ((@@gross + @@special_rate)*100).round.to_f / 100
#
#    @@pos = slmc.oss_computation(:total_gross => @@gross)
#    @@courtesy_discount = slmc.compute_courtesy_discount(:fixed => true, :amount => @@courtesy_amount)
#    @@charge_discount = ((@@pos[:net_of_promo] - @@courtesy_discount) * (@@class_discount/100.0) * 100 ).round.to_f / 100 ## 100% discount for Company guarantor
#
#    @@balance_due = ( @@gross - (slmc.truncate_to(@@pos[:discount],2) + slmc.truncate_to(@@courtesy_discount,2) + slmc.truncate_to(@@charge_discount,2)))
#  end
#
#  it "7th Scenario: OSS - Verifies computation for VAT, Promo/Senior, Courtesy and Balance due amount displayed in total summary details" do
#    @@summary7 = slmc.get_summary_totals
#
#    ((slmc.truncate_to((@@summary7[:total_gross_amount].to_f - @@pos[:gross]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary7[:total_promo].to_f - @@pos[:discount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary7[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary7[:total_discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary7[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary7[:total_charge_amount].to_f - @@charge_discount),2).to_f).abs).should <= 0.02
#  end
#
#  it "7th Scenario: OSS - Verifies computation for Total Net, Discount and Balance due amount displayed in billing details" do
#    @@billing7 = slmc.get_billing_details
#
#    ((slmc.truncate_to((@@billing7[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing7[:discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing7[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing7[:balance_due].to_f - 0.00),2).to_f).abs).should <= 0.02
#  end
#
#  it "7th Scenario: OSS - Submit payment successfully" do
#    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
#  it "8th Scenario: OSS - NO Courtesy Discount with Individual guarantor" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@pin)
#    slmc.click_outpatient_order.should be_true
#    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
#
#    @@orders2.each do |item,q|
#      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true).should be_true
#    end
#
#    slmc.oss_order(:item_code => "9999", :org_code => "0004", :special => true, :rate => @@special_rate, :order_add => true).should be_true
#
#    @@gross = 0.0
#    @@orders2.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt
#    end
#
#    @@gross = ((@@gross + @@special_rate)*100).round.to_f / 100
#
#    @@pos = slmc.oss_computation(:total_gross => @@gross)
#    @@balance_due = ( @@gross - slmc.truncate_to(@@pos[:discount],2) )
#  end
#
#  it "8th Scenario: OSS - Verifies computation for VAT, Promo/Senior and Balance due amount displayed in total summary details" do
#    @@summary8 = slmc.get_summary_totals
#
#    ((slmc.truncate_to((@@summary8[:total_gross_amount].to_f - @@pos[:gross]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary8[:total_promo].to_f - @@pos[:discount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary8[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary8[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#
#  it "8th Scenario: OSS - Verifies computation for Total Net, Discount and Balance due amount displayed in billing details" do
#    @@billing8 = slmc.get_billing_details
#
#    ((slmc.truncate_to((@@billing8[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing8[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#
#  it "8th Scenario: OSS - Submit payment successfully" do
#    @@amount = slmc.get_total_net_amount
#    slmc.oss_add_payment(:type => "CASH", :amount => @@amount)
#    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
#  it "9th Scenario: OSS - Courtesy Discount per Department(15000) with Doctor Dependent(25%)" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@doctor_dependent)
#    slmc.click_outpatient_order.should be_true
#
#    sleep 5
#    @@orders2.each do |item,q|
#      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true).should be_true
#    end
#
#    sleep 5
#    slmc.oss_order(:item_code => "9999", :org_code => "0004", :special => true, :rate => @@special_rate, :order_add => true).should be_true
#
#    sleep 5
#    @@courtesy_amount = 15000.0
#    slmc.oss_add_discount(:scope => "dept", :type => "fixed" , :amount => @@courtesy_amount).should be_true
#
#    @@class_discount = 25.0
#    slmc.oss_add_guarantor(:acct_class => "DOCTOR DEPENDENT", :guarantor_type => "DOCTOR", :guarantor_code => "4972", :coverage_choice => "percent", :coverage_amount => @@class_discount.to_s, :guarantor_add => true)
#
#    sleep 10
#    @@gross = 0.0
#    @@orders2.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = ((@@gross + @@special_rate)*100).round.to_f / 100
#
#    @@pos = slmc.oss_computation(:total_gross => @@gross)
#    @@courtesy_discount = slmc.compute_courtesy_discount(:fixed => true, :amount => @@courtesy_amount)
#    @@class_discount2 = (((@@special_rate - (@@special_rate * (16.0/100.0))) * (10.0/100.0)) * 100 ).round.to_f / 100 ## Automatic 10% discount for DOCTOR DEPENDENTS applicable only for special items
#    @@charge_discount = ((@@pos[:net_of_promo] - @@courtesy_discount - @@class_discount2) * (@@class_discount/100.0) * 100 ).round.to_f / 100 ## 25% discount for Doctor Dependent guarantor as inputted in Add Guarantor
#    @@total_net_amount = @@pos[:net_amount] - @@class_discount2
#
#    @@balance_due = ( @@gross - (slmc.truncate_to(@@pos[:discount],2) + slmc.truncate_to(@@courtesy_discount,2) + slmc.truncate_to(@@charge_discount,2) + slmc.truncate_to(@@class_discount2,2)))
#  end
#
#  it "9th Scenario: OSS - Verifies computation for VAT, Promo/Senior, Courtesy and Balance due amount displayed in total summary details" do
#    @@summary9 = slmc.get_summary_totals
#
#    ((slmc.truncate_to((@@summary9[:total_gross_amount].to_f - @@pos[:gross]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary9[:total_promo].to_f - @@pos[:discount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary9[:total_net_amount].to_f - @@total_net_amount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary9[:total_discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary9[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary9[:total_charge_amount].to_f - @@charge_discount),2).to_f).abs).should <= 0.02
#  end
#
#  it "9th Scenario: OSS - Verifies computation for Total Net, Discount, Courtesy and Balance due amount displayed in billing details" do
#    @@billing9 = slmc.get_billing_details
#
#    ((slmc.truncate_to((@@billing9[:total_net_amount].to_f - @@total_net_amount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing9[:discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing9[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#
#  it "9th Scenario: OSS - Submit payment successfully" do
#    @@amount = slmc.get_total_amount_due
#    slmc.oss_add_payment(:type => "CASH", :amount => @@amount)
#    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
#  it "10th Scenario: OSS - Foreign patient, senior citizen" do
#    slmc.login("sel_oss3", @password).should be_true
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => "test")
#    slmc.oss_create_new_patient(@oss_patient2.merge!(:last_name => @lname, :birth_day => "07/01/1940", :citizenship => "AMERICAN"))
#
#    # get pin number of @lname variable
#    # this part of the script is executed because oss_create_new_patient method no longer returns the pin of the newly created patients
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @lname)
#    if slmc.is_text_present("Master Patient Index is unavailable. Searching from local data...")
#      @@pin2 = slmc.get_text('css=table[id="results"] tr[class="even"] td:nth-child(3)').gsub(' ', '')
#    else
#      @@pin2 = slmc.get_text(Locators::Admission.admission_search_results_pin).gsub(' ', '')
#      @@pin2 = slmc.get_text("css=#results>tbody>tr>td:nth-child(4)").gsub(' ','') if @@pin2 == "SLMC_GC"
#    end
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@pin2)
#    slmc.click_outpatient_order.should be_true
#    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
#
#    @@orders2.each do |item,q|
#      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true).should be_true
#    end
#
#    slmc.oss_order(:item_code => "9999", :org_code => "0004", :special => true, :rate => @@special_rate, :order_add => true).should be_true
#
#    @@gross = 0.0
#    @@orders2.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt
#    end
#
#    @@gross = (( @@gross + @@special_rate ) * 100 ).round.to_f / 100
#    @@pos = slmc.pos_computation(:total_gross => @@gross)
#
#    @@balance_due = ( @@gross - slmc.truncate_to(@@pos[:discount],2) )
#  end
#
#  it "10th Scenario: OSS - Verifies computation for VAT, Promo/Senior and Balance due amount displayed in total summary details" do
#    @@summary10 = slmc.get_summary_totals
#
#    ((slmc.truncate_to((@@summary10[:total_gross_amount].to_f - @@pos[:gross]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary10[:total_promo].to_f - @@pos[:discount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary10[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary10[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#
#  it "10th Scenario: OSS - Verifies computation for Total Net, Discount and Balance due amount displayed in billing details" do
#    @@billing10 = slmc.get_billing_details
#
#    ((slmc.truncate_to((@@billing10[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@billing10[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#
#  it "10th Scenario: OSS - Submit payment successfully" do
#    @@amount = slmc.get_total_net_amount
#    slmc.oss_add_payment(:type => "CASH", :amount => @@amount)
#    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end

  it "11th Scenario: OSS - 2 HMO Guarantors, Courtesy Discount per Department(10%) and Cash transaction " do
    slmc.login("sel_oss3", @password).should be_true
    slmc.go_to_das_oss
       slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@pin = slmc.oss_outpatient_registration(@oss_patient).gsub(' ', '')

    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    @@class_discount1 = 25.0
    @@class_discount2 = 25.0
    slmc.oss_add_guarantor(:acct_class => "HMO", :guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :coverage_choice => "percent", :coverage_amount => @@class_discount1.to_s, :guarantor_add => true)
    slmc.oss_add_guarantor(:acct_class => "HMO", :guarantor_type => "HMO", :guarantor_code => "COCOLIFE HEALTH CARE", :coverage_choice => "percent", :coverage_amount => @@class_discount2.to_s, :guarantor_add => true)

    @@orders2.each do |item,q|
      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true).should be_true
    end

    @@courtesy_amount = 10.0
    slmc.oss_add_discount(:scope => "dept", :type => "percent" , :amount => @@courtesy_amount).should be_true

    @@gross = 0.0
    @@orders2.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt
    end

    @@pos = slmc.oss_computation(:total_gross => @@gross)
    @@courtesy_discount = slmc.compute_courtesy_discount(:percent => true, :net => @@pos[:net_amount], :amount => @@courtesy_amount)
    @@charge_discount1 = ((@@pos[:net_of_promo] - @@courtesy_discount) * (@@class_discount1/100.0) * 100 ).round.to_f / 100 ## 25% discount for 1st HMO guarantor
    @@charge_discount2 = ((@@pos[:net_of_promo] - @@courtesy_discount) * (@@class_discount2/100.0) * 100 ).round.to_f / 100 ## 25% discount for 2nd HMO guarantor
    #@@total_charge_discount = @@charge_discount1 + (@@charge_discount2 - (@@charge_discount2 * @@class_discount2/100.0))
    @@total_charge_discount = (@@charge_discount1 + @@charge_discount2)
    @@balance_due = ( @@gross - (slmc.truncate_to(@@pos[:discount],2) + slmc.truncate_to(@@courtesy_discount,2) + slmc.truncate_to(@@charge_discount1,2) + slmc.truncate_to(@@charge_discount2,2)))
    #@@balance_due = ( @@gross - (slmc.truncate_to(@@pos[:discount],2) + slmc.truncate_to(@@courtesy_discount,2) + slmc.truncate_to(@@total_charge_discount,2)))
  end

  it "11th Scenario: OSS - Verifies computation for VAT, Promo/Senior, Courtesy and Balance due amount displayed in total summary details" do
    @@summary11 = slmc.get_summary_totals

    ((slmc.truncate_to((@@summary11[:total_gross_amount].to_f - @@pos[:gross]),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary11[:total_promo].to_f - @@pos[:discount]),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary11[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary11[:total_discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary11[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary11[:total_charge_amount].to_f - @@total_charge_discount),2).to_f).abs).should <= 0.02
  end

  it "11th Scenario: OSS - Verifies computation for Total Net, Discount, Courtesy and Balance due amount displayed in billing details" do
    @@billing11 = slmc.get_billing_details

    ((slmc.truncate_to((@@billing11[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@billing11[:discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@billing11[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
  end

  it "12th Scenario: OSS - HMO Guarantors(50%), Courtesy Discount per Department(10%) and Cash transaction " do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    @@class_discount = 50.0
    slmc.oss_add_guarantor(:acct_class => "HMO", :guarantor_type => "HMO", :guarantor_code => "COCOLIFE HEALTH CARE", :coverage_choice => "percent", :coverage_amount => @@class_discount.to_s, :guarantor_add => true)

    @@orders2.each do |item,q|
      slmc.oss_order(:item_code => item, :quantity => q, :order_add => true).should be_true
    end

    @@courtesy_amount = 10.0
    slmc.oss_add_discount(:scope => "dept", :type => "percent" , :amount => @@courtesy_amount).should be_true

    @@gross = 0.0
    @@orders2.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt
    end

    @@pos = slmc.oss_computation(:total_gross => @@gross)
    @@courtesy_discount = slmc.compute_courtesy_discount(:percent => true, :net => @@pos[:net_amount], :amount => @@courtesy_amount)
    @@charge_discount = ((@@pos[:net_of_promo] - @@courtesy_discount) * (@@class_discount/100.0) * 100 ).round.to_f / 100 ## 50% discount for HMO guarantor

    @@balance_due = ( @@gross - (slmc.truncate_to(@@pos[:discount],2) + slmc.truncate_to(@@courtesy_discount,2) + slmc.truncate_to(@@charge_discount,2)))
  end

  it "12th Scenario: OSS - Verifies computation for VAT, Promo/Senior, Courtesy and Balance due amount displayed in total summary details" do
    @@summary12 = slmc.get_summary_totals

    ((slmc.truncate_to((@@summary12[:total_gross_amount].to_f - @@pos[:gross]),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary12[:total_promo].to_f - @@pos[:discount]),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary12[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary12[:total_discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary12[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary12[:total_charge_amount].to_f - @@charge_discount),2).to_f).abs).should <= 0.02
  end

  it "12th Scenario: OSS - Verifies computation for Total Net, Discount, Courtesy and Balance due amount displayed in billing details" do
    @@billing12 = slmc.get_billing_details

    ((slmc.truncate_to((@@billing12[:total_net_amount].to_f - @@pos[:net_amount]),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@billing12[:discount].to_f - @@courtesy_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@billing12[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
  end

  it "12th Scenario: OSS - Submit payment successfully" do
    @@amount = slmc.get_total_net_amount
    slmc.oss_add_payment(:type => "CASH", :amount => @@amount)
    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "13th Scenario: OR - HMO(25%), Courtesy Discount per Department(50%)" do
    slmc.login("sel_or3", @password).should be_true
    @or_patient = @or_patient.merge!(:admit => true, :birth_day => '01/20/2000', :account_class => "HMO", :guarantor_code => "FORTUNE CARE")
    @@or_pin = slmc.or_create_patient_record(@or_patient).gsub(' ', '').should be_true
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin)

    @@orders2.each do |item,q|
      slmc.search_order(:ancillary => true, :description => item).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true).should be_true
    end

    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true

    slmc.go_to_occupancy_list_page
    slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :no_pending_order => true, :pf_amount => "100.00", :pf_type => "COMPLIMENTARY", :save => true).should be_true

    slmc.login("sel_pba2", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
    @@courtesy_amount = 50.0
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_rate => @@courtesy_amount, :save => true, :close_window => true).should be_true

    # update guarantor code - HMO 20%
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.click_guarantor_to_update
    @@class_discount = 20.0
    slmc.pba_update_guarantor(:guarantor_type => "HMO", :guarantor_code => "FORTUNE CARE", :loa_percent => @@class_discount).should be_true
  end

  it "13th Scenario: OR - Verifies computation of Discounts" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)

    sleep 10
    @@gross = 0.0
    @@orders2.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end

    @@or = slmc.oss_computation(:total_gross => @@gross)
    @@courtesy_discount = slmc.compute_courtesy_discount(:percent => true, :net => @@or[:net_amount], :amount => @@courtesy_amount)
    @@total_discount = slmc.truncate_to(@@courtesy_discount + @@or[:discount],2) ## summation of promo discount(16%) and courtesy discount(50%) as inputted in Discount page
    @@charged_amount = (((@@gross - (@@courtesy_discount + @@or[:discount])) * (@@class_discount/100.0)) * 100).round.to_f / 100

    @@balance_due = ( @@gross - (@@or[:discount] + slmc.truncate_to(@@courtesy_discount,2) + slmc.truncate_to(@@charged_amount,2) ))
  end

  it "13th Scenario: OR - Verifies computation for Total Hospital Bills, Discounts(Promo, Courtesy, Charged amount) and Balance due amount displayed in Payment Data Entry" do
    @@payment = slmc.get_billing_details_from_payment_data_entry

    ((slmc.truncate_to((@@payment[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@payment[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@payment[:charged_amount].to_f - @@charged_amount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@payment[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@payment[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
  end

  it "14th Scenario: OR - Promo discount is applicable to foreign patient" do
    slmc.login("sel_or3", @password).should be_true
    @or_patient2 = @or_patient2.merge!(:admit => true, :birth_day => '01/20/2000', :citizenship => "AMERICAN", :birth_country => "UNITED STATES", :nationality => "AMERICAN" )


    @@or_pin2 = slmc.or_create_patient_record(@or_patient2).gsub(' ', '')
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@or_pin2)

    @@orders2.each do |item,q|
      slmc.search_order(:ancillary => true, :description => item)
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true)
    end
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items

    slmc.go_to_occupancy_list_page
    slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin2, :pf_amount => "100.00", :pf_type => "COMPLIMENTARY", :save => true).should be_true

    # add manual discount
    slmc.login("sel_pba2", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin2)
    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
    @@courtesy_amount = 10.0
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_rate => @@courtesy_amount, :save => true, :close_window => true).should be_true
  end

  it "14th Scenario: OR - Verifies computation of Discounts" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin2)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)

    @@gross = 0.0
    @@orders2.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt
    end

    @@or = slmc.oss_computation(:total_gross => @@gross)
    @@courtesy_discount = slmc.compute_courtesy_discount(:percent => true, :net => @@or[:net_amount], :amount => @@courtesy_amount)
    @@total_discount = slmc.truncate_to(@@courtesy_discount + @@or[:discount],2) ## summation of promo discount(16%) and courtesy discount(10%) as inputted in Discount page

    @@balance_due = ( @@gross - (@@or[:discount] + slmc.truncate_to(@@courtesy_discount,2) ))
    puts @@or_pin2
  end

  it "14th Scenario: OR - Verifies computation for Total Hospital Bills, Discounts(Promo, Courtesy, Charged amount) and Balance due amount displayed in Payment Data Entry" do
    @@payment = slmc.get_billing_details_from_payment_data_entry

    ((slmc.truncate_to((@@payment[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@payment[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@payment[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@payment[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
  end
#adsadsadsa
  it "15th Scenario: OR - Doctor Dependent" do
  @@or_pin2  = '1204036200'
  slmc.login("pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
  #  slmc.insert_patient_to_doctor_dep(@or_patient2.merge!(:pin =>@@or_pin2))
    slmc.pba_search(:pin => @@or_pin2)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)

    # delete default INDIVIDUAL guarantor
    slmc.select_guarantor
    slmc.click_delete_guarantor.should be_true

    # update account class from INDIVIDUAL to DOCTOR DEPENDENT
    slmc.pba_update_account_class("DOCTOR DEPENDENT").should == "The Patient Info was updated."

    # add new DOCTOR DEPENDENT guarantor
    slmc.click_new_guarantor
    slmc.pba_update_guarantor(:guarantor_type => "DOCTOR", :guarantor_code => "6733").should == "Patient is not registered as Doctor dependent."
  end

  it "15th Scenario: OR - Verifies computation of Discounts" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@or_pin2)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)

    @@gross = 0.0
    @@orders2.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end

    @@or = slmc.oss_computation(:total_gross => @@gross)
    @@class_discount = 10.0 ## discount percentage for discount scheme DRDMO0DP004 as checked in REF_DISCOUNT_COVERED table
    @@courtesy_discount = slmc.compute_courtesy_discount(:percent => true, :net => @@or[:net_amount], :amount => @@courtesy_amount) ## courtesy amount as inputted in 14th scenario
    @@total_discount = slmc.truncate_to(@@courtesy_discount + @@or[:discount],2) ## summation of promo discount(16%) and courtesy discount(10%) as inputted in Discount page
    #@@charged_amount = (((@@gross - (@@courtesy_discount + @@or[:discount])) * (@@class_discount/100.0)) * 100).round.to_f / 100

    #@@balance_due = ( @@gross - (slmc.truncate_to(@@total_discount,2) + slmc.truncate_to(@@charged_amount,2) ))
    @@balance_due = (@@gross - @@total_discount)
  end

  it "15th Scenario: OR - Verifies computation for Total Hospital Bills, Discounts(Promo, Courtesy, Charged amount) and Balance due amount displayed in Payment Data Entry" do
    @@payment = slmc.get_billing_details_from_payment_data_entry

    ((slmc.truncate_to((@@payment[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@payment[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
    slmc.truncate_to(((@@payment[:total_amount_due].to_f - @@balance_due).abs),2).should <= 0.02
    ((slmc.truncate_to((@@payment[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.03
  end

  it "16th Scenario: OR - Senior Citizen, Board Member account class" do
    slmc.login("sel_or3", @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@board_member)
    slmc.click("physout", :wait_for => :page) if slmc.is_element_present("physout")
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@board_member)
    if (slmc.get_text("results").gsub(' ', '').include? @@board_member) && slmc.is_element_present("link=Register Patient")
      slmc.click_register_patient.should be_true
      slmc.admit_or_nb_patient(:admit => true, :account_class => "BOARD MEMBER", :guarantor_code => "BMLC001")
    else
      if slmc.is_text_present("NO PATIENT FOUND")
        @or_patient3 = @or_patient3.merge!(:admit => true, :lastname => "CABILI", :firstname => "LEONORA", :birth_day => '01/20/1940', :account_class => "BOARD MEMBER", :guarantor_code => "BMLC001")
        @@board_member = slmc.or_create_patient_record(@or_patient3).gsub(' ', '')
      else
        if slmc.verify_su_patient_status(@@board_member) != "Clinically Discharged"
          slmc.validate_incomplete_orders(:outpatient => true, :pin => @@board_member, :ancillary => true, :orders => "multiple")
          slmc.go_to_occupancy_list_page
          @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@board_member, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
        end
        slmc.login("sel_pba2", @password).should be_true
        slmc.go_to_patient_billing_accounting_page
        slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
        slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
        slmc.click_guarantor_to_update
        slmc.pba_update_guarantor(:guarantor_type => "BOARD MEMBER", :guarantor_code => "BMLC001").should be_true
        slmc.click_submit_changes

        slmc.go_to_patient_billing_accounting_page
        @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
        slmc.select_discharge_patient_type(:type => "DAS").should be_true # if error occurs in this part, contact Janren

        slmc.login("sel_or3", @password).should be_true
        slmc.or_print_gatepass(:pin => @@board_member, :visit_no => @@visit_no).should be_true
      end
      slmc.or_register_patient(:pin => @@board_member, :account_class => "BOARD MEMBER", :guarantor_type => "BOARD MEMBER", :guarantor_code => "BMLC001", :org_code => "0164").should be_true
    end
    slmc.go_to_occupancy_list_page
    slmc.go_to_order_page(:pin => @@board_member)
    @@orders2.each do |item,q|
      slmc.search_order(:ancillary => true, :description => item)
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true)
    end
    slmc.er_submit_added_order # no drugs ordered means no validation
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items

    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@board_member, :no_pending_order => true, :pf_amount => "100.00", :save => true).should be_true

    slmc.login("sel_pba2", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@board_member)
    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
    @@courtesy_amount = 50.0
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_rate => @@courtesy_amount, :save => true, :close_window => true).should be_true

    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@board_member)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.click_guarantor_to_update
    slmc.pba_update_guarantor(:guarantor_type => "BOARD MEMBER", :guarantor_code => "BMLC001").should be_true
    slmc.click_submit_changes
  end

  it "16th Scenario: OR - Verifies computation of Discounts" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@board_member)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)

    @@gross = 0.0
    @@orders2.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end

    @@or = slmc.oss_computation(:total_gross => @@gross, :senior => true)
    @@courtesy_discount = slmc.compute_courtesy_discount(:percent => true, :net => @@or[:net_amount], :amount => @@courtesy_amount)
    @@total_discount = slmc.truncate_to(@@courtesy_discount + @@or[:discount],2) ## summation of promo discount(16%) and courtesy discount(50%) as inputted in Discount page
    @@charged_amount = (((@@gross - (@@courtesy_discount + @@or[:discount])) * (100.0/100.0)) * 100).round.to_f / 100 # 100% charge for board member

    #@@balance_due = ( @@gross - (@@or[:discount] + slmc.truncate_to(@@total_discount,2) + slmc.truncate_to(@@charged_amount,2) ))
    @@balance_due = (@@gross - @@total_discount)
  end

  it "16th Scenario: OR - Verifies computation for Total Hospital Bills, Discounts(Promo, Courtesy, Charged amount) and Balance due amount displayed in Payment Data Entry" do
    @@payment = slmc.get_billing_details_from_payment_data_entry

    ((slmc.truncate_to((@@payment[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@payment[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@payment[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@payment[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
  end

  it "Discharges board member" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@board_member)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS").should be_true
    slmc.login("sel_or3", @password)
    slmc.or_print_gatepass(:pin => @@board_member, :visit_no => @@visit_no).should be_true
  end

end





