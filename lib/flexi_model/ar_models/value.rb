module FlexiModel
  module ArModels
    class Value < ActiveRecord::Base
      self.table_name = 'flexi_model_values'

      attr_accessible :record_id, :field_id, :bool_value, :int_value,
                      :dec_value, :str_value, :txt_value, :dt_value, :field,
                      :value

      belongs_to :record
      belongs_to :field

      # Set value based on field type.
      # ie. if it is `string` type it will store value in str_value
      #
      # List of field value mappings -
      #   Boolean   'bool_value'
      #   Integer   'int_value'
      #   Decimal   'dec_value'
      #   String    'str_value'
      #   Text      'txt_value'
      #   Datetime  'dt_value'
      def value=(val)
        self.send :"#{_mapped_value_column}=", val
      end

      # Get value from corresponding column based on field type
      def value
        self.send :"#{_mapped_value_column}"
      end

      def column_for_attribute(name)
        if :value == name.to_sym
          self.class.columns_hash[self.field.value_column.to_s]
        else
          self.class.columns_hash[name.to_s]
        end
      end

    private
      def _mapped_value_column
        raise 'No field is set' if field.nil?

        value_col =
            FlexiModel::ArModels::Field::COLUMNS_MAP[field.field_type.to_sym]
        raise "Unknown field type - #{field.field_type}" if value_col.nil?

        value_col
      end
    end
  end
end