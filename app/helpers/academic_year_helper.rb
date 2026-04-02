module AcademicYearHelper
  def academic_years_row(academic_years)
    academic_years_html = tag.ul(class: "govuk-list govuk-list--bullet") do
      academic_years.collect do |academic_year|
        concat tag.li(display_academic_year(academic_year))
      end
    end

    { key: { text: "Academic years" },
      value: { text: academic_years_html } }
  end

  def display_academic_year(academic_year)
    academic_year_text = "#{academic_year.duration.begin.year} to #{academic_year.duration.end.year}"
    [:current, :last, :next].each do |label|
      academic_year_text += " - #{label}" if academic_year.send(:"#{label}?")
    end

    academic_year_text
  end

  def academic_year_helper_text(academic_year)
    "Starts on 1 August #{academic_year.duration.begin.year}, ends on 31 July #{academic_year.duration.end.year}"
  end
end
