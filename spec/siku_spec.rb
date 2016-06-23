# To change this template, choose Tools | Templates
# and open the template in the editor.
#!/usr/bin/env ruby


#require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
#require File.expand_path(File.dirname(__FILE__)) + '/spec_helper'

#require 'spec_helper'

require 'rubygems'
require 'sikulirc'


describe "Siku" do
  before(:each) do
    #@siku = Siku.new
  end
  
  it "should desc" do
sleep 2
rs = Sikulirc::RemoteScreen.new("127.0.0.1")
sleep 2
rs.click("C:\\Users\\sandy\\Desktop\\newfolder\\1426066894202.png")
sleep 2
  end
end

