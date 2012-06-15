module FlexiModel
  module Fields
    extend ActiveSupport::Concern

    included do
      instance_eval <<-RUBY
        attr_accessor :attributes
      RUBY

      class_eval <<-RUBY
        @@flexi_fields = []
        cattr_accessor :flexi_fields

        @@_flexi_fields_by_name = {}
        cattr_accessor :_flexi_fields_by_name

        @@flexi_namespace = nil
        cattr_accessor :flexi_namespace

        @@flexi_partition_id = 0
        cattr_accessor :flexi_partition_id
      RUBY
    end

    # Define attribute initializable constructor
    def initialize(args = {})
      @attributes = {}
      args.each do |k, v|
        self.send :"#{k.to_s}=", v
      end

    end

    module ClassMethods

      # Isolate and group all models under a single administration panel
      # This is useful when we are hosting these models under a single platform.
      def set_flexi_partition_id(_id)
        self.flexi_partition_id = _id
      end

      # Set filed with name, type and default value or proc
      #
      # name    - Field name should be downcased multi words separated by underscore
      # type    - Supported type String, Integer, Time, Date
      # options - Hash of options
      #   default   - Default value proc or object
      #   singular  - Singular label
      #   plural    - Plural label
      #
      # Return +Field+ instance
      def flexi_field(name, type, options = {})
        default = options[:default]
        singular = options[:singular] || name.to_s.singularize
        plural = options[:plural] || name.to_s.pluralize
        _type = type.is_a?(Symbol) || type.is_a?(String) ? type : type.name

        field = FlexiField.new(name, _type.to_s.downcase, default)
        field.singular = singular
        field.plural = plural

        define_field(field)
      end

      # Remove field by field name
      # Return list of existing fields
      def remove_flexi_field(name)
        flexi_fields.reject!{|f| f.name == name }
      end

      def define_field(field)
        # Remove existing definition
        remove_flexi_field field.name

        # Add new field
        flexi_fields << field

        # Map name and field
        _flexi_fields_by_name[(field.name.is_a?(Symbol) ? field.name : field.name.to_sym)] = field

        # Define setter & getter
        self.class_eval <<-RUBY
          def #{field.name.to_s}=(v)
            @attributes[:'#{field.name.to_s}'] = v
          end

          def #{field.name.to_s}
            val = @attributes[:'#{field.name.to_s}']
            if val.nil?
              return _load_value_from_record(:'#{field.name.to_s}') if self._record.present?
              default_value(:'#{field.name.to_s}')
            else
              val
            end
          end
        RUBY

        # Define ? method if boolean field
        if field.type == 'boolean'
          self.class_eval <<-RUBY
            def #{field.name.to_s}?
              self.#{field.name.to_s}
            end
          RUBY
        end
      end
    end

    def default_value(field_name)
      _field = _flexi_fields_by_name[field_name]
      if _field.default.present?
        _field.value(self)
      else
        nil
      end
    end

    def _load_value_from_record(field_name)
      val = self._record.value_of(field_name.to_s)
      if val.present?
        val.value
      else
        nil
      end
    end

    class FlexiField
      attr_accessor :name, :type, :default, :singular, :plural

      def initialize(name, type, default = nil)
        @name = name
        @type = type
        @default = default
      end

      def value(context)
        if default.is_a?(Proc)
          default.call(context)
        else
          default
        end
      end
    end
  end
end