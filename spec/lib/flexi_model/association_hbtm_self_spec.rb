require 'spec_helper'

describe 'Association With self HasAndBelongsToMany' do
  module Abc
    class Category
      include FlexiModel

      _string :name
      has_and_belongs_to_many :categories
    end
  end

  it 'should not throw any error while creating without association' do
    lambda {
      Abc::Category.create(name: 'Cat 1')
    }.should_not raise_error
  end

  it 'should not throw any error while creating with association' do
    lambda {
      Abc::Category.create(name: 'Cat 1', categories: 5.times.map { |i| Abc::Category.new(name: "Cat - #{i}") })
    }.should_not raise_error
  end

  it 'should create category instance without association' do
    lambda {
      Abc::Category.create(name: 'cat 1')
    }.should change(Abc::Category, :count).by(1)
  end

  it 'should associate with multiple categories' do
    lambda {
      Abc::Category.create(name: 'Cat 1', categories: 5.times.map { |i| Abc::Category.new(name: "Cat - #{i}") })
    }.should change(Abc::Category, :count).by(6)
  end

  it 'should not create already created child categories' do
    _cats = 5.times.map { |i| Abc::Category.create(name: "Cat - #{i}") }
    lambda {
      Abc::Category.create(name: 'Cat 1', categories: _cats)
    }.should change(Abc::Category, :count).by(1)
  end

  it 'should retrieve all child categories' do
    _cats = 5.times.map { |i| Abc::Category.create(name: "Cat - #{i}") }
    _cat  = Abc::Category.create(name: 'Cat 1', categories: _cats)

    _cat.categories.to_a.map(&:_id).sort.should == _cats.map(&:_id).sort
  end

  it 'should create child categories by category_ids' do
    _cats = 5.times.map { |i| Abc::Category.create(name: "Cat - #{i}") }
    _cat  = Abc::Category.create(name: 'Cat 1', category_ids: _cats.map(&:_id))

    _inst = Abc::Category.find(_cat._id)
    _inst.categories.to_a.map(&:_id).sort.should == _cats.map(&:_id).sort
  end
end