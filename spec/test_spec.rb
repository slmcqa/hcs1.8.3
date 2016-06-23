require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
#require File.expand_path(File.dirname(__FILE__)) + 'C:/jruby-9.0.0.0.rc1/lib/ruby/gems/shared/gems/sikuli-0.3.0'
#require File.expand_path(File.dirname(__FILE__)) + 'C:/Ruby193/lib/ruby/gems/1.9.1/gems/sikuli-0.3.0/lib/sikuli.rb'
#!/usr/bin/env jruby
#require File.dirname(__FILE__) + '/../lib/slmc'

#require "rspec"

#require 'selenium/rake/tasks'
#require 'spec/rake/spectask'
#require 'fileutils'
#require 'yaml'
#require "net/http"
#require 'spec_helper'
#require 'yaml'
#require 'faker'
#require 'oci8'
#require 'rubygems'
#gem "rspec", "<=1.2.9"
#equire 'selenium-webdriver'
gem "sikuli", "<=0.3.0"   
require 'sikuli'
#require 'rubygems/package_task'
#require 'win32/taskscheduler'
#require 'rpdfbox'

#require 'win32/sound'
#include Win32
#require "multi_json"
#require "selenium-webdriver"

#include 'rake'
#require 'selenium/rake/tasks'
#require 'spec/rake/spectask'
#require 'fileutils'
#require 'yaml'
#require "net/http"
#require "ruby2jar"
#Srequire 'syscmd'

describe "test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
#    @selenium_driver = SLMC.new
#    @selenium_driver.start_new_browser_session
     @@rs = Sikuli::Screen.new
#    @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
    #@pba_user = "ldcastro" #"sel_pba7"
#    @or_user =  "slaquino"     #"or21"
#    @oss_user = "jtsalang"  #"sel_oss7"
#    @dr_user = "jpnabong" #"sel_dr4"
#    @er_user =  "jtabesamis"   #"sel_er4"
#    @wellness_user = "ragarcia-wellness" # "sel_wellness2"
#    @inhouse_user = "sel_inhouse1"
#    @gu_user_0287 = "gycapalungan"
#
#    @doctors = ["6726","0126","6726","0126"]
#    @@room_rate = 4167.0
#
#    @patient = Admission.generate_data
#    @drugs1 =  {"040004334" => 1}
#    @ancillary1 = {"010001634" => 1}
#    @supplies1 = {"080200000" => 1}
#
#    @drugs2 =  {"040010009" => 1}
#    @ancillary2 = {"010002840" => 1}
#    @supplies2 = {"269401035" => 1}
#
#
#
#    @password = "123qweuser"
    #@driver = Selenium::WebDriver.for(:remote =>  SLMC.new)
#   @driver = Selenium::WebDriver.for :firefox
##  @driver.get("http://www.google.com");
#  @driver.navigate.to = "http://192.168.137.153:2010/"
#    @accept_next_alert = true
#    @driver.manage.timeouts.implicit_wait = 30
#    @verification_errors = []




#      @user = "billing_spec_user2"
#
#    @password = "123qweuser"
#    @drugs =  {"040004334" => 1}
#    @ancillary = {"010000003" => 1}
#    @@orders = {"040004334" => 5, "040010002" => 1,"044810074" => 1}
#    @@nursing=   {"0164" => 50, "0165" => 50, "0167" => 50, "0170" => 64, "0171" => 2, "0173" => 72, "0174" => 40, "0176" => 10, "0246" => 50, "0272" => 21, "0278" => 58, "0279" => 55, "0280" => 32, "0281" => 39, "0283" => 37, "0284" => 35, "0285" => 47, "0286" => 63, "0287" => 38, "0288" => 32, "0289" => 45, "0290" => 33, "0291" => 53, "0292" => 37, "0293" => 54, "0294" => 34, "0295" => 56, "0296" => 50, "0298" => 19, "0299" => 3, "0300" => 6, "0301" => 8, "0302" => 4, "0304" => 21, "0305" => 14, "0307" => 18, "0327" => 8}

#
#
#          @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
#    @pba_user = "ldcastro" #"sel_pba7"
#    @or_user =  "slaquino"     #"or21"
#    @oss_user = "jtsalang"  #"sel_oss7"
#    @dr_user = "jpnabong" #"sel_dr4"
#    @er_user =  "jtabesamis"   #"sel_er4"
#    @wellness_user = "ragarcia-wellness" # "sel_wellness2"
#    @gu_user_0287 = "gycapalungan"

  end
   #@driver = Selenium::WebDriver.for :firefox
