module Accounts
  class GenerateNoltToken < Action
    NOLT_SSO_SECRET = ENV['NOLT_SSO_SECRET']

    parameter :user, load: User, required: true

    def call
      payload = {
        id: user.id,
        email: user.email,
        name: user.name,
        imageUrl: user.avatar(:large)&.url
      }

      token = JWT.encode(payload, NOLT_SSO_SECRET, 'HS256')

      { token: token }
    end
  end
end
