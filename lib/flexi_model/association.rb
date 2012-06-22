module FlexiModel
  module Association
    extend ActiveSupport::Concern

    included do
      class_eval <<-ATTRS, __FILE__, __LINE__ + 1
        cattr_accessor :associations
        @@associations = {}
      ATTRS
    end

    module ClassMethods

      # Create relationship between two flexi model based on primary key
      def belongs_to(model_name, options = { })
        _id_field     = "#{model_name.to_s}_id"
        _target_model = (options[:class_name] || model_name).to_s.classify

        self.flexi_field _id_field.to_sym, :integer

        # Generate dynamic finder method
        _build_belongs_to_accessors model_name, _target_model, _id_field

        (self.associations[:belongs_to] ||= []) << model_name
      end

      # Create one to many relationship among the flexi models
      #
      #   Options
      #     - :class_name - Target model class name
      def has_many(model_name, options = { })
        _class_name = (options[:class_name] ||
            model_name.to_s.singularize.classify).to_sym

        _build_has_many_accessors _class_name, model_name

        (self.associations[:hash_many] ||= []) << model_name
      end

      # Create many to many relationship between two flexi models based
      # on foreign key
      #
      #   Options
      #     - joining_class - You can define your joining class name or
      #                       you can leave it to us to generate on the fly.
      #
      def has_and_belongs_to_many(method_name, options = { })
        # Get joining class name (dev can specify over :joining_class option)
        _joining_class_name =
            ( options[:joining_class] || _build_joining_class_name(method_name) ).to_sym

        # Build field name
        _fields = [ _build_field_name(self.name), _build_field_name(method_name) ]

        # Eval dynamic joining class
        _joining_class = _build_joining_class _joining_class_name, _fields

        # Create setter for setting all <target> records
        _build_habtm_class_accessors _joining_class_name, method_name, _fields

        (self.associations[:hash_and_belongs_to_many] ||= []) << method_name
      end

    private
      def _build_belongs_to_accessors(model_name, target_model, id_field)
        self.class_eval <<-ACCESSORS, __FILE__, __LINE__ + 1
          # Return object instance
          def #{model_name.to_s}
            @#{model_name.to_s} ||= self.class.parent::#{target_model}.find(self.#{id_field})
          end

          # Set object instance
          def #{model_name.to_s}=(inst)
            inst.save if inst.new_record?
            self.#{id_field} = inst._id
            @#{model_name.to_s} = inst
          end
        ACCESSORS
      end

      def _build_habtm_class_accessors(_class_name, method_name, _fields)
        _column_name = "#{_fields.first}_id"

        self.class_eval <<-ACCESSORS, __FILE__, __LINE__ + 1
          def #{method_name}_changed?; @#{method_name}_changed end

          def #{method_name}
            @#{method_name} ||= #{_class_name}.where(#{_column_name}: self._id).select_field(:#{_fields.last})
          end

          def #{method_name.to_s.singularize}_ids=(ids)
            @#{method_name.to_s.singularize}_ids ||= ids
            @#{method_name}= self.class.send(:_find_class, :#{method_name.to_s.classify}).where(id: ids).to_a
            @#{method_name}_changed = true
          end

          def #{method_name.to_s.singularize}_ids
            @#{method_name.to_s.singularize}_ids ||= #{method_name}.map(&:_id)
          end

          def #{method_name}=(an_array)
            @#{method_name} = an_array
            @#{method_name}_changed = true
          end

          after_save :_#{method_name}_after_save
          after_update :_#{method_name}_after_update

          def _#{method_name}_after_save
            return if @#{method_name}.nil?
            _create_#{method_name}_mappings!
          end

          def _#{method_name}_after_update
            return if @#{method_name}.nil?
            _update_#{method_name}_mappings!
          end

          def _update_#{method_name}_mappings!
            _destroy_#{method_name}_mappings!
            _create_#{method_name}_mappings!
          end

          def _destroy_#{method_name}_mappings!
            #{_class_name}.where(#{_column_name}: self._id).destroy_all
          end

          def _create_#{method_name}_mappings!
            @#{method_name}.each do |_target_inst|
              _target_inst.save if _target_inst.new_record?
              _map = #{_class_name}.create(
                #{_fields.first}: self,
                #{_fields.last}: _target_inst
              )

              raise _map.errors.inspect if _map.errors.present?
            end
          end
        ACCESSORS
      end

      def _build_field_name(name)
        name.to_s.split("::").last.underscore.singularize
      end

      def _build_joining_class(class_name, fields)
        _cls = self.send(:_find_class, class_name.to_s.split('::').last.to_sym)
        _cls if _cls.present?

        self.class_eval <<-CLASS, __FILE__, __LINE__ + 1
          class #{class_name}
            include FlexiModel

            belongs_to :#{fields.first}
            belongs_to :#{fields.last}

            validates_presence_of :#{fields.first}_id, :#{fields.last}_id
          end

          #{class_name}
        CLASS
      end

      def _build_joining_class_name(model_name)
        _parts = self.name.to_s.split("::")
        _name = _parts.last

        _class_name = [model_name.to_s.pluralize.downcase,
                       _name.pluralize.downcase].sort.join('_').classify

        if _parts.length > 1
          "#{_parts[0..(_parts.length - 2)].join('::')}::#{_class_name}"
        else
          _class_name
        end
      end

      def _build_has_many_accessors(_class_name, _method)
        _field_name = "#{self.name.underscore.split('/').last}_id"

        self.class_eval <<-ACCESSORS, __FILE__, __LINE__ + 1
          def #{_method}
            @#{_method} ||= self.class.send(:_find_class, :#{_class_name}).where(#{_field_name}: self._id)
          end

          def #{_method}=(items)
            @#{_method} = items
          end

          after_save :_#{_method}_after_save

          def _#{_method}_after_save
            return unless @#{_method}.present?
            @#{_method}.each do |_item|
              _item.update_attribute(#{_field_name}: self._id)
            end
          end

        ACCESSORS
      end

      def _find_class(_constant)
        if self.parent && self.parent.constants.include?(_constant)
          self.parent.const_get(_constant)
        elsif self.class.parent.constants.include?(_constant)
          self.class.parent.const_get(_constant)
        elsif self.class.constants.include?(_constant)
          self.class.const_get(_constant)
        else
          nil
        end
      end

      def _find_or_generate_joining_class(_class_name, _fields)
        _class = _find_class _class_name
        if _class.nil?
          _generate_mapping_class _class_name, _fields.first, _fields.last
        else
          _class
        end
      end

      def _generate_mapping_class(name, _field_1, _field_2)
        self.class_eval <<-CLASS, __FILE__, __LINE__ + 1
            class #{name.to_s}
              include FlexiModel

              flexi_field :#{_field_1}_id, :integer
              flexi_field :#{_field_2}_id, :integer

              belongs_to :#{_field_1}
              belongs_to :#{_field_2}
            end

            #{name.to_s}
        CLASS
      end
    end
  end
end