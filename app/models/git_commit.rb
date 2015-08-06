require 'virtus'

class GitCommit
  include Virtus.value_object

  values do
    attribute :id, String
    attribute :author_name, String
    attribute :message, String
    attribute :time, Time
  end

  def subject_line
    message.split("\n").first
  end
end
