ActiveRecord::Base.establish_connection(
    :adapter  => "sqlite3",
    :database => ':memory:',
    :pool     => 5,
    :timeout  => 5000
)

require File.join(File.dirname(__FILE__), '..', 'fixtures', 'schema.rb')
