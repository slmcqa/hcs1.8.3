#require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
require 'spec_helper'
require 'yaml'
require 'ruby-plsql'
require 'permutation'


describe "Testdata" do
  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser" #123qweuser"

    @patient = Admission.generate_data
    @oss_patient = Admission.generate_data
    @or_patient = Admission.generate_data
    @dr_patient = Admission.generate_data
    @er_patient = Admission.generate_data
    @wellness_patient1 = Admission.generate_data
    @wellness_patient2 = Admission.generate_data

    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient[:age])
    @@promo_discount2 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@oss_patient[:age])
    @@promo_discount3 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@or_patient[:age])
    @@promo_discount4 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@dr_patient[:age])
    @@promo_discount5 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@er_patient[:age])
    @@promo_discount6 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@wellness_patient1[:age])
    @@promo_discount7 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@wellness_patient2[:age])

    #"5c456b0314b9013d321e5f917a3a4aa3d6235dab"
    if CONFIG['db_sid'] == "QAFUNC"
            @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
            @pba_user = "ldcastro" #"sel_pba7"
            @or_user =  "slaquino"     #"or21"
            @oss_user = "jtsalang"  #"sel_oss7"
            @dr_user = "jpnabong" #"sel_dr4"
            @er_user =  "jtabesamis"   #"sel_er4"
            @wellness_user = "ragarcia-wellness" # "sel_wellness2"
            @gu_user_0287 = "gycapalungan"
            @pharmacy_user =  "cmrongavilla"
    else
            @user = "fcdeleon"  #"billing_spec_user3"  #admission_login#
            @pba_user = "dmgcaubang" #"sel_pba7"
            @or_user =  "amlompad"     #"or21"
            @oss_user = "kjcgangano-pet"  #"sel_oss7"
            @dr_user = "aealmonte" #"sel_dr4"
            @er_user =  "asbaltazar"   #"sel_er4"
            @wellness_user = "emllacson-wellness" # "sel_wellness2"
            @gu_user_0287 = "ajpsolomon"
    end
    

    @room_rate = 4167.0
    #@drugs = {"040800031" => 1, "040860043" => 1, "041840008" => 1, "041844322" => 1, "042000061" => 1, "042090007" => 1, "044810074" => 1, "047632803" => 1, "048414006" => 1, "048470011" => 1, "049000028" => 1, "040010002" => 1} # 12
    #@drugs = {"048459911" => 1,"045260049" => 1,"044006788" => 1,	"044000123" => 1,	"042450007" => 1,	"044009992" => 1,	"044810007" => 1,	"048839002" => 1,	"040700049" => 1,	"048870007" => 1,	"044005581" => 1,	"040884317" => 1,	"042410010" => 1,	"045640003" => 1,	"042400011" => 1,	"044820089" => 1,	"048410016" => 1,	"042004363" => 1,	"043010015" => 1,	"042040011" => 1,	"042422509" => 1,	"042090002" => 1,	"042422514" => 1,	"042000162" => 1,	"040860039" => 1}
    @drugs =    {"040010062" => 1,	"040700096" => 1,	"040800013" => 1,	"040800038" => 1,	"040823379" => 1,	"040823386" => 1,	"040823390" => 1,	"040824337" => 1,	"040850025" => 1,	"040880012" => 1,	"040950597" => 1,	"041020081" => 1,	"041020083" => 1,	"041036708" => 1,	"041070045" => 1,	"041824341" => 1,	"041850020" => 1,	"042000787" => 1,	"042000808" => 1,	"042000818" => 1,	"042008708" => 1,	"042008720" => 1,	"042008736" => 1,	"042008740" => 1,	"042008760" => 1,	"042407709" => 1,	"042427139" => 1,	"042430033" => 1,	"042460026" => 1,	"042460034" => 1,	"042497657" => 1,	"042804897" => 1,	"042824882" => 1,	"042834969" => 1,	"042834971" => 1,	"042840213" => 1,	"042870012" => 1,	"042903026" => 1,	"042944115" => 1,	"043610016" => 1,	"044009959" => 1,	"044010017" => 1,	"044010047" => 1,	"044010049" => 1,	"044010058" => 1,	"044818109" => 1,	"044830023" => 1,	"045260042" => 1,	"045616080" => 1,	"046960022" => 1,	"048004339" => 1,	"048020010" => 1,}
    @ancillary = {"010000317" => 1, "010000212" => 1, "010001039" => 1, "010000211" => 1} # 4
    @supplies = {"085100003" => 1, "089100004" => 1, "080100021" => 1, "080100023" => 1} # 4
    
    
 #  @ancillary1 =  {"010000000" => 1,	"010000003" => 1,	"010000007" => 1,	"010000008" => 1,	"010000015" => 1,	"010000021" => 1,	"010000034" => 1,	"010000036" => 1,	"010000040" => 1,	"010000054" => 1,	"010000130" => 1,	"010000131" => 1,	"010000070" => 1,	"010000076" => 1,	"010000082" => 1,	"010000097" => 1,	"010000098" => 1,	"010003814" => 1,	"010000111" => 1,	"010000115" => 1,	"010000116" => 1,	"010000127" => 1,	"010004054" => 1,	"010004072" => 1,	"010004242" => 1,	"010004049" => 1,	"010004071" => 1,	"010004064" => 1,	"010000010" => 1,	"010000012" => 1,	"010000028" => 1,	"010000038" => 1,	"010000046" => 1,	"010000059" => 1,	"010000064" => 1,	"010000132" => 1,	"010000087" => 1,	"010000088" => 1,	"010000072" => 1,	"010000079" => 1,	"010000083" => 1,	"010000084" => 1,	"010000096" => 1,	"010000107" => 1,	"010000117" => 1,	"010000128" => 1,	"010000121" => 1,	"010000122" => 1,	"010002595" => 1,	"010004250" => 1,	"010004053" => 1,	"010004124" => 1,	"010004060" => 1,	"010004068" => 1,	"010004069" => 1,	"010004056" => 1,	"010004061" => 1,	"010004062" => 1,	"010003870" => 1,	"010000026" => 1,	"010000027" => 1,	"010000047" => 1,	"010000048" => 1,	"010000060" => 1,	"010000095" => 1,	"010000108" => 1,	"010000119" => 1,	"010000125" => 1,	"010000126" => 1,	"010003509" => 1,	"010004051" => 1,	"010003852" => 1,	"010004238" => 1,	"010004050" => 1,	"010004046" => 1,	"010004165" => 1,	"010000011" => 1,	"010000014" => 1,	"010000018" => 1,	"010000025" => 1,	"010000039" => 1,	"010000055" => 1,	"010000057" => 1,	"010000058" => 1,	"010000063" => 1,	"010000129" => 1,	"010000134" => 1,	"010000086" => 1,	"010000068" => 1,	"010000069" => 1,	"010000074" => 1,	"010000077" => 1,	"010000092" => 1,	"010000102" => 1,	"010000112" => 1,	"010000114" => 1,	"010000118" => 1,	"010003510" => 1,	"010004258" => 1,	"010004045" => 1,	"010004059" => 1,	"010004055" => 1,	"010000009" => 1,	"010000022" => 1,	"010000030" => 1,	"010000041" => 1,	"010000053" => 1,	"010000062" => 1,	"010000075" => 1,	"010000078" => 1,	"010000094" => 1,	"010000106" => 1,	"010004052" => 1,	"010004151" => 1,	"010004070" => 1,	"010004063" => 1,	"010004065" => 1,	"010004057" => 1,	"010004161" => 1,	"010004162" => 1,	"010004164" => 1,	"010000005" => 1,	"010000013" => 1,	"010000023" => 1,	"010000024" => 1,	"010000029" => 1,	"010000032" => 1,	"010000035" => 1,	"010000044" => 1,	"010000050" => 1,	"010000052" => 1,	"010002593" => 1,	"010000067" => 1,	"010000101" => 1,	"010000103" => 1,	"010000105" => 1,	"010004066" => 1,	"010004048" => 1,	"010000001" => 1,	"010000006" => 1,	"010000016" => 1,	"010000037" => 1,	"010000042" => 1,	"010000045" => 1,	"010000049" => 1,	"010000056" => 1,	"010000061" => 1,	"010000133" => 1,	"010000135" => 1,	"010000066" => 1,	"010000071" => 1,	"010000089" => 1,	"010000091" => 1,	"010000093" => 1,	"010000109" => 1,	"010000120" => 1,	"010000123" => 1,	"010003625" => 1,	"010004047" => 1,	"010004073" => 1,	"010004058" => 1,	"010004067" => 1,	"010004038" => 1,	"010002594" => 1,	"010000002" => 1,	"010000004" => 1,	"010000017" => 1,	"010000031" => 1,	"010000033" => 1,	"010000043" => 1,	"010000051" => 1,	"010000065" => 1,	"010000073" => 1,	"010000080" => 1,	"010000081" => 1,	"010000085" => 1,	"010000090" => 1,	"010000099" => 1,	"010000100" => 1,	"010000104" => 1,	"010000110" => 1,	"010004163" => 1,}
    
    
