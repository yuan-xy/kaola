require_relative 'boot'

require 'rails/all'
require 'rack/cors'

require_relative '../custom_fk'

$many = YAML.load(File.read('./public/many.yaml'))
$belongs = YAML.load(File.read('./public/belongs.yaml'))
$belongs_class = YAML.load(File.read('./public/belongs_class.yaml'))

#$belongs.each{|k,v| raise "$belongs duplicate: #{k} -> #{v}" if v.uniq.size != v.size} if $belongs
#$many.each{|k,v| raise "$many duplicate: #{k} -> #{v}" if v.uniq.size != v.size} if $many

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ScmApi
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = "zh-CN"

    config.generators do |g|
      g.orm             :active_record, migration: false
      g.template_engine :erb
      g.helper          false
      g.test_framework  false
      g.stylesheets     false
      g.javascripts     false      
      g.jbuilder        false
    end
    config.middleware.use Rack::Attack
    config.middleware.use Rack::Deflater
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get, :post, :delete, :put, :patch, :options, :head]
      end
    end
  end
end
