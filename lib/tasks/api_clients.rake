namespace :api_clients do
  desc <<~DESC
    Create an API token for a client.

    Usage:
      rake api_clients:create_token['ClientName','user_email@example.com','YYYY-MM-DD']

    Arguments:
      ClientName        - Name of the API client (will be created if it doesn't exist)
      user_email        - Email of the user who creates the token
      YYYY-MM-DD        - (Optional) Expiry date of the token. Defaults to 6 months from today.
  DESC
  task :create_token, [:client_name, :user_email, :expires_at] => :environment do |_t, args|
    # Ensure args are present or nil
    client_name = args[:client_name]
    user_email  = args[:user_email]
    expires_at  = args[:expires_at] # optional, may be nil

    if client_name.blank? || user_email.blank?
      puts "Error: client_name and user_email are required."
      exit 1
    end

    # Your service call
    token = Api::Clients::CreateToken.call(
      client_name: client_name,
      created_by_email: user_email,
      expires_at: expires_at
    )

    puts "Token created successfully:"
    puts "  Client: #{token.api_client.name}"
    puts "  Token: #{token.token}"
    puts "  Expires at: #{token.expires_at}"
    puts "Curl: curl -H 'Authorization: Bearer #{token.token}' http://localhost:1025/api/v0/info"
  end

  desc <<~DESC
    List all API clients.

    Usage:
      rake api_clients:list

    No arguments required.
  DESC
  task list: :environment do
    ApiClient.order(:name).each do |client|
      puts "- #{client.name} (ID: #{client.id}, Discarded: #{client.discarded?})"
    end
  end

  desc <<~DESC
    Revoke all active tokens for a given API client.

    Usage:
      rake api_clients:revoke['ClientName']

    Arguments:
      ClientName  - Name of the API client whose tokens you want to revoke.
  DESC
  task :revoke, [:client_name] => :environment do |_t, args|
    client_name = args[:client_name]

    if client_name.blank?
      puts "Error: client_name is required."
      exit 1
    end

    client = ApiClient.kept.find_by(name: client_name)
    if client.nil?
      puts "API client '#{client_name}' not found or discarded."
      exit 1
    end

    client.revoke_all_active_tokens!
    puts "All active tokens for '#{client.name}' have been revoked."
  end
end
