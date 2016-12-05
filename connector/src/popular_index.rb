require 'algoliasearch'

require_relative './config.rb'

class PopularIndex
  DEFAULT_SETTINGS = {
    attributesToIndex: %w(query),
    customRanking: %w(desc(popularity)),
    numericAttributesToIndex: []
  }.freeze

  def self.client
    @client ||= Algolia::Client.new(
      application_id: client_app_id,
      api_key: client_api_key
    )
  end

  def self.client_app_id
    CONFIG['algolia_target_app_id'] || CONFIG['algolia_app_id']
  end

  def self.client_api_key
    CONFIG['algolia_target_api_key'] || CONFIG['algolia_api_key']
  end

  def initialize
  end

  def push records
    tmp_index.set_settings! settings
    records.each_slice(1000) do |recs|
      tmp_index.add_objects! recs
    end
    move_tmp
  end

  def name
    "#{CONFIG['index']}_popular_queries"
  end

  def index
    @index ||= self.class.client.init_index name
  end

  def tmp_index
    @tmp_index ||= self.class.client.init_index "#{name}.tmp"
  end

  def move_tmp
    self.class.client.move_index tmp_index.name, index.name
  end

  def settings
    index.get_settings
  rescue Algolia::AlgoliaProtocolError => e
    raise if e.code / 100 != 4
    puts index.client.application_id
    index.set_settings! DEFAULT_SETTINGS
    DEFAULT_SETTINGS
  end
end