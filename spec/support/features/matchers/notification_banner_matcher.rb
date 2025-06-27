RSpec::Matchers.define :have_notification_banner do |expected_title, expected_content|
  match do |page|
    page.has_css?(".govuk-notification-banner") &&
      page.has_css?(".govuk-notification-banner__header", text: expected_title) &&
      page.has_css?(".govuk-notification-banner__content", text: expected_content)
  end

  failure_message do |_page|
    "expected to find a notification banner with title '#{expected_title}' and content '#{expected_content}', but it was not found."
  end

  failure_message_when_negated do |_page|
    "expected not to find a notification banner with title '#{expected_title}' and content '#{expected_content}', but it was found."
  end
end
