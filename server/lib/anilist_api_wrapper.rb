# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'

module AnilistApiWrapper
  GRAPHQL_API = 'https://graphql.anilist.co'

  begin
    HTTP = GraphQL::Client::HTTP.new(GRAPHQL_API) do
      def headers(_)
        { 'Content-Type': 'application/json' }
      end
    end

    Schema = GraphQL::Client.load_schema(HTTP)

    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
  rescue StandardError => e
    Sentry.capture_exception(e)
  end
end
