# To change this template, choose Tools | Templates
# and open the template in the editor.
gem 'jruby-openssl'
puts "Hello World"

require 'java'
require 'sikuli'

Sikuli::Config.run do |config|
  config.image_path = "#{Dir.pwd}/images/"
  config.logging = false
end

screen = Sikuli::Screen.new
screen.click("C:\\1.png")