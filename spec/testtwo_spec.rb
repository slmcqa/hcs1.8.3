#!/bin/env ruby
# encoding: utf-8

require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  

#require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'
require 'faker'
require 'oci8'
require 'ruby-plsql'

describe "test" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
#      @user = "billing_spec_user2"
#    @password = "123qweuser"
#    @patient = Admission.generate_data
  end

  after(:all) do
  #  slmc.logout
    slmc.close_current_browser_session
  end



  it "should desc" do
#      Database.connect
#                  visit_no = "5302000786"
#                  new_adm_date = "02/23/2013"
#                  dis_date = "02/23/2013"
#                #  a =  "begin slmc.sproc_updater('#{visit_no}','#{new_adm_date}','#{dis_date}'); end;"
#       plsql.connection = Database.connect
#       plsql.slmc.sproc_updater(visit_no,new_adm_date,dis_date)
#       plsql.logoff
@@visit_no = "5403000012"
        Database.connect
            a =  "SELECT PIN  FROM SLMC.TXN_OCCUPANCY_LIST WHERE VISIT_NO ='#{@@visit_no}'"
            aa = Database.select_statement a
    Database.logoff
    @@or_no  = aa
    puts "#{@@or_no}"
    
      #ww = Database.update_statement(a)
     # puts ww
    #  Database.logoff
end
end

