import accessibleAutocomplete from "accessible-autocomplete";
import tracker from "./tracker.js";
import {
  guard,
  renderTemplate,
  setHiddenField,
} from "./autocomplete/helpers.js";

const $allAutocompleteElements = document.querySelectorAll(
  '[data-module="app-partners-autocomplete"]',
);
const idElement = document.getElementById("partners-id");

let statusMessage = " ";

const fetchpartners = ({ query, populateResults }) => {
  const encodedQuery = encodeURIComponent(query);

  window
    .fetch(`/autocomplete/partners?query=${encodedQuery}`)
    .then((response) => response.json())
    .then(guard)
    .then((data) => data.training_partners)
    .then((partners) => {
      if (partners.length === 0) {
        statusMessage = "No results found";
      }

      return partners;
    })
    .then(populateResults)
    .catch(console.log);
};

const findPartners = ({ query, populateResults }) => {
  idElement.value = "";

  statusMessage = "Loading..."; // Shared state

  fetchpartners({ query, populateResults });
};

const setupAutoComplete = (form) => {
  const element = form.querySelector("#partners-autocomplete-element");
  const inputs = form.querySelectorAll('[data-field="partners-autocomplete"]');
  const defaultValueOption = element.getAttribute("data-default-value") || "";
  const fieldName = element.getAttribute("data-field-name") || "";

  try {
    inputs.forEach((input) => {
      accessibleAutocomplete({
        element,
        id: input.id,
        minLength: 2,
        defaultValue: defaultValueOption,
        name: fieldName,
        source: (query, populateResults) => {
          tracker.trackSearch(query);
          return findpartners({
            query,
            populateResults,
          });
        },
        templates: renderTemplate,
        onConfirm: (value) => {
          tracker.sendTrackingEvent(value, fieldName);
          setHiddenField(idElement, value);
        },
        tNoResults: () => statusMessage,
      });

      // Move autocomplete to the form group containing the input to be replaced
      const inputFormGroup = element.previousElementSibling;
      if (inputFormGroup.contains(input)) {
        inputFormGroup.appendChild(element);
      }

      input.remove();
    });
  } catch (err) {
    console.error("Could not enhance:", err);
  }
};

$allAutocompleteElements.forEach(setupAutoComplete);
