RSpec::Matchers.define :have_warning_text do |expected_content|
  include CapybaraNodeHelper

  match do |page_or_html|
    node = wrap_as_capybara_node(page_or_html)
    expect(node).to have_css(".govuk-warning-text")
    warning_text = node.find(".govuk-warning-text")
    expect(warning_text).not_to be_nil

    expect(warning_text).to have_css(".govuk-warning-text__icon", text: "!")
    expect(warning_text).to have_css(".govuk-warning-text__text", text: "Warning#{expected_content}")
  end

  failure_message do |_page|
    "expected to find a warning text with content '#{expected_content}', but it was not found."
  end

  failure_message_when_negated do |_page|
    "expected not to find a warning text with content '#{expected_content}', but it was found."
  end
end
