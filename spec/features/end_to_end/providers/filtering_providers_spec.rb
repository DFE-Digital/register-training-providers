RSpec.feature "Filter Training Providers" do
  scenario "User filters providers by type" do
    given_i_am_on_the_provider_list_page
    when_i_check_the_box_for_higher_education_institution
    then_the_list_of_providers_should_only_show_higher_education_institutions
  end

  scenario "User filters providers by accreditation type" do
    given_i_am_on_the_provider_list_page
    when_i_check_the_box_for_accredited
    then_the_list_of_providers_should_only_show_accredited_providers
  end

  scenario "User filters providers by archived status" do
    given_i_am_on_the_provider_list_page
    when_i_check_the_box_for_include_archived_providers
    then_the_list_of_providers_should_include_archived_providers
  end

  scenario "User filters providers by seed data provider issues" do
    given_i_am_on_the_provider_list_page(debug: true)
    when_i_check_the_box_for_show_seed_data_with_issues_issues
    then_the_list_of_providers_should_include_archived_providers
  end

  def given_i_am_on_the_provider_list_page(debug: false)
    given_i_am_an_authenticated_user
    and_there_are_a_number_of_providers

    url = "/providers"
    url += "?debug=true" if debug
    visit url
  end

  def when_i_check_the_box_for_higher_education_institution
    check "Higher education institution (HEI)"
    click_on "Apply filters"
  end

  def then_the_list_of_providers_should_only_show_higher_education_institutions
    expect(page).to have_title("Providers (3)")
    expect(page).to have_css(".govuk-summary-card", count: hei_providers.count)

    hei_providers.each do |provider|
      expect(page).to have_selector("h2", text: provider.operating_name)
    end
    expect(page).to have_selector(".govuk-summary-list__value", text: "Higher education institution", count: hei_providers.count)
  end

  def when_i_check_the_box_for_accredited
    check "Accredited"
    click_on "Apply filters"
  end

  def then_the_list_of_providers_should_only_show_accredited_providers
    expect(page).to have_title("Providers (#{accredited_providers_count})")

    expect(page).to have_css(".govuk-summary-card", count: accredited_providers.count)

    accredited_providers.each do |provider|
      expect(page).to have_selector("h2", text: provider.operating_name)
    end

    expect(page).to have_selector(".govuk-summary-list__value", text: "Accredited", count: accredited_providers.count)
  end

  def when_i_check_the_box_for_show_seed_data_with_issues_issues
    check "Include archived providers"
    click_on "Apply filters"
  end

  def when_i_check_the_box_for_include_archived_providers
    check "Include archived providers"
    click_on "Apply filters"
  end

  def then_the_list_of_providers_should_include_archived_providers
    expect(page).to have_title("Providers (#{Provider.count})")
  end

  def and_there_are_a_number_of_providers
    hei_providers
    create_list(:provider, 5, :other, :accredited)
    create_list(:provider, 5, :school)
    create_list(:provider, 5, :scitt, :accredited)
    archived_providers
  end

  def hei_providers
    @hei_providers ||= create_list(:provider, 3, :hei, :accredited)
  end

  def accredited_providers
    @accredited_providers ||= Provider.accredited.where(archived_at: nil).order_by_operating_name.limit(10)
  end

  def accredited_providers_count
    @accredited_providers_count ||= Provider.accredited.where(archived_at: nil).count
  end

  def archived_providers
    @archived_providers ||= create_list(:provider, 4, :archived)
  end
end
