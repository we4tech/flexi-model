module FlexiModel
  module ArModels
    class Collection < ActiveRecord::Base
      self.table_name = 'flexi_model_collections'

      validates_presence_of :name
      validates_uniqueness_of :name, :scope => :partition_id, :if => :partition_id
      has_and_belongs_to_many :fields, :join_table => 'flexi_model_collections_fields'
      has_many :records, :dependent => :destroy

      attr_accessible :namespace, :name, :partition_id,
                      :singular_label, :plural_label, :fields
    end
  end
end