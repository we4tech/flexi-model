module FlexiModel
  module ArModels
    class Field < ActiveRecord::Base
      self.table_name = 'flexi_model_fields'
      attr_accessible :name, :singular_label,:plural_label, :namespace,
                      :partition_id, :field_type, :default_value

      COLUMNS_MAP     = {
          boolean:  :bool_value,
          integer:  :int_value,
          decimal:  :dec_value,
          float:    :dec_value,
          string:   :str_value,
          email:    :str_value,
          phone:    :str_value,
          location: :str_value,
          address:  :txt_value,
          text:     :txt_value,
          multiple: :txt_value,
          datetime: :dt_value,
          date:     :dt_value,
          time:     :dt_value
      }

      has_and_belongs_to_many :collections, :join_table => 'flexi_model_collections_fields'
      has_many :values, :dependent => :destroy

      validates_presence_of :name, :field_type
      validates_uniqueness_of :name, :scope => [:namespace, :partition_id, :field_type]

      def value_column
        FlexiModel::ArModels::Field::COLUMNS_MAP[self.field_type.to_sym]
      end
    end
  end
end