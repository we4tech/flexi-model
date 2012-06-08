require 'spec_helper'

describe FlexiModel::Persistence do
  class Model
    include FlexiModel

    flexi_field :name, String
    flexi_field :email, String

  end

  describe 'exposed methods' do
    [:save, :create, :update_attributes, :update_attribute,
     :destroy, :destroy_all, :delete_all, :count, :length].each do |f|
      it "should have method - #{f}" do
        Model.new.respond_to?(f).should be_true
      end
    end
  end

  describe '#save' do
    it 'should have #save method' do
      Model.new().respond_to?(:save).should be
    end

    it 'should save new record' do
      inst = Model.new(:name => 'hasan', :email => 'hasan@swi.com')
      lambda {
        inst.save
      }.should change(Model, :count).by(1)
    end

  end

  describe '#create'

  describe '#update_attributes'
  describe '#destroy'

end