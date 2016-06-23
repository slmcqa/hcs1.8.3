require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "User Management" do
  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver =  SLMC.new
    @selenium_driver.start_new_browser_session
    @roles = UserManagement.user_roles
    @users = { # user_name => org_code
      "jglifonea" => "0287",
      "user_gene" => "0287",
      "billing_spec_user" => "0287",
      "gu_spec_user" => "0287",
      "smoke_test_spec_user" => "0287",
      "oss_philhealth_normal_spec_user1" => "0164",
      "oss_philhealth_normal_spec_user2" => "0164",
      "gu_spec_user2" => "0287",
      "gu_spec_user3" => "0287",
      "gu_spec_user4" => "0287",
      "gu_spec_user5" => "0287",
      "gu_spec_user6" => "0287",
      "gu_spec_user7" => "0287",
      "gu_spec_user8" => "0287",
      "gu_spec_user9" => "0287",
      "gu_spec_user10" => "0287",
      "gu_spec_user11" => "0287",
      "gu_spec_user12" => "0287",
      "billing_spec_user1" => "0287",
      "billing_spec_user2" => "0287",
      "billing_spec_user3" => "0287",
      "billing_spec_user4" => "0287",
      "billing_spec_user5" => "0287",
      "billing_spec_user6" => "0287",
      "billing_spec_user7" => "0287",
      "billing_spec_user8" => "0287",
      "billing_spec_user9" => "0287",
      "css_spec_user" => "0278",
      "fnb_spec_user" => "0278",
      "newborn_spec_user" => "0278",
      "update_guarantor_spec_user" => "0278",
      "philhealth_spec_user" => "0278",
      "update_guarantor_spec_user2" => "0278",
      "update_guarantor_spec_user3" => "0278",
      "update_guarantor_spec_user4" => "0278",
    }

    @additional_arms_users = {
      "arms_spec_user" => "0058",
      "sel_arms_spec_user" => "0058",
      "sel_arms_spec_user1" => "0058",
      "sel_arms_spec_user2" => "0058"
    }

    @additional_readers_fee_users = {
      "sel_readers_fee_user1" => "0058",
      "sel_readers_fee_user2" => "0058",
      "sel_readers_fee_user3" => "0058",
    }

    @additional_armsdastech_users = {
      "armsdastech1" => "0066",
      "sel_armsdastech" => "0058",
      "sel_armsdastech1" => "0066",
      "sel_armsdastech2" => "0066",
      "sel_armsdastech3" => "0066",
      "sel_armsdastech4" => "0066"
    }

    @additional_pba_users = { #pba1 users
      "pba21" => "0016",
      "pba22" => "0016",
      "pba23" => "0016",
      "pba24" => "0016",
      "pba25" => "0016",
      "pba26" => "0016",
      "pba27" => "0016",
      "pba28" => "0016",
      "pba29" => "0016",
      "sel_pba1" => "0016",
      "sel_pba2" => "0016",
      "sel_pba3" => "0016",
      "sel_pba4" => "0016",
      "sel_pba5" => "0016",
      "sel_pba6" => "0016",
      "sel_pba7" => "0016",
      "sel_pba8" => "0016",
      "sel_pba9" => "0016",
      "sel_pba10" => "0016",
      "sel_pba11" => "0016",
      "sel_pba12" => "0016",
      "sel_pba13" => "0016",
      "sel_pba14" => "0016",
      "sel_pba15" => "0016",
      "sel_pba16" => "0016",
      "sel_pba17" => "0016",
      "sel_pba18" => "0016",
      "sel_pba19" => "0016",
      "sel_pba20" => "0016",
      "sel_pba21" => "0016",
      "sel_pba22" => "0016",
      "sel_pba23" => "0016"
    }

    @additional_pba2_users ={ #user without ROLE_PHILHEALTH_OFFICER
      "sel_pba97" => "0016",
      "sel_pba98" => "0016",
      "sel_pba99" => "0016",
    }

    @additional_partial_discount_users = {
      "sel_partial1" => "0016",
      "sel_partial2" => "0016"
    }

    @additional_or_users = { # or1 users
      "or21" => "0164",
      "or22" => "0164",
      "or23" => "0164",
      "or24" => "0164",
      "or25" => "0164",
      "or26" => "0164",
      "or27" => "0164",
      "or28" => "0164",
      "or29" => "0164",
      "sel_or1" => "0164",
      "sel_or2" => "0164",
      "sel_or3" => "0164",
      "sel_or4" => "0164",
      "sel_or5" => "0164",
      "sel_or6" => "0164", # ROLE_LATE_TRANSACTION
      "sel_or7" => "0165",
      "sel_or8" => "0165",
      "sel_or9" => "0164", #role_spu_nursing_manager
      "sel_or10" => "0164", #role_spu_nursing_manager,
      "sel_or11" => "0164",
      "sel_or12" => "0164"
    }

    @additional_adm_users = { #adm1 users
      "sel_adm1" => "0018",
      "sel_adm2" => "0018",
      "sel_adm3" => "0018",
      "sel_adm4" => "0018",
      "sel_adm5" => "0018",
      "sel_adm6" => "0018",
      "sel_adm7" => "0018",
      "sel_adm8" => "0018",
      "sel_adm9" => "0018"
    }

    @additional_er_users = { # er1 users
      "sel_er1" => "0173",
      "sel_er2" => "0173",
      "sel_er3" => "0173",
      "sel_er4" => "0173",
      "sel_er5" => "0173",
      "sel_er6" => "0173",
      "sel_er7" => "0173",
      "sel_er8" => "0173",
      "sel_er9" => "0173",
      "sel_er10" => "0173",
      "sel_er11" => "0173",
      "sel_er12" => "0173" # without role_spu_nursing_manager
    } 

    @additional_pharmacy_users = { #pharmacy1 user
      "sel_pharmacy1" => "0004",
      "sel_pharmacy2" => "0004",
      "sel_pharmacy3" => "0004",
      "sel_pharmacy4" => "0004",
      "sel_pharmacy5" => "0004",
      "sel_pharmacy6" => "0004"
    }

    @additional_oss_users ={ #oss1 user
      "sel_oss1" => "0036",
      "sel_oss2" => "0036",
      "sel_oss3" => "0036",
      "sel_oss4" => "0036",
      "sel_oss6" => "0036",
      "sel_oss7" => "0036",
      "sel_oss8" => "0036",
      "sel_oss9" => "0036",
      "sel_oss10" => "0036",
      "sel_oss11" => "0036",
      "sel_oss12" => "0036",
      "sel_oss13" => "0036"
    }

    @additional_oss2_users ={ # oss2 user
      "sel_oss5" => "0088"
    }

    @additional_wellness_users ={ # wellness1 users
      "sel_wellness1" => "0050",
      "sel_wellness2" => "0050",
      "sel_wellness3" => "0050"
    }

    @additional_fnb_users ={ #fnb users
      "sel_fnb1" => "0194",
      "sel_fnb2" => "0194"
    }

    @additional_dr_users ={
      "sel_dr1" => "0170",
      "sel_dr2" => "0170",
      "sel_dr3" => "0170",
      "sel_dr4" => "0170",
      "sel_dr5" => "0170",
      "sel_dr6" => "0170",
      "sel_dr7" => "0170",
      "sel_dr8" => "0170",
      "sel_dr9" => "0170",
      "sel_dr10" => "0170" #with role spu_nursing_manager
    }

    @additional_ss_users ={
      "sel_ss1" => "0012",
      "sel_ss2" => "0012",
      "sel_ss3" => "0012",
      "sel_ss4" => "0012",
      "sel_ss5" => "0012"
    }

    @validator_users ={
      "sel_0278_validator" => "0278",
      "sel_0287_validator" => "0287",
      "sel_0332_validator" => "0332"
    }

    @or_validator_users ={
      "sel_0164_validator" => "0164",
      "sel_0165_validator" => "0165"
    }

    @additional_gu_users ={
      "sel_discount_gu" => "0287",
      "sel_gu1" => "0287",
      "sel_gu2" => "0287",
      "sel_gu3" => "0287"
    }

    @additional_dastech_users ={
      "sel_dastech1" => "0052",
      "sel_dastech2" => "0135"
    }

    @additional_supplies_users ={
      "sel_supplies1" => "0008",
      "sel_supplies2" => "0008",
    }

    @additional_inhouse_users ={
      "sel_inhouse1" => "0019",
      "sel_inhouse2" => "0019"
    }

    @additional_hoa_users ={
      "sel_hoa1" => "0301",
      "sel_hoa2" => "0301"
    }

    @additional_file_maintenance_users ={
      "sel_fm1" => "0058" # org_code of exist
    }

    @additional_miscellaneous_users ={
      "sel_misc1" => "0234"
    }

    @additional_css_users = {
      "sel_css1" => "0008",
      "sel_css2" => "0008"
    }
