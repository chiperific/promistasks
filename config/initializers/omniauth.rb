# frozen_string_literal: true

OmniAuth.config.logger = Rails.logger

OmniAuth.config.full_host = Rails.env.production? ? Rails.environment.secrets.full_host : 'http://localhost:3000'

# ==> Now handled in config/initializers/devise.rb
# Rails.application.config.middleware.use OmniAuth::Builder do
#   provider  :google_oauth2,
#             Rails.application.secrets.google_client_id,
#             Rails.application.secrets.google_client_secret,
#             {
#               scope: 'email, profile, tasks',
#               image_aspect_ratio: 'square',
#               image_size: 50,
#               # hd: Rails.application.secrets.org_domain,
#               client_options: {
#                 ssl: { ca_file: Rails.root.join('cacert.pem').to_s }
#               }
#             }
# end
