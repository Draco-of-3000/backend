# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.production?
      origins ENV.fetch('FRONTEND_URL', 'https://default-frontend-url.com') # Set a sensible default or raise if not set
    else
      origins "localhost:3000", "localhost:3001", "127.0.0.1:3000", "127.0.0.1:3001", /https?:\/\/[a-z0-9\-]+dev\-\d+\.ws\-.+\.gitpod\.io/ # Allow Gitpod
    end

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
