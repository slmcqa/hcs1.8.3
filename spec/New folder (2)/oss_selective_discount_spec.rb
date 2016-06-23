require File.dirname(__FILE__) + "/../lib/slmc"
require "spec_helper"
require "yaml"

USERS = YAML.load_file File.dirname(__FILE__) + "/../spec_users.yml"

describe "SLMC :: OSS - Selective Discount (INDIVIDUAL, SOCIAL SERVICE and COMPANY)" do # to do drugs included are not compesable please delete if not needed.

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @patient1 = Admission.generate_data(:not_senior => true)
    @promo_discount1 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient1[:age])

    @patient2 = Admission.generate_data(:senior => true)
    @promo_discount2 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient2[:age])

    @patient3 = Admission.generate_data(:senior => true)
    @promo_discount3 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient3[:age])

    @patient4 = Admission.generate_data
    @promo_discount4 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient4[:age])

    @patient5 = Admission.generate_data
    @promo_discount5 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient5[:age])

    @patient6 = Admission.generate_data
    @promo_discount6 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient6[:age])

    @patient7 = Admission.generate_data
    @promo_discount7 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient7[:age])

    @patient8 = Admission.generate_data
    @promo_discount8 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient8[:age])

    @patient9 = Admission.generate_data
    @promo_discount9 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient9[:age])
    @esc_no = "0004589" #0000462

    @patient10 = Admission.generate_data
    @promo_discount10 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient10[:age])

    @patient11 = Admission.generate_data
    @promo_discount11 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient11[:age])

    @password = "123qweuser"

    @drugs = {"049000075" => 1}
    @ancillary = {
                "010001662" => 1,
                "010001525" => 1,
                "010000007" => 1,
                "010000008" => 1,
                "010002460" => 1,
                "010001460" => 1,
                "010000009" => 1
                }
    @doctors = ["6726","0126","6726","0126"]
  end

  after(:all) do
#    slmc.logout
#    slmc.close_current_browser_session
  end

#-LOG-IN AS OSS USER
#- CREATE PATIENT
#- WITH PHILHEALTH
#- CHOOSE INDIVIDUAL AS ACCOUNT CLASS
#- INDIVIDUAL FOR GUARANTOR
#- CREATE ORDERS
#- ADD A PER DEPARTMENT → COURTESY DISCOUNT → 10%

