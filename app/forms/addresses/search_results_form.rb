module Addresses
  class SearchResultsForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include SaveAsTemporary

    attribute :results, :string
    attribute :selected_address_index, :integer

    def self.model_name
      ActiveModel::Name.new(self, nil, "SearchResults")
    end

    def self.i18n_scope
      :activerecord
    end

    def results_array
      return [] if results.blank?

      JSON.parse(results)
    rescue JSON::ParserError
      []
    end

    def results_array=(array)
      self.results = array.to_json
    end

    alias_method :serializable_hash, :attributes
  end
end
