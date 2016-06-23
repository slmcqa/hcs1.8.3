require 'rubygems'
require 'selenium-webdriver'




driver = Selenium::WebDriver.for :firefox
driver.navigate.to "http://google.com"
sleep 6
element = driver.find_element(:name, 'q')
element.send_keys "Hello WebDriver!"
element.submit
puts driver.title
driver.quit


# #navigate to the login page
#driver = Selenium::WebDriver.for :firefox
#
##driver = Selenium::WebDriver.for(:remote,:url => "http://127.0.0.1:4443/wd/hub", :desired_capabilities => :firefox)
#driver.get 'http://yourblog.com/login'
## log in a test user
#driver.find_element(:name, 'email').send_keys 'example@example.com'
#driver.find_element(:name, 'password').send_keys 'password'
#driver.find_element(:id, 'btn-login').click
#
## create a post driver.get 'http://yourblog.com/post'
#driver.find_element(:name, 'title').send_keys 'post title'
#driver.find_element(:name, 'content').send_keys 'here is some post content'
#driver.find_element(:id, 'btn-post').click
#
## close the browser
#driver.quit