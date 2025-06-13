RSpec::Matchers.define :have_error_summary do |*expected_messages|
  include CapybaraNodeHelper

  match do |page_or_html|
    node = wrap_as_capybara_node(page_or_html)
    node.has_css?(".govuk-error-summary") &&
      expected_messages.all? do |msg|
        node.all(".govuk-error-summary__list li a").map(&:text).include?(msg)
      end
  end

  failure_message do |page_or_html|
    node = wrap_as_capybara_node(page_or_html)
    actual = node.has_css?(".govuk-error-summary") ? node.all(".govuk-error-summary__list li a").map(&:text) : []
    "expected error summary to include #{expected_messages.inspect}, but got #{actual.inspect}"
  end

  failure_message_when_negated do |_page|
    "expected not to find error summary element with CSS selector '.govuk-error-summary', but found one"
  end
end
