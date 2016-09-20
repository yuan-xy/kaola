require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'rack/cors'

$many = YAML.load(File.read('./public/many.yaml'))
$belongs = YAML.load(File.read('./public/belongs.yaml'))

str = <<-FOO
select  product_code,product_name,common_name,product_license,product_spec,product_unit,dosage_form,manu_facturer,kc,spell_code
 from 
(select id,tbw_store_id  from tpo_rm_headers where tbw_store_id=? ) b
left join 
(select id,tpo_rm_header_id,tbp_product_id,(rm_qty-sales_qty-rtv_qty-rtv1_qty) kc,
batch_no,expired_date,production_date from tpo_rm_details  where (rm_qty-sales_qty-rtv_qty-rtv1_qty)>0) a
on a.tpo_rm_header_id=b.id
left join 
(select id,product_code,product_name,common_name,spell_code,product_license,product_spec,product_unit,dosage_form,manu_facturer from tbp_products
where (spell_code like ? or product_code like ? )) c
on a.tbp_product_id=c.id
 where  a.tpo_rm_header_id=b.id and  a.tbp_product_id=c.id
order by expired_date
FOO

$raw_sqls=[nil,
        "select * from  tbp_products where id in (select tbp_product_id  from tbp_product_mappings)",
        "select * from  tbp_products where id in (select tbp_product_id  from tbp_product_mappings)",
        str     
      ]

$raw_sql_params=[0,0,0,3]

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
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    config.generators do |g|
      g.orm             :active_record, migration: false
      g.template_engine :erb
      g.helper          false
      g.test_framework  false
      g.stylesheets     false
      g.javascripts     false      
    end
    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get, :post, :delete, :put, :patch, :options, :head]
      end
    end
  end
end
