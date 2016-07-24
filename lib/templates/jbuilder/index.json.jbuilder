json.array!(@<%= plural_table_name %>) do |<%= singular_table_name %>|
  json.merge! <%= singular_table_name %>.attributes
end
