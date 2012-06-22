module FlexiModel
  module ArQueryable
    extend ActiveSupport::Concern

    RECORD = FlexiModel::ArPersistence::RECORD

    module ClassMethods
      # Return count of items from the model
      def count
        _build_criteria.count
      end

      # Alias to :count
      def length;
        self.count
      end

      # Find a record instance by id
      # Returns model instance
      def find(id_or_ids)
        records = RECORD.includes(:values).where(id: id_or_ids)

        if records.present?
          if id_or_ids.is_a?(Array)
            records.map { |_record| initialize_with_record(_record)  }
          else
            initialize_with_record(records.first)
          end
        else
          nil
        end
      end

      # Load all records from the model
      def all
        _build_criteria
      end

      # Load first record from the model
      def first
        _build_criteria.first
      end

      # Load last record from the model
      def last
        _build_criteria.last
      end

      # Apply conditions using hash map
      def where(conditions = {})
        _build_criteria.where(conditions)
      end

    private
      def _build_criteria
        Criteria.new(RECORD, self, self.get_flexi_namespace)
      end

    end

    def count;
      Criteria.new(RECORD, self, self.get_flexi_namespace).count
    end

    def length;
      self.class.count
    end

    class Criteria
      include Enumerable

      attr_accessor :offset, :limit, :conditions, :host, :orders, :joins,
                    :groups, :select_field
      attr_reader :target_model

      protected :"joins=", :joins, :"orders=", :orders, :"groups=", :groups

      def initialize(host, target_model, namespace)
        @conditions = {namespace: namespace}
        @joins = []
        @orders = {}
        @groups = []
        @target_model = target_model
        @select_object = nil

        # By default Max 100 items will be retrieved
        @limit = 100
        @offset = 0
        @host = host
        @members = nil
      end

      def where(hash)
        self._convert_query(hash)
        self
      end

      def offset(num)
        self.offset = num
        self
      end

      def get_offset
        @offset
      end

      def limit(num)
        self.limit = num
        self
      end

      def get_limit
        @limit
      end

      def select_field(field)
        self.select_field = field
        self
      end

      def destroy_all
        _perform_query.destroy_all
      end

      DEFAULT_SORTABLE_FIELDS = [:created_at, :updated_at]

      # Order query by the given field and order type
      #
      #   key - field name in symbol or string
      #   order_type - order type :asc or :desc
      #     :asc - stands for ascending order
      #     :desc - stands for descending order
      # Returns self instance
      def order(key, order_type)
        if DEFAULT_SORTABLE_FIELDS.include?(key.to_sym)
          self.orders[key.to_sym] = order_type
        else
          field = _find_field(key)
          _join_table :values
          column = "'#{FlexiModel::ArModels::Value.table_name}'.'#{field.value_column}'"
          self.orders[column] = order_type
          self.groups << "'#{FlexiModel::ArModels::Record.table_name}'.'id'"
        end

        self
      end

      def each(&block)
        _members.each {|m| block.call _convert_to_model(m) }
      end

      def last
        @target_model.initialize_with_record(_members.last)
      end

      def to_sql
        self._perform_query.to_sql
      end

      protected
        def _convert_query(hash = {})
          hash.each do |k, v|
            case k.to_sym

              when :namespace
                self.conditions[:namespace] = v

              when :id
                self.conditions[:id] = v

              else
                _join_table :values

                # Find associated field
                field = _find_field(k)
                self.conditions["#{FlexiModel::ArModels::Value.table_name}.field_id"] = field.id
                self.conditions["#{FlexiModel::ArModels::Value.table_name}.#{field.value_column.to_s}"] = v
            end
          end
        end

        def _join_table(model)
          unless @joins.include?(model)
            @joins.push(model)
          end
        end

        def _find_field(k)
          field = (@empty_inst ||= @target_model.new)
            .get_flexi_fields_map[k.to_sym]
          raise "Invalid field - #{k}" unless field

          field
        end

        def _convert_to_model(r)
          _inst = @target_model.initialize_with_record(r)
          if @select_field.present?
            _inst.send(@select_field.to_sym)
          else
            _inst
          end
        end

        def _singular_field(class_name)
          class_name.name.split('::').last.underscore
        end

        def _members
          @members ||= _perform_query
        end

        def _perform_query
          # Prepare conditions
          _host = self.host
            .where(self.conditions)
            .limit(self.get_limit)
            .offset(self.get_offset)

          # Join tables
          if self.joins.present?
            _host = _host.joins(@joins)
          end

          # Add orders
          self.orders.each do |k, v|
            _host = _host.order("#{k} #{v.to_sym == :desc ? 'DESC' : 'ASC'}")
          end

          # Add groups
          if self.groups.present?
            _host = _host.group(self.groups)
          end

          _host
        end
    end
  end
end