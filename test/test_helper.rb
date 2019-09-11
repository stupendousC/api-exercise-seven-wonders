require "minitest/autorun"
require "minitest/reporters"
require "vcr"
require "webmock/minitest"

require "dotenv"
Dotenv.load     
# .env should have ...    MY_KEY="blahblahblah"

require_relative "../lib/seven_wonders" # or wherever the main program is

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new


VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes" # folder where casettes will be located
  config.hook_into :webmock # tie into this other tool called webmock
  config.default_cassette_options = {
    :record => :new_episodes,    # record new data when we don't have it yet
    :match_requests_on => [:method, :uri, :body], # The http method, URI and body of a request all need to match
  }

  # Don't leave our token lying around in a cassette file.
  # ex: https://us1.locationiq.com/v1/search.php?format=json&key=&q=Seattle <- look! key=<erased>
  config.filter_sensitive_data("<KEY>") do   # note the quotes!
    ENV["KEY"]
  end
end