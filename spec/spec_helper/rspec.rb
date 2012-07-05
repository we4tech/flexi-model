RSpec.configure do |config|
  config.mock_with :rspec

  require "paperclip/matchers"
  config.include Paperclip::Shoulda::Matchers
end