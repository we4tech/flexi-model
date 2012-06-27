require 'spec_helper'

describe 'Associate both HasAndBelongsToMany' do
  module YesHola

    class Poll
      include FlexiModel
      has_many :options
    end

    class Option
      include FlexiModel
    end

    class Participant
      include FlexiModel
      has_many :votes
    end

    class Vote
      include FlexiModel
      belongs_to :poll
      belongs_to :option
      belongs_to :participant
    end
  end
end