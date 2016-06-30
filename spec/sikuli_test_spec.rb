# To change this template, choose Tools | Templates
# and open the template in the editor.
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
#require# File.expand_path(File.dirname(__FILE__) + 'C:\\Ruby\\lib\\ruby\\gems\\1.8\\gems\\sikulirc-0.0.1\\lib')

#require 'org.sikuli.script'
#
#gem 'sikulirc'
#       require 'java'
require 'sikuli'
#require 'org_sikuli_script'
#include Sikulirc
##require 'java'
#require 'sikulirc'
#require 'java'
#require 'java'
#require 'rubygems'
#gem "rspec", "<=1.2.9"
#require 'rspec'
#require 'java'
#require 'sikuli'
#require "java"
#require "C:\\SikuliX\\sikuli-java.jar"
#import org.sikuli.script.App;
#import org.sikuli.script.Screen;
#import org.sikuli.script.Pattern;

describe "Sikuli test" do
  before(:all) do
  # @@rs =SIKULI.new("127.0.0.1")
  end
  it "should desc" do
#equire 'java'
#java_import 'org.sikuli.script.Screen'
#screen = Screen.new
#image_path='/Users/mubbashir/Desktop'
#
#screen.click("#{image_path}/apple.png", 0)
#rs = Sikuli::Screen.new
#rs = Sikulirc::RemoteSikuli::Screen.newen.new("127.0.0.1")
#rs = Sikulirc::RemoteScreen.new("localhost")

  #   rs =  RemoteScreen.new("localhost")



rs = Sikuli::Screen.new
#rs.set_min_similarity 0.9
#rs.find("C:\\1.png")

rs.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\image1.png")
rs.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\image2.png")


#RemoteScreen rs = new RemoteScreen("localhost");
#rs.setMinSimilarity(0.9);
#rs.click("D://

#rs.app_focus "title"
#rs.type_in_field "D:\\field.png", "content"
#rs.page_down
#rs.wait "D:\\field.png"
#rs.find "D:\\field.png"
#rs.set_min_similarity 0.9


  end
end

