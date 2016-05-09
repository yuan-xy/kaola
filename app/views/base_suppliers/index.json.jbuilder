json.array!(@base_suppliers) do |base_supplier|
  json.merge! base_supplier.attributes
end
