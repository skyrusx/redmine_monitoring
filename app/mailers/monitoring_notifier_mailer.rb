class MonitoringNotifierMailer < ApplicationMailer
  default from: 'redmine@monitoring.com'

  def alert(payload, recipients)
    @payload = payload
    mail(to: recipients, subject: "#{@payload[:headline]} (#{@payload[:count_in_window] || 1}×)")
  end
end