############################ ROLES ################################


    @user_roles =[
      'ROLE_ADMISSION_CLERK',
      'ROLE_ANCILLARY_FNB',
      'ROLE_LATE_TRANSACTION',
      'ROLE_NURSING_ADJUSTMENT_ANCILLARY',
      'ROLE_NURSING_ADJUSTMENT_OTHERS',
      'ROLE_NURSING_ADJUSTMENT_PHARMACY',
      'ROLE_NURSING_GENERAL_UNITS',
      'ROLE_NURSING_VALIDATE',
      'ROLE_PACKAGE_ADJUSTMENT',
      'ROLE_RPT_OM_DIET_LISTING',
      'ROLE_RPT_OM_NURSING_ENDORSEMENT',
      'ROLE_RPT_OM_TWENTY_FOUR_HOUR_MEDICINE',
      'ROLE_RPT_OM_PATIENT_ASSIGNMENT',
      'ROLE_RPT_USER',
      'ROLE_SPECIAL_ORDERS',
      'ROLE_USER'
    ]

    @arms_user_roles =[
      'ROLE_ARMS_ADMIN',
      'ROLE_ARMS_DAS_TECHNOLOGIST',
      'ROLE_ARMS_MEDICAL_RECORD',
      'ROLE_DAS_ADMIN_ASSISTANT',
      'ROLE_DAS_ANCILLARY_DOCTOR',
      'ROLE_DAS_NON_ANCILLARY_DOCTOR',
      'ROLE_DAS_TECHNOLOGIST',
      'ROLE_NURSING_ADJUSTMENT_PHARMACY',
      'ROLE_NURSING_ADJUSTMENT_CSS',
      'ROLE_NURSING_ADJUSTMENT_ANCILLARY',
      'ROLE_NURSING_GENERAL_UNITS',
      'ROLE_NURSING_VALIDATE',
      'ROLE_SPECIAL_ORDERS',
      'ROLE_USER'
    ]

    @readers_fee_user_roles = [
      'ROLE_ANCILLARY_READERS_FEE',
      'ROLE_ARMS_DAS_TECHNOLOGIST',
      'ROLE_ARMS_DAS_MANAGER',
      'ROLE_DAS_ONESTOP_SHOP',
      'ROLE_USER'
    ]

    @armsdastech_user_roles =[
      'ROLE_ANCILLARY_READERS_FEE',
      'ROLE_ARMS_DAS_TECHNOLOGIST',
      'ROLE_USER'
    ]

    @pba_user_roles =[
      'ROLE_ACCOUNTING_STAFF',
      'ROLE_BILLING_ASSOCIATE',
      'ROLE_PHILHEALTH_OFFICER',
      'ROLE_PACKAGE_ADJUSTMENT',
      'ROLE_LATE_TRANSACTION',
      'ROLE_PBA_CASHIER',
      'ROLE_USER'
    ]

    @pba2_user_roles =[
      'ROLE_BILLING_ASSOCIATE',
      'ROLE_LATE_TRANSACTION',
      'ROLE_PBA_CASHIER',
      'ROLE_USER'
    ]

    @partial_discount_user_roles =[
      'ROLE_PACKAGE_ADJUSTMENT',
      'ROLE_BILLING_ASSOCIATE',
      'ROLE_GU_NURSING_MANAGER',
      'ROLE_NURSING_GENERAL_UNITS',
      'ROLE_PHILHEALTH_OFFICER',
      'ROLE_ACCOUNT_SERVICES',
      'ROLE_USER'
    ]

    @or_user_roles =[
      'ROLE_SPU_OUTPATIENT_NURSE',
      'ROLE_USER'
    ]

    @adm_user_roles =[
      'ROLE_ADMIN',
      'ROLE_ADMISSION_CLERK',
      'ROLE_FILE_MAINTENANCE_DIAGNOSIS',
      'ROLE_FILE_MAINTENANCE_ROOM_BOARD',
      'ROLE_ENDORSEMENT_TAGGING',
      'ROLE_ENDORSEMENT_VIEWING',
      'ROLE_ADMISSION_MANAGER',
      'ROLE_ADMISSION_CONFIDENTIAL',
      'ROLE_USER'
    ]

    @er_user_roles =[
       'ROLE_DRUG_ORDER_VALIDATION',
       'ROLE_ER_BILLING',
       'ROLE_ER_NURSE',
       'ROLE_NURSING_ADJUSTMENT_OTHERS',
       'ROLE_PHILHEALTH_OFFICER',
       'ROLE_SPECIAL_ORDERS',
       'ROLE_SPU_NURSING_MANAGER',
       'ROLE_USER'
    ]

    @pharmacy_user_roles =[
     'ROLE_ANCILLARY_PHARMACY',
     'ROLE_DRUG_ORDER_VALIDATION',
     'ROLE_NURSING_ADJUSTMENT_PHARMACY',
     'ROLE_OSS_SPECIAL_ORDERING',
     'ROLE_PHARMACY_CASHIER',
     'ROLE_PHARMACY_COMPOUNDED',
     'ROLE_POS_ADJUSTMENT_PHARMACY',
     'ROLE_RPT_OM_NURSING_ENDORSEMENT',
     'ROLE_RPT_OM_SPECIAL_UNITS_REVENUE',
     'ROLE_RPT_OM_SUMMARY_OF_ADJUSTMENT_CANCELLATION',
     'ROLE_RPT_USER',
     'ROLE_USER'
    ]

    @oss_user_roles =[
     'ROLE_DAS_ONESTOP_SHOP',
     'ROLE_NURSING_ADJUSTMENT_ANCILLARY',
     'ROLE_OSS_SPECIAL_ORDERING',
     'ROLE_OSS_COMPOUNDED_ORDERING',
     'ROLE_OSS_PAYMENT_CANCELLATION',
     'ROLE_SPECIAL_ORDERS',
     'ROLE_USER'
    ]

    @oss2_user_roles =[
     'ROLE_DAS_ONESTOP_SHOP',
     'ROLE_IAPR_USER_ADMINISTRATOR',
     'ROLE_OSS_COMPOUNDED_ORDERING',
     'ROLE_OSS_PAYMENT_CANCELLATION',
     'ROLE_OSS_SPECIAL_ORDERING',
     'ROLE_SPECIAL_ORDERS',
     'ROLE_USER'
    ]

    @wellness_user_roles =[
      'ROLE_WELLNESS_ASSOCIATE',
      'ROLE_USER'
    ]

    @fnb_user_roles =[
     'ROLE_ANCILLARY_FNB',
     'ROLE_FNB_CASHIER',
     'ROLE_NURSING_ADJUSTMENT_FNB',
     'ROLE_OSS_SPECIAL_ORDERING',
     'ROLE_POS_ADJUSTMENT_FNB',
     'ROLE_POS_ADJUSTMENT_PHARMACY',
     'ROLE_SPECIAL_ORDERS',
     'ROLE_USER'
    ]

    @dr_user_roles =[
      'ROLE_SPU_OUTPATIENT_NURSE',
      'ROLE_NURSING_ADJUSTMENT_OTHERS',
      'ROLE_USER'
    ]

    @ss_user_roles =[
      'ROLE_SOCIAL_WORKER',
      'ROLE_USER'
    ]

    @validator_user_roles =[
      'ROLE_GU_NURSING_MANAGER',
      'ROLE_BILLING_ASSOCIATE',
      'ROLE_BUDGET_OFFICER',
      'ROLE_USER'
    ]

    @or_validator_user_roles =[
      'ROLE_DRUG_ORDER_VALIDATION',
      'ROLE_SPU_NURSING_MANAGER',
      'ROLE_SPU_OUTPATIENT_NURSE'
    ]

    @gu_user_roles =[
     'ROLE_DRUG_ORDER_VALIDATION',
     'ROLE_NURSING_ADJUSTMENT_ANCILLARY',
     'ROLE_NURSING_ADJUSTMENT_CSS',
     'ROLE_NURSING_ADJUSTMENT_FNB',
     'ROLE_NURSING_ADJUSTMENT_OTHERS',
     'ROLE_NURSING_ADJUSTMENT_PHARMACY',
     'ROLE_NURSING_GENERAL_UNITS',
     'ROLE_NURSING_VALIDATE',
     'ROLE_PACKAGE_ADJUSTMENT',
     'ROLE_SPECIAL_ORDERS',
     'ROLE_USER'
    ]

    @dastech_user_roles =[
      'ROLE_NURSING_ADJUSTMENT_CSS',
      'ROLE_ARMS_DAS_TECHNOLOGIST',
      'ROLE_DAS_TECHNOLOGIST',
      'ROLE_NURSING_ADJUSTMENT_PHARMACY',
      'ROLE_NURSING_ADJUSTMENT_ANCILLARY',
      'ROLE_DAS_ONESTOP_SHOP',
      'ROLE_SPECIAL_ORDERS',
      'ROLE_LATE_TRANSACTION',
      'ROLE_ACCOUNTING_STAFF',
      'ROLE_DAS_ADMIN_STAFF',
      'ROLE_ANCILLARY_READERS_FEE',
      'ROLE_USER'
    ]

    @supplies_user_roles =[
     'ROLE_CSS_CASHIER',
     'ROLE_CSS_OXYGEN_MONITORING',
     'ROLE_NURSING_ADJUSTMENT_CSS',
     'ROLE_OSS_SPECIAL_ORDERING',
     'ROLE_POS_ADJUSTMENT_CSS',
     'ROLE_RPT_PBA_CASHIERS',
     'ROLE_RPT_USER',
     'ROLE_USER'
    ]

    @inhouse_user_roles =[
      'ROLE_ENDORSEMENT_TAGGING',
      'ROLE_INHOUSE_SERVICES',
      'ROLE_USER'
    ]

    @hoa_user_roles =[
      'ROLE_NURSING_GENERAL_UNITS',
      'ROLE_USER'
    ]

    @file_maintenance_user_roles =[
      'ROLE_FILE_MAINTENANCE',
      'ROLE_FILE_MAINTENANCE_AOP',
      'ROLE_FILE_MAINTENANCE_BUDGET',
      'ROLE_FILE_MAINTENANCE_BUSINESS_PARTNER',
      'ROLE_FILE_MAINTENANCE_CREDIT_CARD',
      'ROLE_FILE_MAINTENANCE_DEPENDENCIES',
      'ROLE_FILE_MAINTENANCE_DIAGNOSIS',
      'ROLE_FILE_MAINTENANCE_DOCTOR',
      'ROLE_FILE_MAINTENANCE_MEDICATION_FREQUENCY',
      'ROLE_FILE_MAINTENANCE_PHARMACY',
      'ROLE_FILE_MAINTENANCE_ROOM_BOARD',
      'ROLE_FILE_MAINTENANCE_WAREHOUSE',
      'ROLE_ICD10_MANAGER',
      'ROLE_USER'
    ]

    @miscellaneous_user_roles =[
      'ROLE_MISC_CASHIER'
    ]

    @css_user_roles =[
      'ROLE_NURSING_ADJUSTMENT_CSS',
      'ROLE_CSS_CASHIER',
      'ROLE_POS_ADJUSTMENT_CSS',
      'ROLE_CSS_OXYGEN_MONITORING',
      'ROLE_PHARMACY_COMPOUNDED',
      'ROLE_USER'
    ]

  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Admin login"  do
    slmc.login("exist","123qweadmin").should be_true
  end