#  @driver.get("http://www.google.com");
#  @driver.navigate.to = "http://192.168.137.153:2010/"
#  @driver.quit
#  @verification_errors.should == []




  after(:all) do
#    slmc.logout
#    slmc.close_current_browser_session
  end


it "create test data" do

    
# slmc.login(@pba_user, @password).should be_true
  sleep 2

@@rs.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\image1.png")
@@rs.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\image2.png")
# `jruby ""C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\spec\\sikuli.rb""`
# `cd c:/`
#Syscmd.exec!(command)

#@@pin = "1503081319"
#    Database.connect
#    t = "SELECT CI_NO FROM SLMC.TXN_OM_ORDER_GRP WHERE VISIT_NO IN (SELECT VISIT_NO FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN = '#{@@pin}')"
#    myci_no = Database.select_all_statement t
#    Database.logoff
#    puts myci_no[0]
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
#    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#    slmc.skip_update_patient_information.should be_true
#    slmc.skip_room_and_bed_cancelation.should be_true
#    puts @@pin
#    slmc.click "id=btnPrint"
#    sleep 5
#
#    page.click "id=download"
#
#    slmc.open("C:\Users\15239\Downloads\document.pdf")
#    text = RPDFBox::TextExtraction.get_text_all("C:\\Users\\15239\\Downloads\\document.pdf")
#puts text
##  username = "threnodicthreats"
#  password = "bold185cram008"
##  secret_key = "sam"
##  consumer_key = "sam"
#  sam = Engine.new(username,password)
##
##  sam.signon(status, state)
#puts sam
##@@visit_no = "5503000521"
##    Database.connect
##        a =  "SELECT ORDER_DTL_NO  FROM TXN_OM_ORDER_DTL JOIN TXN_OM_ORDER_GRP ON TXN_OM_ORDER_DTL.ORDER_GRP_NO = TXN_OM_ORDER_GRP.ORDER_GRP_NO WHERE VISIT_NO = '#{@@visit_no}'"
##        @@order_dtl_no = Database.select_all_rows a
##    Database.logoff
##    n = @@order_dtl_no.length - 1
##    @@order_dtl_no.each do |item, q|
##
##              slmc.is_text_present(@@order_dtl_no[n])
##              n -= 1
##    end
#       # @@pin = "1502080044"
#      @@pin = "1404070483"
#            slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin)
#  #  @@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
#    @@visit_no1 = slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :save => true).should
#       Database.connect
#                  x = "SELECT TO_CHAR(COUNT(*)) FROM SLMC.TXN_PATMAS "
#                  mcount = Database.select_all_statement x
#       Database.logoff
#        puts "mcount #{mcount}"
#               count = mcount[0].to_i
#               puts "count  - #{count }"
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pin = slmc.create_new_patient(@patient)
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin)
#    puts @@pin
#    slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :account_class => "COMPANY", :diagnosis => "GASTRITIS", :guarantor_code => "ABSC001").should == "Patient admission details successfully saved."
#
#    slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
#    @@visit_no = slmc.get_text("//html/body/div[1]/div[2]/div[2]/div[8]/div[2]/div[3]/div[1]/label")
#    @@visit_no = @@visit_no.gsub(' ','')
#      puts @@visit_no
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :multiple => true).should == 2
#     slmc.confirm_validation_all_items.should be_true
#
#all_ci = []

#puts all_ci[:ci_no].join("\n")
#puts   all_ci[:ci_no][1]
#puts all_ci[:ci_no].count

#  XXXX = org unit
#YYYY = YEAR
#MM = Month
#nnnnnn = "000001"


#saa =Time.now.strftime("%m%Y")
#puts saa

# @@pin = "1404069530"
#
#    slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
#         @@visit_no = slmc.get_text("//html/body/div[1]/div[2]/div[2]/div[8]/div[2]/div[3]/div[1]/label")
#         @@visit_no = @@visit_no.gsub(' ','')
#         puts @@visit_no
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "A"
end

