module FlexiModel
  module ArPersistence
    extend ActiveSupport::Concern

    RECORD     = FlexiModel::ArModels::Record
    COLLECTION = FlexiModel::ArModels::Collection
    FIELD      = FlexiModel::ArModels::Field
    VALUE      = FlexiModel::ArModels::Value

    included do
      class_eval <<-RUBY
        @@_flexi_collection = nil
        cattr_accessor :_flexi_collection

        @@_flexi_metadata = { }
        cattr_accessor :_flexi_metadata

        @@_flexi_fields_map = nil
        cattr_accessor :_flexi_fields_map

      RUBY
    end

    module ClassMethods
      # Set collection label
      #
      # singular - Set singular name for the collection
      # plural - Set plural name for the collection
      def set_flexi_label(singular, plural)
        _flexi_metadata[:label_singular] = singular
        _flexi_metadata[:label_plural]   = plural
      end

      # Return singular and plural collection label
      # If not defined it will take class name as collection name
      #
      # Returns array of singular and plural labels
      def get_flexi_label
        labels = [_flexi_metadata[:label_singular],
                  _flexi_metadata[:label_plural]].compact

        if labels.empty?
          _f_name = _friendly_name(self.name)
          [_f_name.singularize, _f_name.pluralize]
        else
          labels
        end
      end

      # Return collection name based on parametrized class name
      def flexi_collection_name
        self.name.parameterize
      end

      def get_flexi_namespace
        self.flexi_collection_name.parameterize
      end

      # Initialize new instance and set data from record
      def initialize_with_record(record)
        inst = self.new
        inst.send(:_record=, record)
        inst.send(:_id=, record.id)
        inst
      end

      # Return by default plural label
      def flexi_label(singular = false)
        if singular
          self._flexi_collection.singular_label
        else
          self._flexi_collection.plural_label
        end
      end

      def flexi_collection;
        _flexi_collection
      end

      delegate :id, :to => :_flexi_collection

      def destroy_all;
        RECORD.by_namespace(self.get_flexi_namespace).each do |record|
          inst = initialize_with_record(record)
          inst.destroy
        end
      end

      def delete_all;
        RECORD.by_namespace(self.get_flexi_namespace).delete_all
      end

      # Create does exactly as `save`, but it initiates `:create` callbacks
      def create(attributes = { })
        inst = self.new(attributes)
        inst.save

        inst
      end

      private
      def _friendly_name(long_name)
        long_name.to_s.split("::").last
      end
    end

    def initialize(*)
      super
      _find_or_update_or_build_collection!
    end

    # Ensure object with same _id returns true on equality check
    def ==(another_instance)
      self._id && self._id == another_instance._id
    end

    # Return true if record is not saved
    def new_record?
      !_id.present?
    end

    # Store record in persistent storage
    def save
      create_or_update
      _id.present?
    end

    # Update stored attributes by give hash
    def update_attributes(_params)
      hash = Hash[_params.map { |k, v| [k.to_sym, v] }]

      # Send message to local methods
      assign_attributes hash

      # Retrieve existing record
      _load_record_instance!

      _fields_with_new_values = Hash[
          get_flexi_fields_map.map { |_key, _field|
            [_field, hash[_key]] if hash.keys.include?(_key)
          }.compact
      ]

      # Retrieve existing mapping
      _existing_values           = Hash[_record.values.map { |_v| [_v.field, _v] }]

      _fields_with_new_values.each do |_field, _new_value|
        _existing_value = _existing_values[_field]

        if _existing_value
          _existing_value.update_attribute _field.value_column, self.send(_field.name.to_sym)
        else
          self._record.values << VALUE.new(:field => _field, value: self.send(_field.name.to_sym))
        end
      end

      true
    end

    # Update single attribute by key and value
    def update_attribute(key, value)
      self.update_attributes(key => value)
    end

    def destroy
      if _id.present?
        RECORD.delete(self._id)
      else
        false
      end
    end

    # Reload object instance
    def reload
      self.class.find(self._id)
    end

    # Forcefully load all attributes
    def load_attributes!
      self.flexi_fields.map { |f| self.send(f.name.to_sym) }
    end

    # Return existing or create new collection set
    def get_flexi_collection
      _find_or_update_or_build_collection!

      self._flexi_collection
    end

    # Return flexi fields in name and field object map
    def get_flexi_fields_map
      self._flexi_fields_map ||=
          Hash[get_flexi_collection.fields.
                   map { |_field| [_field.name.to_sym, _field] }]
    end

    private
    def create_or_update
      _id.nil? ? create : update
    end

    def create(*)
      # Initialize AR record and store
      record = _get_record
      record.save

      # Set Id and errors to the parent host object
      self._id = record.id
      @errors  = record.errors

      record
    end

    def update
      record = _get_record
      record.values.destroy_all
      record.update_attributes( values: _get_values )
      record
    end

    def _get_record
      _load_record_instance!
      self._record
    end

    def _load_record_instance!
      self._record ||= _record_load_or_initialize
    end

    def _record_load_or_initialize
      collection = _find_or_update_or_build_collection!

      if self._id.nil?
        RECORD.new(
            namespace:  self.class.get_flexi_namespace,
            collection: collection,
            values:     self.send(:_get_values)
        )
      else
        RECORD.find(self._id)
      end
    end

    # Return `Value` object based on flexi attributes
    def _get_values
      _fields_map = get_flexi_fields_map

      @attributes.map do |k, v|
        field = _fields_map[k]
        raise "Field - #{k} not defined" if field.nil?
        VALUE.new(:field => field, value: self.send(:"#{k}"))
      end
    end

    # Find existing collection object
    #   If not found create new collection
    #   If found but schema is back dated
    #     update schema
    def _find_or_update_or_build_collection!
      return _flexi_collection if _flexi_collection.present?

      # Find existing collection
      self._flexi_collection = COLLECTION.find_by_namespace_and_name_and_partition_id(
          self.class.get_flexi_namespace,
          self.class.flexi_collection_name,
          self.class.flexi_partition_id
      )

      # Update if schema changed
      if self._flexi_collection
        _update_schema
      else
        _build_collection
      end

      self._flexi_collection
    end

    # Check whether update is back dated
    # This update is verified through comparing stored collection
    # and new definition
    def _update_schema
      singular_label, plural_label = self.class.get_flexi_label
      existing                     = self._flexi_collection

      # Check labels
      if existing.singular_label != singular_label
        existing.update_attribute :singular_label, singular_label
      end

      if existing.plural_label != plural_label
        existing.update_attribute :plural_label, plural_label
      end


      # Check fields
      fields = _build_fields
      if _fields_changed? fields, existing
        # TODO: Dangerous need to fix it up
        existing.fields.destroy_all
        existing.update_attribute :fields, fields
      end
    end

    def _fields_changed?(fields, existing)
      added_or_removed = existing.fields.length != fields.length
      name_changed     = existing.fields.map(&:name).sort != fields.map(&:name).sort
      type_changed     = existing.fields.map(&:field_type).sort != fields.map(&:field_type).sort

      added_or_removed || name_changed || type_changed
    end

    def _build_collection
      singular_label, plural_label = self.class.get_flexi_label

      self._flexi_collection = COLLECTION.create(
          namespace:      self.class.get_flexi_namespace,
          name:           self.class.flexi_collection_name,
          partition_id:   self.class.flexi_partition_id,
          singular_label: singular_label,
          plural_label:   plural_label,

          fields:         _build_fields
      )
    end

    def _build_fields
      self.flexi_fields.map do |field|
        _find_existing_field(field) || FIELD.new(
            namespace:      self.class.get_flexi_namespace,
            name:           field.name.to_s,
            partition_id:   self.class.flexi_partition_id,
            field_type:     field.type,
            singular_label: field.singular,
            plural_label:   field.plural
        )
      end
    end

    def _find_existing_field(field)
      FIELD.find_by_namespace_and_name_and_field_type_and_partition_id(
          self.class.get_flexi_namespace,
          field.name.to_s,
          field.type,
          self.class.flexi_partition_id
      )
    end
  end
end