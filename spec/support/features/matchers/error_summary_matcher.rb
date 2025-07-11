RSpec::Matchers.define :have_error_summary do |*expected_messages|
  include CapybaraNodeHelper

  match do |page_or_html|
    node = wrap_as_capybara_node(page_or_html)

    return false unless node.has_css?(".govuk-error-summary")

    actual_messages = node.all(".govuk-error-summary__list li a").map(&:text)
    actual_messages == expected_messages
  end

  failure_message do |page_or_html|
    node = wrap_as_capybara_node(page_or_html)
    actual = node.has_css?(".govuk-error-summary") ? node.all(".govuk-error-summary__list li a").map(&:text) : []
    "expected error summary messages to exactly match #{expected_messages.inspect}, but got #{actual.inspect}"
  end

  failure_message_when_negated do |_page|
    "expected not to find error summary element with CSS selector '.govuk-error-summary', but found one"
  end
end
