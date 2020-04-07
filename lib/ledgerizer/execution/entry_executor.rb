module Ledgerizer
  class EntryExecutor
    include Ledgerizer::Validators
    include Ledgerizer::Formatters

    delegate :new_movements, :adjusted_movements, :entry_instance, :add_new_movement,
             to: :executable_entry, prefix: false

    def initialize(config:, tenant:, document:, entry_code:, entry_date:)
      @executable_entry = Ledgerizer::Execution::Entry.new(
        config: config,
        tenant: tenant,
        document: document,
        entry_code: entry_code,
        entry_date: entry_date
      )
    end

    def execute
      validate_existent_movements!
      validate_zero_trial_balance!(new_movements)
      create_entry
      true
    end

    private

    attr_reader :executable_entry

    def create_entry
      ActiveRecord::Base.transaction do
        return if adjusted_movements.none?

        validate_zero_trial_balance!(adjusted_movements)
        entry_instance.save!
        adjusted_movements.each do |movement|
          entry_instance.create_line!(movement)
        end
      end
    end

    def validate_existent_movements!
      raise_error("can't execute entry without movements") if new_movements.none?
    end

    def validate_zero_trial_balance!(movements)
      raise_error("trial balance must be zero") unless zero_trial_balance?(movements)
    end

    def zero_trial_balance?(movements)
      movements.inject(0) do |sum, movement|
        amount = movement.signed_amount
        amount = -amount if movement.credit?
        sum += amount
        sum
      end.zero?
    end
  end
end
