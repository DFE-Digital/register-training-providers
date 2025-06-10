module NavigationHelper
  def then_i_am_taken_to(path)
    expect(page).to have_current_path(path)
  end

  def when_i_click_on(button_or_link)
    page.click_on(button_or_link)
  end

  alias_method :and_i_click_on, :when_i_click_on
  alias_method :and_i_am_taken_to, :then_i_am_taken_to
end
