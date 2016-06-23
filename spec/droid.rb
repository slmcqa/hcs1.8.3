
require 'selenium-webdriver 2.24.0'
require 'webdriver-user-agent'

driver = UserAgent.driver(:browser => :firefox , :agent => :android_phone, :orientation => :portrait)
driver.get 'http://tiffany.com'
driver.current_url.should == 'http://m.tiffany.com/International.aspx'