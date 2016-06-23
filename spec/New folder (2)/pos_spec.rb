require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'

describe "SLMC :: Point Of Sales" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Computes Senior citizen discount(20%) for Drugs" do
    slmc.login("sel_pharmacy2", @password).should be_true
    slmc.go_to_pos_ordering
    slmc.oss_patient_info(:senior => true)
    slmc.oss_order(:item_code => "TRAZADONE 150MG TAB", :order_add => true).should be_true #slmc.oss_order(:item_code => "ALFADIL XL 8MG TAB", :order_add => true).should be_true
    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :senior => true)
    @net_of_promo = @unit_price - @discount
    @net_amount = slmc.compute_net_amount(:senior => true, :net_promo => @net_of_promo)
    @vat = slmc.compute_vat(:senior => true, :net_promo => @net_of_promo)

    #verify discount, vat and net amount
    slmc.get_db_discount_value.should == @discount
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == ("%0.2f" %(@net_amount)).to_f
  end

  it "Test if input field for Search accepts either description or item code" do
    slmc.go_to_pos_ordering
    slmc.oss_order(:item_code => "040004334", :order_add => true).should be_true
    slmc.oss_order(:item_code => "CAPSICUM SACHET 10's", :order_add => true).should be_true
    slmc.oss_order(:item_code => "040004337", :order_add => true).should be_true
    slmc.oss_order(:item_code => "VENOTUBE TWINSITE", :order_add => true).should be_true
  end

  it "Computes Promo discount(16%) for Drugs" do
    slmc.go_to_pos_ordering
    slmc.oss_order(:item_code => "TRAZADONE 150MG TAB", :order_add => true).should be_true

    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :promo => true)
    @net_of_promo = @unit_price - @discount
    @vat = slmc.compute_vat(:net_promo => @net_of_promo)

    #verify discount, vat and net amount
    slmc.get_db_discount_value.should == @discount
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == (((@unit_price - @discount)) * 100).round.to_f / 100
  end

  it "Verify that default relationship for INDIVIDUAL type is 'SELF' " do
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :relationship => "SELF", :guarantor_add => true)
    slmc.get_text("css=#guarantorListTableBody>tr>td:nth-child(6)").should == "REL26" # which is the SELF relationship
  end

  it "MRP tagged item with guarantor of BOARD MEMBER type computes SENIOR and CLASS discount for LOCAL patient" do
    slmc.go_to_pos_ordering
    slmc.oss_patient_info(:senior => true)
    slmc.oss_add_guarantor(:acct_class => "BOARD MEMBER", :guarantor_type => "BOARD MEMBER", :guarantor_code => "BMAA001", :guarantor_add => true)
    slmc.oss_order(:item_code => "DOXORUBICIN 10MG VIAL (BIOMEDIS)", :order_add => true).should be_true

    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :senior => true)
    @net_of_promo = @unit_price - @discount
    @net_amount = slmc.compute_net_amount(:net_promo => @net_of_promo)
    @vat = slmc.compute_vat(:senior => true, :net_promo => @net_of_promo)
    @class_discount = 0.0
    #@class_discount = slmc.compute_class_discount(:unit_price => @unit_price, :discount => @discount)

    #verify discount, vat and net amount
    #slmc.get_db_class_discount_value.should == @class_discount
    slmc.get_db_class_discount_value.should == 0.0 # modified r29507 as per venz and erlyn (v1.4.1b-RC4)
    slmc.get_db_discount_value.should == @discount
    slmc.get_db_vat_value.should == @vat
    #slmc.get_db_net_amount.should == (((@unit_price - @discount) - @class_discount) * 100).round.to_f / 100
    slmc.get_db_net_amount.should == (((@unit_price - @discount) - @vat) * 100).round.to_f / 100 # less vat as per erl Oct/5/2011
  end

  it "MRP tagged item with guarantor of EMPLOYEE type computes CLASS discount only for LOCAL patient" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109092", :guarantor_add => true)
    slmc.oss_order(:item_code => "DOXORUBICIN 10MG VIAL (BIOMEDIS)", :order_add => true).should be_true    

    @unit_price = slmc.get_db_unit_price
    @vat = slmc.compute_vat(:net_promo => @unit_price)
    @class_discount = slmc.get_db_class_discount_value

    #verify class discount, vat and net amount
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == (((@unit_price) - @class_discount) * 100).round.to_f / 100
  end

  # needs client advice, system currently computes class, senior discount for EMPLOYEE patient
  it "MRP tagged item with guarantor of EMPLOYEE type computes CLASS discount only for LOCAL patient" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109092", :guarantor_add => true)
    slmc.oss_order(:item_code => "DOXORUBICIN 10MG VIAL (BIOMEDIS)", :order_add => true).should be_true    

    @unit_price = slmc.get_db_unit_price
    @vat = slmc.compute_vat(:net_promo => @unit_price)
    @class_discount = slmc.get_db_class_discount_value

    #verify discount, class discount, vat and net amount
    slmc.get_db_discount_value.should == 0
    slmc.get_db_class_discount_value.should == @class_discount
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == (((@unit_price) - @class_discount) * 100).round.to_f / 100
  end

  it "MRP tagged item computes NO discount for FOREIGN patient" do
    slmc.go_to_pos_ordering
    slmc.oss_patient_info(:foreign => true)
    slmc.oss_order(:item_code => "DOXORUBICIN 10MG VIAL (BIOMEDIS)", :order_add => true).should be_true

    @unit_price = slmc.get_db_unit_price
    @vat = slmc.compute_vat(:net_promo => @unit_price)

    slmc.get_db_discount_value.should == 0.0
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == ((@unit_price) * 100).round.to_f / 100
  end

  it "MRP tagged item with guarantor of EMPLOYEE type computes NO discount for FOREIGN patient" do
    slmc.go_to_pos_ordering
    slmc.oss_patient_info(:foreign => true)
    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109092", :guarantor_add => true)
    slmc.oss_order(:item_code => "DOXORUBICIN 10MG VIAL (BIOMEDIS)", :order_add => true).should be_true

    @class_discount = slmc.get_db_class_discount_value
    @unit_price = slmc.get_db_unit_price
    @vat = slmc.compute_vat(:net_promo => @unit_price)

    slmc.get_db_discount_value.should == 0.0
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == ((@unit_price - @class_discount) * 100).round.to_f / 100
  end

  it "MRP tagged item with guarantor of INDIVIDUAL type computes NO PROMO discount for LOCAL patient" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
    slmc.oss_order(:item_code => "DOXORUBICIN 10MG VIAL (BIOMEDIS)", :order_add => true).should be_true

    @discount = slmc.get_db_discount_value
    @unit_price = slmc.get_db_unit_price
    @vat = slmc.compute_vat(:net_promo => @unit_price)

    slmc.get_db_discount_value.should == 0.0
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == ((@unit_price) * 100).round.to_f / 100
  end

  it "MRP tagged item with guarantor of INDIVIDUAL type computes SENIOR discount for LOCAL patient" do
    slmc.go_to_pos_ordering
    slmc.oss_patient_info(:senior => true)
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
    slmc.oss_order(:item_code => "DOXORUBICIN 10MG VIAL (BIOMEDIS)", :order_add => true).should be_true

    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :senior => true)
    @net_of_promo = @unit_price - @discount
    @vat = slmc.compute_vat(:net_promo => @net_of_promo, :senior => true)

    slmc.get_db_discount_value.should == @discount
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == (((@unit_price - @discount) - @vat) * 100).round.to_f / 100
  end

  # input nonMRP item_code
  it "Non MRP items computes PROMO discount for LOCAL patient" do
    slmc.go_to_pos_ordering
    slmc.oss_order(:item_code => "TRAZADONE 150MG TAB", :order_add => true).should be_true

    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :promo => true)
    @net_of_promo = @unit_price - @discount
    @vat = slmc.compute_vat(:net_promo => @net_of_promo)

    #verify discount, vat and net amount
    slmc.get_db_discount_value.should == @discount
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == (((@unit_price - @discount)) * 100).round.to_f / 100
  end

  # input nonMRP item_code
  it "Non MRP items computes SENIOR discount for LOCAL patient" do
    slmc.go_to_pos_ordering
    slmc.oss_patient_info(:senior => true)
    slmc.oss_order(:item_code => "TRAZADONE 150MG TAB", :order_add => true).should be_true

    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :senior => true)
    @net_of_promo = @unit_price - @discount
    @vat = slmc.compute_vat(:net_promo => @net_of_promo, :senior => true)

    #verify discount, vat and net amount
    slmc.get_db_discount_value.should == @discount
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == (((@unit_price - @discount) - @vat) * 100).round.to_f / 100
  end

  # input nonMRP item_code
  it "Non MRP items computes PROMO discount for FOREIGN patient" do
    slmc.go_to_pos_ordering
    slmc.oss_patient_info(:foreign => true)
    slmc.oss_order(:item_code => "TRAZADONE 150MG TAB", :order_add => true).should be_true

    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :promo => true)
    @net_of_promo = @unit_price - @discount
    @vat = slmc.compute_vat(:net_promo => @net_of_promo)

    #verify discount, vat and net amount
    slmc.get_db_discount_value.should == @discount
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == (((@unit_price - @discount)) * 100).round.to_f / 100
  end

  it "EMPLOYEE guarantor type of HEEI1R0N computes 30% discount for ORT02 or items tagged as 'Vitamins'" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109092", :guarantor_add => true)
    slmc.oss_order(:item_code => "CEELIN SYRUP 120ML", :order_add => true).should be_true
    
    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :promo => true)
    @net_of_promo = @unit_price - @discount
    #@vat = slmc.compute_vat(:net_promo => @net_of_promo) # Jan 25 2012 - debugged computation of vat for GC
    @class_discount = slmc.compute_class_discount(:unit_price => @unit_price, :discount => @discount, :percent => 30)
    @vat = slmc.compute_vat(:net_promo => @net_of_promo, :class_discount => @class_discount)

    slmc.get_db_class_discount_value.should == @class_discount
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == (((@unit_price - @discount) - @class_discount) * 100).round.to_f / 100
  end

  it "Item classified as 'Prescribed drugs' and 'Vitamins' with guarantor of EMPLOYEE type of HEEI1R0N computes Promo, HE discount(30%) and VAT" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109092", :guarantor_add => true)
    slmc.oss_order(:item_code => "CEELIN SYRUP 120ML", :prescription => true, :order_add => true).should be_true

    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :promo => true)
    @net_of_promo = @unit_price - @discount
    @class_discount = slmc.compute_class_discount(:unit_price => @unit_price, :discount => @discount, :percent => 30)
    @vat = slmc.compute_vat(:net_promo => @net_of_promo, :class_discount => @class_discount)

    sleep 5
    #verify class discount, vat and net amount
    slmc.get_db_class_discount_value.should == @class_discount
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == ((((@unit_price - @discount)) - @class_discount) * 100).round.to_f / 100
  end

  it "Computes FIXED courtesy discount after PROMO discount" do
    slmc.go_to_pos_ordering
    slmc.oss_order(:item_code => "BABYHALER", :order_add => true).should be_true
    @discount = 100.0
    slmc.oss_add_discount(:item => "BABYHALER", :type => 'fixed', :scope => 'service', :amount => @discount.to_s)

    sleep 5
    slmc.get_db_fixed_courtesy_discount.should == @discount
    #slmc.get_db_courtesy_discount.should == @discount
  end

  it "Computes PERCENTAGE courtesy discount after SENIOR discount" do
    slmc.go_to_pos_ordering
    slmc.oss_patient_info(:senior => true)
    slmc.oss_order(:item_code => "BABYHALER", :order_add => true).should be_true
    @discount = 10.0
    slmc.oss_add_discount(:item => "BABYHALER", :type => 'percent', :scope => 'service', :amount => @discount.to_s)

    #@courtesy_discount = (slmc.get_db_net_amount * (@discount/100) * 100).round.to_f / 100
    @discount_net_amount = slmc.get_db_discount_net_amount
    #@courtesy_discount = slmc.compute_courtesy_discount(:percent => true, :amount => @discount_net_amount, :net => @discount)
    sleep 5
    slmc.get_db_percent_courtesy_discount.should == @discount
    #slmc.get_db_courtesy_discount.should == @courtesy_discount
  end

  # this may get an error due to javascript of some sort. if FAIL, please manually check. expected only 1 guarantor since edited
  it "Edit guarantor from list" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :relationship => "SELF", :guarantor_add => true).should be_true
    sleep 5
    slmc.oss_add_guarantor(:edit => true, :acct_class => "BOARD MEMBER", :guarantor_type => "BOARD MEMBER", :guarantor_code => "BMAA001", :guarantor_add => true).should be_true
    slmc.get_text("//table[@id='guarantorListTable']/tbody/tr/td[3]").should == "BMAA001"
    slmc.get_text("//table[@id='guarantorListTable']/tbody/tr/td[2]").should == "BM"
  end

  it "Delete guarantor from list" do
    slmc.oss_add_guarantor(:delete => true).should == 0
  end

  it "Edit order from list" do
    slmc.oss_order(:item_code => "BABYHALER", :order_add => true).should be_true
    slmc.oss_order(:order_edit => true, :quantity => "5").should be_true
    sleep 5
    slmc.get_text("ops_order_quantity_0").should == "5.00"
  end

  it "Delete order from list" do
    slmc.oss_order(:order_delete => true).should be_true
  end

  it "Add check payment" do
    slmc.oss_add_payment(:type => "CHECK", :bank_name => "BDO", :check_no => "123456789", :date => Time.now.strftime("%m/%d/%Y"), :amount => "10000")
    slmc.get_css_count("css=#checkPaymentRows>tr").should == 1
  end

  it "Remove check payment from list" do
    slmc.click("checkPayment0")
    slmc.click("removeCheckPayment")
    slmc.get_css_count("css=#checkPaymentRows>tr").should == 0
  end

  it "Add and Remove Credit Card in Payment" do
    slmc.oss_add_payment(:type => "CREDIT CARD", :amount => "1000")
    slmc.get_css_count("css=#ccPaymentRows>tr").should == 1
    slmc.click("ccPayment0")
    slmc.click("removeCreditCardPayment")
    slmc.get_css_count("css=#ccPaymentRows>tr").should == 0
  end

  it "Display Refund Screen : Not display for CI document type" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
    slmc.oss_order(:item_code => "BABYHALER", :order_add => true).should be_true
    slmc.oss_order(:item_code => "042450011", :order_add => true).should be_true
    @amount = slmc.get_db_net_amount.to_s + '0'
    slmc.oss_add_payment(:type => "CASH", :amount => @amount).should be_true
    slmc.submit_order.should be_true
    @@doc_number = slmc.get_document_number
    slmc.print_or_confirmation("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."

    slmc.go_to_pos_order_cancellation
    @@ci_number = (slmc.get_ci_number_using_pos_number(@@doc_number)).gsub(' ', '')
    slmc.pos_document_search(:type => "CI NUMBER", :doc_no => @@ci_number).should be_true
    slmc.pos_click_view_details(:ci_no => @@ci_number)
    slmc.pos_cancel_item(:reason => "CANCELLATION - PATIENT REFUSAL", :order_of_item => 2).should == "The CM was successfully updated with printTag = 'Y'."
    slmc.is_element_present("refundAmount").should be_false
  end

  it "Display Calendar pop-up of transaction dates" do
    slmc.go_to_pos_order_cancellation
    slmc.is_visible("ui-datepicker-div").should be_false
    slmc.click("//img[@class='ui-datepicker-trigger']")
    sleep 3
    slmc.is_visible("ui-datepicker-div").should be_true
  end

  it "Successfuly proceed through CASH payment and assert if OR confirmation is displayed" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
    slmc.oss_order(:item_code => "BABYHALER", :order_add => true).should be_true
    slmc.oss_order(:item_code => "042450011", :order_add => true).should be_true
    @amount = slmc.get_db_net_amount.to_s + '0'
    slmc.oss_add_payment(:type => "CASH", :amount => @amount).should be_true
    slmc.submit_order.should be_true
    @@doc_no = slmc.get_document_number
    slmc.print_or_confirmation("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "Should be able to Reprint Sales Invoice" do
    slmc.go_to_pos_order_cancellation
    @@sales_invoice_number = (slmc.get_or_number_using_pos_number(@@doc_no)).gsub(' ', '')
    slmc.pos_document_search(:type => "PHARMACY SALES INVOICE", :doc_no => @@sales_invoice_number).should be_true
    slmc.click_reprint_button(:sales_invoice => true).should be_true
  end

  it "Refund amount field is editable" do # Feature # 39782
    slmc.go_to_pos_order_cancellation
    slmc.pos_document_search(:type => "PHARMACY SALES INVOICE", :doc_no => @@sales_invoice_number)
    slmc.pos_click_view_details(:sales_invoice_number => @@sales_invoice_number)
    slmc.pos_cancel_item(:reason => "CANCELLATION - PATIENT REFUSAL", :order_of_item => 2).should == "The CM was successfully updated with printTag = 'Y'."
    slmc.is_element_present("refundAmount").should be_true
    slmc.is_editable("refundAmount").should be_true
  end

  it "Refund Amount should not be less or equal to zero" do # Feature # 39782
    slmc.submit_refund(:receiver => "seleniumReceiver", :valid_id => "seleniumID", :amount => "-1").should == "Invalid Refund Amount."
    slmc.submit_refund(:receiver => "seleniumReceiver", :valid_id => "seleniumID", :amount => "0").should == "Invalid Refund Amount."
    slmc.submit_refund(:receiver => "seleniumReceiver", :valid_id => "seleniumID", :amount => "10").should == "The refund was successfully updated with printTag = 'Y'."
  end

  it "Bug 22597 - Search per Document Type - CI NUMBER" do
    slmc.go_to_pos_order_cancellation
    @@ci_no = (slmc.get_ci_number_using_pos_number(@@doc_no)).gsub(' ', '')
    slmc.pos_document_search(:type => "CI NUMBER", :doc_no => @@ci_no).should be_true
  end

  it "Successfuly proceed through CHARGE payment and assert if OR confirmation is displayed" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "HMO", :guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :coverage_choice => "percent", :coverage_amount => '100.00', :guarantor_add => true)
    slmc.oss_order(:item_code => "BABYHALER", :order_add => true).should be_true
    slmc.submit_order.should be_true
  end

  it "Should be able to Reprint Charge Invoice(CI)" do
    slmc.go_to_pos_order_cancellation
    slmc.pos_document_search(:type => "CHARGE INVOICE").should be_true
    slmc.click_reprint_button(:ci => true).should be_true
  end

  it "Bug #22730 - Should be able to search order for cancellation by requestion unit" do
    slmc.go_to_order_adjustment_and_cancellation
    slmc.ci_search(:start_date => "01/01/2011", :end_date => Time.now.strftime('%m/%d/%Y'), :request_unit => "0278")
    slmc.get_value(Locators::OrderAdjustmentAndCancellation.requesting_unit_description).should == slmc.get_text(Locators::OrderAdjustmentAndCancellation.ci_searched_result_description)
  end

  it "Account class is individual with HMO guarantor = 50%, credit card payment" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "HMO", :guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :relationship => "SELF", :coverage_choice => "percent", :coverage_amount => '50.00', :guarantor_add => true)
    slmc.oss_order(:item_code => "GELFOAM SIZE 100", :order_add => true).should be_true
    slmc.get_text("css=#guarantorListTableBody>tr>td:nth-child(6)").should == "REL26" # which is the SELF relationship

    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :promo => true)
    @net_of_promo = @unit_price - @discount
    @vat = slmc.compute_vat(:net_promo => @net_of_promo)

    sleep 5
    #verify discount, vat and net amount
    slmc.get_db_discount_value.should == @discount
    slmc.get_db_vat_value.should == @vat
    slmc.get_db_net_amount.should == ("%0.2f" %(@net_of_promo)).to_f
    @discount = 500.0

    slmc.oss_add_discount(:item => "GELFOAM SIZE 100", :type => 'fixed', :scope => 'service', :amount => @discount.to_s)

    sleep 5
    slmc.get_db_fixed_courtesy_discount.should == @discount
    #slmc.get_db_courtesy_discount.should == @discount
    @amount = slmc.get_db_net_amount.to_s + '0'
    @amount = @amount.to_f

    #charge_amount = @amount / 2
    charge_amount = (@amount - @discount) / 2 # r26390 patchA

    @amount = slmc.truncate_to(charge_amount, 2)
    slmc.oss_add_payment(:type => "CREDIT CARD", :amount => @amount.to_s)
    slmc.submit_order.should be_true
    slmc.print_or_confirmation("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'." #"The OR was successfully updated with printTag = 'Y'."
  end

  it "Bug #26279 - [Pharmacy]: NullPointerException encountered on reprinting of OR" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
    #slmc.oss_order(:item_code => "9999", :service_rate => 5000, :order_add => true, :special => true).should be_true ## special order is not applicable in POS as per Jichelle
    slmc.oss_order(:item_code => "GELFOAM SIZE 100", :order_add => true).should be_true
    @discount = 10.0
    slmc.oss_add_discount(:type => "percent", :scope => "dept", :amount => @discount.to_s)

    #@courtesy_discount = (slmc.get_db_net_amount * (@discount/100) * 100).round.to_f / 100
    @discount_net_amount = slmc.get_db_discount_net_amount
    @courtesy_discount = slmc.compute_courtesy_discount(:percent => true, :amount => @discount_net_amount, :net => @discount)
    slmc.get_db_percent_courtesy_discount.should == @discount
    #slmc.get_db_courtesy_discount.should == @courtesy_discount

    @amount = slmc.get_db_net_amount.to_s + '0'
    slmc.oss_add_payment(:type => "CASH", :amount => @amount.to_s)
    slmc.submit_order.should be_true
    @@doc_no = slmc.get_document_number
    slmc.print_or_confirmation("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."

    slmc.go_to_pos_order_cancellation
    @@sales_invoice_number2 = (slmc.get_or_number_using_pos_number(@@doc_no)).gsub(' ', '')
    slmc.pos_document_search(:type => "PHARMACY SALES INVOICE", :doc_no => @@sales_invoice_number2, :start_date => "", :end_date => "").should be_true
    slmc.click_reprint_button(:sales_invoice => true).should be_true
  end

  it "Bug #25899 - Order Adjustment/Cancellation Page: Order Search Page Does Not Load" do
    slmc.go_to_order_adjustment_and_cancellation
    slmc.click_order_search_link.should be_true
  end

  it "Cancel All items" do # Feature 39782
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
    slmc.oss_order(:item_code => "GELFOAM SIZE 100", :order_add => true).should be_true
    slmc.oss_order(:item_code => "BABYHALER", :order_add => true).should be_true
    @amount = slmc.get_db_net_amount.to_s + '0'
    slmc.oss_add_payment(:type => "CASH", :amount => @amount.to_s)
    slmc.submit_order.should be_true
    @@doc_no = slmc.get_document_number
    slmc.print_or_confirmation("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."

    slmc.go_to_pos_order_cancellation
    @@sales_invoice_number3 = (slmc.get_or_number_using_pos_number(@@doc_no)).gsub(' ', '')
    slmc.pos_document_search(:type => "PHARMACY SALES INVOICE", :doc_no => @@sales_invoice_number3, :start_date => "", :end_date => "").should be_true
    slmc.pos_cancel_order(:reason => "CANCELLATION - PATIENT REFUSAL").should == "The OR must be cancelled at the billing department. No refund to be processed."
    slmc.tag_document.should == "The CM was successfully updated with printTag = 'Y'."
  end

  it "Computes for Senior citizen discount for Supplies" do
    slmc.login("sel_supplies1", @password).should be_true
    slmc.go_to_pos_ordering
    slmc.oss_patient_info(:senior => true)
    slmc.oss_order(:item_code => "BABY OIL 50ML (J & J)", :order_add => true).should be_true

    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :senior => true)
    @net_of_promo = @unit_price - @discount
    @vat = slmc.compute_vat(:net_promo => @net_of_promo)

    slmc.get_db_discount_value.should == @discount
    slmc.get_db_net_amount.should == (((@unit_price - @discount)) * 100).round.to_f / 100
  end

  it "Computes for Promo discount for Supplies" do
    slmc.go_to_pos_ordering
    slmc.oss_patient_info(:senior => false)
    slmc.oss_order(:item_code => "BABY OIL 50ML (J & J)", :order_add => true).should be_true

    @unit_price = slmc.get_db_unit_price
    @discount = slmc.compute_discounts(:unit_price => @unit_price, :promo => true)
    @net_of_promo = @unit_price - @discount
    @vat = slmc.compute_vat(:net_promo => @net_of_promo)

    slmc.get_db_discount_value.should == @discount
    slmc.get_db_net_amount.should == (((@unit_price - @discount)) * 100).round.to_f / 100
  end

  it "Bug 24020 - Successfuly proceed through CASH payment and assert if OR confirmation is displayed" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
    slmc.oss_order(:item_code => "BABY OIL 50ML (J & J)", :order_add => true).should be_true    
    @amount = slmc.get_db_net_amount.to_s + '0'
    slmc.oss_add_payment(:type => "CASH", :amount => @amount.to_s)
    slmc.submit_order.should be_true
    @@pos_number = slmc.get_document_number
    slmc.print_or_confirmation("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "Bug #26296 CSS POS Cancellation - Yikes encountered in Reprinting Of OR" do
    @@or_no = (slmc.get_or_number_using_pos_number(@@pos_number)).gsub(' ', '')
    slmc.go_to_pos_order_cancellation
    slmc.pos_document_search(:type => "CSS OFFICIAL RECEIPT", :doc_no => @@or_no, :start_date => "", :end_date => "")
    slmc.click_reprint_button(:sales_invoice => true).should be_true
  end

  it "Bug #25846 POS- ORDER CANCELLATION: Unable to cancel orders of HE" do
    slmc.login("sel_pharmacy2", @password).should be_true
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109040", :guarantor_add => true)
    slmc.oss_order(:item_code => "PROSURE VANILLA 380g", :quantity => "3.0", :order_add => true).should be_true
    slmc.oss_order(:item_code => "GELFOAM SIZE 100", :quantity => "3.0", :order_add => true).should be_true
    slmc.submit_order
    @@pos_number2 = slmc.get_document_number
    @@ci_no = (slmc.get_ci_number_using_pos_number(@@pos_number2)).gsub(' ', '')
    slmc.go_to_pos_order_cancellation
    slmc.pos_document_search(:type => "CI NUMBER", :doc_no => @@ci_no, :start_date => "", :end_date => "").should be_true
    slmc.pos_click_view_details(:ci_no => @@ci_no)
    slmc.get_css_count("css=#results>tbody>tr").should == 2
  end

  # Feature 39782 (last 3 samples below the testcase)
  it "Refund in PBA page" do
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "INDIVIDUAL", :guarantor_type => "INDIVIDUAL", :guarantor_name => "TEST", :guarantor_add => true)
    slmc.oss_order(:item_code => "BABYHALER", :order_add => true).should be_true
    slmc.oss_order(:item_code => "042450011", :order_add => true).should be_true
    @amount = slmc.get_db_net_amount.to_s + '0'
    slmc.oss_add_payment(:type => "CASH", :amount => @amount).should be_true
    slmc.submit_order.should be_true
    @@doc_no = slmc.get_document_number
    slmc.print_or_confirmation("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."

    slmc.go_to_pos_order_cancellation
    @@sales_invoice_number = (slmc.get_or_number_using_pos_number(@@doc_no)).gsub(' ', '')
    slmc.pos_document_search(:type => "PHARMACY SALES INVOICE", :doc_no => @@sales_invoice_number).should be_true
    slmc.pos_click_view_details(:sales_invoice_number => @@sales_invoice_number)
    slmc.pos_cancel_item(:reason => "CANCELLATION - PATIENT REFUSAL", :order_of_item => 2).should == "The CM was successfully updated with printTag = 'Y'."

    #slmc.add_user_security(:user => "sel_pba20", :org_code => "0016", :tran_type => "AUT002")
    slmc.login("sel_pba20", @password).should be_true
    slmc.pba_adjustment_and_cancellation(:doc_type => "OFFICIAL RECEIPT", :search_option => "DOCUMENT NUMBER", :entry => @@sales_invoice_number).should be_true
    slmc.click_refund(:doc_number => @@sales_invoice_number)

    ## "Entered refund amount that is higher than the originally indicated refund amount is not allowed"
    refund_original = slmc.get_value("refundAmount").to_f
    refund_amount = refund_original + 1000.0
    returned_amount = slmc.submit_refund(:receiver => "seleniumReceiver", :valid_id => "seleniumID", :amount => refund_amount)

    # blank refund amount is not allowed
    slmc.submit_refund(:receiver => "seleniumReceiver", :valid_id => "seleniumID", :amount => "0").should == "Invalid Refund Amount."

    slmc.is_editable("refundAmount").should be_true # - refund amount field is editable # Feature 39782
    slmc.submit_refund(:receiver => "seleniumReceiver", :valid_id => "seleniumID", :amount => "1000").should be_true
    
    returned_amount.should == "Refund amount should not exceed (#{refund_original})."
  end

end