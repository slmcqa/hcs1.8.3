require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Wellness - Automatic Discount Module Test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @wellness_patient1 = Admission.generate_data
    @wellness_patient2 = Admission.generate_data
    @password = "123qweuser"
    @employee = "1108010707" #SELENIUM_SELECTIVE_E,0824012
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates patient for pba transactions - Male, Under 60 years old" do
    slmc.login("sel_wellness1", @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "test")
    @@wellness_pin1 = slmc.create_new_patient(@wellness_patient1.merge!(:gender => 'M', :birth_day => '07/01/2010'))
    @@wellness_pin1.should be_true
  end

  it "Creates patient for pba transactions - Female, 60 years old and above" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "test")
    @@wellness_pin2 = slmc.create_new_patient(@wellness_patient2.merge!(:gender => 'F', :birth_day => '01/01/1950'))
    @@wellness_pin2.should be_true
  end

  it "Verifies error messages when required items are not satisfied" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.click_outpatient_package_management.should be_true
    slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A MALE").should == "Doctor is a required field."
  end

  it "Adds a wellness package for patient" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.click_outpatient_package_management.should be_true
    slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A MALE", :doctor => "6930").should be_true
  end

  it "Deletes a patient's package" do
    slmc.delete_wellness_package.should be_true
  end

  it "Edits a patient's package" do
    slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A MALE", :doctor => "6930").should be_true
    slmc.validate_wellness_package
    slmc.edit_wellness_package(:package => "CANCER PACKAGE - ADVANCE B MALE", :doctor => "6930", :replace => true).should be_true#it hangs
  end

  it "Should not allow PF higher than inclusive of package" do
    slmc.wellness_allocate_doctor_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => 18000).should == "Only 16000 is available."
    slmc.additional_order_pf(:add => true, :add_doctor_type => "REFERRING", :add_doctor => "6726")
    slmc.additional_order_pf(:add_pf => true, :pin => "6930", :pf_type => "DIRECT", :pf_amount => "7000")
    slmc.additional_order_pf(:add_pf => true, :pin => "6726", :pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => "9000")
    slmc.additional_order_pf(:edit_pf_type => true, :pf_type => "DIRECT", :new_pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => "9000")
    slmc.click("//input[@type='submit' and @value='Submit']", :wait_for => :page)
    slmc.get_text("errorMessages").should == "PF Inclusive of Package has exceeded. Please edit 'PF Inclusive of Package'."
    # Remove PF Doctor
    slmc.additional_order_pf(:delete => true, :delete_type => "REFERRING")
    slmc.additional_order_pf(:delete_pf_type => true, :pf_type => "PF INCLUSIVE OF PACKAGE")
    slmc.additional_order_pf(:add_pf => true, :pin => "6930", :pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => "15000")
    slmc.click("//input[@type='submit' and @value='Submit']", :wait_for => :page)
    slmc.get_text("errorMessages").should == "Please distribute the amount of 1,000.00 using 'PF Inclusive of Package'."
  end

  it "LOCAL patient, under 60 years old - Computes PACKAGE Discount" do
    slmc.login("sel_wellness1", @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_allocate_doctor_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => 16000).should be_true
    slmc.wellness_update_guarantor(:guarantor => "INDIVIDUAL").should be_true
    slmc.wellness_payment(:view => true).should be_true

    @total_gross = slmc.get_total_gross_amount.to_f
    @promo_discount = slmc.compute_discounts(:unit_price => @total_gross, :promo => true)
    @net_amount = slmc.get_total_net_amount.to_f

    @package_discount = ((@total_gross - (@promo_discount + @net_amount))* 100).round.to_f / 100

    ((slmc.truncate_to((slmc.get_package_discount.to_f - @package_discount),2).to_f).abs).should <= 0.02
  end

  it "LOCAL patient, under 60 years old - Computes PROMO Discount(16%)" do

    @total_gross = slmc.get_total_gross_amount.to_f
    @promo_discount = slmc.compute_discounts(:unit_price => @total_gross, :promo => true)
    @package_discount = slmc.get_package_discount.to_f

    @net_amount = ((@total_gross - (@promo_discount + @package_discount)) * 100).round.to_f / 100

    ((slmc.truncate_to((slmc.get_total_promo_amount.to_f - @promo_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_total_net_amount.to_f - @net_amount),2).to_f).abs).should <= 0.02
  end

  it "LOCAL patient, under 60 years old - Clicking Senior checkbox should NOT compute for SENIOR Discount(20%)" do
    slmc.oss_patient_info(:senior => true)

    @total_gross = slmc.get_total_gross_amount.to_f
    @promo_discount = slmc.compute_discounts(:unit_price => @total_gross, :promo => true)
    @package_discount = slmc.get_package_discount.to_f

    @net_amount = ((@total_gross - (@promo_discount + @package_discount)) * 100).round.to_f / 100

    ((slmc.truncate_to((slmc.get_total_promo_amount.to_f - @promo_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_total_net_amount.to_f - @net_amount),2).to_f).abs).should <= 0.02
  end

  it "LOCAL patient, 60 years old and above - Computes SENIOR Discount(20%)" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin2)
    slmc.click_outpatient_package_management.should be_true
    slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A FEMALE", :doctor => "6930").should be_true
    slmc.validate_wellness_package
    slmc.wellness_allocate_doctor_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => 16600).should be_true
    slmc.wellness_update_guarantor(:guarantor => "INDIVIDUAL").should be_true
    slmc.wellness_payment(:view => true).should be_true

    @total_gross = slmc.get_total_gross_amount.to_f
    @promo_discount = slmc.compute_discounts(:unit_price => @total_gross, :senior => true)
    @package_discount = slmc.get_package_discount.to_f

    @net_amount = ((@total_gross - (@promo_discount + @package_discount)) * 100).round.to_f / 100

    ((slmc.truncate_to((slmc.get_total_promo_amount.to_f - @promo_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_total_net_amount.to_f - @net_amount),2).to_f).abs).should <= 0.02
  end

  it "LOCAL patient, DISABLED, 60 years old and above - Computes SENIOR Discount(20%)" do
    slmc.oss_patient_info(:pwd => true)

    @total_gross = slmc.get_total_gross_amount.to_f
    @promo_discount = slmc.compute_discounts(:unit_price => @total_gross, :senior => true)
    @package_discount = slmc.get_package_discount.to_f

    @net_amount = ((@total_gross - (@promo_discount + @package_discount)) * 100).round.to_f / 100

    sleep 5
    ((slmc.truncate_to((slmc.get_total_promo_amount.to_f - @promo_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_total_net_amount.to_f - @net_amount),2).to_f).abs).should <= 0.02
  end

  it "LOCAL patient, DISABLED under 60 years old - Computes PWD Discount(20%)" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_payment(:view => true).should be_true
    slmc.oss_patient_info(:pwd => true)

    @total_gross = slmc.get_total_gross_amount.to_f
    @promo_discount = slmc.compute_discounts(:unit_price => @total_gross, :disabled => true)
    @package_discount = slmc.get_package_discount.to_f

    @net_amount = ((@total_gross - (@promo_discount + @package_discount)) * 100).round.to_f / 100

    slmc.get_total_promo_amount.to_f.should == slmc.truncate_to(@promo_discount,2)
    slmc.get_total_net_amount.to_f.should == @net_amount

    ((slmc.truncate_to((slmc.get_total_promo_amount.to_f - @promo_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_total_net_amount.to_f - @net_amount),2).to_f).abs).should <= 0.02
  end

   it "Test if input field for Search accepts either description or item code" do
    slmc.login("sel_wellness1", @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_payment(:view => true).should be_true
    slmc.oss_order(:item_code => "040004334", :order_add => true).should be_true
    slmc.oss_order(:item_code => "CAPSICUM SACHET 10's", :order_add => true).should be_true
    slmc.oss_order(:item_code => "040004337", :order_add => true).should be_true
    slmc.oss_order(:item_code => "VENOTUBE TWINSITE", :order_add => true).should be_true
  end

  it "Ancillary items outside the package computes for Promo discount(16%) and Contractual Discount(10%)" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_payment(:view => true).should be_true
    @package_discount = slmc.get_package_discount.to_f
    slmc.oss_order(:item_code => "HEMATOCRIT", :doctor => "6930", :order_add => true).should be_true

    sleep 5
    order_list = slmc.oss_verify_order_list
    (order_list.include? "HEMATOCRIT").should be_true
    count = order_list.index("HEMATOCRIT")

    @item_amount = slmc.get_item_amount(count)
    @item_discount = ((@item_amount * (16.0/100.0)) * 100).round.to_f / 100
    @item_net = ((@item_amount - @item_discount) * 100).round.to_f / 100
    @item_package_discount = ((@item_net * (10.0/100.0)) * 100).round.to_f / 100
    @@total_package_discount = ((@package_discount + @item_package_discount) * 100).round.to_f / 100

    ((slmc.truncate_to((slmc.get_item_promo_discount(count).to_f - @item_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_item_net_amount(count).to_f - @item_net),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_package_discount.to_f - @@total_package_discount),2).to_f).abs).should <= 0.02
  end

  it "Pharmacy items outside the package should compute for Promo discount(16%) but NOT Contractual Discount(10%)" do
    slmc.oss_order(:item_code => "BABYHALER", :order_add => true).should be_true

    sleep 5
    order_list = slmc.oss_verify_order_list
    (order_list.include? "BABYHALER").should be_true
    count = order_list.index("BABYHALER")

    @item_amount = slmc.get_item_amount(count)
    @item_discount = ((@item_amount * (16.0/100.0)) * 100).round.to_f / 100
    @item_net = ((@item_amount - @item_discount) * 100).round.to_f / 100

    ((slmc.truncate_to((slmc.get_item_promo_discount(count).to_f - @item_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_item_net_amount(count).to_f - @item_net),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_package_discount.to_f - @@total_package_discount),2).to_f).abs).should <= 0.02
  end


  it "Supply items outside the package should NOT compute for Promo discount(16%) but NOT Contractual Discount(10%)" do
    slmc.oss_order(:item_code => "BABY WET WIPES", :order_add => true).should be_true

    sleep 5
    order_list = slmc.oss_verify_order_list
    (order_list.include? "BABY WET WIPES").should be_true
    count = order_list.index("BABY WET WIPES")

    @item_amount = slmc.get_item_amount(count)
    @item_discount = ((@item_amount * (16.0/100.0)) * 100).round.to_f / 100
    @item_net = ((@item_amount - @item_discount) * 100).round.to_f / 100

    ((slmc.truncate_to((slmc.get_item_promo_discount(count).to_f - @item_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_item_net_amount(count).to_f - @item_net),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_package_discount.to_f - @@total_package_discount),2).to_f).abs).should <= 0.02
  end

  it "LOCAL patient, under 60 years old - Adding MRP items should not compute PROMO Discount(16%)" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_payment(:view => true).should be_true
    slmc.oss_order(:item_code => "DOXORUBICIN 10MG VIAL (BIOMEDIS)", :order_add => true).should be_true

    order_list = slmc.oss_verify_order_list
    (order_list.include? "DOXORUBICIN 10MG VIAL (BIOMEDIS)").should be_true
    count = order_list.index("DOXORUBICIN 10MG VIAL (BIOMEDIS)")

    @item_amount = slmc.get_item_amount(count)
    @item_discount = slmc.get_item_promo_discount(count)
    @item_net = ((@item_amount - @item_discount) * 100).round.to_f / 100
    #@item_package_discount = ((@item_net * (10.0/100.0)) * 100).round.to_f / 100
    #@total_package_discount = ((@package_discount + @item_package_discount) * 100).round.to_f / 100

    #slmc.get_package_discount.to_f.should == @total_package_discount

    ((slmc.truncate_to((slmc.get_item_promo_discount(count).to_f - 0.0),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_item_net_amount(count).to_f - @item_net),2).to_f).abs).should <= 0.02
  end

  it "FOREIGN patient, under 60 years old - Adding MRP items should not compute PROMO Discount(16%)" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.update_patient(:citizenship => "RUSSIAN", :wellness => true)
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_payment(:view => true).should be_true
    slmc.oss_order(:item_code => "DOXORUBICIN 10MG VIAL (BIOMEDIS)", :order_add => true).should be_true

    order_list = slmc.oss_verify_order_list
    (order_list.include? "DOXORUBICIN 10MG VIAL (BIOMEDIS)").should be_true
    count = order_list.index("DOXORUBICIN 10MG VIAL (BIOMEDIS)")

    @item_amount = slmc.get_item_amount(count)
    @item_discount = slmc.get_item_promo_discount(count)
    @item_net = ((@item_amount - @item_discount) * 100).round.to_f / 100

    ((slmc.truncate_to((slmc.get_item_promo_discount(count).to_f - 0.0),2).to_f).abs).should <= 0.00
    ((slmc.truncate_to((slmc.get_item_net_amount(count).to_f - @item_net),2).to_f).abs).should <= 0.00
  end

  it "FOREIGN patient, under 60 years old - Computes PROMO Discount(16%)" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_payment(:view => true).should be_true
    @total_gross = slmc.get_total_gross_amount.to_f
    @promo_discount = slmc.compute_discounts(:unit_price => @total_gross, :promo => true)
    @package_discount = slmc.get_package_discount.to_f

    @net_amount = ((@total_gross - (@promo_discount + @package_discount)) * 100).round.to_f / 100

    ((slmc.truncate_to((slmc.get_total_promo_amount.to_f - @promo_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_total_net_amount.to_f - @net_amount),2).to_f).abs).should <= 0.02
  end

  it "FOREIGN patient, 60 years old and above - Computes PROMO Discount(16%)" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin2)
    slmc.update_patient(:citizenship => "ENGLISH", :wellness => true)
    slmc.patient_pin_search(:pin => @@wellness_pin2)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_payment(:view => true).should be_true

    @total_gross = slmc.get_total_gross_amount.to_f
    @promo_discount = slmc.compute_discounts(:unit_price => @total_gross, :promo => true)
    @package_discount = slmc.get_package_discount.to_f

    @net_amount = ((@total_gross - (@promo_discount + @package_discount)) * 100).round.to_f / 100

    ((slmc.truncate_to((slmc.get_total_promo_amount.to_f - @promo_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_total_net_amount.to_f - @net_amount),2).to_f).abs).should <= 0.02
  end

  it "FOREIGN patient, 60 years old and above - Successfully proceed with CASH payment" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin2)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_payment(:cash => true).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    slmc.wellness_print_soa(:package_gross_soa => true).should be_true
  end

  it "Bug #21909 OP Package Mgmt_SOA/OR Reprint" do
    slmc.go_to_wellness_package_ordering_page
    slmc.click_soa_or_reprint.should be_true
    slmc.or_soa_search(:pin => @@wellness_pin2)
    slmc.click_search_or.should be_true
    slmc.get_xpath_count("//html/body/div/div[2]/div[2]/table/tbody/tr").should == "2"
    slmc.is_text_present("Reprint OR").should be_true
  end

  it "Should be able to Reprint OR" do
    slmc.go_to_wellness_package_ordering_page
    slmc.click_soa_or_reprint.should be_true
    slmc.or_soa_search(:pin => @@wellness_pin2)
    slmc.click_search_or.should be_true
    slmc.click_reprint_or.should be_true
  end

  it "Should be able to Reprint SOA" do
    slmc.or_soa_search(:pin => @@wellness_pin2)
    slmc.click_search_soa.should be_true
    slmc.click_reprint_soa(:package_gross_soa => true).should be_true
  end

  it "Switch Package in Wellness" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.click_outpatient_package_management.should be_true
    slmc.switch_package(:wellness => true, :to_package => "CANCER PACKAGE - BASIC MALE", :doctor => "ABAD").should be_true
    slmc.wellness_allocate_doctor_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => 3500).should be_true
  end

  it "LOCAL patient, under 60 years old - Successfully proceed with CASH payment after COMPANY guarantor of 50%" do
    slmc.login("sel_wellness1", @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.update_patient(:citizenship => "FILIPINO", :wellness => true)
    slmc.patient_pin_search(:pin => @@wellness_pin1)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_payment(:cash => true).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    slmc.wellness_print_soa.should be_true
  end

  it "Bug #21316 - Employee patient(HEE) with package order should NOT compute for Account Class discounts" do
    slmc.login("sel_wellness1", @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @employee)
    slmc.click_outpatient_package_management.should be_true
    if slmc.is_element_present("payment").should be_true
      if slmc.is_editable("payment").should be_true
        slmc.wellness_payment(:view => true).should be_true
        slmc.get_class_discount_value.should == 0.00
      end
    else
      slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A FEMALE", :doctor => "6930").should be_true
      slmc.validate_wellness_package
      slmc.wellness_allocate_doctor_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => 16600)
      slmc.wellness_update_guarantor(:account_class => "EMPLOYEE", :guarantor => "EMPLOYEE", :guarantor_code => "0824012")
      slmc.wellness_payment(:view => true).should be_true
      slmc.get_class_discount_value.should == 0.00
    end
  end

  it "Employee patient(HEE) with package order computes Account Class discounts for added orders outside the package" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @employee)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_payment(:view => true).should be_true

    @normal_package_discount = slmc.get_package_discount.to_f
    slmc.oss_order(:item_code => "HEMATOCRIT", :doctor => "6930", :order_add => true).should be_true

    sleep 5
    order_list = slmc.oss_verify_order_list
    (order_list.include? "HEMATOCRIT").should be_true
    count = order_list.index("HEMATOCRIT")

    @item_amount = slmc.get_item_amount(count)
    @item_discount = ((@item_amount * (16.0/100.0)) * 100).round.to_f / 100
    @item_class_discount = ((@item_amount - @item_discount) * 100).round.to_f / 100
    @item_net = ((@item_amount - (@item_discount + @item_class_discount)) * 100).round.to_f / 100
    @package_discount = @normal_package_discount + (@item_class_discount * 0.10)

    ((slmc.truncate_to((slmc.get_item_promo_discount(count).to_f - @item_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_item_net_amount(count).to_f - @item_net),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_item_class_discount(count).to_f - @item_class_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_package_discount.to_f - @package_discount),2).to_f).abs).should <= 0.02
  end

  it "Employee patient(HEE) with package order should be able to add an item that is existing in the package" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @employee)
    slmc.click_outpatient_package_management.should be_true
    slmc.wellness_payment(:view => true).should be_true

    @normal_package_discount = slmc.get_package_discount.to_f
    slmc.oss_order(:item_code => "PAP'S SMEARS", :doctor => "6930", :order_add => true).should be_true
    slmc.validate_existing_order(:new_line => true).should be_true

    sleep 5
    order_list = slmc.oss_verify_order_list
    (order_list.include? "PAP'S SMEARS").should be_true
    count = order_list.rindex("PAP'S SMEARS")

    @item_amount = slmc.get_item_amount(count)
    @item_discount = ((@item_amount * (16.0/100.0)) * 100).round.to_f / 100
    @item_class_discount = ((@item_amount - @item_discount) * 100).round.to_f / 100
    @item_net = ((@item_amount - (@item_discount + @item_class_discount)) * 100).round.to_f / 100
    @package_discount = @normal_package_discount + (@item_class_discount * 0.10)

    ((slmc.truncate_to((slmc.get_item_promo_discount(count).to_f - @item_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_item_net_amount(count).to_f - @item_net),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_item_class_discount(count).to_f - @item_class_discount),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((slmc.get_package_discount.to_f - @package_discount),2).to_f).abs).should <= 0.02
  end

end
