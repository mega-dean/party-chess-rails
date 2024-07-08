import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bank", "button", "chosen"]

  static values = {
    bank: Number,
    party: Array,
    url: String,
  }

  bankValueChanged() {
    this.bankTarget.innerHTML = this.bankValue;

    this.buttonTargets.forEach((element) => {
      if (parseInt(element.dataset.cost) <= this.bankValue) {
        element.dataset.affordable = 'yes';
        element.parentNode.classList.remove('not-affordable');
      } else {
        element.dataset.affordable = '';
        element.parentNode.classList.add('not-affordable');
      }
    });

    document.$("#join-button").disabled = (this.chosenTargets.length === 0);
  }

  removePiece(event) {
    const cost = event.params.cost;
    this.bankValue += cost;
    const parent = event.target.parentNode;
    parent.parentNode.removeChild(parent);
  }

  choosePiece(event) {
    if (event.target.dataset.affordable) {
      const img = document.createElement("img");

      const findSrc = (kind) => {
        const img = [...document.getElementsByTagName("img")].find((img) => {
          return img.dataset.kind === kind;
        });

        return img?.src;
      };

      img.src = findSrc(event.target.dataset.kind);

      img.dataset.kind = event.target.dataset.kind;
      img.dataset.choosePartyTarget = "chosen";

      const container = document.createElement("div");
      container.classList.add('chosen-piece-container');
      container.appendChild(img);

      const removeButton = document.createElement("button");
      removeButton.classList.add("remove-button");
      removeButton.innerHTML = "remove";
      removeButton.dataset.action = "click->choose-party#removePiece";
      const cost = parseInt(event.target.dataset.cost);
      removeButton.dataset.choosePartyCostParam = cost;
      container.appendChild(removeButton);

      document.$('#current-party').appendChild(container);

      let hiddenField = document.$('#js-chosen-kinds');
      hiddenField.value = this.chosenTargets.map((target) => target.dataset.kind).join();

      this.bankValue -= cost;
    }
  }

};
