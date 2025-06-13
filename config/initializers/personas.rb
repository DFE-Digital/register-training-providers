PERSONAS = [
  { first_name: "Anne", last_name: "Wilson", email: "test1@education.gov.uk", discarded?: false },
  { first_name: "Mary", last_name: "Lawson", email: "test2@education.gov.uk", discarded?: false },
  { first_name: "Colin", last_name: "Chapman", email: "test3@education.gov.uk", discarded?: false },
  { first_name: "Marla", last_name: "Signer", email: "test4@education.gov.uk", discarded?: true },
].freeze

NON_EXISTING_PERSONA = { first_name: "Tyler", last_name: "Durden", email: "test5@education.gov.uk" }.freeze

PERSONA_EMAILS = PERSONAS.pluck(:email)
