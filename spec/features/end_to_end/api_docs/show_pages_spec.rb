require "rails_helper"

RSpec.feature "navigate to the all the api endpoint documentation" do
  all_links = ApiDocs::OpenapiSpecification.endpoints.map { |path, data|
    data[:specifications].keys.map do |http_method|
      "api-docs/#{http_method}/#{path.delete_prefix("/")}"
    end
  }.flatten

  shared_examples "navigate to" do |link|
    scenario "navigate to #{link}" do
      visit link

      expect(page.status_code).to eq(200)
      expect(page).to have_css("#main-content")
    end
  end

  all_links.each do |link|
    it_behaves_like "navigate to", link
  end
end
