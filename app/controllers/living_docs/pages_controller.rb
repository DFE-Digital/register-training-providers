module LivingDocs
  class PagesController < BaseController
    def home
      @items = Rails.public_path.join("living_docs").children
  .filter_map do |name|
        return unless Rails.public_path.join("living_docs", name).directory?

        file_name = name.basename.to_s

        [humanize_feature_name(file_name), file_name]
      end
    end

    def show
      path = Rails.public_path.join("living_docs", params[:path], "data.json")

      @data = JSON.parse(path.read).with_indifferent_access
    end

  private

    def humanize_feature_name(name)
      name
        .tr("_", " ")
        .gsub(/\s+/, " ")
        .strip
        .capitalize
    end
  end
end