#  it "OSS - Individual Patient 1 - Create patient" do
#    slmc.login("sel_oss9", @password).should be_true
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => "test")
#    slmc.click_outpatient_registration.should be_true
#    @@oss_pin1 = (slmc.oss_outpatient_registration(@patient1)).gsub(" ","")
#  end
#
#  it "OSS - Individual Patient 1 - Go to Outpatient Order" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@oss_pin1)
#    slmc.click_outpatient_order.should be_true
#    slmc.oss_patient_info(:philhealth => true)
#  end
#
#  it "OSS - Individual Patient 1 - Add Guarantor (Individual)" do
#    slmc.oss_add_guarantor(:guarantor_type =>  "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true).should be_true
#  end
#
#  it "OSS - Individual Patient 1 - Order items" do
#    @@orders = @ancillary#.merge(@drugs)
#    n = 0
#    @@orders.each do |item, q|
#      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
#      n += 1
#    end
#  end
#
#  it "OSS - Individual Patient 1 - Add Discount 10% (Per Department)" do
#    @discount = 10.0
#    slmc.oss_add_discount(:type => "percent", :scope => "dept", :amount => @discount.to_s)
#  end
#
#  it "OSS - Individual Patient 1 - Compute PhilHealth" do
#    @@ph = slmc.oss_input_philhealth(:case_type => "SUPER CATASTROPHIC CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060",  :compute => true)
#  end
#
#  it "OSS - Individual Patient 1 - System should be able to divide the percentage of discount equally to the items" do
#    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
#    # Order Toggle
#    @@lab_max = @@lab_ph_benefit[:max_amt].to_f
#    @@number_of_rows = slmc.get_css_count("css=#tableRows>tr")
#    @philhealth_claims = []
#    @net_amount = []
#    x = 0
#    @@number_of_rows.times do
#      amount = slmc.get_text("//*[@id=\"ops_order_amount_#{x}\"]").gsub(',','').to_f
#      discount = amount * @promo_discount1
#      net_amount = amount - discount
#      if net_amount < @@lab_max
#        @philhealth_claims << net_amount
#        @@lab_max = @@lab_max - net_amount if (@@lab_max > net_amount)
#        @net_amount << 0
#      else
#        @philhealth_claims << @@lab_max
#        @net_amount << net_amount - @@lab_max
#        @@lab_max = 0
#      end
#      x += 1
#    end
#
#    # total philhealth claim should equal
#    @@total_philhealth_claim = 0
#    x = 0
#    @philhealth_claims.each do
#      @@total_philhealth_claim += @philhealth_claims[x]
#      x += 1
#    end
#    @@total_philhealth_claim.should == @@lab_ph_benefit[:max_amt].to_f
#
#    bool = []
#    x = 0
#    @@number_of_rows.times do
#      #bool << (("%0.2f" %(@net_amount[x])).to_f.should == slmc.get_text("//*[@id=\"ops_order_net_amount_#{x}\"]").gsub(',','').to_f)
#      bool << (((slmc.truncate_to((("%0.2f" %(@net_amount[x])).to_f - slmc.get_text("//*[@id=\"ops_order_net_amount_#{x}\"]").gsub(',','').to_f),2).to_f).abs).should <= 0.02)
#      bool[x].should be_true
#      x += 1
#    end
#
#    # Discount Toggle
#    @@number_of_rows.should == slmc.get_css_count("css=#discountDetails>tr")
#
#    x = 0
#    @@number_of_rows.times do
#      amount = slmc.get_text("//*[@id=\"discountNetAmountDisplay-#{x}\"]").gsub(',','').to_f
#      discount = (amount * 0.10).to_f
#      ("%0.2f" %(discount)).to_f.should == slmc.get_text("//*[@id=\"discountAdditionalDiscountDisplay-#{x}\"]").gsub(',','').to_f
#      x += 1
#    end
#  end
#
##-LOG-IN AS OSS USER
##- CREATE PATIENT
##- WITH PHILHEALTH
##- CHOOSE INDIVIDUAL AS ACCOUNT CLASS
##- INDIVIDUAL FOR GUARANTOR
##- CREATE ORDERS
##- ADD A PER DEPARTMENT → CONTRACTUAL DISCOUNT → 10%
##-SENIOR CITIZEN
#
#  it "OSS - Individual Patient 2 - Create patient" do
#    slmc.login("sel_oss9", @password).should be_true
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => "test")
#    slmc.click_outpatient_registration.should be_true
#    @@oss_pin2 = (slmc.oss_outpatient_registration(@patient2)).gsub(" ","")
#  end
#
#  it "OSS - Individual Patient 2 - Go to Outpatient Order" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@oss_pin2)
#    slmc.click_outpatient_order.should be_true
#    slmc.oss_patient_info(:philhealth => true, :senior => true)
#  end
#
#  it "OSS - Individual Patient 2 - Add Guarantor (Individual)" do
#    slmc.oss_add_guarantor(:guarantor_type =>  "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true).should be_true
#  end
#
#  it "OSS - Individual Patient 2 - Order items" do
#    @@orders = @ancillary#.merge(@drugs)
#    n = 0
#    @@orders.each do |item, q|
#      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
#      n += 1
#    end
#  end
#
#  it "OSS - Individual Patient 2 - Add Discount 10% (Per Department)" do
#    @discount = 10.0
#    slmc.oss_add_discount(:type => "percent", :scope => "dept", :amount => @discount.to_s)
#  end
#
#  it "OSS - Individual Patient 2 - Compute PhilHealth" do
#    @@ph = slmc.oss_input_philhealth(:case_type => "CATASTROPHIC CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060",  :compute => true)
#  end
#
#  it "OSS - Individual Patient 2 - System should be able to divide the percentage of discount equally to the items" do
#    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
#    # Order Toggle
#    @@lab_max = @@lab_ph_benefit[:max_amt].to_f
#    @@number_of_rows = slmc.get_css_count("css=#tableRows>tr")
#    @philhealth_claims = []
#    @net_amount = []
#    x = 0
#    @@number_of_rows.times do
#      amount = slmc.get_text("//*[@id=\"ops_order_amount_#{x}\"]").gsub(',','').to_f
#      discount = amount * @promo_discount2
#      net_amount = amount - discount
#      if net_amount < @@lab_max
#        @philhealth_claims << net_amount
#        @@lab_max = @@lab_max - net_amount if (@@lab_max > net_amount)
#        @net_amount << 0
#      else
#        @philhealth_claims << @@lab_max
#        @net_amount << net_amount - @@lab_max
#        @@lab_max = 0
#      end
#      x += 1
#    end
#
#    # total philhealth claim should equal
#    @@total_philhealth_claim = 0
#    x = 0
#    @philhealth_claims.each do
#      @@total_philhealth_claim += @philhealth_claims[x]
#      x += 1
#    end
#    @@total_philhealth_claim.should == @@lab_ph_benefit[:max_amt].to_f
#
#    bool = []
#    x = 0
#    @@number_of_rows.times do
#      #bool << (("%0.2f" %(@net_amount[x])).to_f.should == slmc.get_text("//*[@id=\"ops_order_net_amount_#{x}\"]").gsub(',','').to_f)
#      bool << (((slmc.truncate_to((("%0.2f" %(@net_amount[x])).to_f - slmc.get_text("//*[@id=\"ops_order_net_amount_#{x}\"]").gsub(',','').to_f),2).to_f).abs).should <= 0.02)
#      bool[x].should be_true
#      x += 1
#    end
#
#    # Discount Toggle
#    @@number_of_rows.should == slmc.get_css_count("css=#discountDetails>tr")
#
#    x = 0
#    @@number_of_rows.times do
#      amount = slmc.get_text("//*[@id=\"discountNetAmountDisplay-#{x}\"]").gsub(',','').to_f
#      discount = (amount * 0.10).to_f
#      ("%0.2f" %(discount)).to_f.should == slmc.get_text("//*[@id=\"discountAdditionalDiscountDisplay-#{x}\"]").gsub(',','').to_f
#      x += 1
#    end
#  end
#
#  it "OSS - Individual Patient 2 - Complete Payment" do
#    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
#    slmc.oss_add_payment(:amount => amount, :type => "CASH")
#    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
##-LOG-IN AS OSS USER
##- CREATE PATIENT
##- WITH PHILHEALTH
##- SENIOR CITIZEN
##- CHOOSE INDIVIDUAL AS ACCOUNT CLASS
##- GUARANTOR COMPANY → 150K
##- CREATE ORDERS
##- ADD A PER SERVICE → SOCIAL SERVICE → 10%
#
#  it "OSS - Individual Patient 3 - Create patient" do
#    slmc.login("sel_oss9", @password).should be_true
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => "test")
#    slmc.click_outpatient_registration.should be_true
#    @@oss_pin3 = (slmc.oss_outpatient_registration(@patient3)).gsub(" ","")
#  end
#
#  it "OSS - Individual Patient 3 - Go to Outpatient Order" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@oss_pin3)
#    slmc.click_outpatient_order.should be_true
#    slmc.oss_patient_info(:philhealth => true, :senior => true)
#  end
#
#  it "OSS - Individual Patient 3 - Add Guarantor (Individual)" do
#    slmc.oss_add_guarantor(:guarantor_type =>  "COMPANY", :acct_class => "INDIVIDUAL", :guarantor_code => "AYCO003", :coverage_choice => 'max_amount', :coverage_amount => 150000, :guarantor_add => true).should be_true
#  end
#
#  it "OSS - Individual Patient 3 - Order items" do
#    @@orders = @ancillary#.merge(@drugs)
#    n = 0
#    @@orders.each do |item, q|
#      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
#      n += 1
#    end
#  end
#
#  it "OSS - Individual Patient 3 - Add Social Service Discount 10% (Per Service)" do
#    @discount = 10.0
#    slmc.oss_add_discount(:discount_type => "Social Service",:type => "percent", :scope => "service", :amount => @discount.to_s)
#  end
#
#  it "OSS - Individual Patient 3 - Compute PhilHealth" do
#    @@ph = slmc.oss_input_philhealth(:case_type => "INTENSIVE CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060",  :compute => true)
#  end
#
#  it "OSS - Individual Patient 3 - System should be able to divide the percentage of discount equally to the items" do
#    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
#    # Order Toggle
#    @@lab_max = @@lab_ph_benefit[:max_amt].to_f
#    @@number_of_rows = slmc.get_css_count("css=#tableRows>tr")
#    @philhealth_claims = []
#    @net_amount = []
#    x = 0
#    @@number_of_rows.times do
#      amount = slmc.get_text("//*[@id=\"ops_order_amount_#{x}\"]").gsub(',','').to_f
#      discount = amount * @promo_discount3
#      net_amount = amount - discount
#      if net_amount < @@lab_max
#        @philhealth_claims << net_amount
#        @@lab_max = @@lab_max - net_amount if (@@lab_max > net_amount)
#        @net_amount << 0
#      else
#        @philhealth_claims << @@lab_max
#        @net_amount << net_amount - @@lab_max
#        @@lab_max = 0
#      end
#      x += 1
#    end
#
#    # total philhealth claim should equal
#    @@total_philhealth_claim = 0
#    x = 0
#    @philhealth_claims.each do
#      @@total_philhealth_claim += @philhealth_claims[x]
#      x += 1
#    end
#    @@total_philhealth_claim.should == @@lab_ph_benefit[:max_amt].to_f
#
#    bool = []
#    x = 0
#    @@number_of_rows.times do
#      #bool << (("%0.2f" %(@net_amount[x])).to_f.should == slmc.get_text("//*[@id=\"ops_order_net_amount_#{x}\"]").gsub(',','').to_f)
#      bool << (((slmc.truncate_to((("%0.2f" %(@net_amount[x])).to_f - slmc.get_text("//*[@id=\"ops_order_net_amount_#{x}\"]").gsub(',','').to_f),2).to_f).abs).should <= 0.02)
#      bool[x].should be_true
#      x += 1
#    end
#
#    # Discount Toggle
#    @@number_of_rows.should_not == slmc.get_css_count("css=#discountDetails>tr")
#    @@number_discount = slmc.get_css_count("css=#discountDetails>tr")
#
#    x = 0
#    @@number_discount.times do
#      amount = slmc.get_text("//*[@id=\"discountNetAmountDisplay-#{x}\"]").gsub(',','').to_f
#      discount = (amount * 0.10).to_f
#      ("%0.2f" %(discount)).to_f.should == slmc.get_text("//*[@id=\"discountAdditionalDiscountDisplay-#{x}\"]").gsub(',','').to_f
#      x += 1
#    end
#  end
#
#  it "OSS - Individual Patient 3 - PAYMENT and the amount that will be covered by the company " do
#    slmc.get_total_amount_due.should == ("%0.2f" %(0.0))
#  end
#
#  it "OSS - Individual Patient 3 - Submit Order without payment" do
#    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end

