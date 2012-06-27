require 'spec_helper'

describe FlexiModel::Filter do
  class Vote
    include FlexiModel

    _string :name, :voter
  end

  describe '#flexi_filter' do
    it 'should have filter method' do
      Vote.respond_to?(:flexi_filter).should be
    end

    it 'should define instance method for given filter' do
      Vote.flexi_filter :by_name do |i|
        puts 'ho'
      end
      Vote.new.respond_to?(:by_name).should be
    end

    it 'should define class method for given filter' do
      Vote.flexi_filter :by_hola do |hola|
        puts "hola"
      end

      Vote.respond_to?(:by_hola).should be
      Vote.by_hola
    end

    it 'should accept parameters through defined filter method'

    it 'should throw error if length of args and accepted params are not equal' do
      Vote.flexi_filter :by_what_kinda_name do |hola|
        puts "Instance - #{instance}"
      end

      Vote.new.respond_to?(:by_what_kinda_name)
    end

    it 'should be executed in host class' do
      Vote.flexi_filter :by_what do
        raise self.to_s
      end

      lambda {
        Vote.by_what
      }.should raise_error('Vote')
    end

    it 'should be executed in host class instance' do
      Vote.flexi_filter :by_what do
        raise self.to_s
      end

      _inst = Vote.new
      lambda {
        _inst.by_what
      }.should raise_error(_inst.to_s)
    end

    it 'should return criteria object'

    it 'should assign instance to the instance param'
  end

end