module Ledgerizer
  class EntryCreator
    delegate :movements, to: :executable_entry, prefix: false

    def initialize(entry:, executable_entry:)
      @entry = entry
      @executable_entry = executable_entry
    end

    def execute
      ActiveRecord::Base.transaction do
        entry.save!
        movements.each { |movement| entry.create_line!(movement) }
      end

      true
    end

    private

    attr_reader :entry, :executable_entry
  end
end
