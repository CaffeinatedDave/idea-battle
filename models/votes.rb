class Votes < ActiveRecord::Base
  #Empty class - only rules here (why not DB? Who knows... Ruby is strange)
  validates :uuid, uniqueness: true
  validates :left, presence: true
  validates :right, presence: true

  validate :result_check
  validate :uuid_format_check

  def result_check
    if result != nil
      if result != left && result != right
        errors.add(:result, "Can't have a result that wasn't asked for")
      end
    end
  end

  def uuid_format_check
    if uuid !~ /^[0-9A-F]{8}\-[0-9A-F]{4}\-[0-9A-F]{4}\-[0-9A-F]{4}\-[0-9A-F]{12}$/
      errors.add(:uuid, "Wrong format - use XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX")
    end
  end

end

