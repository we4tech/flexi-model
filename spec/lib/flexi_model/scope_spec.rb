require 'spec_helper'

describe FlexiModel::Scope do
  class SModel
    include FlexiModel

    flexi_field :name, String
    flexi_field :email, String

  end

  describe '#scope'
  describe '#define_scope'

end