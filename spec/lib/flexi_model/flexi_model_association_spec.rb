require 'spec_helper'

describe FlexiModel::Association do
  class Model
    include FlexiModel

    flexi_field :name, String
    flexi_field :email, String

  end

  describe '#belongs_to'
  describe '#has_many'
  describe '#has_one'
  describe '#has_and_belongs_to_many'

end