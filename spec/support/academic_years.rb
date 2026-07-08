RSpec.configure do |config|
  config.include AcademicYearSpecHelper
  config.before(:each) do
    create(:academic_year, :current)
    create(:academic_year, :previous)
    create(:academic_year, :next)
  end
end
