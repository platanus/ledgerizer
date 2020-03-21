module Ledgerizer
  class EntryEditor
    include Ledgerizer::Errors

    delegate :movements, to: :executable_entry, prefix: false

    def initialize(entry:, executable_entry:)
      @entry = entry
      @executable_entry = executable_entry
    end

    def execute
      validate_entry!
      true
    end

    private

    def validate_entry!
      if entry.new_record?
        raise_error("can't use Ledgerizer::EntryEditor with not persisted entry ##{entry.id}")
      end
    end

    attr_reader :entry, :executable_entry
  end
end
