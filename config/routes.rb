class ActionDispatch::Routing::Mapper
  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/#{routes_name}.rb")))
  end
end

Rails.application.routes.draw do
  draw :route_common
  draw :route_codegen
end