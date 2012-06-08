require 'spec_helper'

describe FlexiModel do
  context 'New Flex Model' do
    describe '.flexi_field' do
      before do
        class MyModel;
          include FlexiModel
        end
      end

      it 'should have `flexi_field` method' do
        MyModel.respond_to?(:flexi_field).should be
      end

      it 'should define new field' do
        lambda {
          MyModel.flexi_field :name, String, 'untitled'
        }.should change(MyModel.flexi_fields, :count).by(1)
      end
    end

    describe '.remove_flexi_field' do
      before do
        class MyModel;
          include FlexiModel
        end
      end

      it 'should have `remove_flexi_field`' do
        MyModel.respond_to?(:remove_flexi_field).should be
      end

      it 'should remove a defined field' do
        class MyModel2;
          include FlexiModel
        end

        MyModel2.flexi_field :name, String
        MyModel2.flexi_fields.count.should == 1

        MyModel2.remove_flexi_field :name
        MyModel2.flexi_fields.count.should == 0
      end
    end

    describe '.flexi_fields' do
      before {
        class MyModel;
          include FlexiModel
        end }

      it 'should have `flexi_fields`' do
        MyModel.respond_to?(:flexi_fields).should be
      end

      it 'should be an array' do
        MyModel.flexi_fields.should be_instance_of Array
      end
    end

  end

  context 'Defined Flex Model' do
    it 'should have 3 fields' do
      class Model1
        include FlexiModel

        flexi_field :name, String
        flexi_field :email, String
        flexi_field :phone, Integer

      end

      Model1.flexi_fields.count.should == 3
    end


  end
end