# frozen_string_literal: true

require 'google/apis/civicinfo_v2'
require 'csv'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civicinfo = Google::Apis::CivicinfoV2::CivicInfoService.new
  civicinfo.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civicinfo.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letters(form_letter, name, zipcode)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{name}_#{zipcode}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

file = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol
template_letter = File.read 'form_letter.erb'
erb_template = ERB.new template_letter

# file.each do |row|
#   name = row[:first_name]
#   zipcode = row[:zipcode]
#   zipcode = clean_zipcode(zipcode)
#   legislators = legislators_by_zipcode(zipcode)
#   personal_letter = erb_template.result(binding)
#   save_thank_you_letters(personal_letter, name, zipcode)
# end

def clean_phone_number(phone_number)
  phone_number > 10 || phone_number < 10 ? 'Bad number' : phone_number
  phone_number == 11 && phone_number[0] == 1 ? phone_number[0..10] : 'Bad number'
end

def best_hour_for_ads(attendees)
  hours = []
  attendees.each do |row|
    isolated_hour = row[:regdate].split(' ')[1].split(':')[0]
    hours.push(isolated_hour)
  end

  hours.uniq.max_by(3) { |i| hours.count(i) }
end

def best_day_for_ads(attendees)
  days = []
  attendees.each do |row|
    year = row[:regdate].split(' ')[0].split('/')[2].to_i
    month = row[:regdate].split(' ')[0].split('/')[0].to_i
    day = row[:regdate].split(' ')[0].split('/')[1].to_i
    days << Date.new(year, month, day).wday
  end
  days
end

best_day_for_ads(file)
