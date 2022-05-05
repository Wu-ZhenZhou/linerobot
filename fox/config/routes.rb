Rails.application.routes.draw do
  get '/smallfox/eat', to: 'smallfox#eat'
  get '/smallfox/request_headers', to: 'smallfox#request_headers'
  get '/smallfox/request_body', to: 'smallfox#request_body'
  get '/smallfox/response_headers', to: 'smallfox#response_headers'
  get '/smallfox/response_body', to: 'smallfox#show_response_body'

end
