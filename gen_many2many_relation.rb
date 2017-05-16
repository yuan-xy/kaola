
$belongs.map do |key, arr|
  next if arr.size<2
  arr.permutation(2).each do |comb|
    x1, x2 = comb
    x1 = x1[1].table_name if x1.class==Array
    x2 = x2[1].table_name if x2.class==Array
    filename = "app/models/#{x1.singularize}.rb"
    insert_into_file(filename, "\n  has_many :#{x2.pluralize}, through: :#{key.pluralize}", "\nend", false)
  end
end
