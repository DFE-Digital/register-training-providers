RSpec::Matchers.define :have_back_link do |expected_href|
  include CapybaraNodeHelper

  match do |content|
    node = wrap_as_capybara_node(content)
    node.has_link?("Back", href: expected_href)
  end

  failure_message do |content|
    "expected that content would have a 'Back' link to #{expected_href}, but it did not.\nContent was:\n#{content}"
  end

  failure_message_when_negated do |_content|
    "expected that content would NOT have a 'Back' link to #{expected_href}, but it did."
  end

  description do
    "have a 'Back' link to #{expected_href}"
  end
end
