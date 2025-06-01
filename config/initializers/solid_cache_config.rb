if Rails.env.production?
  Rails.application.config.to_prepare do
    SolidCache::Record.connects_to database: { writing: :primary, reading: :primary }
  end
end 