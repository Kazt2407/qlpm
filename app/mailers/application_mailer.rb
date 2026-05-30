class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "qlpm@example.local")
  layout "mailer"
end
