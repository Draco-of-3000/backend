class AddExplicitUniqueIndexToPlayersId < ActiveRecord::Migration[7.1]
  def change
    # Attempt to remove the index first in case a previous partial attempt left it in a weird state,
    # but only if it exists. This is a safety measure.
    if index_exists?(:players, :id, name: 'index_players_on_id')
      remove_index :players, name: 'index_players_on_id', if_exists: true
      Rails.logger.info "Removed existing 'index_players_on_id' before re-adding."
    end

    # Add the unique index directly on id.
    # If this fails because a suitable index (like the PK) *truly* makes this redundant
    # from the DB's perspective, the DB will error, which is fine.
    # But if it succeeds, AR *should* see it.
    begin
      add_index :players, :id, unique: true, name: 'index_players_on_id'
      Rails.logger.info "Successfully added explicit unique index 'index_players_on_id' to players.id"
    rescue ActiveRecord::StatementInvalid => e
      # This might happen if the primary key constraint itself is ALREADY named 'index_players_on_id'
      # or if another unique index on solely 'id' exists with a different name,
      # though our logs don't show that.
      Rails.logger.warn "Could not add unique index 'index_players_on_id'. It might conflict with an existing index (e.g., the primary key) or another unique index on 'id'. Error: #{e.message}"
      # We still want to check if players_pkey is visible, as that's the ideal scenario.
      unless index_exists?(:players, :id, unique: true, name: 'players_pkey')
        Rails.logger.warn "'players_pkey' is still not being reported by index_exists?."
      else
        Rails.logger.info "'players_pkey' was found by index_exists?."
      end
    end
  end
end