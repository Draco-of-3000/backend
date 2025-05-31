class Card < ApplicationRecord
  validates :color, presence: true, inclusion: { in: %w[red blue green yellow wild] }
  validates :value, presence: true
  validates :card_type, presence: true, inclusion: { in: %w[number skip reverse draw_two wild wild_draw_four] }
  
  enum :card_type, {
    number: 'number',
    skip: 'skip',
    reverse: 'reverse',
    draw_two: 'draw_two',
    wild: 'wild',
    wild_draw_four: 'wild_draw_four'
  }, prefix: :card
  
  scope :by_color, ->(color) { where(color: color) }
  scope :special_cards, -> { where.not(card_type: 'number') }
  scope :wild_cards, -> { where(card_type: ['wild', 'wild_draw_four']) }
  
  def can_play_on?(other_card, current_color = nil)
    return true if wild?
    return true if color == other_card.color
    return true if value == other_card.value && card_type == other_card.card_type
    return true if current_color && color == current_color
    
    false
  end
  
  def wild?
    card_type.in?(['wild', 'wild_draw_four'])
  end
  
  def special?
    !card_number?
  end
  
  def draw_penalty
    case card_type
    when 'draw_two'
      2
    when 'wild_draw_four'
      4
    else
      0
    end
  end
  
  def display_name
    if wild?
      card_type.humanize
    else
      "#{color.capitalize} #{value}"
    end
  end
  
  def to_hash
    {
      color: color,
      value: value,
      card_type: card_type
    }
  end
  
  def self.create_deck
    cards = []
    
    # Number cards (0-9) for each color
    %w[red blue green yellow].each do |color|
      # One 0 card per color
      cards << { color: color, value: '0', card_type: 'number' }
      
      # Two of each number 1-9 per color
      (1..9).each do |number|
        2.times do
          cards << { color: color, value: number.to_s, card_type: 'number' }
        end
      end
      
      # Two of each special card per color
      %w[skip reverse draw_two].each do |special|
        2.times do
          cards << { color: color, value: special, card_type: special }
        end
      end
    end
    
    # Wild cards (4 of each)
    4.times do
      cards << { color: 'wild', value: 'wild', card_type: 'wild' }
      cards << { color: 'wild', value: 'wild_draw_four', card_type: 'wild_draw_four' }
    end
    
    cards
  end
end
