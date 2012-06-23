module FlexiModel
  module ArModels
    class Record < ActiveRecord::Base
      self.table_name = 'flexi_model_records'

      attr_accessible :collection_id, :namespace, :values, :values_attributes,
                      :collection

      belongs_to :collection
      has_many :values, :dependent => :destroy
      has_many :fields, :through => :values

      scope :by_namespace, lambda { |n| where(namespace: n) }
      scope :recent, order('created_at DESC')

      accepts_nested_attributes_for :values

      def value_of(field_name)
        values.select{|v| v.field.present? }.
            select{|v| v.field.name.downcase == field_name.to_s.downcase}.first
      end

      def title
        _value = value_of(:name) || value_of(:title)
        return _value.value if _value.present?

        self.collection.singular_label
      end
    end
  end
end