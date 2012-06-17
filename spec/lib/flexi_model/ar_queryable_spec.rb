require 'spec_helper'

describe FlexiModel::ArQueryable do
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
      let(:loaded_user) { User.find(users.first._id) }
      subject { loaded_user }

      its(:_id) { should == loaded_user._record.id }
      its(:name) { should == 'hasan' }
    end
  end

  describe '#all' do
    let!(:users) {
      User.destroy_all
      10.times.map do |i|
        User.create(name: "user name - #{i}")
      end
    }

    it 'should load all records' do
      User.all.map(&:_id).should == users.map(&:_id)
    end

    it 'should return an array' do
      users.should be_instance_of Array
    end

    it 'should set _id and _record to all loaded instance' do
      users.map { |u| [u._id.class.name, u._record.class.name] }.flatten.should == (['Fixnum', 'FlexiModel::ArModels::Record'] * 10).flatten
    end

    context 'should not mix data with other model' do
      before do
        module ArQuerySpec
          class Item
            include FlexiModel
            flexi_field :location, String
          end

          class Item2
            include FlexiModel
            flexi_field :location, String
          end
        end

        ArQuerySpec::Item.destroy_all
        ArQuerySpec::Item2.destroy_all

        3.times.each { ArQuerySpec::Item.create location: 'khulna' }
        5.times.each { ArQuerySpec::Item2.create location: 'dhaka' }
      end


      it 'should have 5 items from Item2' do
        ArQuerySpec::Item2.all.count.should == 5
      end

      it 'should have 3 items from Item' do
        ArQuerySpec::Item.all.count.should == 3
      end
    end
  end

  describe '#first' do
    before do
      module ArQuerySpec
        class Item3
          include FlexiModel
          flexi_field :address, String
        end

        class Item4
          include FlexiModel
          flexi_field :address, String
        end
      end

      ArQuerySpec::Item3.create address: 'Dhaka, bangladesh'
    end

    it 'should load first record' do
      ArQuerySpec::Item3.first.address.should == 'Dhaka, bangladesh'
    end

    it 'should not mix data with other model' do
      ArQuerySpec::Item3.destroy_all
      ArQuerySpec::Item4.destroy_all

      lambda {
        ArQuerySpec::Item3.create address: 'Dhaka, bangladesh'
      }.should_not change(ArQuerySpec::Item4, :count).by(1)

      lambda {
        ArQuerySpec::Item4.create address: 'Dhaka, bangladesh'
      }.should_not change(ArQuerySpec::Item3, :count).by(1)

      ArQuerySpec::Item3.first.address.should == 'Dhaka, bangladesh'
      ArQuerySpec::Item4.first.address.should == 'Dhaka, bangladesh'
    end
  end

  describe '#last' do
    before {
      User.create name: 'hi from last'
    }

    it 'should load last record' do
      User.last.name.should == 'hi from last'
    end

    it 'should not mix data with other model' do
      ArQuerySpec::Item3.destroy_all
      ArQuerySpec::Item4.destroy_all

      lambda {
        ArQuerySpec::Item3.create address: 'Dhaka, bangladesh'
      }.should_not change(ArQuerySpec::Item4, :count).by(1)

      lambda {
        ArQuerySpec::Item4.create address: 'Dhaka, bangladesh'
      }.should_not change(ArQuerySpec::Item3, :count).by(1)

      ArQuerySpec::Item3.last.address.should == 'Dhaka, bangladesh'
      ArQuerySpec::Item4.last.address.should == 'Dhaka, bangladesh'
    end
  end

  describe '#where' do
    before do
      module ArQuerySpec
        class Item5
          include FlexiModel
          flexi_field :name, String
          flexi_field :city, String
        end

        class Item6
          include FlexiModel
          flexi_field :address, String
        end
      end

      5.times.each { |i| ArQuerySpec::Item5.create(name: "hasan - #{i}", city: 'dhaka') }
      3.times.each { |i| ArQuerySpec::Item5.create(name: "khan - #{i}", city: 'chittagong') }
    end

    it 'should allow conditions' do
      ArQuerySpec::Item5.where(city: 'dhaka').count.should == 5
      ArQuerySpec::Item5.where(city: 'chittagong').count.should == 3
    end

    describe 'valid query' do
      let(:query) { ArQuerySpec::Item5.where(city: 'dhaka') }
      subject { query }

      its(:to_sql) { should =~ /INNER\s*JOIN\s*"flexi_model_values"/ }

      it 'should query with valid field id' do
        field = ArQuerySpec::Item5._flexi_collection.fields.select { |f| f.name == 'city' }.first
        subject.to_sql.should =~ /\"flexi_model_values\".\"field_id\"\s*=\s*#{field.id}/
      end

      its(:to_sql) { should =~ /"flexi_model_values\".\"str_value\"\s*=\s*'dhaka'/ }
    end

    it 'should not mix data with other model'

    describe '#order' do
      let(:items) do
        ('a'..'z').map { |_c| _c }.shuffle.each do |_c|
          ArQuerySpec::Item5.create(name: "#{_c}_name", city: "#{_c}_city")
        end
      end

      it 'should allow conditions and order' do
        ArQuerySpec::Item5.destroy_all
        items

        ArQuerySpec::Item5.all.count.should == 26
        names = ArQuerySpec::Item5.all.order(:name, :asc).map(&:name)

        ('a'..'z').each_with_index do |_c, i|
          names[i].should == "#{_c}_name"
        end
      end

      it 'should not mix data with other model'
    end
  end

end