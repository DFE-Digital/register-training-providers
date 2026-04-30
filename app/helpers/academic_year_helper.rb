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
      first_group, *remaining_group = academic_years.each_slice(3).to_a
      primary = academic_years_bullet_list(first_group)

      remaining_group = remaining_group.flatten

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
    list_class = if items.one?
                   "govuk-list"
                 else
                   "govuk-list govuk-list--bullet"
                 end

    content_tag(:ul, class: list_class) do
      items.map { |year| content_tag(:li, display_academic_year(year)) }.join.html_safe
    end
  end

  def display_academic_year(academic_year)
    academic_year_text = "#{academic_year.start_year} to #{academic_year.end_year}"
    [:current, :last, :next].each do |label|
      academic_year_text += " - #{label}" if academic_year.send(:"#{label}?")
    end

    academic_year_text
  end

  def academic_year_helper_text(academic_year)
    "Starts on 1 August #{academic_year.start_year}, ends on 31 July #{academic_year.end_year}"
  end

  def academic_years_label(academic_years)
    academic_years.index_by(&:start_year)
      .transform_values { |academic_year| display_academic_year(academic_year) }
      .stringify_keys
  end
end
