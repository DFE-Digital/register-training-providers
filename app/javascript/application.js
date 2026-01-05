import { initAll } from "govuk-frontend";
import accessibleAutocomplete from "accessible-autocomplete";

initAll();

// Initialize accessible-autocomplete on elements rendered by DfE::Autocomplete::View
document
  .querySelectorAll('[data-module="app-dfe-autocomplete"]')
  .forEach((container) => {
    const selectEl = container.querySelector("select");
    if (!selectEl) return;

    const defaultValue = container.getAttribute("data-default-value") || "";

    accessibleAutocomplete.enhanceSelectElement({
      selectElement: selectEl,
      defaultValue: defaultValue,
      minLength: 2,
      showAllValues: true,
    });
  });
