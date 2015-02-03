require 'rack/session/moneta'
require 'rack/builder'
require 'rack/lint'
require 'dragonfly/middleware'

module Locomotive
  module Steam
    module Middlewares

      class Stack

        def initialize(options)
          @options = prepare_options(options)
        end

        def create
          options = @options

          Rack::Builder.new do
            use Rack::Lint

            use Middlewares::Favicon

            if options[:serve_assets]
              use Middlewares::StaticAssets, {
                urls: ['/images', '/fonts', '/samples', '/media']
              }
              use Middlewares::DynamicAssets
            end

            use Rack::Csrf,
              field:    'authenticity_token',
              skip_if:  -> (request) {
                !(request.post? && request.params[:content_type_slug].present?)
              }

            use ::Dragonfly::Middleware, :steam

            use Rack::Session::Moneta, options[:moneta]

            use_steam_middlewares(self)

            run Middlewares::Renderer.new
          end
        end

        protected

        def use_steam_middlewares(builder)
          builder.instance_eval do
            use Middlewares::Logging

            use Middlewares::EntrySubmission

            use Middlewares::Path
            use Middlewares::Locale
            use Middlewares::Timezone

            use Middlewares::Page
            use Middlewares::TemplatizedPage
          end
        end

        def prepare_options(options)
          {
            serve_assets: false,
            moneta: {
              store: Moneta.new(:Memory, :expires => true)
            }
          }.merge(options)
        end

      end

    end
  end
end