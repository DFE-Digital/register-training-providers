return unless ENV.fetch("LIVING_DOCS", nil) == "1"

module HighlightAndPauseClick
  def click(*, &)
    session = Capybara.current_session
    example = RSpec.current_example

    # Highlight element
    begin
      sleep 0.1
      session.execute_script(
        "arguments[0].style.outline = '4px solid #ff4757';" \
        "arguments[0].style.outlineOffset = '2px';" \
        "arguments[0].style.backgroundColor = 'rgba(255, 71, 87, 0.2);'",
        self
      )
      sleep 0.2
    rescue StandardError # Element might be gone or un-styleable
    end

    # Determine action label for the badge
    element_text = begin
      text.strip.tr("\n", " ")[0..30]
    rescue StandardError
      ""
    end
    element_text = " '#{element_text}'" unless element_text.empty?
    current_count = (session.instance_variable_get(:@screenshot_counter) || 0) + 1
    action_label = "Step #{current_count}: Clicked #{tag_name}#{element_text}"

    # Perform actual click
    super

    if example&.metadata&.[](:living_docs)
      inject_badge(session, action_label)
      LivingDocsHelpers.take_screenshot(session, "action", example)
      remove_badge(session)
    end
  end

private

  def inject_badge(session, text)
    session.execute_script(<<~JS, text)
      (function(text) {
        const badge = document.createElement('div');
        badge.id = 'living-doc-action-badge';
        badge.style.cssText = 'position: fixed; bottom: 24px; right: 24px; background: rgba(15, 23, 42, 0.95); color: #f8fafc; padding: 14px 20px; border-radius: 10px; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.5); z-index: 999999; font-family: system-ui, sans-serif; font-size: 14px; font-weight: 600; border: 1px solid #334155;';
        badge.innerHTML = `<span style="color: #ff4757; margin-right: 10px; font-size: 18px; vertical-align: middle;">●</span><span style="vertical-align: middle;">${text}</span>`;
        document.body.appendChild(badge);
      })(arguments[0]);
    JS
    sleep 0.3
  rescue StandardError
  end

  def remove_badge(session)
    session.execute_script("const b = document.getElementById('living-doc-action-badge'); if (b) b.remove();")
  rescue StandardError
  end
end

module AutoIntroCard
  def visit(url, &)
    super

    example = RSpec.current_example
    session = Capybara.current_session

    if example&.metadata&.[](:living_docs) && !session.instance_variable_get(:@intro_shown)
      session.instance_variable_set(:@intro_shown, true)

      show_intro_overlay(session, example.description)
      LivingDocsHelpers.take_screenshot(session, "initial", example)
    end
  end

private

  def show_intro_overlay(session, description)
    session.execute_script(<<~JS, description)
      (function(desc) {
        const overlay = document.createElement('div');
        overlay.id = 'living-doc-intro';
        overlay.style.cssText = 'position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: rgba(15, 23, 42, 0.98); color: #fff; display: flex; flex-direction: column; justify-content: center; align-items: center; z-index: 999999; font-family: system-ui, sans-serif; transition: opacity 0.4s ease;';
        overlay.innerHTML = `
          <div style="text-align: center; padding: 40px; max-width: 800px;">
            <span style="font-size: 13px; text-transform: uppercase; letter-spacing: 2px; color: #ff4757; font-weight: bold; margin-bottom: 14px; display: block;">Workflow Demonstration</span>
            <h1 style="font-size: 32px; font-weight: 700; margin: 0 0 12px 0; line-height: 1.2;">${desc}</h1>
            <p style="font-size: 15px; color: #94a3b8; margin: 0;">Living Documentation Engine</p>
          </div>`;
        document.body.appendChild(overlay);
      })(arguments[0]);
    JS

    sleep 2.0

    session.execute_script(<<~JS)
      const overlay = document.getElementById('living-doc-intro');
      if (overlay) {
        overlay.style.opacity = '0';
        setTimeout(() => overlay.remove(), 400);
      }
    JS
    sleep 0.4
  rescue StandardError
  end
end
