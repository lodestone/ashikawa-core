require "ashikawa-core/document"
require "ashikawa-core/index"
require "ashikawa-core/cursor"
require "ashikawa-core/query"
require "ashikawa-core/status"
require "restclient/exceptions"
require "forwardable"

module Ashikawa
  module Core
    # Represents a certain Collection within the Database
    class Collection
      extend Forwardable

      # The name of the collection, must be unique
      #
      # @return [String]
      # @api public
      # @example Change the name of a collection
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.name # => "example_1"
      #   collection.name = "example_2"
      #   collection.name # => "example_2"
      attr_reader :name

      # The ID of the collection. Is set by the database and unique
      #
      # @return [Fixnum]
      # @api public
      # @example Get the id of the collection
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.id #=> 4588
      attr_reader :id

      # A wrapper around the status of the collection
      #
      # @return [Status]
      # @api public
      # @example
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.status.loaded? #=> true
      #   collection.status.new_born? #=> false
      attr_reader :status

      # The database the collection belongs to
      #
      # @return [Database]
      # @api public
      attr_reader :database

      # Sending requests is delegated to the database
      delegate send_request: :@database

      # Create a new Collection object with a name and an optional ID
      #
      # @param [Database] database The database the connection belongs to
      # @param [Hash] raw_collection The raw collection returned from the server
      # @api public
      # @example Create a Collection object from scratch
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      def initialize(database, raw_collection)
        @database = database
        @name = raw_collection['name'] if raw_collection.has_key? 'name'
        @id  = raw_collection['id'].to_i if raw_collection.has_key? 'id'
        @status = Status.new raw_collection['status'].to_i if raw_collection.has_key? 'status'
      end

      # Change the name of the collection
      #
      # @param [String] new_name New Name
      # @return [String] New Name
      # @api public
      # @example Change the name of a collection
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.name # => "example_1"
      #   collection.name = "example_2"
      #   collection.name # => "example_2"
      def name=(new_name)
        send_request_for_this_collection "/rename", put: { "name" => new_name }
        @name = new_name
      end

      # Does the document wait until the data has been synchronised to disk?
      #
      # @return [Boolean]
      # @api public
      # @example Does the collection wait for file synchronization?
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.wait_for_sync? #=> false
      def wait_for_sync?
        server_response = send_request_for_this_collection "/properties"
        server_response["waitForSync"]
      end

      # Change if the document will wait until the data has been synchronised to disk
      #
      # @return [String] Response from the server
      # @api public
      # @example Tell the collection to wait for file synchronization
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.wait_for_sync = true
      def wait_for_sync=(new_value)
        send_request_for_this_collection "/properties", put: { "waitForSync" => new_value }
      end

      # Returns the number of documents in the collection
      #
      # @return [Fixnum] Number of documents
      # @api public
      # @example How many documents are in the collection?
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.length # => 0
      def length
        server_response = send_request_for_this_collection "/count"
        server_response["count"]
      end

      # Return a figure for the collection
      #
      # @param [Symbol] figure_type The figure you want to know:
      #     * :datafiles_count - the number of active datafiles
      #     * :alive_size - the total size in bytes used by all living documents
      #     * :alive_count - the number of living documents
      #     * :dead_size - the total size in bytes used by all dead documents
      #     * :dead_count - the number of dead documents
      # @return [Fixnum] The figure you requested
      # @api public
      # @example Get the datafile count for a collection
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.figure :datafiles_count #=> 0
      def figure(figure_type)
        server_response = send_request_for_this_collection "/figures"
        figure_area, figure_name = figure_type.to_s.split "_"
        server_response["figures"][figure_area][figure_name]
      end

      # Deletes the collection
      #
      # @return [String] Response from the server
      # @api public
      # @example Delete a collection
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.delete
      def delete
        send_request_for_this_collection "", delete: {}
      end

      # Load the collection into memory
      #
      # @return [String] Response from the server
      # @api public
      # @example Load a collection into memory
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.load
      def load
        send_request_for_this_collection "/load", put: {}
      end

      # Load the collection into memory
      #
      # @return [String] Response from the server
      # @api public
      # @example Unload a collection into memory
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.unload
      def unload
        send_request_for_this_collection "/unload", put: {}
      end

      # Delete all documents from the collection
      #
      # @return [String] Response from the server
      # @api public
      # @example Remove all documents from a collection
      #   database = Ashikawa::Core::Database.new "http://localhost:8529"
      #   raw_collection = {
      #     "name" => "example_1",
      #     "waitForSync" => true,
      #     "id" => 4588,
      #     "status" => 3,
      #     "error" => false,
      #     "code" => 200
      #   }
      #   collection = Ashikawa::Core::Collection.new database, raw_collection
      #   collection.truncate!
      def truncate!
        send_request_for_this_collection "/truncate", put: {}
      end

      # Fetch a certain document by its ID
      #
      # @param [Integer] document_id the id of the document
      # @raise [DocumentNotFoundException] If the requested document was not found
      # @return Document
      # @api public
      # @example Fetch a document with the ID 12345
      #   document = collection[12345]
      def [](document_id)
        begin
          server_response = send_request "/document/#{@id}/#{document_id}"
        rescue RestClient::ResourceNotFound
          raise DocumentNotFoundException
        end

        Document.new @database, server_response
      end

      # Replace a document by its ID
      #
      # @param [Integer] document_id the id of the document
      # @param [Hash] raw_document the data you want to replace it with
      # @api public
      def []=(document_id, raw_document)
        send_request "/document/#{@id}/#{document_id}", put: raw_document
      end

      # Create a new document from raw data
      #
      # @param [Hash] raw_document
      # @return DocumentHash
      # @api public
      def create(raw_document)
        server_response = send_request "/document?collection=#{@id}",
          post: raw_document

        Document.new @database, server_response
      end

      alias :<< :create

      # Add an index to the collection
      #
      # @param [Symbol] type specify the type of the index, for example `:hash`
      # @option opts [Array<Symbol>] on fields on which to apply the index
      # @return Index
      # @api public
      # @example Add a hash-index to the fields :name and :profession of a collection
      #   people = database['people']
      #   people.add_index :hash, :on => [:name, :profession]
      def add_index(type, opts)
        server_response = send_request "/index?collection=#{@id}", post: {
          "type" => type.to_s,
          "fields" => opts[:on].map { |field| field.to_s }
        }

        Index.new self, server_response
      end

      # Get an index by ID
      #
      # @param [Integer] id
      # @return Index
      # @api public
      def index(id)
        server_response = send_request "/index/#{@id}/#{id}"

        Index.new self, server_response
      end

      # Get all indices
      #
      # @return [Array<Index>]
      # @api public
      def indices
        server_response = send_request "/index?collection=#{@id}"

        server_response["indexes"].map do |raw_index|
          Index.new self, raw_index
        end
      end

      # Return a Query initialized with this collection
      #
      # @return [Query]
      # @api public
      def query
        Query.new self
      end

      private

      # Send a request to the server with the name of the collection prepended
      #
      # @return [String] Response from the server
      # @api private
      def send_request_for_this_collection(path, method={})
        send_request "/collection/#{id}#{path}", method
      end
    end
  end
end
