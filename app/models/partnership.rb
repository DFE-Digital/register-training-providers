# == Schema Information
#
# Table name: partnerships
#
#  id                     :uuid             not null, primary key
#  discarded_at           :datetime
#  duration               :daterange
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  accredited_provider_id :uuid             not null
#  provider_id            :uuid             not null
#
# Indexes
#
#  index_partnerships_on_accredited_provider_id  (accredited_provider_id)
#  index_partnerships_on_provider_id             (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (accredited_provider_id => providers.id)
#  fk_rails_...  (provider_id => providers.id)
#
class Partnership < ApplicationRecord
  self.implicit_order_column = :created_at
  include PgSearch::Model
  include Discard::Model

  include SaveAsTemporary

  audited except: [:provider_id, :accredited_provider_id]

  belongs_to :provider
  belongs_to :accredited_provider, class_name: "Provider"
  has_many :partnership_academic_years, dependent: :destroy
  has_many :academic_years, through: :partnership_academic_years
  has_many :partnership_types

  validate :partnership_types_present

  validate :partnership_types_remain_available, if: -> { persisted? && will_save_change_to_duration? }

  scope :current_or_scheduled, lambda {
    where("upper(duration) > ?", Time.zone.today)
  }

  scope :ended, lambda {
    where("upper(duration) <= ?", Time.zone.today)
  }

  scope :ordered_by_partner_and_date, ->(viewing_provider) {
    joins(
      sanitize_sql_array([
        "INNER JOIN providers AS partner ON partner.id = CASE
          WHEN partnerships.accredited_provider_id = ?
          THEN partnerships.provider_id
          ELSE partnerships.accredited_provider_id
        END",
        viewing_provider.id
      ])
    ).order("partner.operating_name ASC", "lower(partnerships.duration) ASC")
  }

  def other_partner(partner)
    return accredited_provider if partner == provider

    provider
  end

  def can_be_ended?(on: Time.zone.today)
    # A partnership that starts today has no days before `on` to end it on: the
    # duration would collapse to an empty range, which Postgres stores as
    # `empty` and reads back as no dates at all. Such a record is deleted
    # instead of ended.
    duration&.begin.is_a?(Date) && duration.begin < on && !ended_on?(on:)
  end

  def end!(on: Time.zone.today)
    return false unless can_be_ended?(on:)

    assign_attributes(duration: duration.begin...on)
    save!(validate: false)
  end

  # Records a type change on a partnership that is already running: the current
  # partnership is ended today and replaced by one starting today with the new
  # types. A submitted start date is applied to
  # the record being ended, which is the partnership it belongs to. Returns the
  # saved replacement, or nil when the revision could not be made — in which
  # case nothing is changed and any reason the replacement could not be saved is
  # added to this record's errors.
  def revise_types!(types, academic_years:, end_date:, start_date: nil, on: Time.zone.today)
    return unless can_be_ended?(on:)
    return unless replacement_end_date_valid?(end_date, on)
    return if start_date.present? && start_date >= on

    replacement = nil

    with_lock do
      if can_be_ended?(on:)
        snapshot = slice(:duration, :updated_at)
        candidate = build_replacement(types, academic_years:, end_date:, on:)
        apply_start_date(start_date)

        if end!(on:) && candidate.save
          replacement = candidate
        else
          copy_errors_from(candidate)
          restore_snapshot(snapshot)
          raise ActiveRecord::Rollback
        end
      end
    end

    replacement
  end

  # The partnership that replaced this one on the same day with the same types,
  # which a competing save creates when the same revision is submitted twice at
  # once. The types are matched too: another partnership for the same pair
  # created today is not this revision's replacement, and treating it as one
  # would report a revision that failed as saved.
  def same_day_replacement(types)
    expected = normalise_types(types)

    self.class.kept
        .current_or_scheduled
        .where(accredited_provider_id:, provider_id:)
        .where.not(id:)
        .where(created_at: Time.zone.today.all_day)
        .joins(:partnership_types)
        .where(partnership_types: { partnership_type: expected })
        .find { |candidate| types_of(candidate) == expected }
  end

  def scheduled?
    duration&.begin.is_a?(Date) && duration.begin > Time.zone.today
  end

  def status_label
    scheduled? ? "Scheduled" : "Active"
  end

  def ended_on?(on: Time.zone.today)
    duration&.end.is_a?(Date) && duration.end <= on
  end

  def status_tag
    { text: status_label, colour: scheduled? ? "blue" : "green" }
  end

  def sync_partnership_types(types)
    types = normalise_types(types)
    kept = partnership_types.kept.index_by(&:partnership_type)

    kept.each { |type, record| record.discard unless types.include?(type) }
    (types - kept.keys).each { |type| partnership_types.build(partnership_type: type, source: "user") }
  end

  def apply_partnership_types(types, source: "user")
    types.each do |type|
      partnership_types.build(partnership_type: type, source: source)
    end
  end

  def apply_default_partnership_type(source: "user")
    partnership_types.build(
      partnership_type: PartnershipTypeEnum::RECRUITMENT,
      source: source
    )
  end

private

  def build_replacement(types, academic_years:, end_date:, on:)
    replacement = Partnership.new(
      accredited_provider_id: accredited_provider_id,
      provider_id: provider_id,
      duration: replacement_duration(end_date, on),
      academic_years: academic_years
    )
    replacement.apply_partnership_types(types)
    replacement
  end

  def replacement_end_date_valid?(end_date, on)
    end_date.blank? || end_date > on
  end

  def apply_start_date(start_date)
    return if start_date.blank? || start_date == duration.begin

    assign_attributes(duration: start_date...duration.end)
  end

  # A rollback only undoes the database writes, so the attributes the revision
  # mutated have to be put back by hand: the caller renders this record, and
  # `revise_types!` promises that a failed revision changes nothing.
  def restore_snapshot(snapshot)
    assign_attributes(snapshot)
    clear_changes_information
  end

  def normalise_types(types)
    Array(types).compact_blank.map(&:to_s).uniq.sort
  end

  def types_of(partnership)
    normalise_types(partnership.partnership_types.kept.map(&:partnership_type))
  end

  # Keeps the reasons a replacement could not be saved on the record the caller
  # reports the failure for, since the replacement itself is rolled back.
  def copy_errors_from(replacement)
    messages = replacement.partnership_types.flat_map { |type| type.errors[:partnership_type] }
    messages += replacement.errors.full_messages

    messages.uniq.each { |message| errors.add(:base, message) }
  end

  def replacement_duration(end_date, on)
    end_date.present? ? Range.new(on, end_date, true) : Range.new(on, nil)
  end

  def partnership_types_present
    return if partnership_types.reject(&:discarded?).any?

    errors.add(:partnership_types, :blank)
  end

  def partnership_types_remain_available
    partnership_types.reject(&:discarded?).each do |type|
      next if type.valid?

      type.errors[:partnership_type].each { |message| errors.add(:base, message) }
    end
  end
end
