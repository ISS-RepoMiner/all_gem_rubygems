# Table class and Key structures to create DynamoDB models and items
module DynamoNugget
  Key = Struct.new(:name, :type) do
    def initialize(*)
      super
      self.name ||= 'id'
      self.type ||= Fixnum
    end
  end

  # Model of generic DynamoDB ready table
  class Table
    attr_reader :table, :hash_key, :range_key, :nugget_items
    attr_reader :items

    def initialize(hash_key = NuggetKey.new, range_key = nil, non_key_items = [])
      @table = self.class.name.split('::').last
      @hash_key = hash_key
      @range_key = range_key
      @non_key_items = non_key_items
    end

    def add_item(hash_value, range_value, *item_values)
      @items = { @hash_key.name => hash_value }
      @items[@range_key.name] = range_value if @range_key
      @non_key_items.each.with_index do |name, i|
        @items[name] = { value: item_values[i] }
      end
    end
  end
end

module GemMiner
  # Model of daily downloads table for DynamoDB
  class GemSpecDownload < DynamoNugget::Table
    # def initialize(gem_name = nil, version = nil, date = nil, download = nil)#
    def initialize(name = nil, version = nil, build_date = nil, authors = nil, github = nil, dependencies = nil, platform = nil)
      hash_key = DynamoNugget::Key.new('name_version', String)
      range_key = DynamoNugget::Key.new('build_date', String)
      item_names = %w(authors github dependencies platform)
      super(hash_key, range_key, item_names)

      add_item("#{name}[#{version}]", build_date, authors, github, dependencies, platform)#
    end
  end
end

# StoredNugget.new(NuggetKey.new, NuggetKey.new, ['asfd'])
# gemver = GemMiner::GemVerDownload.new('jem', '0.1.0', '2015-03-24', 11)
# gemversion = GemVersionDownload.new('jem', '0.1.0', '2015-03-24', 11)
