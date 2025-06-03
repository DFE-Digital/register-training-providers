module CapybaraNodeHelper
  def wrap_as_capybara_node(input)
    if input.respond_to?(:has_css?) && input.respond_to?(:find)
      input
    else
      Capybara::Node::Simple.new(input.to_s)
    end
  end
end
