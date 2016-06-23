require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: OSS - Philhealth Module Test - Normal Case (1st - 9th Availment)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
#    @selenium_driver.evaluate_rooms_for_admission('0164','RCHSP')
    @selenium_driver.start_new_browser_session

    #@oss_user = USERS['oss_philhealth_normal_spec_user1']
    @oss_user = "sel_oss2"
    @pba_user = "sel_pba17"
    @password = "123qweuser"

    # @all_oss_items = {"010000317" =>1, "010000212" =>1, "010001039"=>1, "010000211"=>1,"010000160"=>1, "010000008"=>1, "010000003"=>1,  "010000600"=>1, "010000611"=>1}
    #items to be ordered
    #1st availment
    @ancillary1 =
      {
      "010000317" => 1, #QUALITATIVE PROPOXYPHENE
      "010000212" => 1, #ACID PHOSPHATASE
      "010001039" => 1, #URINALYSIS
      "010000211" => 1 #ACETAMINOPHEN
    }
    @operation1 = {"010000160" => 1} #POLARIZING MICROSCOPY

  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


  it "should desc" do

     @@orders1 =  @ancillary1.merge(@operation1)
     sam = @@orders1.count
      puts sam
#           x = 1
#                 @@comp_drugs = 0
      @@comp_xray_lab = 0
      @@comp_operation = 0
      @@comp_others = 0
      @@comp_supplies = 0
      @@non_comp_drugs = 0
      @@non_comp_drugs_mrp_tag = 0
      @@non_comp_xray_lab = 0
      @@non_comp_operation = 0
      @@non_comp_others = 0
      @@non_comp_supplies = 0
#           order = @@orders1.count
#             puts order
      @@orders1.each do |order,n|

#      while sam != 0
            #order = @@orders1.count
            #order = @@orders1.keys
        item = PatientBillingAccountingHelper::Philhealth.get_order_details_based_on_order_number(order)
        if item[:ph_code] == "PHS01"
          amt = item[:rate].to_f * n
          @@comp_drugs += amt  # total compensable drug
        end
        if item[:ph_code] == "PHS06"
          n_amt = item[:rate].to_f * n
          @@non_comp_drugs += n_amt # total non-compensable drug
        end
        if item[:ph_code] == "PHS02"
          x_lab_amt = item[:rate].to_f * n
          @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
        end
        if item[:ph_code] == "PHS07"
          x_lab_amt = item[:rate].to_f * n
          @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
        end
        if item[:ph_code] == "PHS03"
          o_amt = item[:rate].to_f * n
          o_amt = item[:rate].to_f * n
          @@comp_operation += o_amt  # total compensable operations
        end
        if item[:ph_code] == "PHS10"
          s_amt = item[:rate].to_f * n
          @@non_comp_supplies += s_amt  # total non compensable supplies
        end
        sam = sam -1
      end
      puts amt

  end
end

