# To change this template, choose Tools | Templates
# and open the template in the editor.

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.dirname(__FILE__) + '/../lib/slmc'
#require File.dirname(__FILE__) + ('c:/Ruby/lib/ruby/gems/1.8/gems/espeak-ruby-1.0.2/')

require 'spec_helper'
require 'yaml'
require 'win32ole'
#require 'autoit-ffi'
#require "rautomation"
require 'rubygems'
gem 'espeak-ruby'
require 'espeak'
include ESpeak

 
describe "Autoit_test" do
  before(:all) do
    @selenium_driver = SLMC.new
  #  @selenium_driver.start_new_browser_session


  end
it "speak" do

  text = "mike THARA, mike THARA,mike THARA,mike THARA,mike THARA,"


speech = ESpeak::Speech.new(text,  :pitch  => 80, :speed => 30,:voice => "en")
#speech.speak # invokes espeak

#speech = ESpeak::Speech.new("Hallo") #, :voice => "en")
speech.speak()
#speech.save("c:\hello.mp3") # invokes espeak + lame

end
#
# it "Testing Trial - POS Application Java" do
##   window = RAutomation::Window.new(:title => "Floreant POS - Version 1.4-build452")
##    if window.exists?
##      puts "true"
##    else
##      puts "false"
##    end
##    #window.activate
###all_windows = RAutomation::Window.windows
###all_windows.each {|window| puts window.title}
###window.buttons.each {|button| puts button.value}
###window.buttons.each {|button| puts button.value}
##puts  window.text_field.value
#
# end







  it "ymtest" do
#    x = 5
#    auto = WIN32OLE.new("AutoItX3.Control")
#  #  auto.WinActivate("Yahoo! Messenger","")
#    #auto.WinActivate("madel_mendoza","")
#    auto.WinActivate("Michael Anthony Evio (posh_michael)","")
#    # auto.WinActivate("Jichelle Gomez (jigom_jackem)","")
#              while x != 0
#                      #puts x
#                        auto.Send("tanga{ENTER}")
#                        auto.Send("{CTRLDOWN}g{CTRLUP}")
#                        auto.WinActivate("SmileyTablePopup","")
#                         auto.Send("tanga{ENTER}")
#                        sleep 1
#                        x = x + 1
#
#            end
  end
end

