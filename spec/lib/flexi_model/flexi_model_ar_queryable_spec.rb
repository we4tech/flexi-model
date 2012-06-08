require 'spec_helper'

describe FlexiModel::Queryable do
  class User
    include FlexiModel

    flexi_field :name, String
  end

  describe '#find' do
    let(:users) {
      [User.create(name: 'hasan'),
       User.create(name: 'khan'),
       User.create(name: 'tanveer')]
    }

    it 'should find an existing record by id' do
      user = User.find(users.first._id)
      user.should be
    end

    describe 'loaded record' do
      it 'should have _id'
    end
  end

  describe '#all' do
    it 'should load all records'
    it 'should return an array'
    it 'should set _id and _record to all loaded instance'
    it 'should not mix data with other model'
  end

  describe '#first' do
    it 'should load first record'
    it 'should not mix data with other model'
  end

  describe '#last' do
    it 'should load last record'
    it 'should not mix data with other model'
  end

  describe '#where' do
    it 'should allow conditions'
    it 'should not mix data with other model'
  end

  describe '#where.order' do
    it 'should allow conditions and order'
    it 'should not mix data with other model'
  end

end