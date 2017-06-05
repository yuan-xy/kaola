def read_custome_fk
  fks = []
  File.open('custom_fk.txt').each_line do |x|
    next if x[0]=='#'
    fks << x.split(',').map{|x| x.strip}
  end
  fks.delete_if{|x| x.size!=3}  #空行/不符合格式行的删除
  fks
end

def all_fks
  arr = ActiveRecord::Base.connection.find_fks
  read_custome_fk.each{|x| arr << x}
  arr
end

def merge_custome_relation
  fks2 = all_fks.map do |arr|
    t1, t2, fk = arr
    t1 = t1.singularize
    t2 = t2.singularize
    c1 = Object.const_get(t1.camelize.singularize)
    c2 = Object.const_get(t2.camelize.singularize)
    [t1,t2, c1, c2, fk, t2]
  end

  $many2 = {}

  fks2.each do |arr|
    t1,t2, c1, c2, fk, fk_prefix = arr
    if $belongs2[t1].nil?
      $belongs2[t1] = [t2]
    else
      $belongs2[t1] << t2
    end
    if $belongs[t1].nil?
      $belongs[t1] = [[fk_prefix, c2, fk]]
    else
      $belongs[t1] << [fk_prefix, c2, fk]
    end  
    if $many[t2].nil?
      $many[t2] = [t1]
    else
      $many[t2] << t1
    end
    if $many2[t2].nil?
      $many2[t2] = [[c1,fk,t1]]
    else
      $many2[t2] << [c1,fk,t1]
    end
  end

end


