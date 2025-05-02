RSpec::Matchers.define :have_service_name_in_the_header do
  match do |page|
    page.within('.govuk-header') do
      page.has_link?('Register of training providers', href: root_path)
    end
  end
end
