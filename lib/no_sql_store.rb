require 'aws-sdk'

# Generic Store for DynamoDB
class NoSqlStore
  attr_reader :request_items
  attr_reader :unprocessed_items
  MAX_BATCH_SIZE = 25

  def initialize
    @request_items = {}
    @unprocessed_items = []
    @mutex = Mutex.new
    @db = Aws::DynamoDB::Client.new
  end

  # add the item to an array, waiting for later batch write
  def add_to_batch(record)
    @mutex.synchronize do
      @request_items[record.table] ||= []
      @request_items[record.table] << { put_request: { item: record.items } }
      # this line return the updated table in batch write.
      self
    end
  end

  # save the item to remote dynamodb
  def save(record)
    @db.put_item(table_name: record.table, item: record.items)
  end

  # delete
  def batch_flush
    @mutex.synchronize do
      return if @request_items.length == 0
      resp = @db.batch_write_item(request_items: @request_items)
      @request_items = {}
      @unprocessed_items << resp[:unprocessed_items] if resp[:unprocessed_items]
    end
    self
  end

  # checked and save
  def save_eventually(record)
    add_to_batch(record)
    batch_length = @mutex.synchronize { @request_items[record.table].length }
    batch_flush if batch_length == MAX_BATCH_SIZE
  end

  # create new table according to model
  def create_table(model, read_capacity, write_capacity)
    prototype = model.new
    hash_key = prototype.hash_key
    range_key = prototype.range_key
    type = { String => 'S', Fixnum => 'N' }

    params = {
      attribute_definitions: [
        { attribute_name: hash_key.name, attribute_type: type[hash_key.type] },
        { attribute_name: range_key.name, attribute_type: type[range_key.type] }
      ],
      table_name: prototype.table,
      key_schema: [
        { attribute_name: prototype.hash_key.name, key_type: 'HASH' },
        { attribute_name: prototype.range_key.name, key_type: 'RANGE' }
      ],
      provisioned_throughput: {
        read_capacity_units: read_capacity,
        write_capacity_units: write_capacity
      }
    }
    @db.create_table(params)
    self
  end
end
