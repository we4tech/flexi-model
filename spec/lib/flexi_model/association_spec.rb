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

        its('errors.length') { should == 2 }

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
  describe '#has_and_belongs_to_many'

end