RSpec::Matchers.define :have_phase_banner do
  match do |page|
    page.has_css?(".govuk-phase-banner")
  end
end
