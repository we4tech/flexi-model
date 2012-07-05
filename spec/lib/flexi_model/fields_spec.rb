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
            name:         'Cat2',
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

  context 'alternative methods' do
    class Animal
      include FlexiModel
    end

    it 'should have _ff method' do
      Animal.respond_to?(:_ff).should be
    end

    it 'should have types named methods' do
      FlexiModel::Fields::TYPES.each do |_type|
        Animal.respond_to?(:"_#{_type}").should be
      end
    end

    describe 'accept multiple definition through type based method' do
      it 'should not throw any error' do
        lambda {
          class HolaUser
            include FlexiModel
            _string :name, :email
          end
        }.should_not raise_error
      end

      it 'should define 2 fields from the single line definition' do
        class HiUser
          include FlexiModel
          _string :name, :email
        end

        HiUser.flexi_fields.map(&:name).should == [:name, :email]
        HiUser.flexi_fields.map(&:type).should == ['string', 'string']
      end
    end
  end

  describe '.flexi_fields_except_foreign_key' do
    class Cow
      include FlexiModel
      _string :name

      belongs_to :cow
      has_many :cows
    end

    it 'should list all fields' do
      Cow.flexi_fields.map(&:name).should == [:name, :cow_id]
    end

    it 'should exclude foreign keys' do
      Cow.flexi_fields_except_fk.map(&:name).should == [:name]
    end

    it 'should have associated class' do
      Cow.associated_classes[:cow_id].should == :Cow
    end
  end

  describe 'set_flexi_name_field' do
    context 'without explicit definition' do
      class Tiger
        include FlexiModel
        _string :name
      end

      it 'should have _name field' do
        Tiger.new.respond_to?(:_name).should be
      end

      it 'should return value from default field' do
        Tiger.create(name: 'Hola').reload._name.should == 'Hola'
      end
    end

    context 'with explicit definition' do
      class Tiger2
        include FlexiModel
        _string :name
        _string :email

        set_flexi_name_field :email
      end

      it 'should have _name field' do
        Tiger2.new.respond_to?(:_name).should be
      end

      it 'should return value from default field' do
        Tiger2.create(email: 'abc@hola.com', name: 'Hola').reload._name.should == 'abc@hola.com'
      end
    end
  end

  context 'fields without accessor' do
    class AbcDef
      include FlexiModel
      _string :name
      _attachment :file
    end

    it 'should have name only in flexi_fields' do
      AbcDef.flexi_fields.map(&:name).should == [:name]
    end

    it 'should list file in none_flexi_field' do
      AbcDef.none_flexi_fields.map(&:name).should == [:file]
    end

    it 'should generate accessors for name' do
      AbcDef.instance_methods.include?(:name).should be
      AbcDef.instance_methods.include?(:'name=').should be
    end

    it 'should not generate accessors for file' do
      AbcDef.instance_methods.include?('file').should be_false
      AbcDef.instance_methods.include?('file=').should be_false
    end

    class SomeThing
      include FlexiModel
      _string :name
      _attachment :file

      def file=(f)
        @__f = f
        puts "File - #{f}"
      end

      def file
        @__f
      end
    end

    it 'should initialize and save new record without any error' do
      lambda {
        inst = SomeThing.new(name: 'hasan', file: 'hola')
        inst.save
      }.should_not raise_error
    end
  end

end