##-LOG-IN AS OSS USER
##- CREATE PATIENT
##- WITH PHILHEALTH
##- CHOOSE INDIVIDUAL AS ACCOUNT CLASS
##- GUARANTOR HMO → 100K
##- CREATE ORDERS
##- ADD A PER DEPARTMENT → PACKAGE DISCOUNT → 50000
##- ADD AN ANCILLARY → CONTRACTUAL → 25%
#
## Bug #41298 invalid scenario
##  it "OSS - Individual Patient 4 - Create patient" do
##    slmc.go_to_das_oss
##    slmc.patient_pin_search(:pin => "test")
##    slmc.click_outpatient_registration.should be_true
##    @@oss_pin4 = (slmc.oss_outpatient_registration(@patient4)).gsub(" ","")
##  end
##
##  it "OSS - Individual Patient 4 - Go to Outpatient Order" do
##    slmc.go_to_das_oss
##    slmc.patient_pin_search(:pin => @@oss_pin4)
##    slmc.click_outpatient_order.should be_true
##    slmc.oss_patient_info(:philhealth => true, :senior => true) if @promo_discount4 == 0.2
##    slmc.oss_patient_info(:philhealth => true) if @promo_discount4 == 0.16
##  end
##
##  it "OSS - Individual Patient 4 - Add Guarantor (Individual)" do
##    slmc.oss_add_guarantor(:guarantor_type =>  "HMO", :acct_class => "INDIVIDUAL", :guarantor_code => "ASAL002", :coverage_choice => 'max_amount', :coverage_amount => 100000, :guarantor_add => true).should be_true
##  end
##
##  it "OSS - Individual Patient 4 - Order items" do
##    @@orders = @ancillary.merge(@drugs)
##    n = 0
##    @@orders.each do |item, q|
##      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
##      n += 1
##    end
##  end
##
##  it "OSS - Individual Patient 4 - Add Package and Company Discount 50000 and 25% (Per Department and Ancillary)" do
##    @package_discount = 50000
##    @contractual_discount = 25
##    slmc.oss_add_discount(:discount_type => "Package Discount", :type => "fixed", :scope => "dept", :amount => @package_discount.to_s).should be_true
##    slmc.oss_add_discount(:discount_type => "Contractual And Company Discount", :type => "percent", :scope => "ancillary", :amount => @contractual_discount.to_s).should be_true
##  end
##
##  it "OSS - Individual Patient 4 - Compute PhilHealth" do
##    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060",  :compute => true)
##  end
##
##  it "OSS - Individual Patient 4 - The system should be able to compute for the total of 50000 discount for all the items selected" do
##    @package_discount_temp = 0
##    count = slmc.get_css_count("css=#discountDetails>tr")
##    x = 0
##    count.times do
##      @package_discount_temp += slmc.get_text("discountAmountFixedDisplay-#{x}").to_f
##        x += 1
##    end
##    ((slmc.truncate_to((@package_discount_temp.to_f - @package_discount),2).to_f).abs).should <= 0.00
##    @package_discount_temp.should == @package_discount
##  end
##
##  it "OSS - Individual Patient 4 - Submit Order without payment" do
##    puts "Not Yet Completed https://projects.exist.com/issues/41298"
##    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
##  end
#
##-LOG-IN AS OSS USER
##- CREATE PATIENT
##- CHOOSE INDIVIDUAL AS ACCOUNT CLASS
##- CREATE ORDERS
##- ADD A PER DEPARTMENT → DOCTOR  → 10%

