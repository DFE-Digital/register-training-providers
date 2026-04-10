module AcademicYearHelper
  def academic_years_row(academic_years, use_details)
    {
      key: { text: "Academic years" },
      value: { text: academic_years_html(academic_years, use_details) }
    }
  end

  def academic_years_html(academic_years, use_details)
    return content_tag(:p, "No academic years") if academic_years.blank?

    if use_details
      first_group, remaining_group = academic_years.each_slice(3).to_a
      primary = academic_years_bullet_list(first_group)

      if remaining_group.present?
        more = academic_years_bullet_list(remaining_group)
        safe_join([primary, govuk_details(summary_text: "More academic years", text: more)])
      else
        primary
      end
    else
      academic_years_bullet_list(academic_years)
    end
  end

  def academic_years_bullet_list(items)
    content_tag(:ul, class: "govuk-list govuk-list--bullet") do
      items.map { |year| content_tag(:li, display_academic_year(year)) }.join.html_safe
    end
  end

  def display_academic_year(academic_year)
    base = "#{academic_year.duration.begin.year} to #{academic_year.duration.end.year}"
    labels = %i[current last next].select { |l| academic_year.public_send("#{l}?") }
    labels.empty? ? base : "#{base} - #{labels.join(' - ')}"
  end

  def academic_year_helper_text(academic_year)
    "Starts on 1 August #{academic_year.duration.begin.year}, ends on 31 July #{academic_year.duration.end.year}"
  end
end
