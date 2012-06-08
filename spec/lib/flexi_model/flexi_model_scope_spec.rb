require 'spec_helper'

describe FlexiModel::Queryable do
  class Model
    include FlexiModel

    flexi_field :name, String
    flexi_field :email, String

  end

  describe '#find'
  describe '#where'
  describe '#all'
  describe '#first'
  describe '#last'
  describe '#where.order'

end