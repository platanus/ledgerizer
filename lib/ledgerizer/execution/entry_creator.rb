module Ledgerizer
  class EntryCreator
    include Ledgerizer::Errors

    delegate :movements, to: :executable_entry, prefix: false

    def initialize(entry:, executable_entry:)
      @entry = entry
      @executable_entry = executable_entry
    end

    def execute
      ActiveRecord::Base.transaction do
        persist_entry!
        movements.each { |movement| entry.create_line!(movement) }
      end

      true
    end

    private

    def persist_entry!
      if entry.persisted?
        raise_error("can't use Ledgerizer::EntryCreator with persisted entry ##{entry.id}")
      end

      entry.entry_date = executable_entry.entry_date
      entry.save!
    end

    attr_reader :entry, :executable_entry
  end
end
