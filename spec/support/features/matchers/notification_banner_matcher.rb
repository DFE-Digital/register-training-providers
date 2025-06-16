RSpec::Matchers.define :have_notification_banner do |expected_title, expected_content|
  match do |page|
    element = page.find(".govuk-notification-banner", text: expected_title)
    expect(element).not_to be_nil
    within element do
      content_element = find(".govuk-heading-m", text: expected_content)
      expect(content_element).to be_visible
    end
  end

  failure_message do |_page|
    "expected to find a notification banner with title '#{expected_title}' and content '#{expected_content}', but it was not found."
  end

  failure_message_when_negated do |_page|
    "expected not to find a notification banner with title '#{expected_title}' and content '#{expected_content}', but it was found."
  end
end