#    @drugs = {"048459911" => 1} #ORT02 discount_scheme = 'COMIPLDT001' walang ORT02
#    @ancillary = {"010000317" => 1}
#    @supplies = {"085100003" => 1}
    
   # @ancillary = {"010000003" => 1} #ORT01
#
#    @sel_dr_validator = "msgepte"
#    @@nursing=   {"0301" => 20}#, "0292" => 20, "0332" => 20}#, "0278" => 58, "0279" => 55, "0280" => 32, "0281" => 39, "0283" => 37, "0284" => 35, "0285" => 47, "0286" => 63, "0287" => 38, "0288" => 32, "0289" => 45, "0290" => 33, "0291" => 53, "0292" => 37, "0293" => 54, "0294" => 34, "0295" => 56, "0296" => 50, "0298" => 19, "0299" => 3, "0300" => 6, "0301" => 8, "0302" => 4, "0304" => 21, "0305" => 14, "0307" => 18, "0327" => 8}

#"0164" => 50,  "0167" => 50, "0170" => 64, "0171" => 2, "0173" => 72, "0174" => 40, "0176" => 10,


  end
  after(:all) do
#    slmc.logout
    slmc.close_current_browser_session
  end
  it "login" do
# perm = Permutation.for("abc")
# puts perm.map { |p| p.project }
# a = perm.count
# puts "a - #{a}"

