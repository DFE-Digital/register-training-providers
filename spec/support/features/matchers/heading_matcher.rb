RSpec::Matchers.define :have_heading do |tag, text|
  match do |page|
    # Check for the tag with the correct text
    has_correct_text = page.has_selector?(tag, text: text)

    # If it's an h1, also check that there's only one
    if tag.downcase == "h1"
      has_correct_text && page.all(tag).size == 1
    else
      has_correct_text
    end
  end

  failure_message do |page|
    count = page.all(tag).size
    if count == 0
      "expected page to have a #{tag} heading with text '#{text}', but none was found"
    elsif tag.downcase == "h1" && count > 1
      "expected exactly one #{tag}, but found #{count}"
    else
      "found one #{tag}, but text didn't match '#{text}'"
    end
  end
end
