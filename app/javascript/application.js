import { initAll } from "govuk-frontend";
import accessibleAutocomplete from "accessible-autocomplete";

initAll();

// Build maps from option search text to display name and hint
function buildOptionMaps(selectEl) {
  const nameMap = {};
  const hintMap = {};
  Array.from(selectEl.options).forEach((option) => {
    if (option.value) {
      const searchText = option.textContent;
      nameMap[searchText] = option.dataset.name || searchText.split(" | ")[0];
      hintMap[searchText] = option.dataset.hint;
    }
  });
  return { nameMap, hintMap };
}

// Initialize accessible-autocomplete on elements rendered by DfE::Autocomplete::View
document
  .querySelectorAll('[data-module="app-dfe-autocomplete"]')
  .forEach((container) => {
    const selectEl = container.querySelector("select");
    if (!selectEl) return;

    const defaultValue = container.getAttribute("data-default-value") || "";
    const { nameMap, hintMap } = buildOptionMaps(selectEl);

    accessibleAutocomplete.enhanceSelectElement({
      selectElement: selectEl,
      defaultValue: defaultValue,
      minLength: 2,
      showAllValues: false,
      templates: {
        inputValue: (result) => {
          if (!result) return "";
          return nameMap[result] || result.split(" | ")[0];
        },
        suggestion: (result) => {
          if (!result) return "";
          const name = nameMap[result] || result.split(" | ")[0];
          const hint = hintMap[result];
          if (hint) {
            return `<strong>${name}</strong><br><span class="autocomplete__option--hint">${hint}</span>`;
          }
          return name;
        },
      },
    });
  });
