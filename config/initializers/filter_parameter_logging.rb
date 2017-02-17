# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]
Rails.application.config.filter_parameters += [:pass_word]

class ActiveRecord::Base
  def filter_attributes
      attributes.select{ |key, _| key != 'pass_word' && key != 'password' }
  end
end