# a = (Time.now + 10*60*60).strftime("%m/%d/%Y")    
a =  (Time.now + (24*60*60)).strftime("%m/%d/%Y")      
puts a
#                 Database.connect
#                  q = "SELECT PIN FROM SLMC.TXN_PATMAS WHERE GENDER = 'F'"
#               #  number = AdmissionHelper.range_rand(1,29).to_i
##puts "number #{number}"                  
#                  pin = Database.select_statement q
#        #          pin = pin[number]
#                  Database.logoff       
#                  puts " pin = #{pin}"

#puts "a = #{a}"

    

#
#
 # => ["abc", "acb", "bac", "bca", "cab", "cba"]
#             #slmc.login("adm1", @password)
#             slmc.open "/"
#                 type   	'id=username', "username"
#    type 'id=password', "password"
#             slmc.admission_search(:pin => "1")
#visit_number = "5606000061"
#performing_unit = '0036'
#        Database.connect
#    q = "select * from CTRL_APP_USER where username = 'gu_spec_user6'"
#    details = []
#    record = Database.select_all_statement q
#    puts "record - #{record}"
#    details.push record
#    puts "details - #{details}"
#    Database.logoff
#    puts @data1[1]
#    

#        slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pin = slmc.create_new_patient(Admission.generate_data)
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin)
#    slmc.create_new_admission(:room_charge => "REGULAR PRIVATE", :rch_code => 'RCH08', :org_code => '0287', :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
#    puts "@@pin - #{@@pin}"
#    sleep 6

