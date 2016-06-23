#!/bin/env ruby
# encoding: utf-8
require 'rubygems'
#gem "sikuli", "<=0.3.0"
#gem "selenium-client", ">=1.2.18"
#require 'selenium/client'
require 'yaml'
require 'selenium-webdriver'
#gem 'sikulirc'
#
#
#require 'java'
#require 'sikulirc'

#
#require 'selenium-webdriver'


require File.expand_path(File.dirname(__FILE__) + '/selenium_client_extensions')
require File.expand_path(File.dirname(__FILE__) + '/modules/home')
require File.expand_path(File.dirname(__FILE__) + '/modules/admission')
require File.expand_path(File.dirname(__FILE__) + '/modules/nursing_general_units')
require File.expand_path(File.dirname(__FILE__) + '/modules/nursing_special_units')
require File.expand_path(File.dirname(__FILE__) + '/modules/patient_billing_accounting')
require File.expand_path(File.dirname(__FILE__) + '/modules/central_sterile_supply')
require File.expand_path(File.dirname(__FILE__) + '/modules/user_management')
require File.expand_path(File.dirname(__FILE__) + '/modules/arms')
require File.expand_path(File.dirname(__FILE__) + '/modules/medical_records')
require File.expand_path(File.dirname(__FILE__) + '/modules/one_stop_shop')
require File.expand_path(File.dirname(__FILE__) + '/modules/fnb')
require File.expand_path(File.dirname(__FILE__) + '/modules/database')
require File.expand_path(File.dirname(__FILE__) + '/modules/outpatient_ordering')
require File.expand_path(File.dirname(__FILE__) + '/modules/order_adjustment_and_cancellation')
require File.expand_path(File.dirname(__FILE__) + '/modules/stlukes_nursing_general_units')
require File.expand_path(File.dirname(__FILE__) + '/modules/helpers/stlukes_ dr_su_helper')
require File.expand_path(File.dirname(__FILE__) + '/modules/inhouse')
require File.expand_path(File.dirname(__FILE__) + '/modules/social_service')
require File.expand_path(File.dirname(__FILE__) + '/modules/file_maintenance')
require File.expand_path(File.dirname(__FILE__) + '/modules/clinical_alerts')
require File.expand_path(File.dirname(__FILE__) + '/modules/file_maintenance_two')
require File.expand_path(File.dirname(__FILE__) + '/modules/schedule')

CONFIG = YAML.load_file File.dirname(__FILE__) + '/../config.yml'

class SLMCWEBDRIVER <Selenium::WebDriver::Driver
  include Home
  include Admission
  include NursingGenenalUnits
  include NursingSpecialUnits
  include PatientBillingAccounting
  include CentralSterileSupply
  include UserManagement
  include Arms
  include OneStopShop
  include FNB
  include Database
  include OutpatientOrdering
  include OrderAdjustmentAndCancellation
  include StlukesNursingGenenalUnits
  include StLukesDrSuHelper
  include MedicalRecords
  include InHouse
  include SocialService
  include FileMaintenance
  include ClinicalAlerts
  include File_maintenance_two
 include Schedule

    def initialize()
                  caps = Selenium::WebDriver::Remote::Capabilities.firefox
                  caps.version = "7"
                  #time = Time.new.strftime("%Y%m%d%a%H%M")
                  caps.platform = :WINDOWS
                   
                #  filemane = time
                #  caps.save_screenshot("C:/#{filemane}.png")
                  driver = Selenium::WebDriver.for(
                                              :remote,
                                              :url => "http://127.0.0.1:4444/wd/hub",
                                              :takes_screenshot =>false,
                                              :desired_capabilities => caps)
                 #  driver.navigate.to CONFIG['url']
                 

#          version= "7"
#          browser_name = :firefox
#          takes_screenshot = false
#          native_events = false
#          rotatable = false
#          firefox_profile = nil
#          proxy = nil
#          platform = :WINDOWS
#          url = "http://127.0.0.1:4444/wd/hub"
#          remote = true
#      
#    super(browser_name, version, takes_screenshot,native_events,rotatable, platform,firefox_profile,proxy,url,remote)
    super(driver)
    end
end