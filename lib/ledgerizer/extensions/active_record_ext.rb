module Ledgerizer
  module ActiveRecordExt
    extend ActiveSupport::Concern

    class_methods do
      def model_names
        model_files = Dir.glob(Rails.root.join("app", "models", "**", "*").to_s).select do |f|
          f.ends_with?('.rb') && !f.include?('concerns')
        end

        model_files.map do |file|
          file.split('/').last.split('.').first.singularize.to_sym
        end.sort
      end
    end
  end
end

ActiveRecord::Base.include Ledgerizer::ActiveRecordExt
