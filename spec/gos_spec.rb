require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmcwebdriver.rb'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')
CONFIG = YAML.load_file File.dirname(__FILE__) + '/../config.yml'
#require File.dirname(__FILE__) + '/../lib/slmc_webdriver'
#require File.dirname(__FILE__) + '/../lib/slmc'
require 'rubygems'
require 'spec_helper'
require 'selenium-webdriver'
#gem 'selenium-webdriver', '2.35.0'
require 'yaml'

describe "sas"  do
  attr_reader :selenium_driver
  alias :slmc :selenium_driver

    attr_reader :slmcwebdriver
  alias :slmcwebdriver :slmcwebdriver  

before(:all) do
     @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @slmcwebdriver = SLMCWEBDRIVER.new
        
#                          caps = Selenium::WebDriver::Remote::Capabilities.firefox
#                              #caps.save_screenshot("./screen.png")
#                              #caps.save_screenshot("C:\screen.png")
#                            #  caps.take
#                              caps.version = "7"
#                              caps.platform = :WINDOWS
#                              @driver = Selenium::WebDriver.for(
#                                              :remote,
#                                              :url => "http://127.0.0.1:4444/wd/hub",
#                                              :desired_capabilities => caps)
end
 after(:all) do
    slmcwebdriver.quit
  end

it "should desc" do
   slmcwebdriver.navigate.to CONFIG['url']
                      #@driver = SLMC_Webdriver
                      #    @gos = slmc_webdriver
                      #    @driver = Selenium::WebDriver.for :firefox
                      #   @driver.navigate 'http://192.168.137.153:2010/'
                      #   # @driver.navigate.to 'http://192.168.137.153:2010/'
                      #
                      #url = CONFIG['url']
                      #@driver = SLMC_Webdriver.new
                      ##(save_screenshot("./screen.png"))
#
#                      caps = Selenium::WebDriver::Remote::Capabilities.firefox
#                      caps.version = "7"
#                      caps.platform = :WINDOWS
#                      @driver = Selenium::WebDriver.for(
#                      :remote,
#                      :url => "http://127.0.0.1:4444/wd/hub",
#                      :desired_capabilities => caps)
#                      ###driver.navigate.to "http://www.google.com"
#                      ###driver.navigate.to 'http://192.168.137.153:2010/'
#sleep 4
#                     @driver.navigate.to 'http://192.168.137.153:2010/'
                     # @driver.navigate.to "http://www.seleniumtutorials.com"
end
it "should desc" do
                      sleep 6
                      #@driver.get(@base_url + "/login?service=http%3A%2F%2F192.168.137.157%3A2010%2Fj_spring_cas_security_check")
                      #slmcwebdriver.find_e
                      slmcwebdriver.find_element(:id, "username").clear
                      slmcwebdriver.find_element(:id, "username").send_keys "adm1"
                      slmcwebdriver.find_element(:id, "password").clear
                      slmcwebdriver.find_element(:id, "password").send_keys "123qweuser"
                      slmcwebdriver.find_element(:name, "submit").click
end
it "test agian" do
#                       @driver.get(@base_url + "/wiki/Wiki")
#                      @driver.find_element(:link, "Wikipedia").click
#                      (@driver.find_element(:css, "span").text).should == "Wikipedia"
#                      @driver.find_element(:id, "searchInput").clear
#                      @driver.find_element(:id, "searchInput").send_keys "sandy"
#                      @driver.find_element(:id, "searchButton").click
#                      successmessage = (@driver.find_element(:link, "Sandy Island (disambiguation)").text)
#                      "Sandy Island (disambiguation)".eql? successmessage.text
                      #element_present?(:link, "Sandy Island (disambiguation)").should be_true

 end
end

