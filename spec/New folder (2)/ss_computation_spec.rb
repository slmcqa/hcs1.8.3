require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Social Service - Computation" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @er_user = "sel_er6"
    @ss_user = "sel_ss2"
    @or_user = "or28"
    @pba_user = "pba28"
    @dr_user = "sel_dr3"
    @inpatient_user = "gu_spec_user9"
    @oss_user = "sel_oss8"
    @pharmacy_user = "sel_pharmacy4"
    @supply_user = "supplies1"
    @password = "123qweuser"
    @patient   = Admission.generate_data
    @patient3 = Admission.generate_data
    @promo_discount   = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient[:age])
    @promo_discount1 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient3[:age])
    @promo_discount_non_senior = 0.16
    @promo_discount_senior = 0.20
    @items =  {"010002376" => {:desc => "TRANSVAGINAL ULTRASOUND",:code => "0135"}}
    @patient_share = 1000.0
    @fund_share = 1000.0
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it"Outpatient ER  - With Patient Type Classification  and No recommendation to MSSD" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_page
    slmc.er_patient_search(:pin => "test")
    @@pin = slmc.ss_create_outpatient_er(@patient.merge(:gender => 'F'))
    @@er_pin = @@pin.gsub(' ','')
    slmc.go_to_er_landing_page
    slmc.er_patient_search(:pin => @@er_pin)
    slmc.click_register_patient
    slmc.admit_er_patient(:account_class => "SOCIAL SERVICE", :esc_no => "287", :dept_code => "OBSTETRICS AND GYNECOLOGY")
  end

  it"1st scenario Outpatient ER - Order Items" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    sleep 2
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"1st scenario Outpatient ER - Clinically discharge patient" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin)
    @@visit_no = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"1st scenario Outpatient ER - ER Billing Discharge" do
    slmc.go_to_er_billing_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin)
    slmc.go_to_pba_action_page(:visit_no => @@visit_no, :page => "Discharge Patient" )
    slmc.select_discharge_patient_type(:type => "STANDARD")
    slmc.click_new_guarantor
