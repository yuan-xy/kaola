
def exsits_belongs(x1, x2)
  return true if $many2many.find{|x| x==[x1,x2]}
  $belongs[x1].try(:each) do |belong|
    return true  if belong == x2.singularize
    if belong.class == Array
      return true if belong[1].table_name == x2
    end
  end
  false
end

$many2many=[]
$belongs.map do |key, arr|
  next if arr.size<2
  arr.permutation(2).each do |comb|
    x1, x2 = comb
    x1 = x1[1].table_name if x1.class==Array
    x2 = x2[1].table_name if x2.class==Array
    next if exsits_belongs(x1, x2)
    $many2many << [x1,x2]
    filename = "app/models/#{x1.singularize}.rb"
    insert_into_file(filename, "\n  has_many :#{x2.pluralize}, through: :#{key.pluralize}", "\nend", false)
  end
end
