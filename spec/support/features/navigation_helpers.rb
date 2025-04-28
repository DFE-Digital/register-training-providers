module NavigationHelpers
  def then_i_am_take_to(path)
    expect(page).to have_current_path(path)
  end

  def when_i_click_on(button_or_link)
    page.click_on(button_or_link)
  end
end
