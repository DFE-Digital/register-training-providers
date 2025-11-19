module Api
  module ErrorResponse
    def not_found_response(message:)
      {
        status: :not_found,
        json: {
          errors: errors("NotFound", message),
        }
      }
    end

  private

    def errors(error, message)
      [
        {
          error:,
          message:,
        },
      ]
    end
  end
end
