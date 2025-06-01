class GameRoom < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :users, through: :players
  has_one :game_state, dependent: :destroy
  belongs_to :winner_player, class_name: 'Player', optional: true
  belongs_to :turn_player, class_name: 'Player', optional: true
  
  validates :status, presence: true, inclusion: { in: %w[waiting in_progress finished] }
  validates :direction, presence: true, inclusion: { in: %w[clockwise counter_clockwise] }
  validates :current_color, inclusion: { in: %w[red blue green yellow], allow_nil: true }
  validates :code, presence: true, uniqueness: true, on: :create
  
  validate :player_count_within_limits
  
  enum :status, { waiting: 'waiting', in_progress: 'in_progress', finished: 'finished' }
  enum :direction, { clockwise: 'clockwise', counter_clockwise: 'counter_clockwise' }
  
  scope :available, -> { where(status: 'waiting') }
  
  before_validation :generate_unique_code, on: :create

  def to_param
    code
  end
  
  def full?
    players.count >= 4
  end
  
  def can_start?
    players.count >= 2 && status == 'waiting'
  end
  
  def next_player(current_player)
    ordered_players = players.order(:position)
    current_index = ordered_players.index(current_player)
    
    if direction == 'clockwise'
      next_index = (current_index + 1) % ordered_players.count
    else
      next_index = (current_index - 1) % ordered_players.count
    end
    
    ordered_players[next_index]
  end
  
  private
  
  def player_count_within_limits
    if players.count > 4
      errors.add(:players, "cannot exceed 4 players")
    end
  end

  def generate_unique_code
    loop do
      self.code = ("A".."Z").to_a.sample(2).join + SecureRandom.random_number(1000..9999).to_s
      break unless GameRoom.exists?(code: self.code)
    end
  end
end