#  it "test ulit" do
##puts Dir.getwd
##mypath = ("#{Dir.getwd}""/speclist.xls")
##puts mypath
##spec_files = Dir.glob("spec/*_spec.rb")
##puts spec_files
##spec_name = "sam"
##dir_of_dir = "C:/sandy/Project/Code/Healthcare/newfolder/myfile"
##ModuleNameHere.construct_batch_file(:spec_name =>spec_name, :dir_of_spec => dir_of_dir).should be_true
##sam = []
#
##      print  "In which city do you stay?"
##      sched_name = nil
##
##    while  sched_name == nil
##            sched_name = gets.chomp
##            sleep
##
##    end
##
##      puts "In which city do you stay?#{sched_name}"
##      ts = TaskScheduler.new
##      puts ts.delete(sched_name)
#
##STDOUT.flush
##sched_name = gets.chomp
##wait.Until sched_name != nil
#
##sam = ts.enum
##sam.each do |i|
##puts sam[i]
##puts sam
##end
##cmd("dir")
##spec_name = "sam"
##dir_of_dir = "C:/sandy/Project/Code/Healthcare/newfolder/myfile"
##file = File.open("#{dir_of_dir}""/batch/#{spec_name}"".bat", "w")
##file.write("@Echo on\n")
##file.write("TITLE #{spec_name}\n")
##file.write("cd #{dir_of_dir}\n")
##file.write("rake #{spec_name}")
##file.write("pause")
#  end
##it"test" do
#        a = (DateTime.now).strftime("%m/%d/%Y")
#        b = " 12:00 AM"
#        #DateTime.now
#        admitting_diagnosis = a + b
#        puts (admitting_diagnosis).to_s
#        remove_spec = ["additional_account_class","admission_database","another_test","c4_features","ctms","gos","scheduler","search_data","testdata","testtwo","test","tttttes"]
#
#        spec_files = Dir.glob("spec/*_spec.rb")
#     #  puts spec_files.count
#
#        spec_name = []
#    #    final_spec =[]
#        spec_files.length.times do |x|
#          spec_files[x] = spec_files[x].to_s
#        end
#
#        spec_files.length.times do |x|
#          spec_files[x] = spec_files[x].gsub("spec/", "")
#            spec_name << spec_files[x].split('_spec.rb').to_s
#        end
#        remove_spec.count.times do |x|
#                    spec_name.delete(remove_spec[x])
#        end
#        puts spec_name
             #   spec_name.delete_if{ |a| a.include?(remove_spec[x]) }

      #  if spec_name.include?(remove_spec[x])

       # end


##          puts spec_name[2]
##          puts remove_spec[0]
##          if spec_name[2].to_s == remove_spec[0].to_s
##
##            puts "equal"
##          else puts "not"
##          end

  #      spec_name.index{ |x| remove_spec.to_s.include?(x) }.nil?
    #    puts spec_name
#        spec_name.count.times do |x|
#             #     sspec_name = spec_name[x].to_s
#                if (spec_name[x]).exist?(remove_spec)
#                       pus"nothinf"
#                else
#                  final_spec <<  spec_name[x]
#                end
#        puts final_spec[x]
#        end


#            aa =   spec_names - remove_spec
##       puts "#{spec_names[x]}"
#puts aa
#
#          spec_files.length.times do |x|
#          spec_names << spec_files[x].split('_spec.rb')
#        end
#        spec_names.flatten!
#        spec_names.length.times do |x|
#          puts "#{spec_names[x]}  #{spec_files[x]}"
#        end

#end
#


# @@doc_no = "000000162-201001DA"
# slmc.login("sel_ss1", @password).should be_true
#slmc.go_to_social_services_landing_page
## slmc.ss_document_search(:select => "Payment", :doc_type => "OFFICIAL RECEIPT", :search_option => "DOCUMENT NUMBER", :entry => @@doc_no).should be_true
#    slmc.ss_document_search(:select => "Payment", :search_option => "DOCUMENT NUMBER", :entry => @@doc_no).should be_true
#   # slmc.get_css_count("css=#orTableBody>tbody>tr").should == 1
# #   slmc.get_xpath_count('//*[@id="orTableBody"]').should == 1
#   # ("//html/body/div/div[2]/div[2]/div[6]/table/tbody/tr")
#   slmc.get_xpath_count("//html/body/div/div[2]/div[2]/div[6]/table/tbody/tr").should == 1
#mdate = "11/25/2014"
#gdate = Date.parse mdate
#
#
#puts gdate
#puts gdate.year

#    Sound.beep(5000, 3000)
#
#page.click "xpath=(//input[@name='action'])[4]"
#
#page.click "xpath=(//button[@type='button'])[3]"
#page.wait_for_page_to_load "30000"



#"//html/body/div/div[2]/div[2]/form/div[8]/input[3]"
#end







#
#@patient1 = Admission.generate_data
#@@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient1[:age])
#@@discount_amount = (@@room_rate * @@promo_discount)
#@@room_discount = @@room_rate - @@discount_amount
#
#
#slmc.login(@user, @password)




