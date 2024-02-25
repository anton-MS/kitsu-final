require 'rails_admin/config/fields/types/text'

module RailsAdmin
  module Config
    module Fields
      module Types
        class LocalizedString < RailsAdmin::Config::Fields::Types::Text
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :html_attributes do
            {
              required: required?,
              cols: '70',
              rows: '6'
            }
          end

          def form_default_value
            default_value if bindings[:object].new_record?
          end

          def formatted_value
            return nil if value.blank?
            value.map { |(key, value)| "#{key}: #{value}" }.join("\n")
          end

          def parse_value(value)
            return if value.blank?

            value.each_line
                 .map { |line| line.split(':', 2).map(&:strip) }
                 .select { |line| line.count == 2 }
                 .to_h
          end

          def parse_input(params)
            return unless params[name].is_a?(::String)
            params[name] = parse_value(params[name])
          end
        end
      end
    end
  end
end
