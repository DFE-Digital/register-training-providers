RSpec::Matchers.define :have_error_summary do |*expected_messages|
  include CapybaraNodeHelper

  match do |page_or_html|
    node = wrap_as_capybara_node(page_or_html)
    return false unless node.has_css?(".govuk-error-summary")

    return true if expected_messages.empty?

    actual_messages = node.all(".govuk-error-summary__list li a").map(&:text)
    actual_messages == expected_messages
  end

  match_when_negated do |page_or_html|
    node = wrap_as_capybara_node(page_or_html)
    !node.has_css?(".govuk-error-summary")
  end

  failure_message do |page_or_html|
    node = wrap_as_capybara_node(page_or_html)
    if node.has_css?(".govuk-error-summary")
      actual = node.all(".govuk-error-summary__list li a").map(&:text)
      "expected error summary messages to exactly match #{expected_messages.inspect}, but got #{actual.inspect}"
    else
      "expected error summary to be present, but it was not found"
    end
  end

  failure_message_when_negated do |_page|
    "expected not to find error summary element with CSS selector '.govuk-error-summary', but found one"
  end
end