#    slmc.select "guarantorType", "HMO"
    slmc.pba_update_guarantor(:guarantor_type => "SOCIAL SERVICE")
    sleep 10
    slmc.click_submit_changes.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end

  it"1st scenario Outpatient ER - Check Discounts applied" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f * @promo_discount
    @discounts_promo = @@summary[:hospital_bill].to_f - @original_discount_promo
    @original_discount_classification = (@discounts_promo * 50).round.to_f / 100
    @discount_classification =  @discounts_promo - @original_discount_classification
    @total_discount = @original_discount_promo + @original_discount_classification

    @@summary[:discounts].to_f.should == ("%0.2f" %(@total_discount)).to_f
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@discount_classification)).to_f

    (slmc.ss_get_discount_amount(:promo => true, :visit_no => @@visit_no)).should == @original_discount_promo
    (slmc.ss_get_discount_amount(:classification => true, :visit_no => @@visit_no)).should == @original_discount_classification
  end

  it"1st scenario Outpatient ER - Disharge patient" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end

  it"Outpatient ER  - With Patient Type Classification and with recommendation to MSSD" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_page
    slmc.er_patient_search(:pin => "test")
    @@er_pin1 = slmc.ss_create_outpatient_er(Admission.generate_data(:not_senior => true).merge(:gender => 'F')).gsub(' ','')
    slmc.go_to_er_landing_page
    slmc.er_patient_search(:pin => @@er_pin1)
    slmc.click_register_patient
    slmc.admit_er_patient(:account_class => "SOCIAL SERVICE", :esc_no => "287", :dept_code => "OBSTETRICS AND GYNECOLOGY")
  end

  it"2nd scenario Outpatient ER - Order Items" do
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin1)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin1)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    sleep 2
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"2nd scenario Outpatient ER - Go to Social Service Page" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@er_pin1)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    @@amount = (slmc.get_text"//form[@id='recommendationForm']/div[4]/div/table/tbody/tr/td[1]").gsub(',','')
    sleep 2
    slmc.ss_benefactor(:amount => @@amount, :add => true)
    sleep 2
    if slmc.is_text_present"Please select copayor."
      slmc.click"searchBenefactorButton"
      slmc.click'//input[@type="button" and @onclick="BusinessPartner.search();" and @value="Search"]'
      slmc.click'//input[@type="button" and @onclick="AddCoPayorForm.addBenefactorToList();" and @value="Add Benefactor"]'
    end
    sleep 8
    slmc.click'//input[@type="submit" and @value="Submit"]', :wait_for => :page
  end

  it"2nd scenario Outpatient ER - Clinically discharge patient" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_landing_page
    slmc.patient_pin_search(:pin => @@er_pin1)
    @@visit_no1 = slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin1, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"2nd scenario Outpatient ER - Go to Payment" do
    slmc.go_to_er_billing_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin1)
    slmc.go_to_pba_action_page(:visit_no => @@visit_no1, :page => "Payment" )
  end

  it"2nd scenario Outpatient ER - Check Discounts applied" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f * @promo_discount_non_senior

    @@summary[:hospital_bill].to_f.should ==  (@original_discount_promo + @@amount.to_f)
    @@summary[:social_service_coverage].to_f.should == @@amount.to_f

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:balance_due].should == "0.00"

    (slmc.ss_get_discount_amount(:promo => true, :visit_no => @@visit_no1)).should == @original_discount_promo
    (slmc.ss_get_discount_amount(:ss_discount => true, :visit_no => @@visit_no1)).should == @@amount.to_f
  end

  it"2nd scenario Outpatient ER - ER Billing Discharge" do
    slmc.spu_submit_bills
  end

  it"Outpatient OR   - With Patient Type Classification and with recommendation to MSSD" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration
    @@or_pin = slmc.outpatient_registration(Admission.generate_data(:not_senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.click_register_patient
    slmc.admit_er_patient(:org_code => "0164", :account_class => "SOCIAL SERVICE", :esc_no => "287", :dept_code => "OBSTETRICS AND GYNECOLOGY")
  end

  it"Outpatient OR - Order Items" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    sleep 2
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Outpatient OR - Clinically discharge patient" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Discharge Instructions\302\240", @@or_pin)
    slmc.add_final_diagnosis(:save => true)
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Doctor and PF Amount", @@or_pin)
    @@visit_no = slmc.get_text("banner.visitNo").gsub(' ', '')
    slmc.clinical_discharge(:no_pending_order => true, :pf_amount => "1000").should be_true
  end

  it"Outpatient OR - Go to Social Service Page" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share)
  end

  it"Outpatient OR - Billing Discharge" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end

  it"Outpatient OR - Check Discounts applied" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f*@promo_discount_non_senior
    @ss_discount = @patient_share + @fund_share
    @total_ss_discount = @@summary[:hospital_bill].to_f - @ss_discount  - @original_discount_promo

    @@summary[:discounts].to_f.should == ("%0.2f" %(@total_ss_discount + @original_discount_promo)).to_f
    @@summary[:social_service_coverage].to_f.should == ("%0.2f" %(@fund_share)).to_f
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@patient_share)).to_f

    (slmc.ss_get_discount_amount(:promo => true, :visit_no => @@visit_no)).should == @original_discount_promo
    (slmc.ss_get_discount_amount(:classification => true, :visit_no => @@visit_no)).should == @total_ss_discount
  end

  it"Verify discount number" do
    @@discount_number = (slmc.ss_get_discount_amount(:social_service_discount_no => true, :visit_no => @@visit_no))
    @@discount_number.length.should == 15
  end

  it"Outpatient OR - Disharge patient" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end

  it"Outpatient DR   - With Patient Type Classification and with recommendation to MSSD" do
    slmc.login(@dr_user,@password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration
    sleep 10
    @@pin = slmc.outpatient_registration(@patient3.merge(:gender => 'F')).should be_true
    @@dr_pin = @@pin.gsub(' ','')
    slmc.go_to_outpatient_nursing_page
    sleep 20
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.click_register_patient
    slmc.admit_er_patient(:org_code => "0170", :account_class => "SOCIAL SERVICE", :esc_no => "287", :dept_code => "OBSTETRICS AND GYNECOLOGY")
  end

  it"Outpatient DR - Order Items" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@dr_pin)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    sleep 2
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Outpatient DR - Go to Social Service Page" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    @@amount = 3000.0
    slmc.add_recommendation_entry(:amount => @@amount)
  end

  it"Outpatient DR - Clinically discharge patient" do
    slmc.login(@dr_user,@password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Discharge Instructions\302\240", @@dr_pin)
    slmc.add_final_diagnosis(:save => true)
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin).should be_true
    slmc.go_to_su_page_for_a_given_pin("Doctor and PF Amount", @@dr_pin)
    @@visit_no = slmc.get_text("banner.visitNo").gsub(' ', '')
    slmc.clinical_discharge(:no_pending_order => true, :pf_amount => "1000").should be_true
  end

  it"Outpatient DR - Go to Payment" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
  end

  it"Outpatient DR - Check Discounts applied" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f * @promo_discount1
    @total_hospital_bills = @@summary[:hospital_bill].to_f - @original_discount_promo  - @@amount

    @@summary[:discounts].to_f.should == ("%0.2f" %( @original_discount_promo)).to_f
    @@summary[:social_service_coverage].to_f.should == ("%0.2f" %(@@amount)).to_f
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f

     (slmc.ss_get_discount_amount(:promo => true, :visit_no => @@visit_no)).should == @original_discount_promo
    (slmc.ss_get_discount_amount(:ss_discount => true, :visit_no => @@visit_no)).should == @@amount
  end

  it"Outpatient DR - Settle Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    slmc.spu_submit_bills
    sleep 5
    if  slmc.is_text_present"Payment Data Entry"
        slmc.click"cashPaymentMode1"
        sleep 2
        slmc.proceed_with_payment
    end
    slmc.go_to_patient_billing_accounting_page
  end

  it"Outpatient DR - Disharge patient" do
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS")
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@dr_pin)
    (slmc.get_text"css=#results>tbody>tr.even>td").gsub(' ','').should == @@dr_pin
  end

  it"Inpatient With Direct Admission" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@inpatient_pin = slmc.create_new_patient(Admission.generate_data(:senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
    sleep 20
    slmc.admission_search(:pin => @@inpatient_pin)
    slmc.create_new_admission( :account_class => "SOCIAL SERVICE", :esc_no => "287", :dept_code => "OBSTETRICS AND GYNECOLOGY",
      :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end

  it"Inpatient - Order Items" do
    slmc.nursing_gu_search(:pin => @@inpatient_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@inpatient_pin)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    sleep 2
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Inpatient - Go to Social Service Page" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@inpatient_pin)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    @@amount = 3000.0
    slmc.add_recommendation_entry(:amount => @@amount)
  end

  it"Inpatient - Clinically discharge patient" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.nursing_gu_search(:pin=> @@inpatient_pin)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@inpatient_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"Inpatient - Go to Payment" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
  end

  it"Inpatient - Check Discounts applied" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f * @promo_discount_senior
    @total_hospital_bills = @@summary[:hospital_bill].to_f - @original_discount_promo  - @@amount

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:social_service_coverage].to_f.should == @@amount
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f

    (slmc.ss_get_discount_amount(:promo => true, :visit_no => @@visit_no)).should == @original_discount_promo
    (slmc.ss_get_discount_amount(:ss_discount => true, :visit_no => @@visit_no)).should == @@amount
  end

  it"Inpatient - Settle Payment" do
    slmc.pba_full_payment
    slmc.go_to_patient_billing_accounting_page
  end

  it"Inpatient - Disharge patient" do
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS")
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@inpatient_pin)
    (slmc.get_text"css=#results>tbody>tr.even>td").gsub(' ','').should == @@inpatient_pin
  end

  it"ER Turned Inpatient" do
    slmc.login(@er_user, @password).should be_true
    slmc.go_to_er_page
    slmc.er_patient_search(:pin => "test")
    @@er_pin = slmc.ss_create_outpatient_er(Admission.generate_data(:senior => true).merge(:gender => 'F')).gsub(' ','')
    slmc.go_to_er_landing_page
    slmc.er_patient_search(:pin => @@er_pin)
    slmc.click_register_patient
    slmc.spu_or_register_patient(:turn_inpatient => true, :acct_class => "SOCIAL SERVICE", :esc_no => "287", :dept_code => "OBSTETRICS AND GYNECOLOGY",
      :doctor => "6726", :preview => true, :save => true).should be_true
  end

  it"ER Turned Inpatient - Go to Inpatient Admission" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => @@er_pin)
    slmc.er_outpatient_to_inpatient(:pin => @@er_pin, :room_label => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :social_service => true)
  end

  it"ER Turned Inpatient - Order Items" do
    slmc.nursing_gu_search(:pin => @@er_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@er_pin)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    sleep 2
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end

  it"ER Turned Inpatient - Go to Social Service Page" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@er_pin)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share)
  end

  it"ER Turned Inpatient - Clinically discharge patient" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.nursing_gu_search(:pin=> @@er_pin)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@er_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"ER Turned Inpatient - Go to Payment" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
  end

  it"ER Turned Inpatient - Check Discounts applied" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f * @promo_discount_senior
    @total_hospital_bills = @@summary[:hospital_bill].to_f - @fund_share  - @original_discount_promo

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:social_service_coverage].to_f.should == ("%0.2f" %(@fund_share)).to_f
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f

    (slmc.ss_get_discount_amount(:promo => true, :visit_no => @@visit_no)).should == @original_discount_promo
    (slmc.ss_get_discount_amount(:fund_share => true, :visit_no => @@visit_no)).should == @fund_share
  end

  it"ER Turned Inpatient - Settle Payment" do
    slmc.pba_full_payment
    slmc.go_to_patient_billing_accounting_page
  end

  it"ER Turned Inpatient - Disharge patient" do
    slmc.pba_search(:with_discharge_notice => true, :pin => @@er_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
#   https://projects.exist.com/issues/39741
#    slmc.click"guarantorId"
#    slmc.click_update_guarantor
#    slmc.pba_update_guarantor(:guarantor_type => "INDIVIDUAL")
#    sleep 10
#    slmc.click'//input[@type="submit" and @value="Submit Changes"]',:wait_for => :page
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.click "//input[@value='Skip']", :wait_for => :page
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@er_pin)
    (slmc.get_text"css=#results>tbody>tr.even>td").gsub(' ','').should == @@er_pin
  end

  it"DR Turned Inpatient" do
    slmc.login(@dr_user,@password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration
    @@dr_pin = slmc.outpatient_registration(Admission.generate_data(:not_senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.click_register_patient
    slmc.spu_or_register_patient(:turn_inpatient => true, :acct_class => "SOCIAL SERVICE", :esc_no => "287", :dept_code => "OBSTETRICS AND GYNECOLOGY",
      :doctor => "6726", :preview => true, :save => true).should be_true
  end

  it"DR Turned Inpatient - Go to Inpatient Admission" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => @@dr_pin)
    slmc.er_outpatient_to_inpatient(:pin => @@dr_pin, :room_label => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :social_service => true)
  end

  it"DR Turned Inpatient - Order Items" do
    slmc.nursing_gu_search(:pin => @@dr_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@dr_pin)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    sleep 2
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple")
    slmc.confirm_validation_all_items.should be_true
  end

  it"DR Turned Inpatient - Go to Social Service Page" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    @@amount = 3000.0
    slmc.add_recommendation_entry(:amount => @@amount)
  end

  it"DR Turned Inpatient - Clinically discharge patient" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.nursing_gu_search(:pin=> @@dr_pin)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@dr_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"DR Turned Inpatient - Go to Payment" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
  end

  it"DR Turned Inpatient - Check Discounts applied" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f * @promo_discount_non_senior
    @total_hospital_bills = @@summary[:hospital_bill].to_f - @@amount  - @original_discount_promo

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:social_service_coverage].to_f.should ==@@amount
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f

    (slmc.ss_get_discount_amount(:promo => true, :visit_no => @@visit_no)).should == @original_discount_promo
    (slmc.ss_get_discount_amount(:ss_discount => true, :visit_no => @@visit_no)).should == @@amount
  end

  it"DR Turned Inpatient - Settle Payment" do
    slmc.pba_full_payment
    slmc.go_to_patient_billing_accounting_page
  end

  it"DR Turned Inpatient - Disharge patient" do
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS")
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@dr_pin)
    (slmc.get_text"css=#results>tbody>tr.even>td").gsub(' ','').should == @@dr_pin
  end

  it"OR Turned Inpatient" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration
    @@or_pin = slmc.outpatient_registration(Admission.generate_data(:not_senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.click_register_patient
    slmc.spu_or_register_patient(:turn_inpatient => true, :acct_class => "SOCIAL SERVICE", :esc_no => "287", :dept_code => "OBSTETRICS AND GYNECOLOGY",
      :doctor => "6726", :preview => true, :save => true).should be_true
  end

  it"OR Turned Inpatient - Go to Inpatient Admission" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.admission_search(:pin => @@or_pin)
    slmc.er_outpatient_to_inpatient(:pin => @@or_pin, :room_label => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :social_service => true).should be_true
  end

  it"OR Turned Inpatient - Order Items" do
    slmc.nursing_gu_search(:pin => @@or_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@or_pin)
    slmc.search_order(:ancillary => true, :description => "010002376", :filter => "WOMENS HEALTH CARE").should be_true
    slmc.add_returned_order(:ancillary => true,:description => "TRANSVAGINAL ULTRASOUND", :add => true ).should be_true
    slmc.er_submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it"OR Turned Inpatient - Go to Social Service Page" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click("filter3")
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    @@amount = 3000.0
    slmc.add_recommendation_entry(:amount => @@amount)
  end

  it"OR Turned Inpatient - Clinically discharge patient" do
    slmc.login(@inpatient_user, @password).should be_true
    slmc.nursing_gu_search(:pin=> @@or_pin)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@or_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"OR Turned Inpatient - Go to Payment" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
  end

  it"OR Turned Inpatient - Check Discounts applied" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    @original_discount_promo = @@summary[:hospital_bill].to_f * @promo_discount_non_senior
    @total_hospital_bills = @@summary[:hospital_bill].to_f - @@amount  - @original_discount_promo

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:social_service_coverage].to_f.should == @@amount
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f

    (slmc.ss_get_discount_amount(:promo => true, :visit_no => @@visit_no)).should == @original_discount_promo
    (slmc.ss_get_discount_amount(:ss_discount => true, :visit_no => @@visit_no)).should == @@amount
  end

  it"OR Turned Inpatient - Settle Payment" do
    slmc.pba_full_payment
    slmc.go_to_patient_billing_accounting_page
  end

  it"OR Turned Inpatient - Disharge patient" do
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS")
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@or_pin)
    (slmc.get_text"css=#results>tbody>tr.even>td").gsub(' ','').should == @@or_pin
  end

  it"For Outpatient  - Order in OSS" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(Admission.generate_data(:not_senior => true)).gsub(' ','').should be_true
  end

  it"OSS - CLASS A Discount Add Guarantor" do
     slmc.go_to_das_oss
     slmc.patient_pin_search(:pin => @@oss_pin)
     slmc.click_outpatient_order.should be_true
     slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "287", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"OSS - CLASS A Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "010002376", :quantity => "1", :doctor => '0126')
  end

  it"OSS - CLASS A Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo
    @class_discount = (@item_amount_with_promo * 50).round.to_f / 100

    @@summary[:total_promo].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:total_class_discount].to_f.should == ("%0.2f" %(@class_discount)).to_f
    @@summary[:total_net_amount].to_f.should == ("%0.2f" %(@class_discount)).to_f
  end

  it"OSS - CLASS B Discount Add Guarantor" do
     slmc.go_to_das_oss
     slmc.patient_pin_search(:pin => @@oss_pin)
     slmc.click_outpatient_order.should be_true
     slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "178", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"OSS - CLASS B Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "010002376", :quantity => "1", :doctor => '0126')
  end

  it"OSS - CLASS B Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo
    @class_discount = (@item_amount_with_promo * 75).round.to_f / 100

    @@summary[:total_promo].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:total_class_discount].to_f.should == ("%0.2f" %(@class_discount)).to_f
  end

  it"OSS - CLASS C Discount Add Guarantor" do
     slmc.go_to_das_oss
     slmc.patient_pin_search(:pin => @@oss_pin)
     slmc.click_outpatient_order.should be_true
     slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "216", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"OSS - CLASS C Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "010002376", :quantity => "1", :doctor => '0126')
  end

  it"OSS - CLASS C Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo
    @class_discount = (@item_amount_with_promo * 85).round.to_f / 100

    @@summary[:total_promo].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:total_class_discount].to_f.should == ("%0.2f" %(@class_discount)).to_f
  end

  it"OSS - CLASS D Discount Add Guarantor" do
     slmc.go_to_das_oss
     slmc.patient_pin_search(:pin => @@oss_pin)
     slmc.click_outpatient_order.should be_true
     slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "345", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"OSS - CLASS D Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "010002376", :quantity => "1", :doctor => '0126')
  end

  it"OSS - CLASS D Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo
    @class_discount = (@item_amount_with_promo * 90).round.to_f / 100

    @@summary[:total_promo].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:total_class_discount].to_f.should == ("%0.2f" %(@class_discount)).to_f
  end

  it"OSS - CLASS E Discount Add Guarantor" do
     slmc.go_to_das_oss
     slmc.patient_pin_search(:pin => @@oss_pin)
     slmc.click_outpatient_order.should be_true
     slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "198", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"OSS - CLASS E Discount Order Items" do
    sleep 2
    slmc.oss_order(:order_add => true, :item_code => "010002376", :quantity => "1", :doctor => '0126')
  end

  it"OSS - CLASS E Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo
    @class_discount = (@item_amount_with_promo * 95).round.to_f / 100

    @@summary[:total_promo].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:total_class_discount].to_f.should == ("%0.2f" %(@class_discount)).to_f
  end

  it"OSS - CLASS F Discount Add Guarantor" do
     slmc.go_to_das_oss
     slmc.patient_pin_search(:pin => @@oss_pin)
     slmc.click_outpatient_order.should be_true
     slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "234", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"OSS - CLASS F Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "010002376", :quantity => "1", :doctor => '0126')
  end

  it"OSS - CLASS F Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo

    @@summary[:total_promo].to_f.should == ("%0.2f" %(@original_discount_promo)).to_f
    @@summary[:total_class_discount].to_f.should == ("%0.2f" %(@item_amount_with_promo)).to_f
    @@summary[:total_net_amount].to_f.should == 0.0
  end

  it"For Outpatient  - Order in Phamacy" do
     slmc.login(@pharmacy_user, @password).should be_true
     slmc.go_to_pos_ordering
     slmc.pos_patient_toggle(:pin => @@oss_pin)
  end

  it"Phamacy - CLASS A Discount Add Guarantor" do
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "287", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Phamacy - CLASS A Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "040004334", :quantity => "1", :doctor => '0126')
  end

  it"Phamacy - CLASS A Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo

    @@summary[:total_class_discount].to_f.should == 0.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @item_amount_with_promo),2).to_f).abs).should <= 0.02
  end

  it"Phamacy - CLASS B Discount Add Guarantor" do
    slmc.go_to_pos_ordering
    slmc.pos_patient_toggle(:pin => @@oss_pin)
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "178", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Phamacy - CLASS B Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "040004334", :quantity => "1", :doctor => '0126')
  end

  it"Phamacy - CLASS B Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo

    @@summary[:total_class_discount].to_f.should == 0.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @item_amount_with_promo),2).to_f).abs).should <= 0.02
  end

  it"Phamacy - CLASS C Discount Add Guarantor" do
    slmc.go_to_pos_ordering
    slmc.pos_patient_toggle(:pin => @@oss_pin)
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "216", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Phamacy - CLASS C Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "040004334", :quantity => "1", :doctor => '0126')
  end

  it"Phamacy - CLASS C Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo

    @@summary[:total_class_discount].to_f.should == 0.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @item_amount_with_promo),2).to_f).abs).should <= 0.02
  end

  it"Phamacy - CLASS D Discount Add Guarantor" do
    slmc.go_to_pos_ordering
    slmc.pos_patient_toggle(:pin => @@oss_pin)
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "345", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Phamacy - CLASS D Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "040004334", :quantity => "1", :doctor => '0126')
  end

  it"Phamacy - CLASS D Discount Check Discount applied" do#class D gives 75% on pharmacy
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo
    @class_discount = (@item_amount_with_promo * 75).round.to_f / 100

    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_class_discount].to_f - @class_discount),2).to_f).abs).should <= 0.02
  end

  it"Phamacy - CLASS E Discount Add Guarantor" do
    slmc.go_to_pos_ordering
    slmc.pos_patient_toggle(:pin => @@oss_pin)
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "198", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Phamacy - CLASS E Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "040004334", :quantity => "1", :doctor => '0126')
  end

  it"Phamacy - CLASS E Discount Check Discount applied" do#class E gives 90% on pharmacy item.
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo
    @class_discount = (@item_amount_with_promo * 90).round.to_f / 100

    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_class_discount].to_f - @class_discount),2).to_f).abs).should <= 0.02
  end

  it"Phamacy - CLASS F Discount Add Guarantor" do
    slmc.go_to_pos_ordering
    slmc.pos_patient_toggle(:pin => @@oss_pin)
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "234", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Phamacy - CLASS F Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "040004334", :quantity => "1", :doctor => '0126')
  end

  it"Phamacy - CLASS F Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @class_discount = @@summary[:total_gross_amount].to_f - @original_discount_promo

    @@summary[:total_net_amount].to_f.should == 0.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_class_discount].to_f - @class_discount),2).to_f).abs).should <= 0.02
  end

  it"For Outpatient  - Order in Supplies" do
     slmc.login(@supply_user, @password).should be_true
     slmc.go_to_pos_ordering
     slmc.pos_patient_toggle(:pin => @@oss_pin)
  end

  it"Supplies - CLASS A Discount Add Guarantor" do
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "287", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Supplies - CLASS A Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "080200017", :quantity => "1", :doctor => '0126')
  end

  it"Supplies - CLASS A Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo

    @@summary[:total_class_discount].to_f.should == 0.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @item_amount_with_promo),2).to_f).abs).should <= 0.02
  end

  it"Supplies - CLASS B Discount Add Guarantor" do
    slmc.go_to_pos_ordering
    slmc.pos_patient_toggle(:pin => @@oss_pin)
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "178", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Supplies - CLASS B Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "080200017", :quantity => "1", :doctor => '0126')
  end

  it"Supplies - CLASS B Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo

    @@summary[:total_class_discount].to_f.should == 0.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @item_amount_with_promo),2).to_f).abs).should <= 0.02
  end

  it"Supplies - CLASS C Discount Add Guarantor" do
    slmc.go_to_pos_ordering
    slmc.pos_patient_toggle(:pin => @@oss_pin)
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "216", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Supplies - CLASS C Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "080200017", :quantity => "1", :doctor => '0126')
  end

  it"Supplies - CLASS C Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo

    @@summary[:total_class_discount].to_f.should == 0.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @item_amount_with_promo),2).to_f).abs).should <= 0.02
  end

  it"Supplies - CLASS D Discount Add Guarantor" do
    slmc.go_to_pos_ordering
    slmc.pos_patient_toggle(:pin => @@oss_pin)
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "345", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Supplies - CLASS D Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "080200017", :quantity => "1", :doctor => '0126')
  end

  it"Supplies - CLASS D Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo

    @@summary[:total_class_discount].to_f.should == 0.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @item_amount_with_promo),2).to_f).abs).should <= 0.02
  end

  it"Supplies - CLASS E Discount Add Guarantor" do
    slmc.go_to_pos_ordering
    slmc.pos_patient_toggle(:pin => @@oss_pin)
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "198", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Supplies - CLASS E Discount Order Items" do
    slmc.oss_order(:order_add => true, :item_code => "080200017", :quantity => "1", :doctor => '0126')
  end

  it"Supplies - CLASS E Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo

    @@summary[:total_class_discount].to_f.should == 0.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @item_amount_with_promo),2).to_f).abs).should <= 0.02
  end

  it"Supplies - CLASS F Discount Add Guarantor" do
    slmc.go_to_pos_ordering
    slmc.pos_patient_toggle(:pin => @@oss_pin)
    slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no => "234", :dept_code => "OBSTETRICS AND GYNECOLOGY", :guarantor_add => true)
  end

  it"Supplies - CLASS F Discount Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "080200017", :quantity => "1", :doctor => '0126')
  end

  it"Supplies - CLASS F Discount Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo

    @@summary[:total_class_discount].to_f.should == 0.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @item_amount_with_promo),2).to_f).abs).should <= 0.02
  end

#Scenarios below are already covered on automatic ss discount
#  it"Social Service  - Standard  -Discharge - w/ Adjustment - w/  philhealth Final" do
#
#  end

end