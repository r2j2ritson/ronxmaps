
(function() {

  function findElementDeep(selector, root = document) {
    let el = root.querySelector(selector);
    if (el) return el;

    for (const node of root.querySelectorAll('*')) {
      if (node.shadowRoot) {
        el = findElementDeep(selector, node.shadowRoot);
        if (el) return el;
      }
    }
    return null;
  }

  function setReactValue(element, value) {
    const setter = Object.getOwnPropertyDescriptor(
      HTMLInputElement.prototype,
      'value'
    ).set;

    setter.call(element, value);

    element.dispatchEvent(new Event('input', { bubbles: true }));
    element.dispatchEvent(new Event('change', { bubbles: true }));
  }

  const emailField = findElementDeep('input[name="identifier"]');
  const passwordField = findElementDeep('input[name="password"]');
  const submitBtn = findElementDeep('button[name="method"][value="password"]');

  if (!emailField || !passwordField || !submitBtn) {
    return { email: !!emailField, password: !!passwordField, button: !!submitBtn };
  }

  setReactValue(emailField, "robert.ritson@idfg.idaho.gov");
  setReactValue(passwordField, "IDFG2020");

  setTimeout(() => submitBtn.click(), 250);

  return { ok: true };

})();

