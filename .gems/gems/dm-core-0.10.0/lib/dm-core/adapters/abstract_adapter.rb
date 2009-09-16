module DataMapper
  module Adapters
    # Specific adapters extend this class and implement
    # methods for creating, reading, updating and deleting records.
    #
    # Adapters may only implement method for reading or (less common case)
    # writing. Read only adapter may be useful when one needs to work
    # with legacy data that should not be changed or web services that
    # only provide read access to data (from Wordnet and Medline to
    # Atom and RSS syndication feeds)
    #
    # Note that in case of adapters to relational databases it makes
    # sense to inherit from DataObjectsAdapter class.
    class AbstractAdapter
      include Extlib::Assertions
      extend Extlib::Assertions

      # Adapter name
      #
      # @example
      #   adapter.name  # => :default
      #
      # Note that when you use
      #
      # DataMapper.setup(:default, 'postgres://postgres@localhost/dm_core_test')
      #
      # then adapter name is currently be set to is :default
      #
      # @return [Symbol]
      #   the adapter name
      #
      # @api semipublic
      attr_reader :name

      # Options with which adapter was set up
      #
      # @example
      #   adapter.options  # => { :adapter => 'yaml', :path => '/tmp' }
      #
      # @return [Hash]
      #   adapter configuration options
      #
      # @api semipublic
      attr_reader :options

      # A callable object returning a naming convention for model storage
      #
      # @example
      #   adapter.resource_naming_convention  # => Proc for model storage name
      #
      # @return [#call]
      #   object to return the naming convention for each model
      #
      # @api semipublic
      attr_accessor :resource_naming_convention

      # A callable object returning a naming convention for property fields
      #
      # @example
      #   adapter.field_naming_convention  # => Proc for field name
      #
      # @return [#call]
      #   object to return the naming convention for each field
      #
      # @api semipublic
      attr_accessor :field_naming_convention

      # Persists one or many new resources
      #
      # @example
      #   adapter.create(collection)  # => 1
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Enumerable<Resource>] resources
      #   The list of resources (model instances) to create
      #
      # @return [Integer]
      #   The number of records that were actually saved into the data-store
      #
      # @api semipublic
      def create(resources)
        raise NotImplementedError, "#{self.class}#create not implemented"
      end

      # Reads one or many resources from a datastore
      #
      # @example
      #   adapter.read(query)  # => [ { 'name' => 'Dan Kubb' } ]
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Query] query
      #   the query to match resources in the datastore
      #
      # @return [Enumerable<Hash>]
      #   an array of hashes to become resources
      #
      # @api semipublic
      def read(query)
        raise NotImplementedError, "#{self.class}#read not implemented"
      end

      # Updates one or many existing resources
      #
      # @example
      #   adapter.update(attributes, collection)  # => 1
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Hash(Property => Object)] attributes
      #   hash of attribute values to set, keyed by Property
      # @param [Collection] collection
      #   collection of records to be updated
      #
      # @return [Integer]
      #   the number of records updated
      #
      # @api semipublic
      def update(attributes, collection)
        raise NotImplementedError, "#{self.class}#update not implemented"
      end

      # Deletes one or many existing resources
      #
      # @example
      #   adapter.delete(collection)  # => 1
      #
      # Adapters provide specific implementation of this method
      #
      # @param [Collection] collection
      #   collection of records to be deleted
      #
      # @return [Integer]
      #   the number of records deleted
      #
      # @api semipublic
      def delete(collection)
        raise NotImplementedError, "#{self.class}#delete not implemented"
      end

      # Compares another AbstractAdapter for equality
      #
      # @example with an equal adapter
      #   adapter.eql?(equal_adapter)  # => true
      #
      # @example with a different adapter
      #   adapter.eql?(different_adapter)  # => false
      #
      # AbstractAdapter is equal to +other+ if they are the same object (identity)
      # or if they are of the same class and have the same name
      #
      # @param [AbstractAdapter] other
      #   the other AbstractAdapter to compare with
      #
      # @return [Boolean]
      #   true if they are equal, false if not
      #
      # @api public
      def eql?(other)
        if equal?(other)
          return true
        end

        unless instance_of?(other.class)
          return false
        end

        cmp?(other, :eql?)
      end

      # Compares another AbstractAdapter for equivalency
      #
      # @example with an equivalent adapter
      #   adapter == equivalent_adapter  # => true
      #
      # @example with a different adapter
      #   adapter == different_adapter  # => false
      #
      # AbstractAdapter is equal to +other+ if they are the same object (identity)
      # or if they both have the same name
      #
      # @param [AbstractAdapter] other
      #   the other AbstractAdapter to compare with
      #
      # @return [Boolean]
      #   true if they are equal, false if not
      #
      # @api public
      def ==(other)
        return true if equal?(other)

        other.respond_to?(:name)                       &&
        other.respond_to?(:options)                    &&
        other.respond_to?(:resource_naming_convention) &&
        other.respond_to?(:field_naming_convention)    &&
        cmp?(other, :==)
      end

      protected

      # Set the serial value of the Resource
      #
      # @param [Resource] resource
      #   the resource to set the serial property in
      # @param [Integer] id
      #   the identifier to set in the resource
      #
      # @return [undefined]
      #
      # @api semipublic
      def initialize_serial(resource, next_id)
        return unless serial = resource.model.serial(name)
        return unless serial.get!(resource).nil?
        serial.set!(resource, next_id)

        # TODO: replace above with this, once
        # specs can handle random, non-sequential ids
        #serial.set!(resource, rand(2**32))
      end

      # Translate the attributes into a Hash with the field as the key
      #
      # @example
      #   attributes = { User.properties[:name] => 'Dan Kubb' }
      #   adapter.attributes_as_fields(attributes)  # => { 'name' => 'Dan Kubb' }
      #
      # @param [Hash] attributes
      #   the attributes with the Property as the key
      #
      # @return [Hash]
      #   the attributes with the Property#field as the key
      #
      # @api semipublic
      def attributes_as_fields(attributes)
        attributes.map { |property, value| [ property.field, value ] }.to_hash
      end

      private

      # Initialize an AbstractAdapter instance
      #
      # @param [Symbol] name
      #   the adapter repository name
      # @param [Hash] options
      #   the adapter configuration options
      #
      # @return [undefined]
      #
      # @api semipublic
      def initialize(name, options)
        @name                       = name
        @options                    = options.dup.freeze
        @resource_naming_convention = NamingConventions::Resource::UnderscoredAndPluralized
        @field_naming_convention    = NamingConventions::Field::Underscored
      end

      # Compare other object for equality of equivalency
      #
      # @param [AbstractAdapter] other
      #   the other adapter
      # @param [Symbol] operator
      #   the comparison operator
      #
      # @return [Boolean]
      #   true if the other object is equal or equivalent
      #
      # @api private
      def cmp?(other, operator)
        name.send(operator, other.name)                                             &&
        options.send(operator, other.options)                                       &&
        resource_naming_convention.send(operator, other.resource_naming_convention) &&
        field_naming_convention.send(operator, other.field_naming_convention)
      end
    end # class AbstractAdapter

    const_added(:AbstractAdapter)
  end # module Adapters
end # module DataMapper