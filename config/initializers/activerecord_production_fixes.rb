# Rails 8.0 + Supabase/PostgreSQL Production Compatibility Fixes
#
# This initializer addresses issues with Rails 8.0's schema cache detection
# when used with Supabase (managed PostgreSQL) in production environments.
#
# The main issue is that Rails 8.0's unique index detection doesn't work properly
# with Supabase's PostgreSQL configuration, causing "No unique index found for id" errors.

if Rails.env.production?
  Rails.application.config.after_initialize do
    # Clear schema cache on application start to ensure fresh schema detection
    begin
      ActiveRecord::Base.connection.schema_cache.clear!
      Rails.logger.info "Schema cache cleared for Supabase compatibility"
    rescue => e
      Rails.logger.warn "Could not clear schema cache: #{e.message}"
    end
  end
end 