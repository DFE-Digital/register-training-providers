require "rails_helper"

RSpec.feature "navigate to the api docs" do
  scenario do
    given_i_am_on_the_start_page
    and_i_click_on("API documentation")
    then_i_am_taken_to("/api-docs")
    and_there_is_links_to_all_api_endpoints
  end

  def given_i_am_on_the_start_page
    visit "/"
  end

  def and_i_click_on(link)
    click_link link
  end

  def then_i_am_taken_to(path)
    expect(page).to have_current_path(path)
  end

  def and_there_is_links_to_all_api_endpoints
    ApiDocs::OpenapiSpecification.endpoints.each do |path, data|
      data[:specifications].each_key do |http_method|
        expect(page).to have_link(path, href: api_docs_page_path(http_method, path.delete_prefix("/")))
      end
    end
  end
end