#  it "Add new spec users" do
#    @users.each do |user, org_code|
#      add_spec_users(user, org_code)
#    end
#  end
#
#  it "Adds additional pba users" do
#    @additional_pba_users.each do |user, org_code|
#      add_additional_pba_users(user, org_code)
#    end
#  end
#
#  it "Adds additional pba2 users" do
#    @additional_pba2_users.each do |user, org_code|
#      add_additional_pba2_users(user, org_code)
#    end
#  end
#
#  it "Adds additional partial discount pba users" do
#    @additional_partial_discount_users.each do |user, org_code|
#      add_additional_pba_users(user, org_code)
#    end
#  end
#
#  it "Add additional or users" do
#    @additional_or_users.each do |user, org_code|
#      add_additional_or_users(user, org_code)
#    end
#  end
#
#  it "Add additional adm users" do
#    @additional_adm_users.each do |user, org_code|
#      add_additional_adm_users(user, org_code)
#    end
#  end
#
#  it "Adds additional er users" do
#    @additional_er_users.each do |user, org_code|
#      add_additional_er_users(user, org_code)
#    end
#  end
#
#  it "Add additional pharmacy users" do
#    @additional_pharmacy_users.each do |user, org_code|
#      add_additional_pharmacy_users(user, org_code)
#    end
#  end
#
#  it "Add additional oss users" do
#    @additional_oss_users.each do |user, org_code|
#      add_additional_oss_users(user, org_code)
#    end
#  end
#
#  it "Add additional oss2 users" do
#    @additional_oss2_users.each do |user, org_code|
#      add_additional_oss2_users(user, org_code)
#    end
#  end
#
#  it "Add additional wellness users" do
#    @additional_wellness_users.each do |user, org_code|
#      add_additional_wellness_users(user, org_code)
#    end
#  end
#
#  it "Add additional fnb users" do
#    @additional_fnb_users.each do |user, org_code|
#      add_additional_fnb_users(user, org_code)
#    end
#  end
#
#  it "Add additional arms users" do
#    @additional_arms_users.each do |user, org_code|
#      add_additional_arms_users(user, org_code)
#    end
#  end
#
#  it "Add additional dastech users" do
#    @additional_dastech_users.each do |user, org_code|
#      add_additional_dastech_users(user, org_code)
#    end
#  end
#
#  it "Add additional armsdastech users" do
#    @additional_armsdastech_users.each do |user, org_code|
#      add_additional_armsdastech_users(user, org_code)
#    end
#  end
#
#  it "Add additional readers fee users" do
#    @additional_readers_fee_users.each do |user, org_code|
#      add_additional_readers_fee_users(user, org_code)
#    end
#  end
#
#    it "Add additional dr users" do
#    @additional_dr_users.each do |user, org_code|
#      add_additional_dr_users(user, org_code)
#    end
#  end
#
#  it "Add additional inhouse users" do
#    @additional_inhouse_users.each do |user, org_code|
#      add_additional_inhouse_users(user, org_code)
#    end
#  end
#
#  it "Add additional supplies users" do
#    @additional_supplies_users.each do |user, org_code|
#      add_additional_supplies_users(user, org_code)
#    end
#  end
#
#  it "Add additional hoa users" do
#    @additional_hoa_users.each do |user, org_code|
#      add_additional_hoa_users(user, org_code)
#    end
#  end
#
#  it "Add additional social service users" do
#    @additional_ss_users.each do |user, org_code|
#      add_additional_ss_users(user, org_code)
#    end
#  end
#
#  it "Add validator users" do
#    @validator_users.each do |user, org_code|
#      add_validator_users(user, org_code)
#    end
#  end
#
#  it "Add additional or validators" do
#    @or_validator_users.each do |user, org_code|
#      add_or_validator_users(user, org_code)
#    end
#  end
#  it "Add additional gu validators" do
#    @additional_gu_users.each do |user, org_code|
#      add_gu_users(user, org_code)
#    end
#  end
#  it "Add additional css users" do
#    @additional_css_users.each do |user, org_code|
#      add_css_users(user, org_code)
#    end
#  end


