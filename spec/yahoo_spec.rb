# To change this template, choose Tools | Templates
# and open the template in the editor.

require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')



describe "Yahoo" do
  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
       @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
  end

  it "should desc" do

  end
  YahooMessenger
end

