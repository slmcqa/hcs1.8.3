require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
#require File.dirname(__FILE__) + '/../lib/slmc'
require 'yaml'
#require "win32/sound"
#include Win32

describe "SLMC :: Endoscopic Procedure Case" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver
    before(:all) do
        @selenium_driver = SLMC.new
   # @selenium_driver.start_new_browser_session
  end
    after(:all) do
#    slmc.logout
#    slmc.close_current_browser_session
  end
  it "should desc" do
#Sound.beep(600,200)
# Sound.play("C:/Users/sandy/sandy/Music/Artist/Foreign/3 Doors Down/Kryptonite.mp3")


print 'input ka '
kee = $stdin.gets.chomp   
puts "input mo ay #{kee}"    
sleep 5
  end
end

