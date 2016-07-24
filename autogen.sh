touch belongs.yaml
touch many.yaml
cp lib/templates/jbuilder/*.jbuilder ~/.rvm/gems/ruby-2.3.0/gems/jbuilder-2.4.1/lib/generators/rails/templates/
rails r autogen.rb 
rails r gen_index.rb