#  it "OSS - Individual Patient 5 - Create patient" do
#    slmc.login("sel_oss9", @password).should be_true
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => "test")
#    slmc.click_outpatient_registration.should be_true
#    @@oss_pin5 = (slmc.oss_outpatient_registration(@patient5)).gsub(" ","")
#  end
#
#  it "OSS - Individual Patient 5 - Go to Outpatient Order" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@oss_pin5)
#    slmc.click_outpatient_order.should be_true
#    slmc.oss_patient_info(:senior => true) if @promo_discount5 == 0.2
#  end
#
#  it "OSS - Individual Patient 5 - Add Guarantor (Individual)" do
#    slmc.oss_add_guarantor(:guarantor_type => "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true).should be_true
#  end
#
#  it "OSS - Individual Patient 5 - Order items" do
#    @@orders = @ancillary#.merge(@drugs)
#    n = 0
#    @@orders.each do |item, q|
#      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
#      n += 1
#    end
#  end
#
#  it "OSS - Individual Patient 5 - Add Doctor Discount 10% (Per Department)" do
#    @@doctor_discount = 10
#    slmc.oss_add_discount(:discount_type => "Doctor Discount", :type => "percent", :scope => "dept", :amount => @@doctor_discount.to_s).should be_true
#  end
#
#  it "OSS - Individual Patient 5 - System should be able to divide the percentage of discount equally to the items" do
#    # Order Toggle
#    @@number_of_rows = slmc.get_css_count("css=#tableRows>tr")
#    @net_amount = []
#    x = 0
#    @@number_of_rows.times do
#      amount = slmc.get_text("//*[@id=\"ops_order_amount_#{x}\"]").gsub(',','').to_f
#      discount = amount * @promo_discount5
#      net_amount = amount - discount
#      @net_amount << net_amount
#      x += 1
#    end
#
#    bool = []
#    x = 0
#    @@number_of_rows.times do
#      #bool << (("%0.2f" %(@net_amount[x])).to_f.should == slmc.get_text("//*[@id=\"ops_order_net_amount_#{x}\"]").gsub(',','').to_f)
#      bool << (((slmc.truncate_to((("%0.2f" %(@net_amount[x])).to_f - slmc.get_text("//*[@id=\"ops_order_net_amount_#{x}\"]").gsub(',','').to_f),2).to_f).abs).should <= 0.02)
#      bool[x].should be_true
#      x += 1
#    end
#
#    # Discount Toggle
#    @@number_of_rows.should == slmc.get_css_count("css=#discountDetails>tr")
#
#    x = 0
#    @@number_of_rows.times do
#      amount = slmc.get_text("//*[@id=\"discountNetAmountDisplay-#{x}\"]").gsub(',','').to_f
#      discount = (amount * (@@doctor_discount / 100.0)).to_f
#      ("%0.2f" %(discount)).to_f.should == slmc.get_text("//*[@id=\"discountAdditionalDiscountDisplay-#{x}\"]").gsub(',','').to_f
#      x += 1
#    end
#  end
#
#  it "OSS - Individual Patient 5 - The system should be able to display the discount under the Percentage Column" do
#    slmc.get_value("css=#discountAmountPercentage-0").should == "10"
#    slmc.get_value("css=#discountAmountPercentage-1").should == "10"
#    slmc.get_value("css=#discountAmountPercentage-2").should == "10"
#    slmc.get_value("css=#discountAmountPercentage-3").should == "10"
#    slmc.get_value("css=#discountAmountPercentage-4").should == "10"
#    slmc.get_value("css=#discountAmountPercentage-5").should == "10"
#    slmc.get_value("css=#discountAmountPercentage-6").should == "10"
#    slmc.get_value("css=#discountAmountPercentage-7").should == "10"
#  end
#
#  it "OSS - Individual Patient 5 - Submit Order with payment" do
#    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
#    slmc.oss_add_payment(:amount => amount, :type => "CASH")
#    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
##-LOG-IN AS OSS USER
##- CREATE PATIENT
##- CHOOSE INDIVIDUAL AS ACCOUNT CLASS
##- CREATE ORDERS
##- ADD A PER SERVICE → EMPLOYEE  → 5000 (500 only since item rate is below 5000)
#
#  it "OSS - Individual Patient 6 - Create patient" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => "test")
#    slmc.click_outpatient_registration.should be_true
#    @@oss_pin6 = (slmc.oss_outpatient_registration(@patient6)).gsub(" ","")
#  end
#
#  it "OSS - Individual Patient 6 - Go to Outpatient Order" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@oss_pin6)
#    slmc.click_outpatient_order.should be_true
#    slmc.oss_patient_info(:senior => true) if @promo_discount6 == 0.2
#  end
#
#  it "OSS - Individual Patient 6 - Add Guarantor (Individual)" do
#    slmc.oss_add_guarantor(:guarantor_type => "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true).should be_true
#  end
#
#  it "OSS - Individual Patient 6 - Order items" do
#    @@orders = @ancillary.merge({"010000385" => 1, "010001021" => 1})#.merge(@drugs)
#    n = 0
#    @@orders.each do |item, q|
#      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
#      n += 1
#    end
#  end
#
#  it "OSS - Individual Patient 6 - Add Employee Discount 500 (Per Service)" do
#    @employee_discount = 500
#    slmc.oss_add_discount(:discount_type => "Employee Discount", :type => "fixed", :scope => "service", :amount => @employee_discount.to_s).should be_true
#  end
#
#  it "OSS - Individual Patient 6 - Submit Order with payment" do
#    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
#    slmc.oss_add_payment(:amount => amount, :type => "CASH")
#    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
##-LOG-IN AS OSS USER
##- CREATE PATIENT
##- CHOOSE INDIVIDUAL AS ACCOUNT CLASS
##- CREATE ORDERS
##- ADD A PER SERVICE → EMPLOYEE DEPENDENT  → 5000
#
#  it "OSS - Individual Patient 7 - Create patient" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => "test")
#    slmc.click_outpatient_registration.should be_true
#    @@oss_pin7 = (slmc.oss_outpatient_registration(@patient7)).gsub(" ","")
#  end
#
#  it "OSS - Individual Patient 7 - Go to Outpatient Order" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@oss_pin7)
#    slmc.click_outpatient_order.should be_true
#    slmc.oss_patient_info(:senior => true) if @promo_discount7 == 0.2
#  end
#
#  it "OSS - Individual Patient 7 - Add Guarantor (Individual)" do
#    slmc.oss_add_guarantor(:guarantor_type => "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true).should be_true
#  end
#
#  it "OSS - Individual Patient 7 - Order items" do
#    @@orders = {"010000385" => 1, "010001021" => 1}
#    n = 0
#    @@orders.each do |item, q|
#      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
#      n += 1
#    end
#  end
#
#  it "OSS - Individual Patient 7 - Add Employee Dependent Discount 5000 (Per Service) should not be able to add discount" do
#    @employee_dependent_discount = 5000
#    slmc.oss_add_discount(:discount_type => "Employee Dependent Discount", :type => "fixed", :scope => "service", :amount => @employee_dependent_discount.to_s).should be_false
#  end
#
#  it "OSS - Individual Patient 7 - Submit Order with payment" do
#    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
#    slmc.oss_add_payment(:amount => amount, :type => "CASH")
#    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end

