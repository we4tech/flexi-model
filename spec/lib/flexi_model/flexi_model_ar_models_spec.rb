require 'spec_helper'

describe FlexiModel::ArModels do

  describe FlexiModel::ArModels::Collection do
    subject { FlexiModel::ArModels::Collection }

    describe '#create' do
      it 'should create new record' do
        lambda {
          subject.create(name: 'Products')
        }.should change(subject, :count).by(1)
      end
    end

    describe '#find' do
      before { subject.create(name: 'products_collection') }

      it 'should find products collection' do
        subject.find_by_name('products_collection').should be
      end
    end

    describe '#destroy' do
      let!(:inst) { subject.create(name: 'products_collection') }

      it 'should destroy a collection' do
        lambda {
          inst.destroy
        }.should change(subject, :count).by(-1)
      end
    end
  end

  describe FlexiModel::ArModels::Field do
    subject { FlexiModel::ArModels::Field }

    describe '#create' do
      it 'should create field' do
        lambda {
          inst = subject.create(name: 'email', field_type: 'email')
        }.should change(subject, :count).by(1)
      end
    end

    describe '#find' do
      before { subject.create(name: 'email', field_type: 'email') }

      it 'should find an existing field' do
        subject.find_by_name('email').should be
      end
    end

    describe '#destroy' do
      before { subject.create(name: 'email', field_type: 'email') }

      it 'should destroy an existing object' do
        lambda {
          subject.find_by_name('email').destroy
        }.should change(subject, :count).by(-1)
      end
    end

    context 'association' do
      let!(:coll1) { FlexiModel::ArModels::Collection.create(name: 'products') }
      before {
        coll1.update_attribute :fields, [
            FlexiModel::ArModels::Field.new(name: 'name', field_type: 'string'),
            FlexiModel::ArModels::Field.new(name: 'email', field_type: 'email')
        ]
      }
      subject { FlexiModel::ArModels::Collection.find_by_name('products') }

      its('fields.count') { should == 2 }
      its('fields.first.name') { should == 'name' }
      its('fields.last.name') { should == 'email' }
    end
  end

  describe FlexiModel::ArModels::Record do
    let!(:products) { FlexiModel::ArModels::Collection.create(name: 'products') }
    let(:new_record) do
      FlexiModel::ArModels::Record.create(
          :collection => products,
          :values     => [
              FlexiModel::ArModels::Value.new(
                  field: products.fields.first,
                  value: 'hasan khan'
              ),
              FlexiModel::ArModels::Value.new(
                  field: products.fields[1],
                  value: 'hasan@swi.com'
              ),
              FlexiModel::ArModels::Value.new(
                  field: products.fields.last,
                  value: 3
              ),

          ]
      )
    end
    before {
      products.update_attribute :fields, [
          FlexiModel::ArModels::Field.new(name: 'name', field_type: 'string'),
          FlexiModel::ArModels::Field.new(name: 'email', field_type: 'email'),
          FlexiModel::ArModels::Field.new(name: 'position', field_type: 'integer')
      ]
    }

    context 'when new instance' do
      subject { FlexiModel::ArModels::Record }

      it 'should store new record' do
        lambda {
          new_record
        }.should change(subject, :count).by(1)
      end

      it 'should add rows in value table' do
        lambda {
          new_record
        }.should change(FlexiModel::ArModels::Value, :count).by(3)
      end
    end

    context 'when stored instance' do
      subject { new_record }

      its('values.count') { should == 3 }
      its(:values) { subject.first.value.should == 'hasan khan' }
      its(:values) { subject[1].value.should == 'hasan@swi.com' }
      its(:values) { subject.last.value.should == 3 }
    end

    describe '#destroy' do
      before { new_record }

      it 'should destroy an existing record' do
        lambda {
          FlexiModel::ArModels::Record.find(new_record.id).destroy
        }.should change(FlexiModel::ArModels::Record, :count).by(-1)
      end

      it 'should remove associated values from' do
        lambda {
          FlexiModel::ArModels::Record.find(new_record.id).destroy
        }.should change(FlexiModel::ArModels::Value, :count).by(-3)
      end
    end

  end

  describe FlexiModel::ArModels::Value

end