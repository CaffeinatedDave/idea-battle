class Ideas < ActiveRecord::Base
  #Empty class - only rules here (why not DB? Who knows... Ruby is strange)
  validates :title, uniqueness: true
  validates :description, presence: true
end