#-LOG-IN AS OSS USER
#- CREATE PATIENT
#- CHOOSE INDIVIDUAL AS ACCOUNT CLASS
#- CREATE ORDERS
#- ADD A PER SERVICE → PACKAGE  → 5000 (500 only since item rate is below 5000)

  it "OSS - Individual Patient 8 - Create patient" do
    slmc.login("sel_oss9", @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin8 = (slmc.oss_outpatient_registration(@patient8)).gsub(" ","")
  end

  it "OSS - Individual Patient 8 - Go to Outpatient Order" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin8)
    slmc.click_outpatient_order.should be_true
    slmc.oss_patient_info(:senior => true) if @promo_discount8 == 0.2
  end

  it "OSS - Individual Patient 8 - Add Guarantor (Individual)" do
    slmc.oss_add_guarantor(:guarantor_type => "INDIVIDUAL", :acct_class => "INDIVIDUAL", :guarantor_add => true).should be_true
  end

  it "OSS - Individual Patient 8 - Order items" do
    @@orders = @ancillary#.merge(@drugs)
    n = 0
    @@orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
      n += 1
    end
  end

  it "OSS - Individual Patient 8 - Add Package Discount 5000 (Per Service) should be able to add discount" do
    @package_discount = 500
    slmc.oss_add_discount(:discount_type => "Package Discount", :type => "fixed", :scope => "service", :amount => @package_discount.to_s).should be_true
  end

