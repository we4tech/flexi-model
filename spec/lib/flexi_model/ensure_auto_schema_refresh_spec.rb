require 'spec_helper'

module Test
  ;
end

describe 'Ensure auto schema refreshed' do

  it 'class with simple schema' do
    class Test::User
      include FlexiModel
      _ff :name, :string
      _ff :email, :string
    end

    Test::User.new

    Test::User.flexi_fields.map { |f| [f.name, f.type, f.default] }.should be == [
        [:name, 'string', nil],
        [:email, 'string', nil]
    ]
  end

  it 'class with updated schema' do
    Test.send :remove_const, :User

    class Test::User
      include FlexiModel
      _ff :name, :string
      _ff :email, :string
    end

    Test::User.new
    Test.send :remove_const, :User

    class Test::User
      include FlexiModel
      _ff :name, :string
      _ff :avail, :datetime
    end

    Test::User.new

    Test::User.flexi_fields.map { |f| [f.name, f.type, f.default] }.should be == [
        [:name, 'string', nil],
        [:avail, 'datetime', nil]
    ]

    Test.send :remove_const, :User

    PROC = lambda { |i| Time.now }
    class Test::User
      include FlexiModel
      _ff :name, :string
      _ff :avail, :datetime, default: PROC
    end

    Test::User.new

    Test::User.flexi_fields.map { |f| [f.name, f.type, f.default] }.should be == [
        [:name, 'string', nil],
        [:avail, 'datetime', PROC]
    ]
  end


end