#slmc.login(@user, @password)
#@patient1 = Admission.generate_data
#slmc.admission_search(:pin => "Test")
#@@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
#slmc.admission_search(:pin => @@pin1).should be_true
#slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
#  :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."
#sleep
#puts @@pin1
##Database.connect
##               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
##                l1 = Database.select_all_statement l
##Database.logoff
##l1[0].should == "A"
#
#slmc.login(@gu_user_0287, @password)
#slmc.go_to_general_units_page
#slmc.go_to_adm_order_page(:pin => @@pin1)
#@drugs1.each do |item, q|
#              slmc.search_order(:description => item, :drugs => true).should be_true
#              slmc.add_returned_order(:drugs => true, :description => item,:quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
#end
#@ancillary1.each do |item, q|
#              slmc.search_order(:description => item, :ancillary => true).should be_true
#              slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
#end
#@supplies1.each do |item, q|
#              slmc.search_order(:description => item, :supplies => true).should be_true
#              slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
#end
#slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
#slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
#slmc.confirm_validation_all_items.should be_true
#end
##slmc.go_to_general_units_page
#slmc.nursing_gu_search(:pin => @@pin1)
#@@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
#@@visit_no1 = slmc.clinically_discharge_patient(:pf_type => "COLLECT",:pin => @@pin1, :diagnosis => "A91.0", :no_pending_order => true, :pf_amount => "6400", :save => true).should be_true
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "C"
#puts @@pin1
#
#slmc.go_to_general_units_page
#slmc.nursing_gu_search(:pin => @@pin1)
#slmc.go_to_gu_page_for_a_given_pin("Defer Discharge",@@pin1)
#slmc.type "id=reasonArea", "SELENIUM TEST"
#slmc.type "id=remarksArea", "SELENIUM TEST"
#slmc.click "id=submitDefer", :wait_for =>:page
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "A"
#
#slmc.go_to_general_units_page
#slmc.nursing_gu_search(:pin => @@pin1)
#@@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
#@@visit_no1 = slmc.clinically_discharge_patient(:pf_type => "COLLECT",:pin => @@pin1, :diagnosis => "A91.0", :no_pending_order => true, :save => true).should be_true
#puts @@visit_no1
#puts @@pin1
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "C"
#
#slmc.login(@pba_user, @password)
#slmc.go_to_patient_billing_accounting_page
#slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
#slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "C"
#slmc.skip_update_patient_information.should be_true
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "C"
#slmc.skip_room_and_bed_cancelation.should be_true
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "C"
#@@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "11444", :compute => true)
#slmc.ph_save_computation.should be_true
#sleep 10
#slmc.is_text_present("FINAL").should be_true
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "C"
#@@physician_pf_claim = 6400
#sleep 10
#slmc.skip_philhealth.should be_true
#slmc.skip_discount.should be_true
#slmc.skip_generation_of_soa.should be_true
#slmc.my_pba_full_payment(:pf_amount => @@physician_pf_claim).should be_true
#
#
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "D"
#
#slmc.go_to_patient_billing_accounting_page
#slmc.pba_search(:discharged => true, :pin => @@pin1)
#slmc.go_to_page_using_visit_number("Defer Discharge", slmc.visit_number)
#slmc.pba_defer_patient
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "C"
#
#slmc.login(@gu_user_0287, @password)
#slmc.go_to_general_units_page
#slmc.nursing_gu_search(:pin => @@pin1)
#slmc.go_to_gu_page_for_a_given_pin("Defer Discharge",@@pin1)
#slmc.type "id=reasonArea", "SELENIUM TEST"
#slmc.type "id=remarksArea", "SELENIUM TEST"
#slmc.click "id=submitDefer", :wait_for =>:page
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "A"
#
#slmc.go_to_general_units_page
#slmc.nursing_gu_search(:pin => @@pin1)
#@@room_and_bed = slmc.get_room_and_bed_no_in_gu_page
#@@visit_no1 = slmc.clinically_discharge_patient(:pf_type => "COLLECT",:pin => @@pin1, :diagnosis => "A91.0", :no_pending_order => true, :save => true).should be_true
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "C"
#
#slmc.login(@pba_user, @password)
#slmc.go_to_patient_billing_accounting_page
#slmc.pba_search(:pin => @@pin1)
#slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
#slmc.discharge_to_payment.should be_true
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == "D"
#
#sleep 6
#slmc.login(@gu_user_0287, @password)
#slmc.nursing_gu_search(:pin => @@pin1)
#slmc.print_gatepass(:no_result => true, :pin => @@pin1).should be_true
#Database.connect
#               l  = "SELECT STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                l1 = Database.select_all_statement l
#Database.logoff
#l1[0].should == nil


        #@patient1 = Admission.generate_data