#  it "OSS - Individual Patient 8 - Submit Order with payment" do
#    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
#    slmc.oss_add_payment(:amount => amount, :type => "CASH")
#    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
## SOCIAL SERVICE #
#
##-LOG-IN AS OSS USER
##- CREATE PATIENT
##- WITHOUT PHILHEALTH
##- CHOOSE SOCIAL SERVICE AS ACCOUNT CLASS
##- GUARANTOR SOCIAL SERVICE
##- CREATE ORDERS
##- ADD A PER SERVICE → COURTESY DISCOUNT → 1000 (500 only since item rate is below 1000)
#
#  it "OSS - Social Service Patient 9 - Create patient" do
#    slmc.login("sel_oss9", @password).should be_true
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => "test")
#    slmc.click_outpatient_registration.should be_true
#    @@oss_pin9 = (slmc.oss_outpatient_registration(@patient9)).gsub(" ","")
#  end
#
#  it "OSS - Social Service Patient 9 - Go to Outpatient Order" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@oss_pin9)
#    slmc.click_outpatient_order.should be_true
#    slmc.oss_patient_info(:senior => true) if @promo_discount9 == 0.2
#  end
#
#  it "OSS - Social Service Patient 9 - Add Guarantor (Social Service)" do
#    slmc.oss_add_guarantor(:acct_class => "SOCIAL SERVICE", :guarantor_type => "SOCIAL SERVICE", :esc_no => @esc_no, :guarantor_add => true)
#    slmc.get_css_count("css=#guarantorListTableBody>tr").should == 1
#  end
#
#  it "OSS - Social Service Patient 9 - Order items" do
#    @@orders = @ancillary#.merge(@drugs)
#    n = 0
#    @@orders.each do |item, q|
#      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
#      n += 1
#    end
#  end
#
#  it "OSS - Social Service Patient 9 - Add Courtesy Discount 500 (Per Service) should be able to add discount" do
#    @courtesy_discount = 500
#    slmc.oss_add_discount(:discount_type => "Courtesy Discount", :type => "fixed", :scope => "service", :amount => @courtesy_discount.to_s).should be_true
#  end
#
#  it "OSS - Social Service Patient 9 - Submit Order with payment" do
#    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
#    slmc.oss_add_payment(:amount => amount, :type => "CASH")
#    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
##-LOG-IN AS OSS USER
##- CREATE PATIENT
##- WITH PHILHEALTH
##- CHOOSE SOCIAL SERVICE AS ACCOUNT CLASS
##- GUARANTOR SOCIAL SERVICE
##- CREATE ORDERS
##- ADD A PER SERVICE → COURTESY DISCOUNT → 1000
#
#  it "OSS - Social Service Patient 10 - Create patient" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => "test")
#    slmc.click_outpatient_registration.should be_true
#    @@oss_pin10 = (slmc.oss_outpatient_registration(@patient10)).gsub(" ","")
#  end
#
#  it "OSS - Social Service Patient 10 - Go to Outpatient Order" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@oss_pin10)
#    slmc.click_outpatient_order.should be_true
#    slmc.oss_patient_info(:philhealth => true, :senior => true) if @promo_discount10 == 0.2
#    slmc.oss_patient_info(:philhealth => true) if @promo_discount10 == 0.16
#  end
#
#  it "OSS - Social Service Patient 10 - Add Guarantor (Social Service)" do
#    slmc.oss_add_guarantor(:acct_class => "SOCIAL SERVICE", :guarantor_type => "SOCIAL SERVICE", :esc_no => @esc_no, :guarantor_add => true)
#    slmc.get_css_count("css=#guarantorListTableBody>tr").should == 1
#  end
#
#  it "OSS - Social Service Patient 10 - Order items" do
#    @@orders = @ancillary#.merge(@drugs)
#    n = 0
#    @@orders.each do |item, q|
#      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
#      n += 1
#    end
#  end
#
#  it "OSS - Social Service Patient 10 - Compute PhilHealth" do
#    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060",  :compute => true)
#  end
#
#  it "OSS - Social Service Patient 10 - Add Courtesy Discount 500 (Per Service) should be able to add discount" do
#    @courtesy_discount = 500
#    slmc.oss_add_discount(:discount_type => "Courtesy Discount", :type => "fixed", :scope => "service", :amount => @courtesy_discount.to_s).should be_true
#  end
#
#  it "OSS - Social Service Patient 10 - Submit Order without payment" do
#    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
#    slmc.oss_add_payment(:amount => amount, :type => "CASH")
#    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
## COMPANY #
#
##-LOG-IN AS OSS USER
##- CREATE PATIENT
##- WITHOUT PHILHEALTH
##- CHOOSE COMPANY AS ACCOUNT CLASS → 50% COVERAGE
##- CREATE ORDERS
##- ADD A PER SERVICE → COURTESY DISCOUNT → 1000
#
#  it "OSS - Company Patient 11 - Create patient" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => "test")
#    slmc.click_outpatient_registration.should be_true
#    @@oss_pin11 = (slmc.oss_outpatient_registration(@patient11)).gsub(" ","")
#  end
#
#  it "OSS - Company Patient 11 - Go to Outpatient Order" do
#    slmc.go_to_das_oss
#    slmc.patient_pin_search(:pin => @@oss_pin10)
#    slmc.click_outpatient_order.should be_true
#    slmc.oss_patient_info(:senior => true) if @promo_discount11 == 0.2
#  end
#
#  it "OSS - Company Patient 11 - Add Guarantor (Company)" do
#    slmc.oss_add_guarantor(:acct_class => "COMPANY", :guarantor_type => "COMPANY", :guarantor_code => "ABSC001", :coverage_choice => "percent", :coverage_amount => "50",:guarantor_add => true).should be_true
#    slmc.get_css_count("css=#guarantorListTableBody>tr").should == 1
#  end
#
#  it "OSS - Company Patient 11 - Order items" do
#    @@orders = @ancillary#.merge(@drugs)
#    n = 0
#    @@orders.each do |item, q|
#      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
#      n += 1
#    end
#  end
#
#  it "OSS - Company Patient 11 - Add Courtesy Discount 500 (Per Service) should be able to add discount" do
#    @courtesy_discount = 500
#    slmc.oss_add_discount(:discount_type => "Courtesy Discount", :type => "fixed", :scope => "service", :amount => @courtesy_discount.to_s).should be_true
#  end
#
#  it "OSS - Company Patient 11 - Submit Order with payment" do
#    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
#    slmc.oss_add_payment(:amount => amount, :type => "CASH")
#    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
#  end
#
end