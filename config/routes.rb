class ActionDispatch::Routing::Mapper
  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/#{routes_name}.rb")))
  end
end

Rails.application.routes.draw do
  resources :tsr_salereturnorder_processes
  resources :tsr_salereturnorder_headers
  resources :tsr_salereturnin_payments
  resources :tsr_salereturn_pkgin_headers
  resources :tsr_salereturn_pkgin_details
  resources :tsr_salereturn_pkg_headers
  resources :tsr_salereturn_pkg_details
  resources :ts_nextseqs
  resources :trw_work_items
  resources :trw_work_item_attachments
  resources :trw_demand_replies
  resources :trw_demand_feedbacks
  resources :tbp_bom_headers
  resources :tbp_bom_details
  resources :jbi_infomations
  resources :jbi_infomation_types
  resources :tuser_psy_evaluations
  resources :tpsy_evaluation_results
  resources :tpsy_evaluation_questions
  resources :tpsy_evaluation_options
  resources :tpsy_evaluation_mains
  resources :tuser_psy_evaluations
  resources :tpsy_evaluation_results
  resources :tpsy_evaluation_questions
  resources :tpsy_evaluation_options
  resources :tpsy_evaluation_mains
  draw :route_common
end
