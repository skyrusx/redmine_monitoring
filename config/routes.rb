# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'monitoring', to: 'monitoring_errors#index', as: 'monitoring_errors'
get 'monitoring/test_error', to: 'monitoring_errors#test_error', as: 'monitoring_test_error'
post 'monitoring/clear', to: 'monitoring_errors#clear', as: 'monitoring_clear'
