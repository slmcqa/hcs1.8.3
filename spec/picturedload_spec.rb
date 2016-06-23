
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
#require File.dirname(__FILE__) + '/../lib/slmc'

require 'spec_helper'
require 'yaml'
require 'rubygems'
require 'image_downloader'

describe "Picturedload" do
  
  before(:each) do
    @picturedload = Picturedload.new
  end

  it "should desc" do


page_url = 'www.test.com'
target_path = 'img_dir/'
downloader = ImageDownloader::Process.new(page_url,target_path)

#####
# download all images on page in any place (by regexp, all that look like url with image)
downloader.parse(:any_looks_like_image => true)

##### or
# download images from all elements where usually images placed (<img...>, <a...>, ...)
downloader.parse()

##### or
# download image from exect places in page
downloader.parse(:collect => {:link_icon => true})

##### or
# download images by regexp
downloader.parse(:regexp => /[^'"]+\.jpg/i)

downloader.download()
  end
end

