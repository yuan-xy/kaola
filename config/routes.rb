Rails.application.routes.draw do
  resources :ts_codes
  resources :tbw_warehouses
  resources :tbw_warehouse_logs
  resources :tbw_locations
  resources :tbw_bins
  resources :tbw_bin_types
  resources :tbs_suppliers
  resources :tbs_supplier_warehouses
  resources :tbs_supplier_stores
  resources :tbs_first_suppliers
  resources :tbp_product_types
  resources :tbp_product_suppliers
  resources :tbp_product_skus
  resources :tbp_product_minmaxes
  resources :tbp_product_logs
  resources :tbp_product_locations
  resources :tbp_product_exts
  resources :tbp_product_costs
  resources :tbp_product_barcodes
  resources :tbp_products
  resources :tbp_package_units
  resources :tbp_first_products
  resources :tbp_combin_headers
  resources :tbp_combin_details
  resources :tbp_brands
  resources :tbp_barcode_print_logs
  resources :tbe_expresses
  resources :tbe_express_print_templates
  resources :tbe_express_platforms
  resources :tbe_express_onlineatts
  resources :tbe_express_onlineattr_warehouses
  resources :tbe_express_areas
  resources :tbc_imgs
  resources :tbc_companies
  resources :tbc_certificate_imgs
  resources :ts_codes
  resources :tbs_first_suppliers
  resources :tbc_imgs
  resources :tbc_certificate_imgs

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
