require 'spec_helper'

module Naa
  class Product
    include FlexiModel

    _ff :name, :string
    _ff :price, :decimal
    _ff :starts_on, :datetime
    _ff :ends_on, :datetime

    has_many :product_options
    has_many :option_types
    has_many :product_categories
    has_many :categories
  end

  class Category
    include FlexiModel

    _ff :name, :string

    has_many :categories
    belongs_to :category
  end

  class ProductCategory
    include FlexiModel

    belongs_to :category
    belongs_to :product
  end

  class ProductOption
    include FlexiModel

    belongs_to :option_type
    belongs_to :product
  end

  class OptionType
    include FlexiModel

    _ff :name, :string
    _ff :items, :multiple
  end

end

describe FlexiModel::Association do
  # Setup test data
  let!(:parent_category) {
    Category.create(name: 'Products')
  }

  let!(:child_categories1) {
    3.times.map do
      Category.create(name: "Product Cat 1 #{rand(100) * Time.now.to_i}", category: parent_category)
    end
  }

  let!(:child_categories2) {
    3.times.map do
      Category.create(name: "Product Cat 2 #{rand(100) * Time.now.to_i}", category: parent_category)
    end
  }

  let!(:products) {
    5.times.each do |i|
      prod = Product.create(name: "product - #{i}", price: 5 * i, starts_on: Time.now, ends_on: Time.now + 5.days)

    end
  }


end