#        slmc.login(@user, @password)
#        slmc.go_to_admission_page
#        sma = slmc.get_text("//html/body/div/div[2]/div[2]/div/div[2]/div[9]/div/span")
#        puts sma
#        sma = (sma).to_i
#        ss = sma + 1
#        puts ss
#slmc.click "id=endorsementImg"
#sleep 3
#my_count =  slmc.get_xpath_count("//html/body/div[10]/div[2]/div[2]/table/tbody/tr")
#my_count = my_count.to_i
#puts my_count
#while my_count !=0
#          if  my_count == 1
#               pin= slmc.get_text("//html/body/div[10]/div[2]/div[2]/table/tbody/tr/td")
#          else
#             pin = slmc.get_text("//html/body/div[10]/div[2]/div[2]/table/tbody/tr[#{my_count}]/td")
#          end
#          puts pin
#
#          my_count = my_count - 1
#  end






#it "test" do
#  @@nursing.each do |nurse_unit,n|
#          x = n
#          while x!=0
#                   nursing_unit = nurse_unit
#                   slmc.login("adm1", @password).should be_true
#                   slmc.admission_search(:pin => "1")
#                   @@pba_pin1 = slmc.create_new_patient(@patient1) #.merge!(:gender => "M"))
#                   slmc.admission_search(:pin => @@pba_pin1)
#                   slmc.create_new_admission(:rch_code => "RCH08", :room_charge => "REGULAR PRIVATE",:org_code => nursing_unit, :diagnosis => "GASTRITIS", :account_class => "INDIVIDUAL", :guarantor_code => "ABSC001").should == "Patient admission details successfully saved."
#                   sleep 6
#          end
#  end
#end



#it "test din" do
#
#
##
##     Database.connect
##          visit_no = "5105008449"
##          new_adm_date = "02/23/2014"
##          new_dis_date = "02/23/2014"
##          a =  "begin slmc.sproc_updaters('#{visit_no}','#{new_adm_date}','#{new_dis_date}'); end;"
##          ww = Database.update_statement(a)
##     Database.logoff
##    puts ww
###@driver.get(@base_url + "/login?service=http%3A%2F%2F192.168.137.157%3A2010%2Fj_spring_cas_security_check")
###@driver.find_element(:id, "username").clear
###@driver.find_element(:id, "username").send_keys "dasdsad"
###@driver.find_element(:id, "password").clear
###@driver.find_element(:id, "password").send_keys "dsadsad"
###@driver.find_element(:name, "submit").click
##
#
#end


#it "test" do
#            @dr_patient1 = Admission.generate_data
#            slmc.login("jpnabong", @password).should be_true
#            @@slmc_mother_pin = (slmc.or_create_patient_record(@dr_patient1.merge!(:admit => true, :gender => 'F', :rch_code => 'RCHSP', :org_code => '0170'))).gsub(' ', '')
#
#            slmc.login("jpnabong", @password).should be_true
#            sleep 3
#            slmc.go_to_outpatient_nursing_page
#            slmc.outpatient_to_inpatient(@dr_patient1.merge(:pin => @@slmc_mother_pin, :username => "ldvoropesa", :password => @password,
#                :room_label => "REGULAR PRIVATE", :rch_code => "RCH08", :org_code => "0287")).should be_true
#            slmc.login("jpnabong", @password).should be_true
#            slmc.register_new_born_patient(:pin => @@slmc_mother_pin, :bdate => (Date.today).strftime("%m/%d/%Y"), :gender => "F",:birth_type => "SINGLE",
#              :birth_order => "FIRST", :delivery_type => "OTHER", :weight => 4000, :length => 54,:doctor_name => "ABAD", :rooming_in => true, :save => true)
#            l_name = @dr_patient1[:last_name]
#            l_name  = (l_name).upcase
#            m_name = @dr_patient1[:middle_name]
#            m_name  = (m_name).upcase
#            puts l_name
#            puts m_name
#            Database.connect
#                    a = "SELECT PIN FROM SLMC.TXN_PATMAS WHERE UPPER(LASTNAME) = '#{l_name}' AND UPPER(MIDDLENAME) = '#{m_name}' AND UPPER(FIRSTNAME) = 'BABY GIRL'"
#                    pin = Database.my_select_last_statement a
#                    puts pin
#            Database.logoff
#
#puts @@slmc_mother_pin
#puts pin
                                                        #Database.connect

#      slmc.login('sel_pharmacy2', @password).should be_true
#num = "040004334"
#Database.connect
#        t = "SELECT * FROM MY_SERVICE_ITEMS  WHERE MSERVICE_CODE = '#{num}'"
#        d = Database.select_all_statement t
#Database.logoff
#puts  d[0]