#    Database.connect
#    q = "select ORDER_GRP_NO,CI_NO from TXN_OM_ORDER_GRP where VISIT_NO = '#{visit_number}' and PERFORMING_UNIT = '#{performing_unit}'"
#    details = []
#    record = Database.select_all_statement q
#    details.push record
#    puts "details - #{details}"
#    puts "record - #{record}"
#    Database.logoff
# #   return record
# @data1 = record
# puts "@data1 - #{@data1[1]}"
  end
# it "should desc" do
#      @@nursing.each do |nurse_unit,n|
#          x =0
#          while x!=n
#                  @patient1 = Admission.generate_data
#                   nursing_unit = nurse_unit
#                   slmc.login("10thnw", @password).should be_true
#                   slmc.admission_search(:pin => "1")
#                   @@pba_pin1 = slmc.create_new_patient(@patient1) #.merge!(:gender => "M"))
#                   slmc.admission_search(:pin => @@pba_pin1)
#                   room_charge = "RCH08" if nursing_unit !="0174"
#                   room_charge = "RCHSP" if nursing_unit =="0174"
#                   slmc.create_new_admission(:rch_code => room_charge, :room_charge => "REGULAR PRIVATE",:org_code => nursing_unit, :diagnosis => "GASTRITIS", :account_class => "INDIVIDUAL", :guarantor_code => "ABSC001").should == "Patient admission details successfully saved."
#                   sleep 6
#                   puts @@pba_pin1
#                   x += 1
#
#          end
#      end
#  end
## it "should" do
##   
##    
###       Database.connect
###    t = "SELECT OR_NUMBER FROM SLMC.TXN_PBA_PAYMENT_HDR WHERE PAYMENT_TRANS_HDR_NO IN (SELECT MAX(PAYMENT_TRANS_HDR_NO) FROM SLMC.TXN_PBA_CHECK_DTL)"
###    myor_no = Database.select_all_statement t
###    Database.logoff
###    myor_no = myor_no[0]
###
###    puts myor_no 
###   item = "010000771"
###                       Database.connect
###                        d = "SELECT SUM(RATE) FROM SLMC.REF_PC_MASTER_SERVICE A JOIN SLMC.REF_PC_SERVICE B ON A.MSERVICE_CODE = B.MSERVICE_CODE JOIN SLMC.REF_PC_SERVICE_RATE C ON B.SERVICE_CODE = C.SERVICE_CODE WHERE A.MSERVICE_CODE = '#{item}' AND C.ROOM_CLASS = 'RCL02'"
###                        puts d
###                    dd = Database.select_last_statement  d
###                    puts dd
###                    dd = dd.to_f
###                    puts dd
###                    
###                    Database.logoff    
###   slmc.login(@user, @password).should be_true
###    slmc.admission_search(:pin => "1")
###   # @@pba_pin1 = slmc.create_new_patient(@patient.merge!(:gender => "M"))    :not_senior => true)
###    #slmc.login(@user, @password).should be_true
###    slmc.admission_search(:pin => @@pba_pin1)
###    slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0287', :diagnosis => "GASTRITIS", :account_class => "INDIVIDUAL").should == "Patient admission details successfully saved."
###    puts @@pba_pin1
#  end
# it "Patient1 - Orders items" do
##   @@pba_pin1 = "1602140673"
##    slmc.login("gbbalisong", @password).should be_true
##    slmc.nursing_gu_search(:pin => @@pba_pin1)
##    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pba_pin1)
##    @drugs.each do |drug, q|
##      slmc.search_order(:description => drug, :drugs => true).should be_true
##      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
##    end
##    @ancillary.each do |anc, q|
##      slmc.search_order(:description => anc, :ancillary => true).should be_true
##      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
##    end
##    @supplies.each do |supply, q|
##      slmc.search_order(:description => supply, :supplies => true).should be_true
##      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
##    end
##    sleep 5
###    slmc.verify_ordered_items_count(:drugs => 1).should be_true
###    slmc.verify_ordered_items_count(:supplies => 1).should be_true
###    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
##    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
##    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple") #.should == 3
##    slmc.confirm_validation_all_items.should be_true
##    puts @@pba_pin1
#  end
# it "Patient1 - ORDER 2" do
##      @ancillary1 =  {"010000000" => 1,	"010000003" => 1,	"010000007" => 1,	"010000008" => 1,	"010000015" => 1,	"010000021" => 1,	"010000034" => 1,	"010000036" => 1,	"010000040" => 1,	"010000054" => 1,	"010000130" => 1,	"010000131" => 1,	"010000070" => 1,	"010000076" => 1,	"010000082" => 1,	"010000097" => 1,	"010000098" => 1,	"010003814" => 1,	"010000111" => 1,	"010000115" => 1,	"010000116" => 1,	"010000127" => 1,	"010004054" => 1,	"010004072" => 1,	"010004242" => 1,	"010004049" => 1,	"010004071" => 1,	"010004064" => 1,	"010000010" => 1,	"010000012" => 1,	"010000028" => 1,	"010000038" => 1,	"010000046" => 1,	"010000059" => 1,	"010000064" => 1,	"010000132" => 1,	"010000087" => 1,	"010000088" => 1,	"010000072" => 1,	"010000079" => 1,	"010000083" => 1,	"010000084" => 1,	"010000096" => 1,	"010000107" => 1,	"010000117" => 1,	"010000128" => 1,	"010000121" => 1,	"010000122" => 1,	"010002595" => 1,	"010004250" => 1,	"010004053" => 1,	"010004124" => 1,	"010004060" => 1,	"010004068" => 1,	"010004069" => 1,	"010004056" => 1,	"010004061" => 1,	"010004062" => 1,	"010003870" => 1,	"010000026" => 1,	"010000027" => 1,	"010000047" => 1,	"010000048" => 1,	"010000060" => 1,	"010000095" => 1,	"010000108" => 1,	"010000119" => 1,	"010000125" => 1,	"010000126" => 1,	"010003509" => 1,	"010004051" => 1,	"010003852" => 1,	"010004238" => 1,	"010004050" => 1,	"010004046" => 1,	"010004165" => 1,	"010000011" => 1,	"010000014" => 1,	"010000018" => 1,	"010000025" => 1,	"010000039" => 1,	"010000055" => 1,	"010000057" => 1,	"010000058" => 1,	"010000063" => 1,	"010000129" => 1,	"010000134" => 1,	"010000086" => 1,	"010000068" => 1,	"010000069" => 1,	"010000074" => 1,	"010000077" => 1,	"010000092" => 1,	"010000102" => 1,	"010000112" => 1,	"010000114" => 1,	"010000118" => 1,	"010003510" => 1,	"010004258" => 1,	"010004045" => 1,	"010004059" => 1,	"010004055" => 1,	"010000009" => 1,	"010000022" => 1,	"010000030" => 1,	"010000041" => 1,	"010000053" => 1,	"010000062" => 1,	"010000075" => 1,	"010000078" => 1,	"010000094" => 1,	"010000106" => 1,	"010004052" => 1,	"010004151" => 1,	"010004070" => 1,	"010004063" => 1,	"010004065" => 1,	"010004057" => 1,	"010004161" => 1,	"010004162" => 1,	"010004164" => 1,	"010000005" => 1,	"010000013" => 1,	"010000023" => 1,	"010000024" => 1,	"010000029" => 1,	"010000032" => 1,	"010000035" => 1,	"010000044" => 1,	"010000050" => 1,	"010000052" => 1,	"010002593" => 1,	"010000067" => 1,	"010000101" => 1,	"010000103" => 1,	"010000105" => 1,	"010004066" => 1,	"010004048" => 1,	"010000001" => 1,	"010000006" => 1,	"010000016" => 1,	"010000037" => 1,	"010000042" => 1,	"010000045" => 1,	"010000049" => 1,	"010000056" => 1,	"010000061" => 1,	"010000133" => 1,	"010000135" => 1,	"010000066" => 1,	"010000071" => 1,	"010000089" => 1,	"010000091" => 1,	"010000093" => 1,	"010000109" => 1,	"010000120" => 1,	"010000123" => 1,	"010003625" => 1,	"010004047" => 1,	"010004073" => 1,	"010004058" => 1,	"010004067" => 1,	"010004038" => 1,	"010002594" => 1,	"010000002" => 1,	"010000004" => 1,	"010000017" => 1,	"010000031" => 1,	"010000033" => 1,	"010000043" => 1,	"010000051" => 1,	"010000065" => 1,	"010000073" => 1,	"010000080" => 1,	"010000081" => 1,	"010000085" => 1,	"010000090" => 1,	"010000099" => 1,	"010000100" => 1,	"010000104" => 1,	"010000110" => 1,	"010004163" => 1,}
##
###    slmc.go_to_general_units_page
###    slmc.clinically_discharge_patient(:pin => @@pba_pin1, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
##   @@pba_pin1 = "1602140673"
##    slmc.login("gbbalisong", @password).should be_true
##    slmc.nursing_gu_search(:pin => @@pba_pin1)
##    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pba_pin1)
##    
##    @ancillary1.each do |anc, q|
##      slmc.search_order(:description => anc, :ancillary => true).should be_true
##      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
##    end
##    sleep 5
##    slmc.validate_orders(:ancillary => true,:orders => "multiple") #.should == 3
##    slmc.confirm_validation_all_items.should be_true
##    puts @@pba_pin1        
#  end
# it "check cas" do
#   
#             Database.connect
#            t = "SELECT EMPLOYEE,EMAIL,ORGSTRUCTURE FROM SLMC_CAS.CTRL_APP_USER  WHERE USERNAME <> 'casadmin'"
#            pf = Database.select_all_rows t
#            
#            a = "SELECT COUNT(*) FROM SLMC_CAS.CTRL_APP_USER WHERE USERNAME <> 'casadmin'"
#            c = Database.select_last_statement a
#            
#     Database.logoff
#     all = c
#     count = all.to_i
#   #  puts pf
#     #pf = pf[1]
#    # puts "all -#{all}"
#   #  puts "pf -#{pf}"
#     #employee = 
##          employee_id = pf[1]
##        puts employee_id
#    while count != 0
#        sam[] = Database.get_user_name
#        employee_id = sam[:employee_id].row(count)
#        email = sam[:email].(count)
#        orgstructure = sam[:orgstructure].(count)
#        puts "#{employee_id} - #{email} - #{orgstructure}"
#        count = count - 1
#    end
#    
#  end
#  it "add - patient" do
#     x =10
#     count = 1
#          while x!=n
#                  @patient1 = Admission.generate_data
#                   slmc.login(@user, @password).should be_true
#                   slmc.admission_search(:pin => "1")
#                   @@pba_pin1 = slmc.create_new_patient(@patient1) #.merge!(:gender => "M"))
#                   slmc.admission_search(:pin => @@pba_pin1)
#                   slmc.create_new_admission(:rch_code => "RCH07", :room_charge => "REGULAR PRIVATE",:org_code => '0287', :diagnosis => "GASTRITIS", :account_class => "INDIVIDUAL", :guarantor_code => "ABSC001").should == "Patient admission details successfully saved."
#                   sleep 6
#                   
#                   puts "Inpatient #{count} - #{@@pba_pin1}"
#                   count = count + 1
#                   x += 1
#          end
#          
#         while x!=n
#                  @patient1 = Admission.generate_data
#                  slmc.login(@oss_user, @password).should be_true
#                  slmc.go_to_das_oss
#                  slmc.patient_pin_search(:pin => "test")
#                  slmc.click_outpatient_registration.should be_true
#                  @@pin = (slmc.oss_outpatient_registration(@patient1)).gsub(' ','').should be_true
#                  puts "Inpatient #{count} - #{@@pin}"
#                   count = count + 1
#                   x += 1
#        end
#  end 
  end

  