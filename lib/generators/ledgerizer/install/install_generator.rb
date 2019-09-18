class Ledgerizer::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  def create_initializer
    template "initializer.rb", "config/initializers/ledgerizer.rb"
  end
end
