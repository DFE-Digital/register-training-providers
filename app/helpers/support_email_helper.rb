module SupportEmailHelper
  def support_email(name: nil, subject: nil, classes: nil)
    default_classes = "app-!-overflow-break-word"

    govuk_mail_to(I18n.t("service.email"), name, subject: subject, class: "#{default_classes} #{classes}")
  end
end
