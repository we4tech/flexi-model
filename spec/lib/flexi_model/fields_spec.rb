require 'spec_helper'

describe FlexiModel::Fields do
  context 'New Flex Model' do

    describe '.set_flexi_namespace' do
      class MyModel
        include FlexiModel
      end

      context 'with namespace' do
        it 'should set namespace' do
          MyModel.get_flexi_namespace.should == 'mymodel'
        end

        it 'should store namespace in class scope' do
          class A
            include FlexiModel
          end

          A.get_flexi_namespace.should == 'a'

          class B
            include FlexiModel
          end

          A.get_flexi_namespace.should == 'a'
          B.get_flexi_namespace.should == 'b'
        end
      end

      it 'should have partition id 0' do
        MyModel.flexi_partition_id.should == 0
      end
    end

    describe '.set_flexi_partition_id' do
      class PModelA
        include FlexiModel

        set_flexi_partition_id 20
        flexi_field :name, String

      end

      class PModelB
        include FlexiModel

        set_flexi_partition_id 30
        flexi_field :name, String
      end

      it 'should set partition id 20' do
        PModelA.new.get_flexi_collection.partition_id.should == 20
        PModelB.new.get_flexi_collection.partition_id.should == 30
      end
    end

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
          MyModel.flexi_field :first_name, String, :default => 'untitled'
        }.should change(MyModel.flexi_fields, :count).by(1)
      end

      it 'should not define duplicate field' do
        MyModel.flexi_fields = []
        MyModel.flexi_fields.count.should == 0

        MyModel.flexi_field :name, String, :default => 'untitled'
        MyModel.flexi_fields.count.should == 1

        MyModel.flexi_field :name, String, :default => 'untitled'
        MyModel.flexi_fields.count.should == 1
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

    it 'should set attributes through constructor' do
      lambda {
        Model1.new(name: 'hasan', email: 'khan@hasan.com', phone: "+32323233")
      }.should_not raise_error
    end

    it 'should expose getter for each flexi field' do
      inst = Model1.new
      [:name, :email, :phone].each do |f|
        inst.respond_to?(f).should be
      end
    end

    it 'should expose setter for each flexi field' do
      inst = Model1.new
      [:name, :email, :phone].each do |f|
        inst.respond_to?(:"#{f}=").should be
      end
    end
  end

  context 'multi parameters' do
    class Cat
      include FlexiModel
      _ff :name, :string
      _ff :feed_at, :datetime

      validates_presence_of :name, :feed_at
    end

    it 'should create cat with multiple parameters' do
      lambda {
        Cat.create(
            name:                'Cat2',
            "feed_at(1i)" => "2012",
            "feed_at(2i)" => "6",
            "feed_at(3i)" => "23",
            "feed_at(4i)" => "09",
            "feed_at(5i)" => "58"
        )
      }.should change(Cat, :count).by(1)
    end

    it 'should create cat without multiple parameters' do
      lambda {
        Cat.create(name: 'Cat1', feed_at: Time.now)
      }.should change(Cat, :count).by(1)
    end
  end
end