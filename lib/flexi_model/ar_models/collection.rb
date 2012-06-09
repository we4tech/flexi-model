module FlexiModel
  module ArModels
    class Collection < ActiveRecord::Base
      self.table_name = 'flexi_model_collections'

      validates_presence_of :name
      has_and_belongs_to_many :fields, :join_table => 'flexi_model_collections_fields'

    end
  end
end