module CheckYourAnswers
  class View < ApplicationComponent
    attr_reader :rows, :title, :subtitle, :caption, :back_path, :save_button_text, :save_path, :cancel_path, :method,
                :header

    def initialize(rows:, caption:, back_path:, save_button_text:, save_path:, cancel_path:, method:, subtitle: nil,
                   header: "Check your answers", title: "Check your answers")
      @rows = rows
      @subtitle = subtitle
      @caption = caption
      @back_path = back_path
      @save_button_text = save_button_text
      @save_path = save_path
      @cancel_path = cancel_path
      @title = title
      @header = header
      @method = method
      super()
    end
  end
end