#    @@mycase_rate =  "66983"
#     Database.connect
#            t = "SELECT TO_CHAR(PF_AMOUNT) FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
##            t = "SELECT PF_AMOUNT FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
##            pf = Database.select_last_statement t
#     Database.logoff
#    puts pf
#    pf = (pf).to_i
#        puts pf
#   @room_rate = 4167.0

#    payment = 118321.15250036
#    payment =  ('%.2f' %  + payment.to_f)
# #  payment  = (payment).round
#      #  payment =
#####      days_to_adjust = 1
#####      d = Date.strptime(Time.now.strftime('%Y-%m-%d'))
#####      my_set_date = ((d - days_to_adjust).strftime("%m/%d/%Y").upcase).to_s
#####      puts my_set_date
#
#asa = "A50"
#  s = ".1"
#  puts asa + s

#                  @patient1 = Admission.generate_data
#            slmc.login(@user, @password)
#            slmc.admission_search(:pin => "Test")
#            @@pin1 = slmc.create_new_patient(@patient1).gsub(' ', '')
#            #@@pin1 = "1210068782"
#            slmc.admission_search(:pin => @@pin1).should be_true
#            slmc.create_new_admission(:on_queue => true, :account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
#              :room_charge => "REGULAR PRIVATE", :diagnosis => "DENGUE FEVER", :doctor_code => "6726").should == "Patient admission details successfully saved."
#            puts @@pin1

#          @@pin1 = "1410076101"
#              Database.connect
#                      a = "SELECT * FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#                   # l  = "SELECT REDTAG_FLAG, DEATH_TYPE, DEATH_FLAG, ENDORSEMENT_FLAG, ROOMTRAN_RQST_STATUS FROM SLMC.TXN_OCCUPANCY_LIST WHERE PIN = '#{@@pin1}'"
#
#                    puts a
#                    #a1 = Database.select_all_statement a
#                      b1 = Database.my_select_last_statement a
#
#            Database.logoff
##puts a1[1]


#puts a1[0]
#puts a1[1]
#puts a1[2]
#puts a1[3]
#puts a1[4]

#puts b1


#a1[0].should == nil
#a1[1].should == nil
#a1[2].should == nil
#a1[3].should == nil
##
#    @patient1 = Admission.generate_data
#    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_
 #     my_set_date = ((d - days_to_adjust).strftime("%d/%m/%Y").upcase).to_spromo_discount_based_on_age(@patient1[:age])
#    puts @@promo_discount
#    @discount_amount = (@room_rate * @@promo_discount)
#    @room_discount = @room_rate - @discount_amount
#   @days1 = 1.0
#    @@actual_room_charges = (@room_discount * @days1)
#puts     @@actual_room_charges

#conn = OCI8.new('slmc/newhis')
#table = conn.describe_table('//192.168.105.39:1521/qatrndb.dual')
#table.columns.each do |col|
#  puts "#{col.name} #{col.data_type_string}"3
#end

#puts  d[0]

#    @@orders.each do |order,n|
#              item =PatientBillingAccountingHelper::Philhealth.get_order_details_based_on_order_number(order)
#              amt = item[:rate].to_f * n
#            #ss = n*1
##            puts ss
##            puts item[:order_no]
#            #  @@gross += amt
#            puts amt
#              puts  item[:description]
#    end
#end





##  it "saa" do
##                  #    Database.connect
##                  #    t = "SELECT SUM(RATE) FROM SLMC.REF_PC_SERVICE_RATE WHERE STATUS = 'A' AND SERVICE_CODE IN
##                  #(SELECT SERVICE_CODE FROM SLMC.REF_PC_SERVICE WHERE STATUS = 'A' AND MSERVICE_CODE IN
##                  #(SELECT MSERVICE_CODE FROM SLMC.REF_PC_MASTER_SERVICE WHERE OWN_DEPT = '0004' AND STATUS = 'A' AND MSERVICE_CODE = '040854342'))"
##                  #    vat_from_db = Database.select_last_statement t
##                  #    Database.logoff
##                  #    vat_from_db = vat_from_db.to_f
##                  #    vat_from_db = (vat_from_db).round
##                  #    puts vat_from_db
##                  #  endw
##        x = 1
##        while x != 0
##              @patient1 = Admission.generate_data
##              slmc.login("adm1", @password).should be_true
##              slmc.admission_search(:pin => "1")
##              @@pba_pin1 = slmc.create_new_patient(@patient1) #.merge!(:gender => "M"))
##              slmc.admission_search(:pin => @@pba_pin1)
##              slmc.create_new_admission(:rch_code => "RCH08", :room_charge => "REGULAR PRIVATE",:org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "INDIVIDUAL", :guarantor_code => "ABSC001").should == "Patient admission details successfully saved."
##              sleep 6
##              slmc.login(@gu_user_0287, @password).should be_true
##              slmc.nursing_gu_search(:pin => @@pba_pin1)
##              slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pba_pin1)
##              @drugs.each do |drug, q|
##                      slmc.search_order(:drugs => true, :code => drug).should be_true
##                      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
##              end
##             @ancillary.each do |anc, q|
##                      slmc.search_order(:description => anc, :ancillary => true ).should be_true
##                      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
##              end
##              slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
##              slmc.validate_orders(:drugs => true, :ancillary => true, :multiple => true).should == 2
##              slmc.confirm_validation_all_items.should be_true
##              sleep 6
##              slmc.go_to_general_units_page
##              @@visit_no1 = slmc.clinically_discharge_patient(:pin => @@pba_pin1, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
##              puts @@pba_pin1
##              puts @@visit_no1
##              sleep 10
##              x-=1
##        end
##
##  end
#    slmc.login("gu3", @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)a
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :multiple => true).should == 2
#    slmc.confirm_validation_all_items.should be_true

