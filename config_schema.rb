require 'dry/schema'

DependabotConfigurationSchema = Dry::Schema.Params do 
    config.validate_keys = true
    optional(:package_manager).filled(:string)
    optional(:ignored_versions).array(:hash) do
        required(:name).filled(:string)
        required(:versions).value(:array, min_size?: 1).each(:str?)
    end
end