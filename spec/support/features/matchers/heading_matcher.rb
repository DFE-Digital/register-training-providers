RSpec::Matchers.define :have_heading do |tag, text|
  include CapybaraNodeHelper

  match do |page_or_html|
    node = wrap_as_capybara_node(page_or_html)
    has_correct_text = node.has_selector?(tag, text:)

    # If it's an h1, also check that there's only one
    if tag.downcase == "h1"
      has_correct_text && node.all(tag).size == 1
    else
      has_correct_text
    end
  end

  failure_message do |page_or_html|
    node = wrap_as_capybara_node(page_or_html)

    tags = node.all(tag)
    count = tags.size
    if count == 0
      "expected page to have a #{tag} heading with text '#{text}', but none was found"
    elsif tag.downcase == "h1" && count > 1
      "expected exactly one #{tag}, but found #{count}"
    else
      "found one #{tag}, but text didn't match '#{text}' actual text is '#{tags.first.text}'"
    end
  end
end
