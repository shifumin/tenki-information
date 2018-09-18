# frozen_string_literal: true

require 'capybara'
require 'selenium-webdriver'
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

Capybara.configure do |capybara_config|
  capybara_config.default_driver = :selenium_chrome_headless
end

Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :selenium_chrome_headless

@session = Capybara::Session.new(:selenium_chrome_headless)

# 市原市の天気(tenki.jp)
@session.visit('https://tenki.jp/forecast/3/15/4510/12219/3hours.html')
sleep 5 # waiting for getting assets
@session.driver.execute_script('window.scrollBy(20,555)')
@session.driver.browser.manage.window.resize_to(705, 575)
sleep 1
@session.save_screenshot('./tenki_jp_ichihara.png')

# 市原市の天気(Yahoo!天気)
@session.visit('https://weather.yahoo.co.jp/weather/jp/12/4510/12219.html')
sleep 5 # waiting for getting assets
@session.driver.execute_script('window.scrollBy(0,390)')
@session.driver.browser.manage.window.resize_to(650, 370)
sleep 1
@session.save_screenshot('./yahoo_tenki_ichihara.png')

# 台東区の天気(tenki.jp)
@session.visit('https://tenki.jp/forecast/3/16/4410/13106/3hours.html')
sleep 5 # waiting for getting assets
@session.driver.execute_script('window.scrollBy(20,555)')
@session.driver.browser.manage.window.resize_to(705, 575)
sleep 1
@session.save_screenshot('./tenki_jp_taitou.png')

# 台東区の天気(Yahoo!天気)
@session.visit('https://weather.yahoo.co.jp/weather/jp/13/4410/13106.html')
sleep 5 # waiting for getting assets
@session.driver.execute_script('window.scrollBy(0,390)')
@session.driver.browser.manage.window.resize_to(650, 370)
sleep 1
@session.save_screenshot('./yahoo_tenki_taitou.png')

@session.driver.quit

def post_weather(client, file, place, site)
  client.files_upload(
    channels: '#test',
    as_user: true,
    file: Faraday::UploadIO.new(file, 'image/png'),
    title: "#{place}の#{Time.now.strftime("%m月%d日(#{%w(日 月 火 水 木 金 土)[Time.now.wday]})")}の天気(#{site})",
    filename: "#{File.basename(file, '.*')}_#{Time.now.strftime('%Y%m%d%H%M')}.png",
    initial_comment: "#{place}の#{Time.now.strftime("%m月%d日(#{%w(日 月 火 水 木 金 土)[Time.now.wday]})")}の天気(#{site})です。"
  )
end

client = Slack::Web::Client.new

post_weather(client, 'tenki_jp_ichihara.png', '市原市', 'tenki.jp')
post_weather(client, 'yahoo_tenki_ichihara.png', '市原市', 'Yahoo!天気')
post_weather(client, 'tenki_jp_taitou.png', '台東区', 'tenki.jp')
post_weather(client, 'yahoo_tenki_taitou.png', '台東区', 'Yahoo!天気')
