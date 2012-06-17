module FlexiModel
  module Association
    extend ActiveSupport::Concern

    module ClassMethods

      # Create relationship between two flexi model based on primary key
      def belongs_to(model_name, options = { })
        _id_field     = "#{model_name.to_s}_id"
        _target_model = (options[:class_name] || model_name).to_s.classify

        self.flexi_field _id_field.to_sym, :integer

        # Generate dynamic finder method
        self.class_eval <<-RUBY, __FILE__, __LINE__
          # Return object instance
          def #{model_name.to_s}
            @#{model_name.to_s} ||= self.class.parent::#{_target_model}.find(self.#{_id_field})
          end

          # Set object instance
          def #{model_name.to_s}=(inst)
            self.#{_id_field} = inst._id
            @#{model_name.to_s} = inst
          end
        RUBY
      end

      # Create many to many relationship between two flexi models based
      # on foreign key
      #
      #   Options
      #     - joining_class - You can define your joining class name or
      #                       you can leave it to us to generate on the fly.
      #
      def has_and_belongs_to_many(model_name, options = { })
        _class_name = (options[:joining_class] ||
            [model_name.to_s.classify.pluralize,
             self.name.pluralize].sort.join()).to_sym

        _fields = [
            "#{model_name.singularize.underscore}",
            "#{self.name.singularize.underscore}"
        ]

        # Define mapping class if not already defined
        _class  = _find_or_generate_joining_class(_class_name, _fields)

        # Define method for retrieving all instances
        #_generate_has_many_finder _class_name
      end

      # Create one to many relationship among the flexi models
      #
      #   Options
      #     - :class_name - Target model class name
      def has_many(model_name, options = { })
        _class_name = (options[:class_name] ||
            model_name.to_s.singularize.classify).to_sym

        _generate_setter_and_getter _class_name, model_name
      end

      private
      def _generate_setter_and_getter(_class_name, _method)
        _field_name = "#{self.name.underscore}_id"

        self.class_eval <<-RUBY, __FILE__, __LINE__
          def #{_method}
            @#{_method} ||= self.class.send(:_find_class, :#{_class_name}).where(#{_field_name}: self._id)
          end

          def #{_method}=(items)
            @#{_method} = items
            after_save lambda { |_parent|
              items.each { |_item| _item.update_attribute(#{_field_name}: _parent._id) }
            }
          end

        RUBY
      end

      def _find_class(_constant)
        if self.class.parent::constants.include?(_constant)
          self.class.parent::const_get(_constant)
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
        self.class_eval <<-RUBY, __FILE__, __LINE__
            class #{name.to_s}
              include FlexiModel

              flexi_field :#{_field_1}_id, :integer
              flexi_field :#{_field_2}_id, :integer

              belongs_to :#{_field_1}
              belongs_to :#{_field_2}
            end

            #{name.to_s}
        RUBY
      end
    end
  end
end