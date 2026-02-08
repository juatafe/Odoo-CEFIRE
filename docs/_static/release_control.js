document.addEventListener("DOMContentLoaded", () => {
  const today = new Date();
  document.querySelectorAll("details.sd-dropdown").forEach(el => {
    const span = el.querySelector(".release-date");
    if (span) {
      const release = span.dataset.release;
      const rDate = new Date(release);
      if (today < rDate) {
        el.innerHTML =
          "<p><em>La solució estarà disponible a partir del " +
          rDate.toLocaleDateString() +
          ".</em></p>";
      }
    }
  });
});
