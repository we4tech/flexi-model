require 'spec_helper'

describe FlexiModel::Association do
  describe '#belongs_to' do
    module Bt
      class User
        include FlexiModel

        flexi_field :name, String
        flexi_field :email, String

      end

      class Comment
        include FlexiModel

        belongs_to :user

        flexi_field :content, :text
      end
    end

    describe Bt::Comment do
      [:user_id, :user, :user=].each do |_m|
        it "should have generated method - #{_m}" do
          Bt::Comment.new.respond_to?(_m).should be
        end
      end

      context 'without validation' do
        it 'should create without user association' do
          lambda {
            Bt::Comment.create(content: 'hi there')
          }.should change(Bt::Comment, :count).by(1)
        end

        describe '#user' do
          context 'with association' do
            let(:user) {
              Bt::User.create(name: 'hasan', email: 'hasan@abc.com')
            }
            let!(:comment) {
              Bt::Comment.create(content: 'hi there', user: user)
            }

            subject { comment }

            its(:user) { should be_a Bt::User }
            its('user._id') { should == user._id }

            it 'should create instance variable @user' do
              subject.user
              subject.instance_variable_get(:@user).should be_a Bt::User
            end
          end

          context 'without association' do
            let!(:comment) {
              Bt::Comment.create(content: 'hi there')
            }

            subject { comment }

            its(:user) { should be_nil }
          end
        end
      end

      context 'with validation' do
        module Bt
          class Review
            include FlexiModel

            flexi_field :comment, :text
            belongs_to :user

            validates_presence_of :user_id, :comment
          end
        end

        let(:review) { Bt::Review.create() }
        subject { review }

        its('errors.count') {
          should == 2
        }

        it 'should have error on :comment' do
          subject.errors[:comment].should be
        end

        it 'should have error on :user_id' do
          subject.errors[:user_id].should be
        end

      end
    end
  end

  describe '#has_many' do
    class Author
      include FlexiModel
      flexi_field :name, String
      has_many :books
    end

    class Book
      include FlexiModel

      flexi_field :title, String
      belongs_to :author
    end

    [:books, :books=].each do |_m|
      it "should define method - #{_m}" do
        Author.new.respond_to?(_m).should be
      end
    end

    describe Author do
      before { Author.destroy_all }
      before { Book.destroy_all }
      let(:author) { Author.create(name: 'hasan') }
      let!(:books) { 5.times.map {|i| Book.create(title: "Book title #{i}", author: author)} }

      it 'should have 5 books' do
        Book.all.count.should == 5
      end

      describe 'relation object - books' do
        subject { author.books }

        its(:count) { should == 5 }
        its(:first) { should == books.first }
        its(:last) { should == books.last }
      end
    end
  end

  describe '#has_one'

  describe '#has_and_belongs_to_many' do
    module Hbb
      class Product
        include FlexiModel
        _ff :name, :string

        has_and_belongs_to_many :categories
      end

      class Category
        include FlexiModel
        _ff :name, :string

        has_and_belongs_to_many :products
      end
    end

    let(:cat1) { Hbb::Category.create(name: "Food Menu") }
    let(:cat2) { Hbb::Category.create(name: "Home Page") }

    context 'create product without category' do
      let(:prod) { Hbb::Product.create(name: 'Prod 1') }
      subject { prod }

      it 'should create product without category' do
        lambda { prod }.should change(Hbb::Product, :count).by(1)
      end

      its('categories.to_a') { should == [] }
    end

    context 'create product with categories' do
      let(:prod) { Hbb::Product.create(name: 'Prod 1') }

      it 'should not throw any error' do
        lambda {
          Hbb::Product.create(name: 'Prod 1', :categories => [cat1, cat2])
        }.should_not raise_error
      end

      it 'should create two records' do
        lambda {
          Hbb::Product.create(name: 'Prod 1', :categories => [cat1, cat2])
        }.should change(Hbb.module_eval("Hbb::CategoriesProduct"), :count).by(2)
      end

      it 'should use same joining table for both reference' do
        prod = Hbb::Product.create(name: 'Prod 1', :categories => [cat1, cat2])
        prod = Hbb::Product.find(prod._id)

        prod.categories.instance_variable_get(:@target_model).class.should ==
            prod.categories.first.products.instance_variable_get(:@target_model).class
      end

      it 'should have category_ids method' do
        prod.respond_to?(:category_ids).should be
      end

      it 'should have category_ids= method' do
        prod.respond_to?(:'category_ids=').should be_true
      end

      it 'should set category by category_ids method' do
        prod.update_attribute :category_ids, [cat1._id]

        _prod = prod.reload
        _prod.categories.to_a.should == [cat1]
      end

      it 'should return existing categories in category_ids' do
        prod.update_attribute :category_ids, [cat1._id, cat2._id]
        prod.reload.category_ids.should == [cat1._id, cat2._id]
      end

      describe 'update with existing categories' do
        let!(:prod) { Hbb::Product.create(name: 'Prod x 1', :categories => [cat1]) }

        it 'should have cat1 association' do
          prod.categories.count.should == 1
          prod.categories.first.should == cat1
        end

        it 'should assign cat2 without error' do
          lambda {
            prod.update_attribute :categories, [cat2]
          }.should_not raise_error
        end

        it 'should assign cat2' do
          prod.update_attribute :categories, [cat2]
          _prod = prod.reload

          _prod.categories.count.should == 1
          _prod.categories.to_a.map(&:name).should == [cat2.name]
        end

        it 'should update category association by category_ids' do
          prod.update_attribute :category_ids, [cat2._id]
          prod.reload.category_ids.should == [cat2._id]

          prod.update_attribute :category_ids, [cat1._id]
          prod.reload.category_ids.should == [cat1._id]
        end
      end

      describe 'product with categories' do
        before { 5.times { Hbb::Product.create(name: "Prod x #{Time.now.to_i}") } }
        let!(:prod) { Hbb::Product.create(name: 'Prod x 1', :categories => [cat1]) }
        subject { Hbb::Product.find(prod._id) }

        its(:_id) { should be }

        its('categories.target_model') { should == eval('Hbb::CategoriesProduct') }
        its(:categories) { should be }
        its('categories.count') { should == 1 }
        its('categories.first') { should == cat1 }
      end
    end

    context 'category' do
      it 'should have many products'
    end

  end

end