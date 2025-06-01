class AddExplicitUniqueIndexToPlayersId < ActiveRecord::Migration[7.1]
    def change
      # Check if the primary key index already effectively serves as a unique index on id.
      # This is to be safe, though our logs suggest AR isn't seeing it.
      # The main goal is to add an index that AR will definitely recognize as unique on id.
      unless index_exists?(:players, :id, unique: true, name: 'index_players_on_id') || index_exists?(:players, :id, unique: true, name: 'players_pkey')
        add_index :players, :id, unique: true, name: 'index_players_on_id'
        Rails.logger.info "Added explicit unique index 'index_players_on_id' to players.id"
      else
        Rails.logger.info "Skipped adding explicit unique index to players.id as a suitable one already exists or players_pkey is recognized."
      end
    end
  end