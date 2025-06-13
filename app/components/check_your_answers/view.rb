module CheckYourAnswers
  class View < ViewComponent::Base
    include ApplicationHelper
    attr_reader :rows, :title, :subtitle, :caption, :back_path, :save_button_text, :save_path, :cancel_path

    def initialize(rows:, subtitle:, caption:, back_path:, save_button_text:, save_path:, cancel_path:,
                   title: "Check your answers")
      @rows = rows
      @subtitle = subtitle
      @caption = caption
      @back_path = back_path
      @save_button_text = save_button_text
      @save_path = save_path
      @cancel_path = cancel_path
      @title = title
      super
    end
  end
end
