#require 'rubygems'
#require "selenium-webdriver"
#
#driver = Selenium::WebDriver.for :firefox
#driver.navigate.to "http://google.com"
#
#element = driver.find_element(:name, 'q')
#element.send_keys "Hello WebDriver!"
#element.submit
#
#puts driver.title
#
#driver.quit

require "rubygems"
#gem "selenium-client"
#gem "selenium-webdriver"
require "selenium-webdriver"
require "selenium-client"


capabilities  = {
    :browserName => "firefox",
    :platform => "Windows"

}

#client = Selenium::WebDriver::Remote::Http::Default.new
#client.timeout = 480

driver = Selenium::WebDriver.for(
  :remote,
  :url => "http://localhost:4723/wd/hub/",
  :desired_capabilities => capabilities)
driver.navigate.to "http://www.google.com"
element = driver.find_element(:name, 'q')
element.send_keys "Hello WebDriver!"
element.submit
puts driver.title
driver.quit