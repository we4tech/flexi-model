require 'spec_helper'

describe FlexiModel::ArPersistence do
  class UserWithMultiple
    include FlexiModel
    _string :name
    _multiple :items, object_type: Hash, object_keys: { :name => :string, :quantity => :decimal }
  end

  it 'should create without error' do
    lambda {
      UserWithMultiple.create(name: 'hasan', items: [{ name: 'hola', quantity: 3 }])
    }.should_not raise_error
  end

  it 'should update without error' do
    inst = UserWithMultiple.create(name: 'hasan', items: [{ name: 'hola', quantity: 3 }])
    lambda {
      inst.update_attribute :name, 'khan'
    }.should_not raise_error
  end

  it 'should store hash' do
    inst = UserWithMultiple.create(name: 'hasan', items: [{ name: 'hola', quantity: 3 }])
    inst.reload.items.should == [{ name: 'hola', quantity: 3 }]
  end

  it 'should retrieve an array' do
    inst = UserWithMultiple.create(name: 'hasan', items: [{ name: 'hola', quantity: 3 }])
    inst.reload.items.should be_an Array
  end

  it 'should not store empty data' do
    inst = UserWithMultiple.create(name: 'hasan', items: [{ name: '', quantity: '' }])
    inst.reload.items.should == []
  end

  it 'should store partial empty data' do
    inst = UserWithMultiple.create(name: 'hasan', items: [{ name: '', quantity: 4 }])
    inst.reload.items.should == [{name: '', quantity: 4}]
  end
end