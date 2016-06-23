#!/usr/bin/env jruby
#require 'ant'
#require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
#require 'spec_helper'
#require 'yaml'
gem "sikuli", "<=0.3.0"   
require 'rubygems'
require 'sikuli'



#  attr_reader :selenium_driver
  #alias :slmc :selenium_driver

#    @selenium_driver = SLMC.new
#    @selenium_driver.start_new_browser_session
#    

rs = Sikuli::Screen.new
#Sikuli::Config.run do |config|
#  config.image_path = "#{Dir.pwd}/images/"
#  config.logging = false
#end

#@selenium_driver.login(@user, @password).should be_true
    
#at1 = Sikuli  
sleep 2

rs.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\image1.png")
rs.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\image2.png")

#puts "Hello World"