############################## METHODS ########################

  def add_additional_adm_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @adm_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_pba_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @pba_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_pba2_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @pba2_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_partial_discount_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @partial_discount_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_or_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @or_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_er_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @er_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_oss_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @oss_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_oss2_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @oss2_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_pharmacy_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @pharmacy_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_wellness_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @wellness_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_fnb_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @fnb_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_arms_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @arms_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_armsdastech_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @armsdastech_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_validator_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @validator_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_or_validator_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @or_validator_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_gu_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @gu_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_dr_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @dr_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_hoa_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @hoa_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_ss_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @ss_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_dastech_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @dastech_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_supplies_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @supplies_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_inhouse_users(user ,key)
    slmc.add_new_user_with_roles(:user => user, :roles => @inhouse_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_additional_readers_fee_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @readers_fee_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_css_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :roles => @css_user_roles, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

  def add_spec_users(user, key)
    slmc.add_new_user_with_roles(:user => user, :all_roles => true, :osf_key => key)
    puts "#{user} already exists!" if slmc.is_element_present("errorMessages")
    puts "Successfully added #{user}" if !(slmc.is_element_present("errorMessages"))
  end

#### used to edit roles on a user #### activate only if roles are incorrect
#  it "Edit spec roles" do
#    @additional_adm_users.each do |user, org_code|
#      slmc.edit_spec_roles(:user => user, :all_roles => @adm_user_roles)
#      puts("Successfully edited roles of #{user}")
#    end
#  end

########

#  def create_users_yaml_file
#    users = ""
#    @users.each do |user, org|
#      users << "{#{user}: #{user}\n"
#    end
#
#    begin
#      File.open("spec_users.yml","w+") {|f| f.write users}
#      puts "Successfully created spec_users.yml file"
#    rescue Exception => e
#      STDERR.puts "Unable to create spec_users.yml file due to: #{e}"
#    end
#  end
end
