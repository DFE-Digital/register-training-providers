class AddAcademicCycles < ActiveRecord::Migration[8.1]
  def up
    2009.upto(2030).each do |year|
      AcademicCycle.create({ duration: Date.new(year, 8, 1)...Date.new(year + 1, 7, 31) })
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
