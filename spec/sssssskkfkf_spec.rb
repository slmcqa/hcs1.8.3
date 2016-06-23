
require 'spec_helper'
describe 'Challenges Happy Flow', :type => :feature do
# test variables
let(:test_image){ "#{Dir.pwd}/assets/tree.png" } # TODO, change to non-rails path
let(:response_answer_max_chars){ '100' }
let(:response_answer_match){ 'big fish' }
let(:response_max_overall){ '100' }
let(:response_interval){ '1' }
let(:response_type){ 'Text Survey' }
let(:response_type_expected){ 'Survey' }
let(:response_types){
[
"Submit Photo",
"Submit Video",
"Caption Photo",
"View URL",
"View Photo",
"View YouTube",
"Share",
"Post",
"Connect",
"Like",
"Follow",
"Facebook Post",
"Ratings Survey",
"Multiple Choice Survey",
"Text Survey",
"Numeric Survey",
"Update Profile",
"Update Preference",
"Custom"
]
}
before :all do
# these variables are defined here so they can be used in the after callback
@admin_email = 'testautomation@stellarloyalty.com'
@admin_password = '12345678'
@challenge_name = "Test Challenge #{`hostname`.chomp}"
# declare faker variables here because faker generates unique values for each test case
@challenge_description = Faker::Lorem.paragraphs.join[0..249] # 250 characters
@response_question = Faker::Hacker.say_something_smart
end
after :all do
login(@admin_email, @admin_password)
within('div#main-navbar-collapse'){ click_link 'Challenges' }
within('div#challenges') { click_link @challenge_name }
within('div.block-flat.show-info') { click_link 'Edit' }
within('div.modal-footer') { find_link('Delete').click(false) } # false = no wait, alert is immediate
page.driver.browser.switch_to.alert.accept
click_link('console-nav-profile')
click_link('Logout')
end
it 'should be able to create a Challenge from the Admin console' do
login(@admin_email, @admin_password)
within('div.cl-sidebar') do
expect(find('.active')).to have_link('Program Dashboard')
end
# navigate to challenges
within('div#main-navbar-collapse') do
expect(find('.active')).to have_link('Home')
click_link 'Challenges'
expect(find('.active')).to have_link('Challenges')
end
# assert challenges side bar is active
within('div.cl-sidebar') do
expect(find('.active')).to have_link('Challenges')
end
# assert page head content
within('div.page-head') do
expect(find('h2')).to have_text('Challenges')
expect(find('div.how-to-help-text')).to have_text('Challenges engage members with interesting activities.')
end
# create challenge
within('#new_challenge') do
fill_in 'challenge_label', with: @challenge_name
click_button 'Create'
end
expect(page).to have_text('Success')
expect(page).to have_text('New challenge created')
# pop modal displays
expect(page).to have_css("form[id^=edit_challenge_]")
# edit created challenge
within('form[id^=edit_challenge_]') do
expect(find('#challenge_label').value).to have_text(@challenge_name) # name is persisted
fill_in 'challenge_description', with: @challenge_description
# array of response types are in dropdown list
expect(
page.has_select?('challenge_response_type', with_options: response_types)
).to be_truthy
select response_type, from: 'challenge_response_type'
attach_file 'challenge_image', test_image
fill_in 'challenge_metric_amount', with: '100'
click_button 'Save'
end
within('div#challenges') { click_link @challenge_name }
within('div.tab-container') do
expect(find('.active')).to have_link('Definition')
click_link 'Definition'
end
within('div#definition_tab') do
#expect(page).to have_text('Question Type')
expect(page).to have_text('Definition for Text Survey')
#expect(page).to have_text('Numeric')
expect(page).to have_text('Correct Answer')
expect(page).to have_text('All answers are accepted')
click_link('Edit')
end
# edit modal displays
expect(page).to have_css("div.modal-content")
within('div.modal-content') do
#expect(page).to have_text('Question type')
expect(page).to have_text('Question')
expect(page).to have_text('Answer')
end
within('form#edit_response_type') do
#select 'Text', from: 'response_type_properties_question_type' # this triggers change in fields
expect(find('input#single-file-uploader').visible?).to be_truthy
expect(find('textarea#response_type_properties_question').visible?).to be_truthy
expect(find('input#response_type_properties_maximum_number_of_characters').visible?).to be_truthy
attach_file 'single-file-uploader', test_image
fill_in 'response_type_properties_question', with: @response_question
fill_in 'response_type_properties_maximum_number_of_characters', with: response_answer_max_chars
select 'Matches', from: 'response-qualifier'
fill_in 'response_type_correct_response', with: response_answer_match
click_button 'Save'
end
# navigate to advanced settings tab
within('div.tab-container') do
expect(find('.active')).to_not have_link('Advanced')
click_link 'Advanced'
expect(find('.active')).to have_link('Advanced')
end
# update limit settings
within('div#challenge-limits'){ click_link 'Edit' }
within('form[id^=edit_challenge_]') do
# update overall max responses
# work-around for checking/unchecking checkbox because
# uncheck('challenge_response_max_overall_unli') doesn't work
if find("input#challenge_response_max_overall")['readonly'] == 'true'
find("label[for=challenge_response_max_overall_unli]").click
end
fill_in('challenge_response_max_overall', with: response_max_overall )
# update response interval
if find("input#challenge_response_interval")['readonly'] == 'true'
find("label[for=challenge_response_interval_unli]").click
end
fill_in('challenge_response_interval', with: response_interval )
select 'Minute', from: 'challenge_response_interval_unit'
click_button 'Save'
end
# update share settings
within('div#challenge-sharing') { click_link 'Edit' }
within('form[id^=edit_challenge_]') do
select 'On Submission', from: 'challenge_share_on_news_feed'
select 'Main Newsfeed', from: 'challenge_news_feed_id'
click_button 'Save'
end
# set focus on page head, workaround so floating navbar doesn't get triggered
page.execute_script("document.getElementById('challenge_page_head').scrollIntoView()")
# update the status
within('div.block-flat.show-statuses') { click_link 'Edit' }
expect(find("div.modal-content").visible?).to be_truthy
within('form[id^=edit_challenge_]') do
select 'Published', from: 'challenge_status'
# select 'Schedule', from: 'schedule_select'
# ts = Time.now
# find('input#challenge_effectivity_start').click # trigger calender
# find('input#challenge_effectivity_start').set(ts.strftime('%Y-%m-%d 00:00'))
# future_year = ts.strftime('%Y').to_i + 1
# find('input#challenge_effectivity_end').click # trigger calender
# find('input#challenge_effectivity_end').set(ts.strftime("#{future_year}-%m-%d 00:00"))
click_button 'Save'
end
end