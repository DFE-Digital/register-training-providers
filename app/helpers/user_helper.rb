module UserHelper
  def status_tags(user)
    status_tags = if user.active?
                    govuk_tag(text: "Active",
                              colour: "teal")
                  else
                    govuk_tag(
                      text: "Not active", colour: "grey"
                    )
                  end
    status_tags += govuk_tag(text: "API user", colour: "yellow") if user.api_user?

    status_tags
  end
end
