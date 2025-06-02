# Rails 8.0 + Supabase/PostgreSQL Production Compatibility Fixes
#
# This initializer addresses issues with Rails 8.0's schema cache detection
# and insert_all behavior when used with Supabase (managed PostgreSQL) 
# in production environments.

module SolidCableEntryInsertAllPatch
  def insert_all(attributes_hashes, returning: nil, unique_by: nil, record_timestamps: nil)
    effective_unique_by = unique_by
    # For SolidCable::Entry, when unique_by is :id (from create! -> _insert_record -> insert_all(unique_by: :id)),
    # change it to [[]] to tell ActiveRecord::InsertAll to not look for any unique index
    # and perform a plain insert. This is to bypass issues with primary key index detection on Supabase.
    if unique_by == :id || unique_by == [:id]
      Rails.logger.warn "[SolidCable::Entry Patch (Prepended)] Overriding unique_by from '#{unique_by.inspect}' to '[[]]' for insert_all on SolidCable::Entry."
      effective_unique_by = [[]] # Force no index for conflict resolution
    else
      # Log if called with other unique_by values, just for observation.
      Rails.logger.info "[SolidCable::Entry Patch (Prepended)] insert_all CALLED on SolidCable::Entry with unique_by: #{unique_by.inspect} (not :id, no override)."
    end
    super(attributes_hashes, returning: returning, unique_by: effective_unique_by, record_timestamps: record_timestamps)
  end
end

if Rails.env.production?
  Rails.application.config.after_initialize do
    # Clear schema cache on application start to ensure fresh schema detection
    begin
      ActiveRecord::Base.connection.schema_cache.clear!
      Rails.logger.info "Schema cache cleared for Supabase compatibility"
    rescue => e
      Rails.logger.warn "Could not clear schema cache: #{e.message}"
    end

    # Patch SolidCable::Entry to avoid "No unique index found for id" during message saving
    if defined?(SolidCable::Entry)
      Rails.logger.info "Attempting to PREPEND SolidCableEntryInsertAllPatch to SolidCable::Entry.singleton_class for Supabase/Rails 8 compatibility"
      SolidCable::Entry.singleton_class.prepend SolidCableEntryInsertAllPatch
      Rails.logger.info "SolidCableEntryInsertAllPatch PREPENDED to SolidCable::Entry.singleton_class for production."
    else
      Rails.logger.warn "SolidCable::Entry not defined at patch time, skipping SolidCable::Entry patch."
    end
  end
end 