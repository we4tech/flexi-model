require 'spec_helper'

describe FlexiModel::ArPersistence do
  class Model
    include FlexiModel

    flexi_field :name, String
    flexi_field :email, String

  end

  describe 'exposed methods' do
    context 'static methods' do
      [:set_flexi_label, :get_flexi_label, :flexi_collection_name].each do |m|
        it "should have #{m}" do
          Model.respond_to?(m).should be_true
        end
      end

      it 'should set and get flexi label' do
        Model.set_flexi_label 'product', 'products'
        Model.get_flexi_label.should == ['product', 'products']
      end

      it 'should get default flexi label' do
        Model._flexi_metadata = { }
        Model.get_flexi_label.should == ['Model', 'Models']
      end

      it 'should return collection name' do
        Model.flexi_collection_name.should == 'model'
      end
    end

    context 'instance methods' do
      [:save, :update_attributes, :update_attribute,
       :destroy, :count, :length].each do |f|
        it "should have method - #{f}" do
          Model.new.respond_to?(f).should be_true
        end
      end
    end
  end

  describe '#count' do
    context 'with different models from same namespace' do
      let(:count_a) do
        class CountA
          include FlexiModel
          flexi_field :name, String
        end
      end

      let(:count_b) do
        class CountB
          include FlexiModel
          flexi_field :name, String
        end
      end

      it 'should count only one change' do
        count_a
        lambda {
          inst = CountA.new(:name => 'hasan')
          inst.save
        }.should change(CountA, :count).by(1)
      end

      it 'should not show other model\'s count' do
        count_a
        count_b
        lambda {
          CountA.new(:name => 'hasan').save
          CountB.new(:name => 'hasan').save
        }.should change(CountA, :count).by(1)
      end
    end

    context 'with different namespace from same named models' do
      let(:count_a) do
        class CountAA
          include FlexiModel
          flexi_field :name, String
        end
      end

      let(:count_b) do
        module Hola
          class CountAA
            include FlexiModel
            flexi_field :name, String
            flexi_field :email, String
          end
        end
      end

      it 'should count only one change' do
        count_a
        count_b
        lambda {
          CountAA.new(name: 'hasan').save
          Hola::CountAA.new(name: 'khan', email: 'hasan@abc.com').save
        }.should change(CountAA, :count).by(1)
      end
    end
  end

  describe '#save' do
    it 'should have #save method' do
      Model.new().respond_to?(:save).should be
    end

    context 'without required fields' do
      class UserWithoutRequiredFields
        include FlexiModel

        flexi_field :name, String
        flexi_field :email, String
      end

      it 'should save new record' do
        inst = UserWithoutRequiredFields.new(:name => 'hasan')
        lambda {
          inst.save
        }.should change(UserWithoutRequiredFields, :count).by(1)
      end
    end

    context 'with required field' do
      class UserWithRequiredFields
        include FlexiModel

        flexi_field :first_name, String
        flexi_field :email, String

        validates_presence_of :first_name
      end

      it 'should not save new record' do
        lambda {
          UserWithRequiredFields.create
        }.should_not change(UserWithRequiredFields, :count).by(1)
      end

      it 'should have errors' do
        inst = UserWithRequiredFields.create
        inst.should_not be_valid
      end

      it 'should have one error' do
        inst = UserWithRequiredFields.create
        inst.errors.size.should == 1
      end

      it 'should have errors on :first_name' do
        inst = UserWithRequiredFields.create
        inst.errors.get(:first_name).should == ["can't be blank"]
      end
    end

  end

  describe '.create' do
    it 'should have #create mehtod' do
      Model.respond_to?(:create).should be
    end

    it 'should store new record' do
      Model.create(name: 'hasan', email: 'hasan@khanb.com')._id.should be
    end
  end

  describe '#update_attributes' do
    class User
      include FlexiModel

      flexi_field :name, String
      flexi_field :email, String
    end

    let!(:user) { User.create(name: 'hasan', email: 'k@k.com') }

    it 'should update without error' do
      lambda {
        user.update_attributes name: 'khan'
      }.should_not raise_error
    end

    it 'should update name attribute' do
      user.update_attributes name: 'khan'
      _u = User.find(user._id)
      _u.name.should == 'khan'
    end

    it 'should update email attribute and keep same name' do
      user.update_attributes email: 'khan@def.com'
      _u = User.find(user._id)
      _u.name.should == 'hasan'
      _u.email.should == 'khan@def.com'
    end

    it 'should update both' do
      user.update_attributes email: 'khan@def.com3', name: 'hola'
      _u = User.find(user._id)
      _u.name.should == 'hola'
      _u.email.should == 'khan@def.com3'
    end
  end

  describe '#update_attribute' do
    class HolaUser
      include FlexiModel

      flexi_field :name, String
      flexi_field :email, String
    end

    let!(:user) { HolaUser.create(name: 'hasan', email: 'k@k.com') }


    it 'should not throw error' do
      lambda {
        user.update_attribute :name, 'mia'
      }.should_not raise_error
    end

    it 'should update with a single key and value' do
      user.update_attribute :name, 'vulu'
      _u = HolaUser.find(user._id)
      _u.name.should == 'vulu'
    end
  end

  describe '#destroy' do
    it 'should destroy single record'
  end

  describe '#destroy_all' do
    class Item
      include FlexiModel
      flexi_field :name, String
    end

    before { 10.times.each { Item.create(name: 'hola') } }

    it 'should have 10 items' do
      Item.count.should == 10
    end

    it 'should destroy all records from the model' do

    end
  end

  context 'callbacks' do
    it 'should call - validate'
    it 'should call - save'
    it 'should call - create'
    it 'should call - destroy'
  end

  context 'validations' do
    it 'should throw validation error'
  end

  context 'serialized value' do
    it 'should store hash map'
    it 'should store array'
  end

end