#        slmc.login("gu3", @password).should be_true
#        slmc.go_to_general_units_page
#      slmc.patient_pin_search(:pin => @@pin)
#      @@pin = @@pin.to_i
##      slmc.select "id=userAction#{@@pin}", "label=regexp:Discharge Instructions\\s"
##
##              sleep 20
#      @@visit_no1 = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#        puts @@visit_no1
#        slmc.login("pba1", @password).should be_true
#        slmc.go_to_patient_billing_accounting_page
#        slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
#        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#        slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#        slmc.discharge_to_payment
#        sleep 6
#        slmc.login("gu3", @password).should be_true
#        slmc.nursing_gu_search(:pin => @@pin)
#        slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
#        sleep 6
#        puts "DONE - #{@@pin}"
#        puts @@visit_no1
#        row+=1
#        x-=1

 # end



#
#
#    count_of_row = 1000
#    x = 0
#var = ""
#
#            while not x == count_of_row
#
#            var = var + "d"
#
#              x+=1
#        end
#puts var
#ngayon =Time.now.strftime("%d/%m/%Y %H:%M:%S")
#puts ngayon
#myti = Time.now
#s = myti - 60
#puts s
#Database.connect
#slmc.check_discharge_datetime(:visit =>"5301000257").should be_true
#Database.logoff
#visit = "5301000257"
#Database.connect
#t = "SELECT ADMIN_DC_DATETIME FROM TXN_ADM_DISCHARGE WHERE VISIT_NO = '#{visit}'"
#adm_date_time = Database.select_all_statement t
#puts adm_date_time
#s = "SELECT DISCHARGE_DATETIME FROM TXN_ADM_ENCOUNTER WHERE VISIT_NO = '#{visit}'"
#encounter_date_time = Database.select_all_statement s
#puts encounter_date_time
#Database.logoff
#

#
#ngayon =Time.now.strftime("%d/%m/%Y %H:%M:%S")
#puts ngayon
#      slmc.login("adm1", @password).should be_true
#      @@er_pin = slmc.er_create_patient_record(@er_patient.merge(:admit => true)).gsub(' ','')
#      slmc.go_to_my_update_registration(:pin =>@@er_pin, :turn_inpatient => true, :save => true)
#      slmc.login("adm1", @password).should be_true
#      slmc.go_to_admission_page
#      slmc.click("id=patientAdmissionImg");
#      sleep 10
#      count = slmc.get_xpath_count("//html/body/div[6]/div[2]/div[2]/table/tbody")
#puts count
#("//html/body/div[6]/div[2]/div[2]/table/tbody")
##

#  sam= 0
#  a = 1
#  b = 2
#  if a!= b
#      sam >> b
#      puts sam
#    slmc.type Locators::Login.username, "username"
#    slmc.type Locators::Login.password, "password"
#    slmc.click Locators::Login.button
##  end
#slmc.waitForPageToLoad(30000)
#
#ngayon = (Time.now).strftime("H%M%S")
#puts ngayon
##
#ngayon2 = (Time.now).strftime("H%M%S")
#puts ngayon2
#myti = Time.now
#puts myti.hour
#  ref_num = 'S530200010413R'
#  ref_num.to_s
#  puts "ss#{ref_num.include?("PhilHealth Reference No.: ")}"
#  if ref_num.include?("PhilHealth Reference No.: ")
#  puts "found"
#  else
#puts "not found"
#mser = '04pharm01'
#ngayon = (Time.now).strftime("%m%d%Y%H%M%S")
#              stat = "PASSED"
#             Database.connect
#              q = "INSERT INTO MY_TEST_TABLE VALUES('#{mser}','#{ngayon}','#{stat}')"
#
#
#              end
#              Database.update_statement q
#              Database.logoff
#
#Database.connect
# @conn = OCI8.new("SLMC", "gcnewhis123", "192.168.137.2:1521/qadb")
#  #x  = "SELECT COUNT(TABLE_NAME) FROM ALL_TABLES WHERE OWNER = 'SLMC'"
#             #while x == 0
#                        q = "SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER = 'SLMC' ORDER BY TABLE_NAME"
#                        mytable = @conn.exec(q)
#                        a = mytable.fetch
#                        a1 = a[0]
#                        puts mytable
#                        puts a1
#                             @conn.logoff

