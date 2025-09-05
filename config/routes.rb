# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'monitoring', to: 'monitoring_errors#index', as: 'monitoring_errors'
post 'monitoring/clear', to: 'monitoring_errors#clear', as: 'monitoring_clear'

unless Rails.env.production?
  get 'monitoring/test_error', to: 'monitoring_errors#test_error', as: 'monitoring_test_error'
  get 'monitoring/test_reco', to: 'monitoring_errors#test_reco'
  get 'monitoring/test_alert', to: 'monitoring_errors#test_alert'
  get 'monitoring/security_scan', to: 'monitoring_errors#security_scan'
  get 'monitoring/security-report/:id', to: 'monitoring_errors#security_report', as: 'monitoring_security_report'

  mount LetterOpenerWeb::Engine, at: '/letter_opener'
end
