class Ideas < ActiveRecord::Base
  #Empty class - only rules here (why not DB? Who knows... Ruby is strange)
  validates :seen, numericality: {only_integer: true, greater_than_or_equal_to: 0} 
  validates :chosen, numericality: {only_integer: true, greater_than_or_equal_to: 0}
end

