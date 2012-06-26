# encoding: UTF-8
module FlexiModel
  module Fields
    TYPES = [:integer, :boolean, :multiple, :decimal, :float, :string, :text,
             :datetime, :date, :time, :email, :phone, :address, :location]

    extend ActiveSupport::Concern

    MULTI_PARAMS_FIELDS = ['datetime', 'date', 'time']

    included do
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        attr_accessor :attributes

        @@flexi_visible = true
        cattr_accessor :flexi_visible

        @@flexi_fields = []
        cattr_accessor :flexi_fields

        @@_flexi_fields_by_name = {}
        cattr_accessor :_flexi_fields_by_name

        @@flexi_namespace = nil
        cattr_accessor :flexi_namespace

        @@flexi_partition_id = 0
        cattr_accessor :flexi_partition_id

        @@flexi_name_field = :name
        cattr_accessor :flexi_name_field
      CODE
    end

    # Define attribute initialization constructor
    def initialize(args = { })
      @attributes = { }
      assign_attributes(args) if args.present?
    end

    def assign_attributes(args)
      _all_keys          = args.keys
      _multi_params_keys = _all_keys.select { |k| k.to_s.match(/\([\w]+\)/) }
      _normal_keys       = _all_keys - _multi_params_keys

      # Execute only single parameter accessors
      _normal_keys.each do |k|
        self.send :"#{k.to_s}=", args[k]
      end

      # Execute multi params accessors
      if _multi_params_keys.present?
        _groups = { }
        _multi_params_keys.each do |k|
          _accessor = k.to_s.gsub(/\([\w]+\)/, '')
          _index    = k.to_s.match(/\(([\w]+)\)/)[1].to_i - 1

          _groups[_accessor] ||= []
          _groups[_accessor].insert(_index, args[k])
        end

        _groups.each do |k, values|
          _int_values = values.map(&:to_i)
          _field      = self.flexi_fields.select { |f| f.name.to_s == k }.first

          if _field
            _value = case _field.type
              when 'datetime'
                DateTime.new(*_int_values)
              when 'time'
                Time.new(*([Time.now.year, Time.now.month, Time.now.day] + _int_values))
              when 'date'
                Date.new(*_int_values)
            end

            self.send :"#{k}=", _value
          end
        end
      end
    end

    # Return default name from the object instance
    # This accessor could be set through set_flexi_name_field :title
    def _name
      if self.respond_to?(self.flexi_name_field)
        self.send(self.flexi_name_field)
      else
        raise "Define your name field accessor (which may return the object
              title, name or whatever it describes about the current instance)
              - set_flexi_name_field :different_accessor"
      end
    end

    def to_s
      %{#<#{self.class.name}:#{sprintf '0x%x', self.object_id} #{@attributes.map { |k, v| ":#{k}=>'#{v}'" }.join(' ')}>}
    end

    module ClassMethods

      # Set field name to determine default name field.
      def set_flexi_name_field(field)
        self.flexi_name_field = field
      end

      # Set current model as visible or invisible to admin panel
      # Setting false won't publicize this model over admin panel
      def set_flexi_visible(bool)
        self.flexi_visible = bool
      end

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
      def flexi_field(name, type, options = { })
        accessible = options[:accessible] || true
        default    = options[:default]
        singular   = options[:singular] || name.to_s.singularize
        plural     = options[:plural] || name.to_s.pluralize
        _type      = type.is_a?(Symbol) || type.is_a?(String) ? type : type.name
        serialize  = options[:serialize]

        field            = FlexiField.new(name, _type.to_s.downcase, default)
        field.accessible = accessible
        field.singular   = singular
        field.plural     = plural

        define_field(field)
      end

      alias_method :_ff, :flexi_field

      # Define flexible field definition
      TYPES.each do |_field|
        self.class_eval <<-CODE
          def _#{_field.to_s}(*args)
            options = args.last && args.last.is_a?(Hash) ? args.last : {}
            args.each do |_field_name|
              unless _field_name.is_a?(Hash)
                flexi_field _field_name, :#{_field.to_s}, options
              end
            end
          end
        CODE
      end

      # Remove field by field name
      # Return list of existing fields
      def remove_flexi_field(name)
        flexi_fields.reject! { |f| f.name == name }
      end

      def define_field(field)
        # Remove existing definition
        remove_flexi_field field.name

        # Add new field
        flexi_fields << field

        # Map name and field
        _flexi_fields_by_name[
            (field.name.is_a?(Symbol) ?
                field.name : field.name.to_sym)] = field

        _define_accessors(field)
      end

      private
      def _define_accessors(field)
        # Define setter & getter
        self.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{field.name.to_s}=(v)
            @attributes[:'#{field.name.to_s}'] = _cast(v, :#{field.type})
          end

          def #{field.name.to_s}
            @attributes[:'#{field.name.to_s}'] ||= _cast(_get_value(:'#{field.name.to_s}'), :#{field.type})
          end

        CODE

        # Define ? method if boolean field
        if field.type == 'boolean'
          self.class_eval <<-CODE
            def #{field.name.to_s}?
              self.#{field.name.to_s}
            end
          CODE
        end
      end
    end

    def _cast(_value, _type)
      return _value if _value.nil?

      case _type
        when :decimal, :float
          _value.to_f
        when :integer, :number
          _value.to_i
        else
          _value
      end
    end

    def _get_value(field_name)
      return _load_value_from_record(field_name) if self._record.present?

      _default_value(field_name)
    end

    def _load_value_from_record(field_name)
      val = self._record.value_of(field_name.to_s)
      if val.present?
        val.value
      else
        nil
      end
    end

    def _default_value(field_name)
      _field = _flexi_fields_by_name[field_name]
      if _field.default.present?
        _field.value(self)
      else
        nil
      end
    end


    class FlexiField
      attr_accessor :name, :type, :default, :singular, :plural, :accessible

      def initialize(name, type, default = nil)
        @name    = name
        @type    = type
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