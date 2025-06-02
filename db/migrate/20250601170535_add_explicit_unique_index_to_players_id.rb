class AddExplicitUniqueIndexToPlayersId < ActiveRecord::Migration[8.0]
  def change
    # This migration was created to potentially fix unique index detection issues
    # but adding a unique index on the primary key is redundant and unnecessary
    # Primary keys are already unique by definition
  end
end