#Database.connect
#  mysearch = 'sandy'
#  t = 'ARMS_CACHE_RESULT_VALUE'
#      q ="SELECT CACHE_VALUE_ID FROM #{t} WHERE CACHE_VALUE_ID like '%#{mysearch}%'"
#ww = Database.my_select_last_statement(q)
#puts ww
#Database.logoff
##
#        Database.connect

# Database.logoff
                                #puts ww

#
             # end
#      slmc.open "/"

#      sleep 10
#      sam = slmc.get_attribute("//html/body/div[7]/div/div/div[2]/div[2]/form/div[7]/div")
#      puts sam
##      slmc.click('//*[@id="the_file"]')
#      sleep 10
#      slmc.type("id=the_file", "C:\\Users\\sandy\\Desktop\\medium_a7bed59c8fd11855baef226cec023428.jpg");
#      #slmc.type("//input[@name='fileupload']","c:lyncalusin.txt");
#      sleep 50
##      slmc.click("id=colorBoxButton");
#     sam =   (Time.now).strftime("%m%d%Y%H%M%S")
#     puts sam
#        count_of_row = 22
#        x = 0
#        while x != count_of_row
##              row = x
##              package_detail  = PatientBillingAccountingHelper::Philhealth.get_read_fm_package_scenario(row)
##              package_type = package_detail[:package_type]
##              patient_type = package_detail[:patient_type]
##              no_of_days = package_detail[:no_of_days]
##              status = package_detail[:status]
##              puts "row - #{row}"
##              puts "package_type - #{package_type}"
##              puts "patient_type - #{patient_type}"
##              puts "no_of_days - #{no_of_days}"
##              puts "status - #{status}"
#              sam = AdmissionHelper.numerify("###")
#                  #@room_add = "GPR#{Faker.numerify("###")}"
#                  puts sam
#              x+=1
#        end
#        @mservice_code = {"060000750",	"010000001",	"040854342",	"269409014",	"082400222",	"010002580",	"060000209",	"010001745",	"060003489",	"089403123",	"060000354",	"030000001",	"089000039",	"089500009",}
#        @mservice_code.each do |mservice_code|
#          puts mservice_code
       # end

#end

#  it "should desc" do
   # slmc.login(@user, @password).should be_true
#visit_no = '5207001124'
#Database.connect
#array = Array.new
##q = "select RB_TRANS_NO from TXN_PBA_ROOM_BED_TRANS where RB_TRANS_NO = (select MAX(RB_TRANS_NO) from TXN_PBA_ROOM_BED_TRANS)"
#f = "SELECT * FROM SLMC.TXN_PBA_GUARANTOR_INFO  WHERE VISIT_NO = '#{visit_no}'"
#ff = Database.select_all_rows f
#
#
#
#
#x = ff.count
#x = x.to_i
#puts x
#puts ff[26]
#puts ff[27]
#puts ff[28]
#puts ff[25]
#
#xx = ff.count
#x = xx.to_i
#while x != -1
#
#
#puts ff[x]
#array.push ff[x]
#x-=1
#end
#puts array
#
#    Database.logoff
#
#  it "Claim Type: Accounts Receivable With Operation: No - Create and Admit Patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "Test")
#    @@pin = slmc.create_new_patient(Admission.generate_data)
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin).should be_true
#    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
#      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "3325").should == "Patient admission details successfully saved."
#  end
#
#    it "Company : Inpatient - Order items" do
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :multiple => true).should == 2
#    slmc.confirm_validation_all_items.should be_true
#  end

 #slmc.update_statement(:visit_no => slmc.visit_number,:new_adm_date => @new_adm_date.to_s,:confine_no => 1)

#  end"exec sproc_doom  ('#{visit_no}','#{new_adm_date}','#{confine_no}')"

end

