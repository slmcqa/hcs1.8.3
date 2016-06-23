# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.
#require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
#require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
#require 'spec_helper'
require 'rubygems'
gem 'sikulirc'

require 'sikulirc'

describe "test_sikuli" do
  before(:each) do
    #@test_sikuli = Test_sikuli.new
  end

#  it "should desc" do
#    # TODO
#    sam = Sikulirc::RemoteScreen.new("127.0.0.1")
#    sleep 2
#    sam.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\image1.png")
##    sam.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\image2.png")
#    sam.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\counterstrike.png")
#  end
  
  it "should open Toad" do
      sam = Sikulirc::RemoteScreen.new("127.0.0.1")
     sam.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\toad.png")
     sleep 5
     sam.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\qafunc.png")
     sam.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\connect.png")
     sleep 10
     sam.click("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\editor.png")
 sleep 5
   #  sss = "SELECT * FROM SLMC.REF_EMPLOYEE WHERE UPPER(LASTNAME) = 'RATUISTE'"
     sam.type_in_field("C:\\Users\\imd15239\\Desktop\\newfolder\\stluke\\167\\image\\editor.png", "SELECT * FROM SLMC.REF_EMPLOYEE WHERE UPPER(LASTNAME) = 'RATUISTE'")
  #   sam.type_in_field(psc, content)
  end
  
  
end

