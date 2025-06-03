RSpec::Matchers.define :have_pagination do
  include CapybaraNodeHelper

  match do |page_or_html|
    node = wrap_as_capybara_node(page_or_html)
    node.has_css?('.govuk-pagination')
  end

  failure_message do |_page|
    "expected to find pagination element with CSS selector '.govuk-pagination' but none found"
  end

  failure_message_when_negated do |_page|
    "expected not to find pagination element with CSS selector '.govuk-pagination' but found one"
  end
end
